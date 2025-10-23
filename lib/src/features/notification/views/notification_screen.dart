import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../common/widgets/appbar/appbar.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../controllers/notification_controller.dart';
import '../models/notification_model.dart';
import 'widgets/empty_notification_widget.dart';
import 'widgets/notification_action_bar.dart';
import 'widgets/notification_item.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NotificationController());
    final isDark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.light,
      appBar: TAppBar(
        title: Obx(() => Row(
          children: [
            Text(
              'Notifications',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (controller.hasUnreadNotifications) ...[
              SizedBox(width: TSizes.sm),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: TColors.unreadIndicator,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${controller.unreadCount}',
                  style: TextStyle(
                    color: TColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        )),
        showBackArrow: true,
        actions: [
          Obx(() => controller.isSelectionMode.value
              ? TextButton(
            onPressed: controller.exitSelectionMode,
            child: Text(
              'Cancel',
              style: TextStyle(color: TColors.primary),
            ),
          )
              : Padding(
                padding: EdgeInsets.only(right: 15),
                child: GestureDetector(
                            onTap: () => _showCustomDropdown(controller, context),
                            child: Icon(
                Iconsax.more_bold,
                color: isDark ? TColors.white : TColors.black,
                            ),
                          ),
              )),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: TColors.primary),
          );
        }

        return Column(
          children: [
            // Tab Bar
            _buildTabBar(controller, isDark),

            // Action Bar (shown in selection mode)
            Obx(() => controller.isSelectionMode.value
                ? NotificationActionBar()
                : SizedBox.shrink()),

            // Notification List
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refreshNotifications,
                color: TColors.primary,
                child: Obx(() {
                  final notifications = controller.currentTabNotifications;

                  if (notifications.isEmpty) {
                    return EmptyNotificationWidget(
                      tabIndex: controller.selectedTabIndex.value,
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.all(TSizes.md),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return NotificationItem(
                        notification: notification,
                        isSelected: controller.selectedNotificationIds
                            .contains(notification.notificationId),
                        isSelectionMode: controller.isSelectionMode.value,
                        onTap: () => _handleNotificationTap(controller, notification),
                        onLongPress: () => _handleNotificationLongPress(controller, notification),
                        onSelectionChanged: (selected) => controller
                            .toggleNotificationSelection(notification.notificationId),
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showCustomDropdown(NotificationController controller, BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => Stack(
        children: [
          // Invisible barrier to close dropdown
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
            ),
          ),
          // Custom dropdown
          Positioned(
            top: kToolbarHeight + MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: Material(
              elevation: 8,
              shadowColor: isDark ? TColors.notificationShadowDark : TColors.notificationShadow,
              borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
              child: Container(
                width: 220,
                decoration: BoxDecoration(
                  color: isDark ? TColors.darkContainer : TColors.white,
                  borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
                  border: Border.all(
                    color: isDark ? TColors.notificationBorderDark : TColors.notificationBorder,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDropdownItem(
                      icon: Iconsax.tick_circle_bold,
                      title: 'Mark all as read',
                      // subtitle: 'Mark all notifications as read',
                      iconColor: TColors.success,
                      onTap: () {
                        Navigator.of(context).pop();
                        _handleMenuSelection(controller, 'mark_all_read');
                      },
                      isDark: isDark,
                      isFirst: true,
                    ),
                    _buildDropdownDivider(isDark),
                    _buildDropdownItem(
                      icon: Icons.checklist_rounded,
                      title: 'Select notifications',
                      // subtitle: 'Select multiple notifications',
                      iconColor: TColors.primary,
                      onTap: () {
                        Navigator.of(context).pop();
                        _handleMenuSelection(controller, 'select_mode');
                      },
                      isDark: isDark,
                    ),
                    _buildDropdownDivider(isDark),
                    _buildDropdownItem(
                      icon: Iconsax.trash_bold,
                      title: 'Clear read notifications',
                      // subtitle: 'Remove all read notifications',
                      iconColor: TColors.warning,
                      onTap: () {
                        Navigator.of(context).pop();
                        _handleMenuSelection(controller, 'clear_read');
                      },
                      isDark: isDark,
                    ),
                    _buildDropdownDivider(isDark),
                    _buildDropdownItem(
                      icon: Iconsax.trash_bold,
                      title: 'Clear all notifications',
                      // subtitle: 'Remove all notifications',
                      iconColor: TColors.error,
                      titleColor: TColors.error,
                      onTap: () {
                        Navigator.of(context).pop();
                        _handleMenuSelection(controller, 'clear_all');
                      },
                      isDark: isDark,
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownItem({
    required IconData icon,
    required String title,
    // required String subtitle,
    required Color iconColor,
    Color? titleColor,
    required VoidCallback onTap,
    required bool isDark,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? Radius.circular(TSizes.borderRadiusLg) : Radius.zero,
          bottom: isLast ? Radius.circular(TSizes.borderRadiusLg) : Radius.zero,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 40,
                height: 50,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              SizedBox(width: TSizes.sm),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: titleColor ?? (isDark ? TColors.white : TColors.textPrimary),
                      ),
                    ),
                    // SizedBox(height: 2),
                    // Text(
                    //   subtitle,
                    //   style: TextStyle(
                    //     fontSize: 12,
                    //     color: TColors.textSecondary,
                    //   ),
                    // ),
                  ],
                ),
              ),
              // Arrow icon
              // Icon(
              //   Iconsax.arrow_right_3_outline,
              //   size: 16,
              //   color: TColors.textSecondary,
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownDivider(bool isDark) {
    return Container(
      height: 1,
      margin: EdgeInsets.symmetric(horizontal: TSizes.sm),
      color: isDark ? TColors.notificationBorderDark : TColors.notificationBorder,
    );
  }

  Widget _buildTabBar(NotificationController controller, bool isDark) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkContainer : TColors.lightContainer,
        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
        border: Border.all(
          color: isDark ? TColors.notificationBorderDark : TColors.notificationBorder,
        ),
      ),
      child: Obx(() => Row(
        children: [
          _buildTabItem(
            controller,
            0,
            'All',
            controller.totalCount,
            isDark,
          ),
          _buildTabItem(
            controller,
            1,
            'Unread',
            controller.unreadCount,
            isDark,
          ),
          _buildTabItem(
            controller,
            2,
            'Read',
            controller.readNotifications.length,
            isDark,
          ),
        ],
      )),
    );
  }

  Widget _buildTabItem(
      NotificationController controller,
      int index,
      String title,
      int count,
      bool isDark,
      ) {
    final isSelected = controller.selectedTabIndex.value == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => controller.changeTab(index),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: TSizes.sm),
          decoration: BoxDecoration(
            color: isSelected
                ? TColors.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? TColors.white
                      : isDark ? TColors.white : TColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              if (count > 0) ...[
                SizedBox(height: 2),
                Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected
                        ? TColors.white.withOpacity(0.8)
                        : TColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(NotificationController controller, NotificationModel notification) {
    if (controller.isSelectionMode.value) {
      controller.toggleNotificationSelection(notification.notificationId);
    } else {
      // Mark as read if unread
      if (!notification.isRead) {
        controller.markAsRead(notification.notificationId);
      }
      // Handle notification action (navigate to relevant screen, show details, etc.)
      _showNotificationDetails(notification);
    }
  }

  void _handleNotificationLongPress(NotificationController controller, NotificationModel notification) {
    if (!controller.isSelectionMode.value) {
      controller.toggleSelectionMode();
      controller.toggleNotificationSelection(notification.notificationId);
    }
  }

  void _handleMenuSelection(NotificationController controller, String value) {
    switch (value) {
      case 'mark_all_read':
        controller.markAllAsRead();
        break;
      case 'select_mode':
        controller.toggleSelectionMode();
        break;
      case 'clear_read':
        _showClearConfirmation(
          'Clear Read Notifications',
          'Are you sure you want to clear all read notifications? This action cannot be undone.',
          controller.clearReadNotifications,
        );
        break;
      case 'clear_all':
        _showClearConfirmation(
          'Clear All Notifications',
          'Are you sure you want to clear all notifications? This action cannot be undone.',
          controller.clearAllNotifications,
        );
        break;
    }
  }

  void _showClearConfirmation(String title, String message, VoidCallback onConfirm) {
    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: TColors.error),
            child: Text('Clear', style: TextStyle(color: TColors.white)),
          ),
        ],
      ),
    );
  }

  void _showNotificationDetails(NotificationModel notification) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(TSizes.lg),
        decoration: BoxDecoration(
          color: THelperFunctions.isDarkMode(Get.context!) ? TColors.dark : TColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(TSizes.borderRadiusLg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: TColors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: TSizes.lg),

            // Notification icon and type
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: notification.notificationType == NotificationType.reminder
                        ? TColors.reminderIcon.withOpacity(0.1)
                        : TColors.systemIcon.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    notification.notificationType == NotificationType.reminder
                        ? Iconsax.clock_bold
                        : Iconsax.info_circle_bold,
                    color: notification.notificationType == NotificationType.reminder
                        ? TColors.reminderIcon
                        : TColors.systemIcon,
                    size: 20,
                  ),
                ),
                SizedBox(width: TSizes.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.notificationType == NotificationType.reminder ? 'Reminder' : 'System',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: notification.notificationType == NotificationType.reminder
                              ? TColors.reminderIcon
                              : TColors.systemIcon,
                        ),
                      ),
                      Text(
                        THelperFunctions.getFormattedDate(notification.createdAt, format: 'MMM dd, yyyy • HH:mm'),
                        style: TextStyle(
                          fontSize: 12,
                          color: TColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: TSizes.lg),

            // Title
            Text(
              notification.notificationTitle,
              style: Theme.of(Get.context!).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: TSizes.sm),

            // Message
            Text(
              notification.message,
              style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),

            SizedBox(height: TSizes.xl),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    child: Text('Close'),
                  ),
                ),
                SizedBox(width: TSizes.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      // Handle notification action (e.g., navigate to relevant screen)
                    },
                    child: Text('Take Action'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}