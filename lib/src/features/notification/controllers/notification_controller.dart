import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/notification/notification_repository.dart';
import '../models/notification_model.dart';

class NotificationController extends GetxController {
  static NotificationController get instance => Get.find();

  final notificationRepository = NotificationRepository.instance;
  final authRepository = AuthenticationRepository.instance;

  // PageController for tab swiping
  late PageController pageController;

  // Observables
  final RxList<NotificationModel> allNotifications = <NotificationModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt selectedTabIndex = 0.obs; // 0: All, 1: Unread, 2: Read
  final RxBool isSelectionMode = false.obs;
  final RxList<String> selectedNotificationIds = <String>[].obs;

  // Computed properties
  List<NotificationModel> get unreadNotifications =>
      allNotifications.where((n) => !n.isRead).toList();

  List<NotificationModel> get readNotifications =>
      allNotifications.where((n) => n.isRead).toList();

  int get unreadCount => unreadNotifications.length;
  int get totalCount => allNotifications.length;
  bool get hasUnreadNotifications => unreadCount > 0;

  List<NotificationModel> get currentTabNotifications {
    switch (selectedTabIndex.value) {
      case 1:
        return unreadNotifications;
      case 2:
        return readNotifications;
      default:
        return allNotifications;
    }
  }

  StreamSubscription? _notificationStreamSubscription;

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: selectedTabIndex.value);
    _subscribeToNotifications();
  }

  @override
  void onClose() {
    _notificationStreamSubscription?.cancel();
    pageController.dispose();
    super.onClose();
  }

  /// Change tab (All, Unread, Read)
  void changeTab(int index) {
    if (selectedTabIndex.value == index) return;

    selectedTabIndex.value = index;

    // Animate to page if not already there
    if (pageController.hasClients && pageController.page?.round() != index) {
      pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    exitSelectionMode();
  }

  /// Subscribe to notification stream
  void _subscribeToNotifications() {
    final userId = authRepository.authUser?.uid;
    if (userId == null) return;

    isLoading.value = true;

    _notificationStreamSubscription = notificationRepository
        .streamUserNotifications(userId)
        .listen(
          (notifications) {
        _processNotifications(notifications);
        isLoading.value = false;
      },
      onError: (error) {
        print('Error loading notifications: $error');
        isLoading.value = false;
        TLoaders.errorSnackBar(
          title: 'Error',
          message: 'Failed to load notifications',
        );
      },
    );
  }

  /// Process and filter notifications
  void _processNotifications(List<NotificationModel> notifications) {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(Duration(days: 30));

    // Filter out read notifications older than 30 days
    final validNotifications = notifications.where((notification) {
      if (notification.isRead && notification.createdAt.isBefore(thirtyDaysAgo)) {
        return false;
      }
      return true;
    }).toList();

    allNotifications.assignAll(validNotifications);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final userId = authRepository.authUser?.uid;
    if (userId == null) return;

    try {
      await notificationRepository.markAsRead(userId, notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark notification as unread
  Future<void> markAsUnread(String notificationId) async {
    final userId = authRepository.authUser?.uid;
    if (userId == null) return;

    try {
      await notificationRepository.markAsUnread(userId, notificationId);
    } catch (e) {
      print('Error marking notification as unread: $e');
    }
  }

  /// Delete single notification
  Future<void> deleteNotification(String notificationId) async {
    final userId = authRepository.authUser?.uid;
    if (userId == null) return;

    try {
      await notificationRepository.deleteNotification(userId, notificationId);
      TLoaders.successSnackBar(title: 'Notification deleted successfully');
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to delete notification',
      );
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final userId = authRepository.authUser?.uid;
    if (userId == null) return;

    try {
      await notificationRepository.markAllAsRead(userId);
      TLoaders.successSnackBar(title: 'All notifications marked as read');
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to mark all as read',
      );
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    final userId = authRepository.authUser?.uid;
    if (userId == null) return;

    try {
      await notificationRepository.clearAllNotifications(userId);
      TLoaders.successSnackBar(title: 'All notifications cleared');
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to clear notifications',
      );
    }
  }

  /// Clear all read notifications
  Future<void> clearReadNotifications() async {
    final userId = authRepository.authUser?.uid;
    if (userId == null) return;

    try {
      await notificationRepository.clearReadNotifications(userId);
      TLoaders.successSnackBar(title: 'Read notifications cleared');
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to clear read notifications',
      );
    }
  }

  /// Toggle selection mode
  void toggleSelectionMode() {
    isSelectionMode.value = !isSelectionMode.value;
    if (!isSelectionMode.value) {
      selectedNotificationIds.clear();
    }
  }

  /// Exit selection mode
  void exitSelectionMode() {
    isSelectionMode.value = false;
    selectedNotificationIds.clear();
  }

  /// Toggle notification selection
  void toggleNotificationSelection(String notificationId) {
    if (selectedNotificationIds.contains(notificationId)) {
      selectedNotificationIds.remove(notificationId);
    } else {
      selectedNotificationIds.add(notificationId);
    }

    // Exit selection mode if no items are selected
    if (selectedNotificationIds.isEmpty) {
      isSelectionMode.value = false;
    }
  }

  /// Select all notifications in current view
  void selectAllInCurrentView() {
    selectedNotificationIds.assignAll(
      currentTabNotifications.map((n) => n.notificationId).toList(),
    );
  }

  /// Deselect all notifications
  void deselectAll() {
    selectedNotificationIds.clear();
  }

  /// Delete selected notifications
  Future<void> deleteSelectedNotifications() async {
    final userId = authRepository.authUser?.uid;
    if (userId == null) return;

    try {
      await notificationRepository.deleteNotifications(
        userId,
        selectedNotificationIds.toList(),
      );
      exitSelectionMode();
      TLoaders.successSnackBar(
        title: 'Notifications deleted',
        message: '${selectedNotificationIds.length} notifications deleted successfully',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to delete notifications',
      );
    }
  }

  /// Mark selected notifications as read
  Future<void> markSelectedAsRead() async {
    final userId = authRepository.authUser?.uid;
    if (userId == null) return;

    try {
      for (final notificationId in selectedNotificationIds) {
        await notificationRepository.markAsRead(userId, notificationId);
      }
      exitSelectionMode();
      TLoaders.successSnackBar(
        title: 'Notifications updated',
        message: '${selectedNotificationIds.length} notifications marked as read',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to update notifications',
      );
    }
  }

  /// Mark selected notifications as unread
  Future<void> markSelectedAsUnread() async {
    final userId = authRepository.authUser?.uid;
    if (userId == null) return;

    try {
      for (final notificationId in selectedNotificationIds) {
        await notificationRepository.markAsUnread(userId, notificationId);
      }
      exitSelectionMode();
      TLoaders.successSnackBar(
        title: 'Notifications updated',
        message: '${selectedNotificationIds.length} notifications marked as unread',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to update notifications',
      );
    }
  }

  /// Refresh notifications
  Future<void> refreshNotifications() async {
    // The stream will automatically update
    isLoading.value = true;
    await Future.delayed(Duration(milliseconds: 500));
    isLoading.value = false;
  }
}