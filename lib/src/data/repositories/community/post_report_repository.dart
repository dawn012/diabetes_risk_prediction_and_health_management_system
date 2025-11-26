import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../features/community/models/post_report_model.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/firebase_collection_names.dart';
import '../../../utils/constants/firebase_field_names.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/exceptions/firebase_exceptions.dart';
import '../../../utils/exceptions/format_exceptions.dart';
import '../../../utils/exceptions/platform_exceptions.dart';
import '../notification/notification_repository.dart';

class PostReportRepository extends GetxController {
  static PostReportRepository get instance => Get.find();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _notificationRepo = NotificationRepository.instance;

  /// Get reports subcollection reference for a post
  CollectionReference<Map<String, dynamic>> _getReportsCollection(String postId) {
    return _db
        .collection(FirebaseCollectionNames.posts)
        .doc(postId)
        .collection(FirebaseCollectionNames.reports);
  }

  /// Check if user has already reported this post (with pending status)
  Future<bool> hasUserReportedPost(String postId, String userId) async {
    try {
      final querySnapshot = await _getReportsCollection(postId)
          .where(FirebaseFieldNames.reporterId, isEqualTo: userId)
          .where(FirebaseFieldNames.status, isEqualTo: ReportStatus.pending.value)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking user report: $e');
      return false;
    }
  }

  /// Submit a new report
  Future<String?> submitReport({
    required String postId,
    required ReportReason reason,
    String? additionalNote,
  }) async {
    try {
      final userId = _auth.currentUser!.uid;

      // Check if user already has a pending report
      final hasReported = await hasUserReportedPost(postId, userId);
      if (hasReported) {
        return 'You have already reported this post';
      }

      final reportId = const Uuid().v4();
      final now = DateTime.now();

      final report = PostReportModel(
        reportId: reportId,
        postId: postId,
        reporterId: userId,
        reason: reason,
        additionalNote: additionalNote,
        status: ReportStatus.pending,
        createdAt: now,
        resolvedAt: null,
      );

      // Save report
      await _getReportsCollection(postId)
          .doc(reportId)
          .set(report.toJson());

      // Update post's report count and latest report time
      await _updatePostReportStats(postId);

      return null;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      print('Error submitting report: $e');
      throw TTexts.commonErrorMessage;
    }
  }

  /// Update post report statistics
  Future<void> _updatePostReportStats(String postId) async {
    try {
      // Get pending reports count
      final pendingCount = await getPendingReportsCount(postId);

      // Get latest report time
      final latestReport = await _getReportsCollection(postId)
          .orderBy(FirebaseFieldNames.createdAt, descending: true)
          .limit(1)
          .get();

      DateTime? latestReportTime;
      if (latestReport.docs.isNotEmpty) {
        final reportData = latestReport.docs.first.data();
        latestReportTime = DateTime.fromMillisecondsSinceEpoch(
            reportData[FirebaseFieldNames.createdAt] ?? 0);
      }

      // Update post document
      await _db.collection(FirebaseCollectionNames.posts).doc(postId).update({
        FirebaseFieldNames.pendingReportCount: pendingCount,
        if (latestReportTime != null)
          FirebaseFieldNames.latestReportTime: latestReportTime.millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error updating post report stats: $e');
    }
  }

  /// Get pending reports count for a post
  Future<int> getPendingReportsCount(String postId) async {
    try {
      final querySnapshot = await _getReportsCollection(postId)
          .where(FirebaseFieldNames.status, isEqualTo: ReportStatus.pending.value)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting pending reports count: $e');
      return 0;
    }
  }

  /// Get all reports for a post (for admin)
  Future<List<PostReportModel>> getPostReports(String postId, {ReportStatus? status}) async {
    try {
      Query<Map<String, dynamic>> query = _getReportsCollection(postId);

      if (status != null) {
        query = query.where(FirebaseFieldNames.status, isEqualTo: status.value);
      }

      query = query.orderBy(
        status == ReportStatus.resolved ? FirebaseFieldNames.resolvedAt : FirebaseFieldNames.createdAt,
        descending: true,
      );

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => PostReportModel.fromSnapshot(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      print('Error getting post reports: $e');
      throw TTexts.commonErrorMessage;
    }
  }

  /// Mark report as reviewed (resolved)
  Future<String?> markReportAsReviewed(String postId, String reportId) async {
    try {
      final now = DateTime.now();

      await _getReportsCollection(postId).doc(reportId).update({
        FirebaseFieldNames.status: ReportStatus.resolved.value,
        FirebaseFieldNames.resolvedAt: now.millisecondsSinceEpoch,
      });

      // Get report to send notification to reporter
      final reportDoc = await _getReportsCollection(postId).doc(reportId).get();
      if (reportDoc.exists) {
        final report = PostReportModel.fromSnapshot(reportDoc);

        // Send notification to reporter
        await _notificationRepo.sendSystemNotification(
          userId: report.reporterId,
          title: 'Report Reviewed',
          message: 'We have received your report and reviewed it. Your help makes the community better.',
        );
      }

      // Update post statistics
      await _updatePostReportStats(postId);

      return null;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      print('Error marking report as reviewed: $e');
      throw TTexts.commonErrorMessage;
    }
  }

  /// Mark multiple reports as reviewed
  Future<String?> markMultipleReportsAsReviewed(String postId, List<String> reportIds) async {
    try {
      final now = DateTime.now();
      final batch = _db.batch();

      // Get all reports first to send notifications
      List<PostReportModel> reports = [];
      for (String reportId in reportIds) {
        final reportDoc = await _getReportsCollection(postId).doc(reportId).get();
        if (reportDoc.exists) {
          reports.add(PostReportModel.fromSnapshot(reportDoc));
        }

        batch.update(
          _getReportsCollection(postId).doc(reportId),
          {
            FirebaseFieldNames.status: ReportStatus.resolved.value,
            FirebaseFieldNames.resolvedAt: now.millisecondsSinceEpoch,
          },
        );
      }

      await batch.commit();

      // Send notifications to all reporters
      for (var report in reports) {
        await _notificationRepo.sendSystemNotification(
          userId: report.reporterId,
          title: 'Report Reviewed',
          message: 'We have received your report and reviewed it. Your help makes the community better.',
        );
      }

      // Update post statistics
      await _updatePostReportStats(postId);

      return null;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      print('Error marking reports as reviewed: $e');
      throw TTexts.commonErrorMessage;
    }
  }

  /// Disable post and mark report as resolved
  Future<String?> disablePostFromReport(String postId, String reportId) async {
    try {
      final now = DateTime.now();

      // Get post document to get poster ID
      final postDoc = await _db.collection(FirebaseCollectionNames.posts).doc(postId).get();
      if (!postDoc.exists) {
        return 'Post not found';
      }
      final posterId = postDoc.data()?[FirebaseFieldNames.posterId] ?? '';

      // Disable the post
      await _db.collection(FirebaseCollectionNames.posts).doc(postId).update({
        FirebaseFieldNames.isDisable: true,
      });

      // Mark report as resolved
      await _getReportsCollection(postId).doc(reportId).update({
        FirebaseFieldNames.status: ReportStatus.resolved.value,
        FirebaseFieldNames.resolvedAt: now.millisecondsSinceEpoch,
      });

      // Send notification to post owner
      await _notificationRepo.sendSystemNotification(
        userId: posterId,
        title: 'Post Disabled',
        message: 'Your post has been reviewed and is temporarily unavailable due to community guidelines. Please make any necessary updates and you can repost it.',
      );

      // Get report to send notification to reporter
      final reportDoc = await _getReportsCollection(postId).doc(reportId).get();
      if (reportDoc.exists) {
        final report = PostReportModel.fromSnapshot(reportDoc);

        await _notificationRepo.sendSystemNotification(
          userId: report.reporterId,
          title: 'Report Reviewed',
          message: 'We have received your report and reviewed it. Your help makes the community better.',
        );
      }

      // Update post statistics
      await _updatePostReportStats(postId);

      return null;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      print('Error disabling post from report: $e');
      throw TTexts.commonErrorMessage;
    }
  }

  /// Resolve all pending reports for a post (when user edits the post)
  Future<void> resolveAllPendingReportsForPost(String postId) async {
    try {
      final now = DateTime.now();

      // Get all pending reports
      final pendingReports = await _getReportsCollection(postId)
          .where(FirebaseFieldNames.status, isEqualTo: ReportStatus.pending.value)
          .get();

      if (pendingReports.docs.isEmpty) return;

      // Batch update all to resolved
      final batch = _db.batch();
      for (var doc in pendingReports.docs) {
        batch.update(doc.reference, {
          FirebaseFieldNames.status: ReportStatus.resolved.value,
          FirebaseFieldNames.resolvedAt: now.millisecondsSinceEpoch,
        });
      }
      await batch.commit();

      // Update post statistics
      await _updatePostReportStats(postId);
    } catch (e) {
      print('Error resolving pending reports: $e');
    }
  }

  /// Get reporter user data for display
  Future<Map<String, dynamic>?> getReporterInfo(String reporterId) async {
    try {
      final userDoc = await _db
          .collection(FirebaseCollectionNames.users)
          .doc(reporterId)
          .get();

      if (userDoc.exists) {
        return userDoc.data();
      }
      return null;
    } catch (e) {
      print('Error getting reporter info: $e');
      return null;
    }
  }
}