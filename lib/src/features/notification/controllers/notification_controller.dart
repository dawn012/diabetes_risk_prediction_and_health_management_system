import 'package:get/get.dart';
import '../../../common/loaders/loaders.dart';
import '../models/notification_model.dart';

class NotificationController extends GetxController {
  static NotificationController get instance => Get.find();

  // Observables
  final RxList<NotificationModel> allNotifications = <NotificationModel>[].obs;
  final RxList<NotificationModel> unreadNotifications = <NotificationModel>[].obs;
  final RxList<NotificationModel> readNotifications = <NotificationModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt selectedTabIndex = 0.obs; // 0: All, 1: Unread, 2: Read
  final RxBool isSelectionMode = false.obs;
  final RxList<String> selectedNotificationIds = <String>[].obs;

  // Computed properties
  int get unreadCount => unreadNotifications.length;
  int get totalCount => allNotifications.length;
  bool get hasUnreadNotifications => unreadNotifications.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    loadSampleData();
  }

  /// Load sample notification data
  void loadSampleData() {
    isLoading.value = true;

    final now = DateTime.now();
    final sampleNotifications = [
      NotificationModel(
        notificationId: '1',
        notificationType: 'reminder',
        notificationTitle: 'Daily Health Check Reminder',
        message: 'It\'s time to log your blood pressure and glucose levels. Stay consistent with your health tracking!',
        isRead: false,
        createdAt: now.subtract(Duration(minutes: 30)),
      ),
      NotificationModel(
        notificationId: '2',
        notificationType: 'reminder',
        notificationTitle: 'Medication Reminder',
        message: 'Don\'t forget to take your morning medication. Metformin 500mg.',
        isRead: false,
        createdAt: now.subtract(Duration(hours: 2)),
      ),
      NotificationModel(
        notificationId: '3',
        notificationType: 'system',
        notificationTitle: 'System Update',
        message: 'New features available! Check out the improved health analytics and community features.',
        isRead: false,
        createdAt: now.subtract(Duration(hours: 4)),
      ),
      NotificationModel(
        notificationId: '4',
        notificationType: 'system',
        notificationTitle: 'Weekly Health Report Ready',
        message: 'Your weekly health summary is now available. Your average glucose level has improved by 8%.',
        isRead: true,
        createdAt: now.subtract(Duration(days: 1)),
      ),
      NotificationModel(
        notificationId: '5',
        notificationType: 'reminder',
        notificationTitle: 'Exercise Reminder',
        message: 'Time for your evening walk! You\'ve walked 6,500 steps today. Just 1,500 more to reach your goal!',
        isRead: true,
        createdAt: now.subtract(Duration(days: 1, hours: 3)),
      ),
      NotificationModel(
        notificationId: '6',
        notificationType: 'system',
        notificationTitle: 'Community Achievement',
        message: 'Congratulations! You\'ve been active in the community for 7 consecutive days. Keep it up!',
        isRead: true,
        createdAt: now.subtract(Duration(days: 2)),
      ),
      NotificationModel(
        notificationId: '7',
        notificationType: 'reminder',
        notificationTitle: 'Appointment Reminder',
        message: 'Your doctor appointment is scheduled for tomorrow at 2:00 PM. Don\'t forget to bring your health records.',
        isRead: false,
        createdAt: now.subtract(Duration(hours: 6)),
      ),
      NotificationModel(
        notificationId: '8',
        notificationType: 'system',
        notificationTitle: 'Data Backup Complete',
        message: 'Your health data has been successfully backed up to the cloud. All your information is secure.',
        isRead: true,
        createdAt: now.subtract(Duration(days: 3)),
      ),
      NotificationModel(
        notificationId: '9',
        notificationType: 'reminder',
        notificationTitle: 'Sleep Quality Reminder',
        message: 'You haven\'t logged your sleep quality today. Good sleep is crucial for managing diabetes.',
        isRead: false,
        createdAt: now.subtract(Duration(minutes: 45)),
      ),
      NotificationModel(
        notificationId: '10',
        notificationType: 'system',
        notificationTitle: 'Security Alert',
        message: 'A new device has been logged into your account. If this wasn\'t you, please secure your account immediately.',
        isRead: true,
        createdAt: now.subtract(Duration(days: 5)),
      ),
    ];

    allNotifications.assignAll(sampleNotifications);
    _filterNotifications();
    isLoading.value = false;
  }

  /// Filter notifications into read and unread
  void _filterNotifications() {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(Duration(days: 30));

    // Filter out read notifications older than 30 days
    final validNotifications = allNotifications.where((notification) {
      if (notification.isRead && notification.createdAt.isBefore(thirtyDaysAgo)) {
        return false;
      }
      return true;
    }).toList();

    allNotifications.assignAll(validNotifications);
    unreadNotifications.assignAll(validNotifications.where((n) => !n.isRead).toList());
    readNotifications.assignAll(validNotifications.where((n) => n.isRead).toList());
  }

  /// Change tab (All, Unread, Read)
  void changeTab(int index) {
    selectedTabIndex.value = index;
    exitSelectionMode();
  }

  /// Mark notification as read
  void markAsRead(String notificationId) {
    final index = allNotifications.indexWhere((n) => n.notificationId == notificationId);
    if (index != -1 && !allNotifications[index].isRead) {
      allNotifications[index] = allNotifications[index].copyWith(isRead: true);
      _filterNotifications();
    }
  }

  /// Mark notification as unread
  void markAsUnread(String notificationId) {
    final index = allNotifications.indexWhere((n) => n.notificationId == notificationId);
    if (index != -1 && allNotifications[index].isRead) {
      allNotifications[index] = allNotifications[index].copyWith(isRead: false);
      _filterNotifications();
    }
  }

  /// Delete single notification
  void deleteNotification(String notificationId) {
    allNotifications.removeWhere((n) => n.notificationId == notificationId);
    _filterNotifications();
    TLoaders.successSnackBar(title: 'Notification deleted successfully');
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    for (int i = 0; i < allNotifications.length; i++) {
      if (!allNotifications[i].isRead) {
        allNotifications[i] = allNotifications[i].copyWith(isRead: true);
      }
    }
    _filterNotifications();
    TLoaders.successSnackBar(title: 'All notifications marked as read');
  }

  /// Clear all notifications
  void clearAllNotifications() {
    allNotifications.clear();
    _filterNotifications();
    TLoaders.successSnackBar(title: 'All notifications cleared');
  }

  /// Clear all read notifications
  void clearReadNotifications() {
    allNotifications.removeWhere((n) => n.isRead);
    _filterNotifications();
    TLoaders.successSnackBar(title: 'Read notifications cleared');
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
    List<NotificationModel> currentNotifications;
    switch (selectedTabIndex.value) {
      case 1:
        currentNotifications = unreadNotifications;
        break;
      case 2:
        currentNotifications = readNotifications;
        break;
      default:
        currentNotifications = allNotifications;
    }

    selectedNotificationIds.assignAll(
      currentNotifications.map((n) => n.notificationId).toList(),
    );
  }

  /// Deselect all notifications
  void deselectAll() {
    selectedNotificationIds.clear();
  }

  /// Delete selected notifications
  void deleteSelectedNotifications() {
    allNotifications.removeWhere((n) => selectedNotificationIds.contains(n.notificationId));
    _filterNotifications();
    exitSelectionMode();
    TLoaders.successSnackBar(
      title: 'Notifications deleted',
      message: '${selectedNotificationIds.length} notifications deleted successfully',
    );
  }

  /// Mark selected notifications as read
  void markSelectedAsRead() {
    for (int i = 0; i < allNotifications.length; i++) {
      if (selectedNotificationIds.contains(allNotifications[i].notificationId)) {
        allNotifications[i] = allNotifications[i].copyWith(isRead: true);
      }
    }
    _filterNotifications();
    exitSelectionMode();
    TLoaders.successSnackBar(
      title: 'Notifications updated',
      message: '${selectedNotificationIds.length} notifications marked as read',
    );
  }

  /// Mark selected notifications as unread
  void markSelectedAsUnread() {
    for (int i = 0; i < allNotifications.length; i++) {
      if (selectedNotificationIds.contains(allNotifications[i].notificationId)) {
        allNotifications[i] = allNotifications[i].copyWith(isRead: false);
      }
    }
    _filterNotifications();
    exitSelectionMode();
    TLoaders.successSnackBar(
      title: 'Notifications updated',
      message: '${selectedNotificationIds.length} notifications marked as unread',
    );
  }

  /// Get notifications for current tab
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

  /// Refresh notifications
  Future<void> refreshNotifications() async {
    isLoading.value = true;
    await Future.delayed(Duration(seconds: 1)); // Simulate API call
    loadSampleData();
  }
}