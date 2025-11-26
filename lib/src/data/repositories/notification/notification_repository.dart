import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../features/notification/models/notification_model.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/firebase_collection_names.dart';
import '../../../utils/constants/firebase_field_names.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/exceptions/firebase_exceptions.dart';
import '../../../utils/exceptions/format_exceptions.dart';
import '../../../utils/exceptions/platform_exceptions.dart';

class NotificationRepository extends GetxController {
  static NotificationRepository get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = Uuid();

  /// Get notification subcollection reference for a user
  CollectionReference<Map<String, dynamic>> _getNotificationCollection(String userId) {
    return _db
        .collection(FirebaseCollectionNames.users)
        .doc(userId)
        .collection(FirebaseCollectionNames.notifications)
        .withConverter<Map<String, dynamic>>(
      fromFirestore: (snapshot, _) => snapshot.data()!,
      toFirestore: (value, _) => value,
    );
  }

  /// Stream all notifications for a user
  Stream<List<NotificationModel>> streamUserNotifications(String userId) {
    try {
      return _getNotificationCollection(userId)
          .orderBy(FirebaseFieldNames.createdAt, descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => NotificationModel.fromSnapshot(doc))
            .toList();
      });
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Get all notifications for a user
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final querySnapshot = await _getNotificationCollection(userId)
          .orderBy(FirebaseFieldNames.createdAt, descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => NotificationModel.fromSnapshot(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Stream unread notifications count for a user
  Stream<int> streamUnreadCount(String userId) {
    try {
      return _getNotificationCollection(userId)
          .where(FirebaseFieldNames.isRead, isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length)
          .handleError((error) {
        print('Error streaming unread count: $error');
        return 0;
      });
    } catch (e) {
      return Stream.value(0);
    }
  }

  /// Get unread notifications count
  Future<int> getUnreadCount(String userId) async {
    try {
      final querySnapshot = await _getNotificationCollection(userId)
          .where(FirebaseFieldNames.isRead, isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// 生成资料更新通知消息
  String generateProfileUpdateMessage({
    bool? usernameChanged,
    bool? roleChanged,
    bool? profileImageChanged,
    String? oldUsername,
    String? newUsername,
    String? oldRole,
    String? newRole,
    bool isManager = false,
  }) {
    final List<String> changeDetails = [];

    if (usernameChanged == true && oldUsername != null && newUsername != null) {
      changeDetails.add('Username: $oldUsername → $newUsername');
    }

    if (roleChanged == true && oldRole != null && newRole != null && isManager) {
      final formattedOldRole = _formatRole(oldRole);
      final formattedNewRole = _formatRole(newRole);
      changeDetails.add('Role: $formattedOldRole → $formattedNewRole');
    }

    if (profileImageChanged == true) {
      changeDetails.add('Profile picture has been updated');
    }

    if (changeDetails.isEmpty) {
      return 'Your account information has been updated by an administrator.';
    }

    final changesList = changeDetails.map((change) => '• $change').join('\n');

    return '''
Your account has been updated by an administrator with the following changes:

$changesList

Please review your profile to ensure all information is correct. If you did not request these changes, please contact support immediately.
    '''.trim();
  }

  /// 格式化角色名称
  String _formatRole(String role) {
    return role.split(' ').map((word) =>
    word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  /// Send a system notification to a user
  Future<void> sendSystemNotification({
    required String userId,
    required String title,
    required String message,
  }) async {
    try {
      final notificationId = _uuid.v4();
      final notification = NotificationModel(
        notificationId: notificationId,
        notificationType: NotificationType.system,
        notificationTitle: title,
        message: message,
        isRead: false,
        createdAt: DateTime.now(),
      );

      await _getNotificationCollection(userId)
          .doc(notificationId)
          .set(notification.toJson());
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      print('Error sending notification: $e');
      throw TTexts.commonErrorMessage;
    }
  }

  /// Send a reminder notification to a user
  Future<void> sendReminderNotification({
    required String userId,
    required String title,
    required String message,
  }) async {
    try {
      final notificationId = _uuid.v4();
      final notification = NotificationModel(
        notificationId: notificationId,
        notificationType: NotificationType.reminder,
        notificationTitle: title,
        message: message,
        isRead: false,
        createdAt: DateTime.now(),
      );

      await _getNotificationCollection(userId)
          .doc(notificationId)
          .set(notification.toJson());
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      print('Error sending notification: $e');
      throw TTexts.commonErrorMessage;
    }
  }

  /// Send account status notification
  Future<void> sendAccountStatusNotification({
    required String userId,
    required String title,
    required String message,
    required String statusType, // 'banned', 'restored', 'deleted', etc.
  }) async {
    try {
      final notificationId = _uuid.v4();
      final notification = NotificationModel(
        notificationId: notificationId,
        notificationType: NotificationType.account_status,
        notificationTitle: title,
        message: message,
        isRead: false,
        createdAt: DateTime.now(),
      );

      await _getNotificationCollection(userId)
          .doc(notificationId)
          .set(notification.toJson());
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      print('Error sending account status notification: $e');
      throw TTexts.commonErrorMessage;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _getNotificationCollection(userId)
          .doc(notificationId)
          .update({
        FirebaseFieldNames.isRead: true,
      });
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Mark notification as unread
  Future<void> markAsUnread(String userId, String notificationId) async {
    try {
      await _getNotificationCollection(userId)
          .doc(notificationId)
          .update({
        FirebaseFieldNames.isRead: false,
      });
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final querySnapshot = await _getNotificationCollection(userId)
          .where(FirebaseFieldNames.isRead, isEqualTo: false)
          .get();

      final batch = _db.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {FirebaseFieldNames.isRead: true});
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _getNotificationCollection(userId)
          .doc(notificationId)
          .delete();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Delete multiple notifications
  Future<void> deleteNotifications(String userId, List<String> notificationIds) async {
    try {
      final batch = _db.batch();
      for (var notificationId in notificationIds) {
        batch.delete(_getNotificationCollection(userId).doc(notificationId));
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Clear all read notifications
  Future<void> clearReadNotifications(String userId) async {
    try {
      final querySnapshot = await _getNotificationCollection(userId)
          .where(FirebaseFieldNames.isRead, isEqualTo: true)
          .get();

      final batch = _db.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications(String userId) async {
    try {
      final querySnapshot = await _getNotificationCollection(userId).get();

      final batch = _db.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Clean up old read notifications (older than 30 days)
  Future<void> cleanupOldNotifications(String userId) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
      final querySnapshot = await _getNotificationCollection(userId)
          .where(FirebaseFieldNames.isRead, isEqualTo: true)
          .where(FirebaseFieldNames.createdAt,
          isLessThan: thirtyDaysAgo.millisecondsSinceEpoch)
          .get();

      final batch = _db.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      print('Error cleaning up notifications: $e');
    }
  }

  /// Send delete account request notification to admin
  Future<void> sendDeleteAccountRequestNotification({
    required String adminId,
    required String requestId,
    required String managerUsername,
    required String managerEmail,
  }) async {
    try {
      final notificationId = _uuid.v4();
      final notification = NotificationModel(
        notificationId: notificationId,
        notificationType: NotificationType.delete_account_request,
        notificationTitle: 'Account Deletion Request',
        message: '$managerUsername ($managerEmail) has requested to delete their account. '
            'Please review and respond within 48 hours.',
        isRead: false,
        createdAt: DateTime.now(),
        requestId: requestId, // Link to the request
      );

      await _getNotificationCollection(adminId)
          .doc(notificationId)
          .set(notification.toJson());
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      print('Error sending delete request notification: $e');
      throw TTexts.commonErrorMessage;
    }
  }

  /// Send delete account response notification to manager
  Future<void> sendDeleteAccountResponseNotification({
    required String managerId,
    required String requestId,
    required bool approved,
    String? responseMessage,
  }) async {
    try {
      final notificationId = _uuid.v4();
      final notification = NotificationModel(
        notificationId: notificationId,
        notificationType: NotificationType.delete_account_request,
        notificationTitle: approved
            ? 'Account Deletion Approved'
            : 'Account Deletion Rejected',
        message: approved
            ? 'Your account deletion request has been approved. ${responseMessage ?? "Your account will be deleted and you will be logged out."}'
            : 'Your account deletion request has been rejected. ${responseMessage ?? "Please contact support for more information."}',
        isRead: false,
        createdAt: DateTime.now(),
        requestId: requestId,
      );

      await _getNotificationCollection(managerId)
          .doc(notificationId)
          .set(notification.toJson());
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      print('Error sending response notification: $e');
      throw TTexts.commonErrorMessage;
    }
  }
}