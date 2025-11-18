import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../models/notification_model.dart';

class NotificationItem extends StatefulWidget {
  final NotificationModel notification;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<bool> onSelectionChanged;
  final VoidCallback onDelete;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onSelectionChanged,
    required this.onDelete,
  });

  @override
  State<NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends State<NotificationItem>
    with SingleTickerProviderStateMixin {
  static const double _swipeThreshold = 80.0;
  double _dragExtent = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Static variable to track currently swiped item
  static _NotificationItemState? _currentlySwipedItem;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 250),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    if (_currentlySwipedItem == this) {
      _currentlySwipedItem = null;
    }
    _animationController.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    if (widget.isSelectionMode) return;

    // Reset any other swiped item
    if (_currentlySwipedItem != null && _currentlySwipedItem != this) {
      _currentlySwipedItem!._resetPosition();
    }
    _currentlySwipedItem = this;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (widget.isSelectionMode) return;

    setState(() {
      _dragExtent += details.primaryDelta!;
      // Only allow left swipe
      if (_dragExtent > 0) {
        _dragExtent = 0;
      }
      // Limit swipe distance
      if (_dragExtent < -_swipeThreshold) {
        _dragExtent = -_swipeThreshold;
      }
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (widget.isSelectionMode) return;

    if (_dragExtent < -_swipeThreshold * 0.35) {
      // Snap to show delete button with animation
      _animationController.forward();
    } else {
      // Reset position
      _resetPosition();
    }
  }

  void _resetPosition() {
    setState(() {
      _dragExtent = 0;
    });
    _animationController.reverse();
    if (_currentlySwipedItem == this) {
      _currentlySwipedItem = null;
    }
  }

  // Check if this item is currently swiped
  bool get _isSwiped => _dragExtent < 0 || _animation.value > 0;

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    final isUnread = !widget.notification.isRead;

    // Reset swipe position when entering selection mode
    if (widget.isSelectionMode && _isSwiped) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resetPosition();
      });
    }

    return GestureDetector(
      // Tap outside to close swipe
      onTap: () {
        if (_isSwiped && !widget.isSelectionMode) {
          _resetPosition();
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: TSizes.sm),
        child: Stack(
          children: [
            // Delete button background - only show when NOT in selection mode
            if (!widget.isSelectionMode)
              Positioned.fill(
                child: Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: TSizes.md),
                  decoration: BoxDecoration(
                    color: TColors.error,
                    borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      widget.onDelete();
                      _resetPosition();
                    },
                    child: Container(
                      width: 70,
                      height: double.infinity,
                      alignment: Alignment.center,
                      child: Icon(
                        Iconsax.trash_bold,
                        color: TColors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),

            // Main notification item
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final animatedOffset = _animation.value * -_swipeThreshold;
                final currentOffset = widget.isSelectionMode ? 0.0 : (_dragExtent == 0 ? animatedOffset : _dragExtent);

                return Transform.translate(
                  offset: Offset(currentOffset, 0),
                  child: child,
                );
              },
              child: GestureDetector(
                onHorizontalDragStart: _handleDragStart,
                onHorizontalDragUpdate: _handleDragUpdate,
                onHorizontalDragEnd: _handleDragEnd,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_isSwiped && !widget.isSelectionMode) {
                        _resetPosition();
                      } else {
                        widget.onTap();
                      }
                    },
                    onLongPress: widget.onLongPress,
                    borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
                    child: Container(
                      padding: EdgeInsets.all(TSizes.md),
                      decoration: BoxDecoration(
                        color: widget.isSelected
                            ? (isDark
                            ? TColors.primary.withOpacity(0.05)
                            : TColors.primary.withOpacity(0.05))
                            : TColors.getNotificationBg(isDark, isUnread),
                        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
                        border: Border.all(
                          color: widget.isSelected
                              ? TColors.primary
                              : TColors.getNotificationBorder(isDark),
                          width: widget.isSelected ? 2.5 : 1,
                        ),
                        boxShadow: [
                          if (widget.isSelected)
                            BoxShadow(
                              color: TColors.primary.withOpacity(0.1),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                              spreadRadius: 0,
                            )
                          else if (!isDark && isUnread)
                            BoxShadow(
                              color: TColors.primary.withOpacity(0.05),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Selection checkbox or icon
                          if (widget.isSelectionMode)
                            Container(
                              margin: EdgeInsets.only(right: TSizes.sm),
                              child: Transform.scale(
                                scale: 1.1,
                                child: Checkbox(
                                  value: widget.isSelected,
                                  onChanged: (value) =>
                                      widget.onSelectionChanged(value ?? false),
                                  activeColor: TColors.primary,
                                  checkColor: TColors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  side: BorderSide(
                                    color: widget.isSelected
                                        ? TColors.primary
                                        : TColors.grey,
                                    width: 2,
                                  ),
                                ),
                              ),
                            )
                          else
                            _buildNotificationIcon(isDark),

                          SizedBox(width: TSizes.sm),

                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header row with title and time
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.notification.notificationTitle,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isUnread
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: isDark
                                              ? TColors.white
                                              : TColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: TSizes.xs),
                                    Text(
                                      _formatTime(widget.notification.createdAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: TColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: TSizes.xs),

                                // Message
                                Text(
                                  widget.notification.message,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: TColors.textSecondary,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                // Bottom row with type badge and unread indicator
                                if (isUnread ||
                                    widget.notification.notificationType !=
                                        NotificationType.system)
                                  Padding(
                                    padding: EdgeInsets.only(top: TSizes.xs),
                                    child: Row(
                                      children: [
                                        // Type badge
                                        _buildTypeBadge(isDark),

                                        Spacer(),

                                        // Unread dot
                                        if (isUnread)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: TColors.unreadDot,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(bool isDark) {
    IconData iconData;
    Color iconColor;

    switch (widget.notification.notificationType) {
      case NotificationType.reminder:
        iconData = Iconsax.clock_bold;
        iconColor = TColors.reminderIcon;
        break;
      case NotificationType.account_status:
        iconData = Iconsax.profile_circle_bold;
        iconColor = TColors.accountIcon;
        break;
      default:
        iconData = Iconsax.info_circle_bold;
        iconColor = TColors.systemIcon;
    }

    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: TColors.getIconBgColor(
          widget.notification.notificationType.name,
          isDark,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  Widget _buildTypeBadge(bool isDark) {
    if (widget.notification.notificationType == NotificationType.system) {
      return SizedBox.shrink();
    }

    String label;
    Color color;

    switch (widget.notification.notificationType) {
      case NotificationType.reminder:
        label = 'Reminder';
        color = TColors.reminderIcon;
        break;
      case NotificationType.account_status:
        label = 'Account';
        color = TColors.accountIcon;
        break;
      default:
        label = 'System';
        color = TColors.systemIcon;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return THelperFunctions.getFormattedDate(dateTime, format: 'MMM dd');
    }
  }
}