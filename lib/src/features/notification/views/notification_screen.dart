import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../common/widgets/appbar/appbar.dart';
import '../../../common/widgets/dialogs/dialog.dart';
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
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      TColors.unreadIndicator,
                      TColors.unreadIndicator.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: TColors.unreadIndicator.withOpacity(0.3),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${controller.unreadCount}',
                  style: TextStyle(
                    color: TColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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
              style: TextStyle(
                color: TColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
              : Padding(
            padding: EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () => _showOptionsMenu(controller, context),
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? TColors.darkContainer
                      : TColors.lightContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.more_vert,
                  color: isDark ? TColors.white : TColors.black,
                  size: 20,
                ),
              ),
            ),
          )),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: TColors.primary),
                SizedBox(height: TSizes.md),
                Text(
                  'Loading notifications...',
                  style: TextStyle(
                    color: TColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Tab Bar
            _buildTabBar(controller, isDark),

            // Action Bar (shown in selection mode)
            Obx(() => controller.isSelectionMode.value
                ? NotificationActionBar()
                : const SizedBox.shrink()),

            // Notification List with PageView
            Expanded(
              child: PageView(
                controller: controller.pageController,
                onPageChanged: (index) => controller.changeTab(index),
                children: List.generate(3, (tabIndex) {
                  final tabNotifications = tabIndex == 0
                      ? controller.allNotifications
                      : tabIndex == 1
                      ? controller.unreadNotifications
                      : controller.readNotifications;

                  if (tabNotifications.isEmpty) {
                    return SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height - 300,
                        child: EmptyNotificationWidget(
                          tabIndex: tabIndex,
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: controller.refreshNotifications,
                    color: TColors.primary,
                    child: ListView.builder(
                      padding: EdgeInsets.all(TSizes.md),
                      physics: AlwaysScrollableScrollPhysics(),
                      itemCount: tabNotifications.length,
                      itemBuilder: (context, index) {
                        final notification = tabNotifications[index];
                        return Obx(() => NotificationItem(
                          key: ValueKey(notification.notificationId),
                          notification: notification,
                          isSelected: controller.selectedNotificationIds
                              .contains(notification.notificationId),
                          isSelectionMode: controller.isSelectionMode.value,
                          onTap: () =>
                              _handleNotificationTap(controller, notification),
                          onLongPress: () => _handleNotificationLongPress(
                              controller, notification),
                          onSelectionChanged: (selected) => controller
                              .toggleNotificationSelection(
                              notification.notificationId),
                          onDelete: () => controller.deleteNotification(notification.notificationId),
                        ));
                      },
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showOptionsMenu(
      NotificationController controller, BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);

    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
            ),
          ),
          Positioned(
            top: kToolbarHeight + MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: Material(
              elevation: 8,
              shadowColor: isDark
                  ? TColors.notificationShadowDark
                  : TColors.notificationShadow,
              borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
              child: Container(
                width: 240,
                decoration: BoxDecoration(
                  color: isDark ? TColors.darkContainer : TColors.white,
                  borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
                  border: Border.all(
                    color: isDark
                        ? TColors.notificationBorderDark
                        : TColors.notificationBorder,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMenuItem(
                      context: context,
                      icon: Iconsax.tick_circle_bold,
                      title: 'Mark all as read',
                      iconColor: TColors.success,
                      onTap: () {
                        Navigator.of(context).pop();
                        controller.markAllAsRead();
                      },
                      isDark: isDark,
                      isFirst: true,
                    ),
                    _buildDivider(isDark),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.checklist_rounded,
                      title: 'Select notifications',
                      iconColor: TColors.primary,
                      onTap: () {
                        Navigator.of(context).pop();
                        controller.toggleSelectionMode();
                      },
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildMenuItem(
                      context: context,
                      icon: Iconsax.trash_bold,
                      title: 'Clear read notifications',
                      iconColor: TColors.warning,
                      onTap: () {
                        Navigator.of(context).pop();
                        TDialog.confirmDialog(title: 'Clear Read Notifications', message: 'Are you sure you want to clear all read notifications? This action cannot be undone.', confirmText: 'Clear');
                      },
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildMenuItem(
                      context: context,
                      icon: Iconsax.trash_bold,
                      title: 'Clear all notifications',
                      iconColor: TColors.error,
                      titleColor: TColors.error,
                      onTap: () {
                        Navigator.of(context).pop();
                        TDialog.deleteDialog(title: 'Clear All Notifications', message: 'Are you sure you want to clear all notifications? This action cannot be undone.', onConfirm: () => controller.clearAllNotifications());
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

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
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
          bottom:
          isLast ? Radius.circular(TSizes.borderRadiusLg) : Radius.zero,
        ),
        child: Container(
          padding: EdgeInsets.all(TSizes.md),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 18,
                ),
              ),
              SizedBox(width: TSizes.sm),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: titleColor ??
                        (isDark ? TColors.white : TColors.textPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 1,
      margin: EdgeInsets.symmetric(horizontal: TSizes.sm),
      color: isDark
          ? TColors.notificationBorderDark
          : TColors.notificationBorder,
    );
  }

  Widget _buildTabBar(NotificationController controller, bool isDark) {
    return Container(
      height: 50,
      margin: EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkContainer : TColors.lightContainer,
        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
        border: Border.all(
          color: isDark
              ? TColors.notificationBorderDark
              : TColors.notificationBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(4),
        child: Obx(() {
          return Row(
            children: [
              Expanded(
                child: _buildTabItem(controller, 0, 'All', controller.totalCount, isDark),
              ),
              SizedBox(width: 4),
              Expanded(
                child: _buildTabItem(controller, 1, 'Unread', controller.unreadCount, isDark),
              ),
              SizedBox(width: 4),
              Expanded(
                child: _buildTabItem(controller, 2, 'Read', controller.readNotifications.length, isDark),
              ),
            ],
          );
        }),
      ),
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

    return GestureDetector(
      onTap: () => controller.changeTab(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? TColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? TColors.white
                      : isDark
                      ? TColors.white
                      : TColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              if (count > 0) ...[
                SizedBox(width: 6),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? TColors.white.withOpacity(0.25)
                        : TColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isSelected ? TColors.white : TColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(
      NotificationController controller, NotificationModel notification) {
    if (controller.isSelectionMode.value) {
      controller.toggleNotificationSelection(notification.notificationId);
    } else {
      if (!notification.isRead) {
        controller.markAsRead(notification.notificationId);
      }
      _showNotificationDetails(notification);
    }
  }

  void _handleNotificationLongPress(
      NotificationController controller, NotificationModel notification) {
    if (!controller.isSelectionMode.value) {
      controller.toggleSelectionMode();
      controller.toggleNotificationSelection(notification.notificationId);
    }
  }

  void _showNotificationDetails(NotificationModel notification) {
    final isDark = THelperFunctions.isDarkMode(Get.context!);

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(TSizes.lg),
        decoration: BoxDecoration(
          color: isDark ? TColors.dark : TColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(TSizes.borderRadiusLg),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: notification.notificationType ==
                        NotificationType.reminder
                        ? TColors.reminderIcon.withOpacity(0.1)
                        : notification.notificationType ==
                        NotificationType.account_status
                        ? TColors.accountIcon.withOpacity(0.1)
                        : TColors.systemIcon.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    notification.notificationType == NotificationType.reminder
                        ? Iconsax.clock_bold
                        : notification.notificationType ==
                        NotificationType.account_status
                        ? Iconsax.profile_circle_bold
                        : Iconsax.info_circle_bold,
                    color: notification.notificationType ==
                        NotificationType.reminder
                        ? TColors.reminderIcon
                        : notification.notificationType ==
                        NotificationType.account_status
                        ? TColors.accountIcon
                        : TColors.systemIcon,
                    size: 24,
                  ),
                ),
                SizedBox(width: TSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.notificationType ==
                            NotificationType.reminder
                            ? 'Reminder'
                            : notification.notificationType ==
                            NotificationType.account_status
                            ? 'Account Status'
                            : 'System',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: notification.notificationType ==
                              NotificationType.reminder
                              ? TColors.reminderIcon
                              : notification.notificationType ==
                              NotificationType.account_status
                              ? TColors.accountIcon
                              : TColors.systemIcon,
                        ),
                      ),
                      Text(
                        THelperFunctions.getFormattedDate(
                          notification.createdAt,
                          format: 'MMM dd, yyyy • HH:mm',
                        ),
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
            Text(
              notification.notificationTitle,
              style: Theme.of(Get.context!).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: TSizes.sm),
            Text(
              notification.message,
              style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: TColors.textSecondary,
              ),
            ),
            SizedBox(height: TSizes.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TSizes.buttonRadius),
                  ),
                ),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: TColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}