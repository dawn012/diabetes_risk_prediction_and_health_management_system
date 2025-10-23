import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/notification_controller.dart';
import '../../models/notification_model.dart';

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<bool> onSelectionChanged;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onSelectionChanged,
  });

  void _showCustomActionMenu(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    final isUnread = !notification.isRead;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? TColors.darkContainer : TColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(TSizes.borderRadiusLg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: TSizes.sm),
              decoration: BoxDecoration(
                color: TColors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Action items
            _buildActionMenuItem(
              context: context,
              icon: isUnread ? Iconsax.tick_circle_bold : Iconsax.close_circle_bold,
              title: isUnread ? 'Mark as read' : 'Mark as unread',
              subtitle: isUnread
                  ? 'Move to read notifications'
                  : 'Move to unread notifications',
              iconColor: isUnread ? TColors.success : TColors.warning,
              onTap: () {
                Navigator.pop(context);
                _handleAction('mark_read');
              },
              isDark: isDark,
            ),

            // Divider
            Container(
              height: 1,
              margin: EdgeInsets.symmetric(horizontal: TSizes.md),
              color: isDark ? TColors.notificationBorderDark : TColors.notificationBorder,
            ),

            _buildActionMenuItem(
              context: context,
              icon: Iconsax.trash_bold,
              title: 'Delete notification',
              subtitle: 'Remove this notification permanently',
              iconColor: TColors.error,
              titleColor: TColors.error,
              onTap: () {
                Navigator.pop(context);
                _handleAction('delete');
              },
              isDark: isDark,
              isLast: true,
            ),

            // Bottom padding
            SizedBox(height: MediaQuery.of(context).padding.bottom + TSizes.sm),
          ],
        ),
      ),
    );
  }

  Widget _buildActionMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    Color? titleColor,
    required VoidCallback onTap,
    required bool isDark,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(TSizes.md),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              SizedBox(width: TSizes.md),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: titleColor ?? (isDark ? TColors.white : TColors.textPrimary),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: TColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow icon
              // Icon(
              //   Iconsax.arrow_right_3_outline,
              //   size: 18,
              //   color: TColors.textSecondary,
              // ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    final isUnread = !notification.isRead;

    return Container(
      margin: EdgeInsets.only(bottom: TSizes.sm),
      child: Dismissible(
        key: Key(notification.notificationId),
        direction: DismissDirection.endToStart,
        background: _buildDismissBackground(),
        onDismissed: (direction) {
          NotificationController.instance.deleteNotification(notification.notificationId);
        },
        child: Material(
          elevation: 1,
          shadowColor: isDark
              ? TColors.notificationShadowDark
              : TColors.notificationShadow,
          borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _getBackgroundColor(isDark, isUnread),
              borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
              border: Border.all(
                color: isSelected
                    ? TColors.batchSelectBorder
                    : isDark
                    ? TColors.notificationBorderDark
                    : TColors.notificationBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
              child: Padding(
                padding: EdgeInsets.all(TSizes.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selection checkbox or notification icon
                    if (isSelectionMode)
                      _buildSelectionCheckbox()
                    else
                      _buildNotificationIcon(isDark),

                    SizedBox(width: TSizes.md),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header (title and time)
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification.notificationTitle,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                                    color: isDark ? TColors.white : TColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: TSizes.sm),
                              Text(
                                _getRelativeTime(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: TColors.textSecondary,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: TSizes.xs),

                          // Message
                          Text(
                            notification.message,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? TColors.white.withOpacity(0.8)
                                  : TColors.textSecondary,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),

                          SizedBox(height: TSizes.sm),

                          // Footer (type badge and unread indicator)
                          Row(
                            children: [
                              // Type badge
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: notification.notificationType == NotificationType.reminder
                                      ? TColors.reminderIcon.withOpacity(0.1)
                                      : TColors.systemIcon.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
                                  border: Border.all(
                                    color: notification.notificationType == NotificationType.reminder
                                        ? TColors.reminderIcon.withOpacity(0.3)
                                        : TColors.systemIcon.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  notification.notificationType == NotificationType.reminder
                                      ? 'Reminder'
                                      : 'System',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: notification.notificationType == NotificationType.reminder
                                        ? TColors.reminderIcon
                                        : TColors.systemIcon,
                                  ),
                                ),
                              ),

                              Spacer(),

                              // Unread indicator
                              if (isUnread)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: TColors.unreadIndicator,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // More actions (only show when not in selection mode)
                    if (!isSelectionMode) ...[
                      SizedBox(width: TSizes.sm),
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: GestureDetector(
                          onTap: () => _showCustomActionMenu(context),
                          child: Icon(
                            Iconsax.more_circle_bold,
                            color: TColors.textSecondary,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCheckbox() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isSelected ? TColors.primary : Colors.transparent,
        border: Border.all(
          color: isSelected ? TColors.primary : TColors.grey,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: isSelected
          ? Icon(
        Icons.check,
        color: TColors.white,
        size: 16,
      )
          : null,
    );
  }

  Widget _buildNotificationIcon(bool isDark) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: notification.notificationType == NotificationType.reminder
            ? TColors.reminderIcon.withOpacity(0.1)
            : TColors.systemIcon.withOpacity(0.1),
        borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
        border: Border.all(
          color: notification.notificationType == NotificationType.reminder
              ? TColors.reminderIcon.withOpacity(0.3)
              : TColors.systemIcon.withOpacity(0.3),
        ),
      ),
      child: Icon(
        notification.notificationType == NotificationType.reminder
            ? Iconsax.clock_bold
            : Iconsax.notification_bold,
        color: notification.notificationType == NotificationType.reminder
            ? TColors.reminderIcon
            : TColors.systemIcon,
        size: 20,
      ),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      margin: EdgeInsets.only(bottom: TSizes.sm),
      decoration: BoxDecoration(
        color: TColors.error,
        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: TSizes.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.trash_bold,
                color: TColors.white,
                size: 24,
              ),
              SizedBox(height: 4),
              Text(
                'Delete',
                style: TextStyle(
                  color: TColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(bool isDark, bool isUnread) {
    if (isSelected) {
      return TColors.batchSelectBackground;
    }

    if (isUnread) {
      return isDark ? TColors.unreadNotificationDark : TColors.unreadNotification;
    }

    return isDark ? TColors.readNotificationDark : TColors.readNotification;
  }

  String _getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(notification.createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return THelperFunctions.getFormattedDate(
        notification.createdAt,
        format: 'MMM dd',
      );
    }
  }

  void _handleAction(String action) {
    final controller = NotificationController.instance;

    switch (action) {
      case 'mark_read':
        if (notification.isRead) {
          controller.markAsUnread(notification.notificationId);
        } else {
          controller.markAsRead(notification.notificationId);
        }
        break;
      case 'delete':
        controller.deleteNotification(notification.notificationId);
        break;
    }
  }
}