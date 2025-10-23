import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

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
              color: isDark ? TColors.notificationBorderDark : TColors.notificationBorder,
            ),
            bottom: BorderSide(
              color: isDark ? TColors.notificationBorderDark : TColors.notificationBorder,
            ),
          ),
        ),
        child: controller.isSelectionMode.value
            ? Padding(
          padding: EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm),
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
                        color: isDark ? TColors.white : TColors.textPrimary,
                      ),
                    ),
                    if (selectedCount > 0)
                      GestureDetector(
                        onTap: controller.deselectAll,
                        child: Text(
                          'Deselect all',
                          style: TextStyle(
                            fontSize: 12,
                            color: TColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Quick selection
              TextButton.icon(
                onPressed: controller.selectAllInCurrentView,
                icon: Icon(
                  Iconsax.tick_square_bold,
                  size: 16,
                  color: TColors.primary,
                ),
                label: Text(
                  'Select All',
                  style: TextStyle(color: TColors.primary),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),

              SizedBox(width: TSizes.sm),

              // Action buttons
              if (selectedCount > 0) ...[
                // Mark as read/unread
                _buildActionButton(
                  icon: Iconsax.tick_circle_bold,
                  color: TColors.success,
                  onPressed: () => _showMarkAsReadDialog(controller, selectedCount),
                ),

                SizedBox(width: TSizes.sm),

                // Delete selected
                _buildActionButton(
                  icon: Iconsax.trash_bold,
                  color: TColors.error,
                  onPressed: () => _showDeleteDialog(controller, selectedCount),
                ),
              ],
            ],
          ),
        )
            : SizedBox.shrink(),
      );
    });
  }

  Widget _buildActionButton({
    required IconData icon,
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
          width: 40,
          height: 40,
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
      ),
    );
  }

  void _showMarkAsReadDialog(NotificationController controller, int selectedCount) {
    // Check if selected notifications have mixed read states
    final selectedNotifications = controller.allNotifications
        .where((n) => controller.selectedNotificationIds.contains(n.notificationId))
        .toList();

    final hasUnread = selectedNotifications.any((n) => !n.isRead);
    final hasRead = selectedNotifications.any((n) => n.isRead);

    if (hasUnread && hasRead) {
      // Show dialog for mixed states
      Get.dialog(
        AlertDialog(
          title: Text('Mark Notifications'),
          content: Text('What would you like to do with the selected $selectedCount notifications?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                controller.markSelectedAsRead();
              },
              child: Text(
                'Mark as Read',
                style: TextStyle(color: TColors.success),
              ),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                controller.markSelectedAsUnread();
              },
              child: Text(
                'Mark as Unread',
                style: TextStyle(color: TColors.warning),
              ),
            ),
          ],
        ),
      );
    } else if (hasUnread) {
      // All selected are unread, mark as read
      controller.markSelectedAsRead();
    } else {
      // All selected are read, mark as unread
      controller.markSelectedAsUnread();
    }
  }

  void _showDeleteDialog(NotificationController controller, int selectedCount) {
    Get.dialog(
      AlertDialog(
        title: Text('Delete Notifications'),
        content: Text(
          'Are you sure you want to delete $selectedCount selected notification${selectedCount == 1 ? '' : 's'}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteSelectedNotifications();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TColors.error,
            ),
            child: Text(
              'Delete',
              style: TextStyle(color: TColors.white),
            ),
          ),
        ],
      ),
    );
  }
}