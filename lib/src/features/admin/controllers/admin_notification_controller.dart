import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../common/widgets/dialogs/dialog.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/notification/notification_repository.dart';
import '../../../data/repositories/user/delete_account_request_repository.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../../../utils/constants/admin_colors.dart';
import '../../../utils/constants/enums.dart';
import '../../notification/models/notification_model.dart';
import '../models/delete_account_request_model.dart';

class AdminNotificationController extends GetxController {
  final _notificationRepo = NotificationRepository.instance;
  final _requestRepo = Get.put(DeleteAccountRequestRepository());
  final _authRepo = AuthenticationRepository.instance;
  final _userRepo = UserRepository.instance;

  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;

  /// 这里仍然保留 map，但它只是「最近一次从 repo 拉下来的快照」，
  /// 不再作为单一真实来源；refresh 的时候总是从 repo 取最新。
  /// （已去掉 DeleteAccountRequestModel 的缓存，不再使用）
  // final RxMap<String, DeleteAccountRequestModel> requestsCache =
  //     <String, DeleteAccountRequestModel>{}.obs;

  final RxMap<String, String> responderUsernamesCache =
      <String, String>{}.obs;

  final RxBool isLoading = false.obs;
  final RxInt unreadCount = 0.obs;

  StreamSubscription<List<NotificationModel>>? _notificationSubscription;
  Timer? _expirationTimer;

  // Get current user ID
  String get currentUserId => _authRepo.authUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    _startNotificationListener();
    _startExpirationChecker();
  }

  @override
  void onClose() {
    _notificationSubscription?.cancel();
    _expirationTimer?.cancel();
    super.onClose();
  }

  /// Start listening to notifications
  void _startNotificationListener() {
    final userId = _authRepo.authUser?.uid;
    if (userId == null) return;

    _notificationSubscription = _notificationRepo
        .streamUserNotifications(userId)
        .listen(
          (notificationList) async {
        notifications.value = notificationList;
        unreadCount.value =
            notificationList.where((n) => !n.isRead).length;

        // 这里仍然会为当前这批通知加载相关 request，
        // 但每次都会从 repo 重新拉，确保数据是最新的
        await _loadRelatedRequests(notificationList);
      },
      onError: (error) {
        print('Error listening to notifications: $error');
      },
    );
  }

  /// Load related delete account requests
  Future<void> _loadRelatedRequests(
      List<NotificationModel> notifications) async {
    final requestIds = notifications
        .where((n) => n.requestId != null)
        .map((n) => n.requestId!)
        .toSet();

    // 清除不再相关的请求缓存
    // （现在不再缓存 DeleteAccountRequestModel，这里只保留注释）
    // requestsCache.removeWhere((key, value) => !requestIds.contains(key));

    for (var requestId in requestIds) {
      // 总是重新加载请求数据，确保状态最新
      final request = await _requestRepo.getRequestById(requestId);
      if (request != null) {
        // 不再写入 requestsCache

        // Load responder username if available
        if (request.responderId != null &&
            !responderUsernamesCache
                .containsKey(request.responderId)) {
          await _loadResponderUsername(request.responderId!);
        }
      }
    }
  }

  /// Load responder username
  Future<void> _loadResponderUsername(String userId) async {
    try {
      final user = await _userRepo.fetchUserDetailsById(userId);
      responderUsernamesCache[userId] = user.username.isNotEmpty
          ? user.username
          : user.email.split('@').first;
    } catch (e) {
      print('Error loading responder username: $e');
      responderUsernamesCache[userId] = 'an administrator';
    }
  }

  /// Get request by ID (从 cache 读快照；如果需要最新，外面自己调 refreshRequestData)
  /// （现在不再缓存 DeleteAccountRequestModel，这个方法也不再从 cache 取）
  DeleteAccountRequestModel? getRequestById(String requestId) {
    return null;
  }

  /// Get responder username
  String getResponderUsername(String userId) {
    if (userId.isEmpty) return 'an administrator';
    if (userId == currentUserId) return 'you';
    return responderUsernamesCache[userId] ?? 'an administrator';
  }

  /// Start periodic check for expired requests
  void _startExpirationChecker() {
    _expirationTimer = Timer.periodic(
      const Duration(minutes: 1),
          (_) async {
        await _requestRepo.markExpiredRequests();
      },
    );
  }

  /// Refresh notifications
  Future<void> refreshNotifications() async {
    try {
      isLoading.value = true;
      await _requestRepo.markExpiredRequests();

      // 清空本地快照，下次 listener 推送或手动 refreshRequestData 时会重新从 repo 拿
      // （已不再缓存 DeleteAccountRequestModel）
      // requestsCache.clear();
      responderUsernamesCache.clear();
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to refresh notifications',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final userId = _authRepo.authUser?.uid;
      if (userId == null) return;

      await _notificationRepo.markAsRead(userId, notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark notification as unread
  Future<void> markAsUnread(String notificationId) async {
    try {
      final userId = _authRepo.authUser?.uid;
      if (userId == null) return;

      await _notificationRepo.markAsUnread(userId, notificationId);
      TLoaders.customToast(message: 'Marked as unread');
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to mark as unread',
      );
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final userId = _authRepo.authUser?.uid;
      if (userId == null) return;

      await _notificationRepo.markAllAsRead(userId);
      TLoaders.successSnackBar(
        title: 'Success',
        message: 'All notifications marked as read',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to mark all as read',
      );
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final confirmed = await TDialog.confirmDialog(
        title: 'Delete Notification',
        message:
        'Are you sure you want to delete this notification?',
        confirmText: 'Delete',
        icon: Icons.delete_outline,
        iconColor: TAdminColors.error,
        confirmButtonColor: TAdminColors.error,
      );

      if (confirmed != true) return;

      final userId = _authRepo.authUser?.uid;
      if (userId == null) return;

      await _notificationRepo.deleteNotification(userId, notificationId);
      TLoaders.customToast(message: 'Notification deleted');
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to delete notification',
      );
    }
  }

  /// Clear read notifications
  Future<void> clearReadNotifications() async {
    try {
      final confirmed = await TDialog.confirmDialog(
        title: 'Clear Read Notifications',
        message:
        'Are you sure you want to clear all read notifications?',
        confirmText: 'Clear',
        icon: Icons.cleaning_services_outlined,
        iconColor: TAdminColors.warning,
        confirmButtonColor: TAdminColors.warning,
      );

      if (confirmed != true) return;

      final userId = _authRepo.authUser?.uid;
      if (userId == null) return;

      await _notificationRepo.clearReadNotifications(userId);
      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Read notifications cleared',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to clear notifications',
      );
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      final confirmed = await TDialog.confirmDialog(
        title: 'Clear All Notifications',
        message:
        'Are you sure you want to clear ALL notifications? This action cannot be undone.',
        confirmText: 'Clear All',
        icon: Icons.delete_sweep_outlined,
        iconColor: TAdminColors.error,
        confirmButtonColor: TAdminColors.error,
      );

      if (confirmed != true) return;

      final userId = _authRepo.authUser?.uid;
      if (userId == null) return;

      await _notificationRepo.clearAllNotifications(userId);
      TLoaders.successSnackBar(
        title: 'Success',
        message: 'All notifications cleared',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to clear notifications',
      );
    }
  }

  /// Respond to delete account request
  ///
  /// 注意：这里不再弹 dialog，`responseMessage` 由外面的 screen 传进来，
  /// 这样 `_showResponseDialog` 就可以完全移到 UI 层。
  Future<void> respondToDeleteRequest({
    required String requestId,
    required bool approved,
    required String responseMessage,
  }) async {
    try {
      isLoading.value = true;

      // 每次操作前，先从 repo 强制刷新一次，确保状态最新
      final freshRequest =
      await _requestRepo.getRequestById(requestId);

      if (freshRequest == null) {
        TLoaders.errorSnackBar(
          title: 'Error',
          message: 'Request not found',
        );
        return;
      }

      // 如果已经处理过 / 过期，可以在这里加保护
      if (!freshRequest.canRespond) {
        TLoaders.errorSnackBar(
          title: 'Error',
          message: 'This request can no longer be responded to',
        );
        // 顺便刷新一下 cache，让 UI 立刻更新
        // requestsCache[requestId] = freshRequest;
        return;
      }

      final adminId = _authRepo.authUser?.uid;
      if (adminId == null) return;

      // Respond to the request（真正写数据库）
      await _requestRepo.respondToRequest(
        requestId: requestId,
        adminId: adminId,
        approved: approved,
        responseMessage: responseMessage,
      );

      // Load admin username if not cached
      if (!responderUsernamesCache.containsKey(adminId)) {
        await _loadResponderUsername(adminId);
      }

      // 再次从 repo 拿最新版本，写入 cache（保证 status/isExpired 等字段和后端一致）
      // （已不再缓存 DeleteAccountRequestModel）
      // final updatedRequest =
      //     await _requestRepo.getRequestById(requestId);
      //
      // if (updatedRequest != null) {
      //   requestsCache[requestId] = updatedRequest;
      // }

      TLoaders.successSnackBar(
        title: 'Success',
        message: approved
            ? 'Delete request approved'
            : 'Delete request rejected',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to respond to request: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 强制刷新单个请求数据的方法（提供给 UI 在进入详情或返回时用）
  Future<void> refreshRequestData(String requestId) async {
    try {
      final request = await _requestRepo.getRequestById(requestId);
      if (request != null) {
        // requestsCache[requestId] = request;
      }
    } catch (e) {
      print('Error refreshing request data: $e');
    }
  }
}
