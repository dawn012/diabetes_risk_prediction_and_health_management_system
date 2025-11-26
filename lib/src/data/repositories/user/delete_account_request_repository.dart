import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../features/admin/models/delete_account_request_model.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/exceptions/firebase_exceptions.dart';
import '../../../utils/exceptions/format_exceptions.dart';
import '../../../utils/exceptions/platform_exceptions.dart';
import '../notification/notification_repository.dart';
import '../user/user_repository.dart';

/// Repository for managing delete account requests
class DeleteAccountRequestRepository extends GetxController {
  static DeleteAccountRequestRepository get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = Uuid();

  // Collection name for delete requests
  static const String _collectionName = 'deleteAccountRequests';

  /// Get request collection reference
  CollectionReference<Map<String, dynamic>> _getRequestCollection() {
    return _db.collection(_collectionName);
  }

  /// Stream all pending delete requests
  Stream<List<DeleteAccountRequestModel>> streamPendingRequests() {
    try {
      return _getRequestCollection()
          .where('status', isEqualTo: RequestStatus.pending.name)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => DeleteAccountRequestModel.fromSnapshot(doc))
            .where((request) => !request.isExpired) // Filter expired ones
            .toList();
      });
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Stream requests by manager ID
  Stream<List<DeleteAccountRequestModel>> streamManagerRequests(String managerId) {
    try {
      return _getRequestCollection()
          .where('requesterId', isEqualTo: managerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => DeleteAccountRequestModel.fromSnapshot(doc))
            .toList();
      });
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Create a new delete account request
  Future<String> createRequest({
    required String managerId,
    required String managerUsername,
    required String managerEmail,
  }) async {
    try {
      // Check if manager already has a pending request
      final existingRequests = await _getRequestCollection()
          .where('requesterId', isEqualTo: managerId)
          .where('status', isEqualTo: RequestStatus.pending.name)
          .get();

      // Filter non-expired pending requests
      final hasValidPending = existingRequests.docs.any((doc) {
        final request = DeleteAccountRequestModel.fromSnapshot(doc);
        return !request.isExpired;
      });

      if (hasValidPending) {
        throw 'You already have a pending delete account request.';
      }

      final requestId = _uuid.v4();
      final now = DateTime.now();
      final expiresAt = now.add(Duration(hours: 48));

      final request = DeleteAccountRequestModel(
        requestId: requestId,
        requesterId: managerId,
        requesterUsername: managerUsername,
        requesterEmail: managerEmail,
        status: RequestStatus.pending,
        createdAt: now,
        expiresAt: expiresAt,
      );

      // Save request to Firestore
      await _getRequestCollection().doc(requestId).set(request.toJson());

      // Send notifications to all admins
      await _sendNotificationsToAdmins(request);

      return requestId;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw e.toString();
    }
  }

  /// Send notifications to all admins
  Future<void> _sendNotificationsToAdmins(DeleteAccountRequestModel request) async {
    try {
      // Get all admin users
      final adminsSnapshot = await _db
          .collection('users')
          .where('userType', isEqualTo: 'admin')
          .get();

      if (adminsSnapshot.docs.isEmpty) {
        throw 'No administrators found to process this request.';
      }

      // Send notification to each admin
      for (var adminDoc in adminsSnapshot.docs) {
        await NotificationRepository.instance.sendDeleteAccountRequestNotification(
          adminId: adminDoc.id,
          requestId: request.requestId,
          managerUsername: request.requesterUsername,
          managerEmail: request.requesterEmail,
        );
      }
    } catch (e) {
      print('Error sending notifications to admins: $e');
      // Don't throw - request was created successfully
    }
  }

  /// Respond to a delete account request
  Future<void> respondToRequest({
    required String requestId,
    required String adminId,
    required bool approved,
    String? responseMessage,
  }) async {
    try {
      final now = DateTime.now();
      final status = approved ? RequestStatus.approved : RequestStatus.rejected;

      // Get the request
      final requestDoc = await _getRequestCollection().doc(requestId).get();
      if (!requestDoc.exists) {
        throw 'Request not found.';
      }

      final request = DeleteAccountRequestModel.fromSnapshot(requestDoc);

      // Check if can respond
      if (!request.canRespond) {
        if (request.isExpired) {
          throw 'This request has expired.';
        }
        throw 'This request has already been responded to.';
      }

      // Update request status
      await _getRequestCollection().doc(requestId).update({
        'status': status.name,
        'responderId': adminId,
        'responseMessage': responseMessage,
        'respondedAt': now.millisecondsSinceEpoch,
      });

      // Send notification to manager
      await NotificationRepository.instance.sendDeleteAccountResponseNotification(
        managerId: request.requesterId,
        requestId: requestId,
        approved: approved,
        responseMessage: responseMessage,
      );

      // If approved, mark manager account as deleted
      if (approved) {
        await UserRepository.instance.updateSingleField(
          {
            'isDeleted': true,
          },
          userId: request.requesterId,
        );
      }
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw e.toString();
    }
  }

  /// Get request by ID
  Future<DeleteAccountRequestModel?> getRequestById(String requestId) async {
    try {
      final doc = await _getRequestCollection().doc(requestId).get();
      if (!doc.exists) return null;
      return DeleteAccountRequestModel.fromSnapshot(doc);
    } catch (e) {
      print('Error getting request: $e');
      return null;
    }
  }

  /// Check if manager has pending request
  Future<bool> hasPendingRequest(String managerId) async {
    try {
      final querySnapshot = await _getRequestCollection()
          .where('requesterId', isEqualTo: managerId)
          .where('status', isEqualTo: RequestStatus.pending.name)
          .get();

      // Check if any non-expired pending request exists
      return querySnapshot.docs.any((doc) {
        final request = DeleteAccountRequestModel.fromSnapshot(doc);
        return !request.isExpired;
      });
    } catch (e) {
      print('Error checking pending request: $e');
      return false;
    }
  }

  /// Mark expired requests
  Future<void> markExpiredRequests() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      // 查询所有pending状态的请求
      final pendingRequests = await _getRequestCollection()
          .where('status', isEqualTo: RequestStatus.pending.name)
          .get();

      final batch = _db.batch();
      bool hasUpdates = false;

      for (var doc in pendingRequests.docs) {
        final data = doc.data();
        final expiresAt = data['expiresAt'] as int?;

        // 直接通过时间戳判断是否过期
        if (expiresAt != null && now > expiresAt) {
          batch.update(doc.reference, {
            'status': RequestStatus.expired.name,
          });
          hasUpdates = true;
        }
      }

      if (hasUpdates) {
        await batch.commit();
        print('标记了过期的请求');
      }
    } catch (e) {
      print('Error marking expired requests: $e');
    }
  }

  /// Get pending requests count for admin
  Future<int> getPendingRequestsCount() async {
    try {
      final querySnapshot = await _getRequestCollection()
          .where('status', isEqualTo: RequestStatus.pending.name)
          .get();

      // Count non-expired requests
      return querySnapshot.docs.where((doc) {
        final request = DeleteAccountRequestModel.fromSnapshot(doc);
        return !request.isExpired;
      }).length;
    } catch (e) {
      print('Error getting pending requests count: $e');
      return 0;
    }
  }

  /// Delete old completed/rejected/expired requests (cleanup)
  Future<void> cleanupOldRequests({int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      final oldRequests = await _getRequestCollection()
          .where('status', whereIn: [
        RequestStatus.approved.name,
        RequestStatus.rejected.name,
        RequestStatus.expired.name,
      ])
          .get();

      final batch = _db.batch();

      for (var doc in oldRequests.docs) {
        final request = DeleteAccountRequestModel.fromSnapshot(doc);

        if (request.createdAt.isBefore(cutoffDate)) {
          batch.delete(doc.reference);
        }
      }

      await batch.commit();
    } catch (e) {
      print('Error cleaning up old requests: $e');
    }
  }
}