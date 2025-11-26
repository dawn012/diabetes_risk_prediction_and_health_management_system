import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../common/widgets/dialogs/common_confirmation_dialog.dart';
import '../../../../utils/constants/admin_colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/formatters/formatter.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../community/models/post_model.dart';
import '../../../community/models/post_report_model.dart';
import '../../controllers/community_management_controller.dart';

class PostReportsDialog extends StatelessWidget {
  final PostModel post;

  const PostReportsDialog({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CommunityManagementController>();
    final darkMode = THelperFunctions.isDarkMode(context);
    final isWeb = THelperFunctions.screenWidth() > 800;

    // Load reports when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadReportsForDialog(post.postId);
    });

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: isWeb ? 900 : MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: TAdminColors.getSurfaceColor(darkMode),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: darkMode ? Colors.black54 : Colors.grey.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(controller, darkMode),
            Divider(color: TAdminColors.getBorderColor(darkMode), height: 1),
            _buildTabs(controller, darkMode),
            Divider(color: TAdminColors.getBorderColor(darkMode), height: 1),
            Obx(() {
              if (controller.selectedReportIds.isNotEmpty) {
                return _buildBatchActionsBar(controller, darkMode);
              }
              return SizedBox.shrink();
            }),
            Expanded(
              child: Obx(() {
                if (controller.isLoadingReports.value) {
                  return _buildLoadingState(darkMode);
                }

                return IndexedStack(
                  index: controller.currentReportTabIndex.value,
                  children: [
                    _buildPendingReportsTab(controller, darkMode),
                    _buildHistoryReportsTab(controller, darkMode),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(CommunityManagementController controller, bool darkMode) {
    return Container(
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TAdminColors.warning.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.document_text_bold,
              color: TAdminColors.warning,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Post Reports',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: TAdminColors.getOnSurfaceColor(darkMode),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Post ID: ${post.postId}',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              controller.clearReportSelections();
              Get.back();
            },
            icon: Icon(
              Iconsax.close_circle_bold,
              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
            ),
            style: IconButton.styleFrom(
              backgroundColor: TAdminColors.getSurfaceVariantColor(darkMode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(CommunityManagementController controller, bool darkMode) {
    return Container(
      color: TAdminColors.getSurfaceVariantColor(darkMode),
      child: Obx(() => Row(
        children: [
          Expanded(
            child: _buildTabButton(
              'Pending',
              0,
              controller.getPendingReportsForPost(post.postId).length,
              controller,
              darkMode,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              'History',
              1,
              controller.getResolvedReportsForPost(post.postId).length,
              controller,
              darkMode,
            ),
          ),
        ],
      )),
    );
  }

  Widget _buildTabButton(
      String label,
      int index,
      int count,
      CommunityManagementController controller,
      bool darkMode,
      ) {
    final isSelected = controller.currentReportTabIndex.value == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.changeReportTab(index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? TAdminColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? TAdminColors.primary
                      : TAdminColors.getOnSurfaceVariantColor(darkMode),
                ),
              ),
              SizedBox(width: 8),
              if (index == 0 && count > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: TAdminColors.warning,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                Text(
                  '($count)',
                  style: TextStyle(
                    fontSize: 11,
                    color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBatchActionsBar(CommunityManagementController controller, bool darkMode) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: TAdminColors.primary.withOpacity(0.1),
      child: Row(
        children: [
          Icon(
            Iconsax.tick_square_bold,
            color: TAdminColors.primary,
            size: 20,
          ),
          SizedBox(width: 12),
          Text(
            '${controller.selectedReportIds.length} report${controller.selectedReportIds.length > 1 ? 's' : ''} selected',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: TAdminColors.getOnSurfaceColor(darkMode),
            ),
          ),
          Spacer(),
          TextButton.icon(
            onPressed: () => controller.clearReportSelections(),
            icon: Icon(Iconsax.close_circle_bold, size: 16),
            label: Text('Clear'),
            style: TextButton.styleFrom(
              foregroundColor: TAdminColors.getOnSurfaceVariantColor(darkMode),
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              ConfirmationDialog.show(
                title: 'Mark as Reviewed',
                message: 'Mark ${controller.selectedReportIds.length} report${controller.selectedReportIds.length > 1 ? 's' : ''} as reviewed?',
                confirmButtonText: 'Mark Reviewed',
                customIcon: Iconsax.tick_circle_bold,
                iconColor: TAdminColors.success,
                confirmButtonColor: TAdminColors.success,
                onConfirm: () => controller.markMultipleReportsAsReviewed(post.postId),
              );
            },
            icon: Icon(Iconsax.tick_circle_bold, size: 14),
            label: Text('Mark Reviewed'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TAdminColors.success,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingReportsTab(CommunityManagementController controller, bool darkMode) {
    return Obx(() {
      final pendingReports = controller.getPendingReportsForPost(post.postId);

      if (pendingReports.isEmpty) {
        return _buildEmptyState(darkMode, 'No pending reports');
      }

      return ListView.builder(
        padding: EdgeInsets.all(24),
        itemCount: pendingReports.length,
        itemBuilder: (context, index) {
          final report = pendingReports[index];
          final isSelected = controller.selectedReportIds.contains(report.reportId);
          return _buildReportCard(
            report,
            darkMode,
            controller,
            isPending: true,
          );
        },
      );
    });
  }

  Widget _buildHistoryReportsTab(CommunityManagementController controller, bool darkMode) {
    return Obx(() {
      final resolvedReports = controller.getResolvedReportsForPost(post.postId);

      if (resolvedReports.isEmpty) {
        return _buildEmptyState(darkMode, 'No resolved reports');
      }

      return ListView.builder(
        padding: EdgeInsets.all(24),
        itemCount: resolvedReports.length,
        itemBuilder: (context, index) {
          final report = resolvedReports[index];
          return _buildReportCard(
            report,
            // false,
            darkMode,
            controller,
            isPending: false,
          );
        },
      );
    });
  }

  Widget _buildReportCard(
      PostReportModel report,
      bool darkMode,
      CommunityManagementController controller, {
        required bool isPending,
      }) {
    return Obx(() { // 在这里添加 Obx
      final isSelected = controller.selectedReportIds.contains(report.reportId);

      return Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? TAdminColors.primary.withOpacity(0.1)
              : TAdminColors.getSurfaceVariantColor(darkMode),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? TAdminColors.primary
                : TAdminColors.getBorderColor(darkMode),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  if (isPending)
                    Checkbox(
                      value: isSelected, // 现在使用 Obx 内部的 isSelected
                      onChanged: (value) {
                        controller.toggleReportSelection(report.reportId);
                      },
                      activeColor: TAdminColors.primary,
                    ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getReasonColor(report.reason).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              report.reason.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getReasonColor(report.reason),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            TFormatter.formatElapsedTime(report.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Reporter: ${report.reporterId}',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isPending) ...[
                  IconButton(
                    onPressed: () {
                      ConfirmationDialog.show(
                        title: 'Mark as Reviewed',
                        message: 'Mark this report as reviewed?',
                        confirmButtonText: 'Mark Reviewed',
                        customIcon: Iconsax.tick_circle_bold,
                        iconColor: TAdminColors.success,
                        confirmButtonColor: TAdminColors.success,
                        onConfirm: () => controller.markReportAsReviewed(post.postId, report.reportId),
                      );
                    },
                    icon: Icon(Iconsax.tick_circle_bold, size: 20),
                    tooltip: 'Mark as Reviewed',
                    style: IconButton.styleFrom(
                      backgroundColor: TAdminColors.success.withOpacity(0.1),
                      foregroundColor: TAdminColors.success,
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      ConfirmationDialog.show(
                        title: 'Disable Post',
                        message: 'Disable this post and mark report as reviewed?',
                        confirmButtonText: 'Disable Post',
                        customIcon: Iconsax.eye_slash_bold,
                        iconColor: TAdminColors.error,
                        confirmButtonColor: TAdminColors.error,
                        onConfirm: () => controller.disablePostFromReport(post.postId, report.reportId),
                      );
                    },
                    icon: Icon(Iconsax.eye_slash_bold, size: 20),
                    tooltip: 'Disable Post',
                    style: IconButton.styleFrom(
                      backgroundColor: TAdminColors.error.withOpacity(0.1),
                      foregroundColor: TAdminColors.error,
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: TAdminColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.tick_circle_bold,
                          size: 14,
                          color: TAdminColors.success,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Reviewed',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: TAdminColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Additional note
          if (report.additionalNote != null && report.additionalNote!.isNotEmpty) ...[
            Divider(color: TAdminColors.getBorderColor(darkMode), height: 1),
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Additional Details:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    report.additionalNote!,
                    style: TextStyle(
                      fontSize: 13,
                      color: TAdminColors.getOnSurfaceColor(darkMode),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Resolved info
          if (!isPending && report.resolvedAt != null) ...[
            Divider(color: TAdminColors.getBorderColor(darkMode), height: 1),
            Container(
              padding: EdgeInsets.all(16),
              child: Text(
                'Resolved: ${TFormatter.formatElapsedTime(report.resolvedAt!)}',
                style: TextStyle(
                  fontSize: 11,
                  color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                ),
              ),
            ),
          ],
        ],
    ));
    });
  }

  Color _getReasonColor(ReportReason reason) {
    switch (reason) {
      case ReportReason.spam:
        return TAdminColors.warning;
      case ReportReason.harassment:
        return TAdminColors.error;
      case ReportReason.fraud:
        return TAdminColors.errorDark;
      case ReportReason.inappropriate:
        return Colors.deepOrange;
      case ReportReason.misinformation:
        return Colors.purple;
      case ReportReason.other:
        return TAdminColors.info;
    }
  }

  Widget _buildLoadingState(bool darkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: TAdminColors.primary,
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Loading reports...',
            style: TextStyle(
              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool darkMode, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.document_bold,
            size: 64,
            color: TAdminColors.getOnSurfaceVariantColor(darkMode),
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: TAdminColors.getOnSurfaceColor(darkMode),
            ),
          ),
        ],
      ),
    );
  }
}