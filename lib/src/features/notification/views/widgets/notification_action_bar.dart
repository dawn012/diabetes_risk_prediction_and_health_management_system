import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../common/widgets/dialogs/dialog.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/notification_controller.dart';

class NotificationActionBar extends StatelessWidget {
  const NotificationActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = NotificationController.instance;
    final isDark = THelperFunctions.isDarkMode(context);

    return Obx(() {
      final selectedCount = controller.selectedNotificationIds.length;

      return AnimatedContainer(
        duration: Duration(milliseconds: 300),
        height: controller.isSelectionMode.value ? 70 : 0,
        decoration: BoxDecoration(
          color: isDark ? TColors.darkContainer : TColors.lightContainer,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? TColors.notificationBorderDark
                  : TColors.notificationBorder,
            ),
            bottom: BorderSide(
              color: isDark
                  ? TColors.notificationBorderDark
                  : TColors.notificationBorder,
            ),
          ),
        ),
        child: controller.isSelectionMode.value
            ? Padding(
          padding: EdgeInsets.symmetric(
              horizontal: TSizes.md, vertical: TSizes.sm),
          child: Row(
            children: [
              // Selection info
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$selectedCount selected',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color:
                        isDark ? TColors.white : TColors.textPrimary,
                      ),
                    ),
                    // if (selectedCount > 0)
                    //   GestureDetector(
                    //     onTap: controller.deselectAll,
                    //     child: Text(
                    //       'Deselect all',
                    //       style: TextStyle(
                    //         fontSize: 12,
                    //         color: TColors.primary,
                    //       ),
                    //     ),
                    //   ),
                  ],
                ),
              ),

              // Quick selection
              TextButton.icon(
                onPressed: () {
                  final allIds = controller.currentTabNotifications
                      .map((n) => n.notificationId)
                      .toSet();
                  final selectedIds =
                  controller.selectedNotificationIds.toSet();

                  if (selectedIds.containsAll(allIds) &&
                      allIds.isNotEmpty) {
                    controller.deselectAll();
                  } else {
                    controller.selectAllInCurrentView();
                  }
                },
                icon: Obx(() {
                  final allIds = controller.currentTabNotifications
                      .map((n) => n.notificationId)
                      .toSet();
                  final selectedIds =
                  controller.selectedNotificationIds.toSet();
                  final allSelected = selectedIds.containsAll(allIds) &&
                      allIds.isNotEmpty;

                  return Icon(
                    allSelected
                        ? Iconsax.tick_square_bold
                        : Iconsax.tick_square_outline,
                    size: 16,
                    color: TColors.primary,
                  );
                }),
                label: Obx(() {
                  final allIds = controller.currentTabNotifications
                      .map((n) => n.notificationId)
                      .toSet();
                  final selectedIds =
                  controller.selectedNotificationIds.toSet();
                  final allSelected = selectedIds.containsAll(allIds) &&
                      allIds.isNotEmpty;

                  return Text(
                    allSelected ? 'Deselect All' : 'Select All',
                    style: TextStyle(color: TColors.primary),
                  );
                }),
                style: TextButton.styleFrom(
                  padding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),

              SizedBox(width: TSizes.sm),

              // Action buttons
              if (selectedCount > 0) ...[
                // Mark as read/unread
                _buildActionButton(
                  icon: _getMarkIcon(controller),
                  label: _getMarkLabel(controller),
                  color: TColors.success,
                  onPressed: () =>
                      _showMarkAsReadDialog(controller, selectedCount),
                ),

                SizedBox(width: TSizes.sm),

                // Delete selected
                _buildActionButton(
                  icon: Iconsax.trash_bold,
                  label: 'Delete',
                  color: TColors.error,
                  onPressed: () => TDialog.deleteDialog(title: 'Delete Notifications', message: 'Are you sure you want to delete $selectedCount selected notification${selectedCount == 1 ? '' : 's'}? This action cannot be undone.', onConfirm: () => controller.deleteSelectedNotifications()),
                ),
              ],
            ],
          ),
        )
            : SizedBox.shrink(),
      );
    });
  }

  IconData _getMarkIcon(NotificationController controller) {
    final selectedNotifications = controller.allNotifications
        .where((n) =>
        controller.selectedNotificationIds.contains(n.notificationId))
        .toList();

    final hasUnread = selectedNotifications.any((n) => !n.isRead);
    final hasRead = selectedNotifications.any((n) => n.isRead);

    if (hasUnread && hasRead) {
      return Iconsax.document_text_bold; // Mixed state
    } else if (hasUnread) {
      return Iconsax.tick_circle_bold; // Mark as read
    } else {
      return Iconsax.refresh_circle_bold; // Mark as unread
    }
  }

  String _getMarkLabel(NotificationController controller) {
    final selectedNotifications = controller.allNotifications
        .where((n) =>
        controller.selectedNotificationIds.contains(n.notificationId))
        .toList();

    final hasUnread = selectedNotifications.any((n) => !n.isRead);
    final hasRead = selectedNotifications.any((n) => n.isRead);

    if (hasUnread && hasRead) {
      return 'Mark';
    } else if (hasUnread) {
      return 'Read';
    } else {
      return 'Unread';
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMarkAsReadDialog(
      NotificationController controller, int selectedCount) {
    // Check if selected notifications have mixed read states
    final selectedNotifications = controller.allNotifications
        .where((n) =>
        controller.selectedNotificationIds.contains(n.notificationId))
        .toList();

    final hasUnread = selectedNotifications.any((n) => !n.isRead);
    final hasRead = selectedNotifications.any((n) => n.isRead);

    if (hasUnread && hasRead) {
      // Show custom dialog for mixed states
      _showMixedStateDialog(controller, selectedCount);
    } else if (hasUnread) {
      // All selected are unread, mark as read
      controller.markSelectedAsRead();
    } else {
      // All selected are read, mark as unread
      controller.markSelectedAsUnread();
    }
  }

  void _showMixedStateDialog(
      NotificationController controller, int selectedCount) {
    final isDark = THelperFunctions.isDarkMode(Get.context!);

    Get.dialog(
      Dialog(
        backgroundColor: isDark ? TColors.dark : TColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(maxWidth: 400),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: TColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.document_text_bold,
                  color: TColors.primary,
                  size: 28,
                ),
              ),

              SizedBox(height: 16),

              // Title
              Text(
                'Mark Notifications',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: isDark ? TColors.white : TColors.black,
                ),
              ),

              SizedBox(height: 8),

              // Message
              Text(
                'You have selected both read and unread notifications. What would you like to do with the selected $selectedCount notifications?',
                style: TextStyle(
                  color: isDark ? TColors.lightGrey : TColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              SizedBox(height: 24),

              // Mark as Read button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    controller.markSelectedAsRead();
                  },
                  icon: Icon(
                    Iconsax.tick_circle_bold,
                    size: 18,
                  ),
                  label: Text(
                    'Mark as Read',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.success,
                    foregroundColor: TColors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              SizedBox(height: 12),

              // Mark as Unread button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    controller.markSelectedAsUnread();
                  },
                  icon: Icon(
                    Iconsax.refresh_circle_bold,
                    size: 18,
                  ),
                  label: Text(
                    'Mark as Unread',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.warning,
                    foregroundColor: TColors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              SizedBox(height: 12),

              // Cancel button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: isDark ? TColors.white : TColors.black,
                    side: BorderSide(
                      color: isDark
                          ? TColors.darkGrey.withOpacity(0.5)
                          : TColors.grey.withOpacity(0.5),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}