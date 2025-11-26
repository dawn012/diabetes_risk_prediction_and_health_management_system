import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../common/widgets/shimmer/shimmer.dart';
import '../../../../data/repositories/user/delete_account_request_repository.dart';
import '../../../../utils/constants/admin_colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/formatters/formatter.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../notification/models/notification_model.dart';
import '../../controllers/admin_notification_controller.dart';
import '../../models/delete_account_request_model.dart';

class AdminNotificationScreen extends StatelessWidget {
  const AdminNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminNotificationController());
    final darkMode = THelperFunctions.isDarkMode(context);
    final isWeb = THelperFunctions.screenWidth() > 600;

    return Scaffold(
      backgroundColor: TAdminColors.getBackgroundColor(darkMode),
      body: Column(
        children: [
          // Header with back button
          _buildHeader(context, controller, darkMode, isWeb),

          // Notifications List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return _buildShimmerLoading(darkMode);
              }

              if (controller.notifications.isEmpty) {
                return _buildEmptyState(darkMode, isWeb);
              }

              return RefreshIndicator(
                onRefresh: controller.refreshNotifications,
                child: ListView.builder(
                  padding: EdgeInsets.all(isWeb ? 24 : 16),
                  itemCount: controller.notifications.length,
                  itemBuilder: (context, index) {
                    final notification = controller.notifications[index];
                    return _buildNotificationCard(
                      context,
                      notification,
                      controller,
                      darkMode,
                      isWeb,
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AdminNotificationController controller,
    bool darkMode,
    bool isWeb,
  ) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 32 : 24),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceColor(darkMode),
        border: Border(
          bottom: BorderSide(
            color: TAdminColors.getBorderColor(darkMode),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Back button
              IconButton(
                onPressed: () => Get.back(),
                icon: Icon(
                  Iconsax.arrow_left_2_bold,
                  color: TAdminColors.getOnSurfaceColor(darkMode),
                ),
                tooltip: 'Back',
              ),
              SizedBox(width: 8),
              Icon(
                Iconsax.notification_bold,
                color: TAdminColors.primary,
                size: isWeb ? 32 : 28,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: isWeb ? 28 : 24,
                        fontWeight: FontWeight.bold,
                        color: TAdminColors.getOnSurfaceColor(darkMode),
                      ),
                    ),
                    SizedBox(height: 4),
                    Obx(
                      () => Text(
                        '${controller.unreadCount.value} unread',
                        style: TextStyle(
                          fontSize: isWeb ? 16 : 14,
                          color:
                              TAdminColors.getOnSurfaceVariantColor(darkMode),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              Row(
                children: [
                  Obx(
                    () => IconButton(
                      onPressed: controller.unreadCount.value > 0
                          ? controller.markAllAsRead
                          : null,
                      icon: Icon(
                        Iconsax.tick_circle_bold,
                        color: controller.unreadCount.value > 0
                            ? TAdminColors.primary
                            : TAdminColors.getOnSurfaceVariantColor(darkMode)
                                .withOpacity(0.3),
                      ),
                      tooltip: 'Mark all as read',
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'clear_read':
                          controller.clearReadNotifications();
                          break;
                        case 'clear_all':
                          controller.clearAllNotifications();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'clear_read',
                        child: Row(
                          children: [
                            Icon(Iconsax.trash_bold, size: 16),
                            SizedBox(width: 12),
                            Text('Clear read'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'clear_all',
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.trash_bold,
                              size: 16,
                              color: TAdminColors.error,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Clear all',
                              style: TextStyle(color: TAdminColors.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: Icon(
                      Icons.more_horiz,
                      color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationModel notification,
    AdminNotificationController controller,
    bool darkMode,
    bool isWeb,
  ) {
    final isDeleteRequest = notification.notificationType ==
        NotificationType.delete_account_request;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: notification.isRead
            ? TAdminColors.getSurfaceColor(darkMode)
            : TAdminColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead
              ? TAdminColors.getBorderColor(darkMode)
              : TAdminColors.primary.withOpacity(0.3),
          width: notification.isRead ? 1 : 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!notification.isRead) {
              controller.markAsRead(notification.notificationId);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(isWeb ? 20 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getNotificationColor(
                          notification.notificationType,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getNotificationIcon(
                          notification.notificationType,
                        ),
                        color: _getNotificationColor(
                          notification.notificationType,
                        ),
                        size: 20,
                      ),
                    ),

                    SizedBox(width: 16),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // EXPIRED badge 会在下面时间行里 render
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification.notificationTitle,
                                  style: TextStyle(
                                    fontSize: isWeb ? 16 : 15,
                                    fontWeight: FontWeight.w600,
                                    color: TAdminColors.getOnSurfaceColor(
                                      darkMode,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            notification.message,
                            style: TextStyle(
                              fontSize: isWeb ? 14 : 13,
                              color: TAdminColors.getOnSurfaceVariantColor(
                                darkMode,
                              ),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Actions menu
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'mark_unread':
                            controller.markAsUnread(
                              notification.notificationId,
                            );
                            break;
                          case 'delete':
                            controller.deleteNotification(
                              notification.notificationId,
                            );
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (notification.isRead)
                          PopupMenuItem(
                            value: 'mark_unread',
                            child: Row(
                              children: [
                                Icon(Iconsax.message_bold, size: 16),
                                SizedBox(width: 12),
                                Text('Mark as unread'),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.trash_bold,
                                size: 16,
                                color: TAdminColors.error,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  color: TAdminColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      child: Icon(
                        Icons.more_horiz,
                        color: TAdminColors.getOnSurfaceVariantColor(
                          darkMode,
                        ),
                        size: 18,
                      ),
                    ),
                  ],
                ),

                // Time + expires（同一行）
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Iconsax.clock_bold,
                      size: 14,
                      color: TAdminColors.getOnSurfaceVariantColor(
                        darkMode,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      TFormatter.formatElapsedTime(
                        notification.createdAt,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: TAdminColors.getOnSurfaceVariantColor(
                          darkMode,
                        ),
                      ),
                    ),
                    if (isDeleteRequest && notification.requestId != null)
                      FutureBuilder<DeleteAccountRequestModel?>(
                        future: Get.find<DeleteAccountRequestRepository>()
                            .getRequestById(notification.requestId!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox.shrink();
                          }
                          final request = snapshot.data;
                          if (request == null) {
                            return const SizedBox.shrink();
                          }

                          final isExpired = request.isExpired;
                          final hasResponded = request.responderId != null;
                          final status = request.status;

                          return Row(
                            children: [
                              if (request.expiresAt != null &&
                                  !hasResponded &&
                                  status == RequestStatus.pending) ...[
                                SizedBox(width: 16),
                                Icon(
                                  Iconsax.timer_bold,
                                  size: 14,
                                  color: isExpired
                                      ? TAdminColors.error
                                      : TAdminColors.warning,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  isExpired
                                      ? 'Expired'
                                      : 'Expires in ${_formatTimeRemaining(request.timeRemaining)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isExpired
                                        ? TAdminColors.error
                                        : TAdminColors.warning,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              if (isExpired) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        TAdminColors.warning.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color:
                                          TAdminColors.warning.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    'EXPIRED',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: TAdminColors.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                  ],
                ),

                // Delete request 相关的按钮和已处理状态
                if (isDeleteRequest && notification.requestId != null)
                  FutureBuilder<DeleteAccountRequestModel?>(
                    future: Get.find<DeleteAccountRequestRepository>()
                        .getRequestById(notification.requestId!),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox.shrink();
                      }
                      final request = snapshot.data!;
                      final canRespond = request.canRespond;
                      final isExpired = request.isExpired;
                      final hasResponded = request.responderId != null;
                      final status = request.status;

                      final currentUserId = controller.currentUserId;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Action buttons for delete requests - show only if can respond
                          if (canRespond) ...[
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      _showResponseDialog(
                                        context,
                                        approved: false,
                                        controller: controller,
                                        requestId: request.requestId,
                                      );
                                    },
                                    icon: Icon(
                                      Iconsax.close_circle_bold,
                                      size: 16,
                                    ),
                                    label: Text('Reject'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: TAdminColors.error,
                                      side: BorderSide(
                                        color: TAdminColors.error,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _showResponseDialog(
                                        context,
                                        approved: true,
                                        controller: controller,
                                        requestId: request.requestId,
                                      );
                                    },
                                    icon: Icon(
                                      Iconsax.tick_circle_bold,
                                      size: 16,
                                    ),
                                    label: Text('Approve'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: TAdminColors.success,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Already responded status（包一层 Obx，确保 username 更新时重建）
                          if (hasResponded && !isExpired) ...[
                            SizedBox(height: 16),
                            Obx(() {
                              // 使用 observable 变量
                              final responderId = request.responderId ?? '';
                              final currentUserId = controller.currentUserId;
                              final responderUsername = controller.responderUsernamesCache[responderId]?.obs.value ?? 'an administrator';

                              final isCurrentUserResponder = responderId == currentUserId;

                              return Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: status == RequestStatus.approved
                                      ? TAdminColors.success.withOpacity(0.1)
                                      : TAdminColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: status == RequestStatus.approved
                                        ? TAdminColors.success.withOpacity(0.3)
                                        : TAdminColors.error.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      status == RequestStatus.approved
                                          ? Iconsax.tick_circle_bold
                                          : Iconsax.close_circle_bold,
                                      color: status == RequestStatus.approved
                                          ? TAdminColors.success
                                          : TAdminColors.error,
                                      size: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Already ${status == RequestStatus.approved ? "approved" : "rejected"} by ${isCurrentUserResponder ? "you" : responderUsername}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: status == RequestStatus.approved
                                              ? TAdminColors.success
                                              : TAdminColors.error,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 放在 screen 的对话框
  Future<void> _showResponseDialog(
    BuildContext context, {
    required bool approved,
    required AdminNotificationController controller,
    required String requestId,
  }) async {
    final textController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      approved ? 'Approve Request' : 'Reject Request',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add an optional message to the manager',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: textController,
                      maxLines: 4,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        hintText: 'Enter your message (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    setState(() => isSubmitting = true);
                                    await controller.respondToDeleteRequest(
                                      requestId: requestId,
                                      approved: approved,
                                      responseMessage:
                                          textController.text.trim(),
                                    );
                                    if (ctx.mounted) {
                                      Navigator.of(ctx).pop();
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: approved
                                  ? TAdminColors.success
                                  : TAdminColors.error,
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(approved ? 'Approve' : 'Reject'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    textController.dispose();
  }

  /// Format time remaining until expiration
  String _formatTimeRemaining(Duration duration) {
    if (duration.inHours >= 24) {
      final days = duration.inHours ~/ 24;
      final hours = duration.inHours % 24;
      if (hours > 0) {
        return '$days day${days > 1 ? 's' : ''} $hours hour${hours > 1 ? 's' : ''}';
      } else {
        return '$days day${days > 1 ? 's' : ''}';
      }
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    } else {
      return '${duration.inSeconds} second${duration.inSeconds > 1 ? 's' : ''}';
    }
  }

  Widget _buildEmptyState(bool darkMode, bool isWeb) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.notification_bold,
            size: isWeb ? 80 : 64,
            color: TAdminColors.getOnSurfaceVariantColor(darkMode)
                .withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: TextStyle(
              fontSize: isWeb ? 20 : 18,
              fontWeight: FontWeight.w600,
              color: TAdminColors.getOnSurfaceColor(darkMode),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              fontSize: isWeb ? 14 : 13,
              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading(bool darkMode) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: TAdminColors.getSurfaceColor(darkMode),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: TAdminColors.getBorderColor(darkMode),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TShimmerEffect(width: 40, height: 40, radius: 10),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TShimmerEffect(width: double.infinity, height: 16),
                    SizedBox(height: 8),
                    TShimmerEffect(width: double.infinity, height: 14),
                    SizedBox(height: 4),
                    TShimmerEffect(width: 150, height: 14),
                    SizedBox(height: 12),
                    TShimmerEffect(width: 100, height: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.system:
        return Iconsax.info_circle_bold;
      case NotificationType.reminder:
        return Iconsax.clock_bold;
      case NotificationType.account_status:
        return Iconsax.user_bold;
      case NotificationType.delete_account_request:
        return Iconsax.trash_bold;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.system:
        return TAdminColors.info;
      case NotificationType.reminder:
        return TAdminColors.warning;
      case NotificationType.account_status:
        return TAdminColors.primary;
      case NotificationType.delete_account_request:
        return TAdminColors.error;
    }
  }
}
