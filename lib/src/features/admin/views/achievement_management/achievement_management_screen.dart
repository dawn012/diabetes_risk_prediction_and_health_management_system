import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../common/widgets/dialogs/common_confirmation_dialog.dart';
import '../../../../common/widgets/pagination/pagination_widget.dart';
import '../../../../common/widgets/table/reusable_data_table.dart';
import '../../../../utils/constants/admin_colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/formatters/formatter.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../achievement/models/achievement_model.dart';
import '../../controllers/achievement_management_controller.dart';
import 'achievement_detail_dialog.dart';
import 'widgets/achievement_batch_action_bar.dart';
import 'widgets/achievement_management_header.dart';

class AchievementManagementScreen extends StatelessWidget {
  const AchievementManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AchievementManagementController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate available space for table
            final headerHeight = 200.0;
            final batchActionsHeight = 60.0;
            final paginationHeight = 80.0;
            final padding = 48.0;
            final availableTableHeight = constraints.maxHeight -
                headerHeight - batchActionsHeight - paginationHeight - padding;

            return SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with search and filters
                    AchievementManagementHeader(controller: controller),
                    const SizedBox(height: 24),

                    // Batch Actions Bar
                    Obx(() {
                      return controller.selectedAchievements.isNotEmpty
                          ? Column(
                        children: [
                          AchievementBatchActionsBar(controller: controller),
                          const SizedBox(height: 16),
                        ],
                      )
                          : const SizedBox.shrink();
                    }),

                    // Data Table Container
                    Container(
                      height: availableTableHeight.clamp(400.0, double.infinity),
                      decoration: BoxDecoration(
                        color: TAdminColors.getSurfaceColor(darkMode),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: darkMode ? Colors.black26 : Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Table
                          Expanded(
                            child: Obx(() {
                              print('Obx rebuilding');

                              return ReusableDataTable<AchievementModel>(
                                data: controller.paginatedAchievements,
                                columns: _getAchievementTableColumns(controller, darkMode),
                                isLoading: controller.isLoading.value,
                                onSelectAll: (selected) => controller.toggleSelectAll(selected),
                                selectedItems: controller.selectedAchievements,
                                onItemSelect: (achievement, selected) =>
                                    controller.toggleAchievementSelection(achievement, selected),
                                searchQuery: controller.searchController.text,
                                sortColumnIndex: controller.sortColumnIndex.value,
                                sortAscending: controller.sortAscending.value,
                                onSort: (columnIndex, ascending) =>
                                    controller.sortAchievements(columnIndex, ascending),
                              );
                            }),
                          ),

                          // Pagination
                          Obx(() => PaginationWidget(
                            currentPage: controller.currentPage.value,
                            totalPages: controller.totalPages.value,
                            onPageChanged: controller.changePage,
                            totalItems: controller.allAchievements.length,
                            itemsPerPage: controller.itemsPerPage.value,
                            startIndex: ((controller.currentPage.value - 1) *
                                controller.itemsPerPage.value) + 1,
                            endIndex: (controller.currentPage.value *
                                controller.itemsPerPage.value).clamp(0, controller.allAchievements.length),
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<DataTableColumn<AchievementModel>> _getAchievementTableColumns(
      AchievementManagementController controller, bool darkMode) {
    return [
      DataTableColumn<AchievementModel>(
        label: 'Achievement',
        field: 'achievementTitle',
        minWidth: 200,
        flex: 8,
        sortable: true,
        builder: (achievement) {
          final query = controller.searchController.text;
          return Row(
            children: [
              // Achievement Image
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: TAdminColors.getBorderColor(darkMode),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: _buildDefaultAchievementIcon(achievement, darkMode),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: controller.getHighlightedText(
                          achievement.achievementTitle,
                          query,
                          textColor: TAdminColors.getOnSurfaceColor(darkMode),
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: TAdminColors.getOnSurfaceColor(darkMode),
                        ),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      achievement.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      DataTableColumn<AchievementModel>(
        label: 'Type',
        field: 'achievementType',
        minWidth: 100,
        flex: 2,
        sortable: true,
        builder: (achievement) => _buildTypeChip(achievement.achievementType, darkMode),
      ),
      DataTableColumn<AchievementModel>(
        label: 'Levels',
        field: 'levelsCount',
        minWidth: 80,
        flex: 3,
        sortable: true,
        builder: (achievement) => _buildLevelsInfo(achievement, darkMode),
      ),
      DataTableColumn<AchievementModel>(
        label: 'Participants',
        field: 'participants',
        minWidth: 100,
        flex: 2,
        sortable: true,
        builder: (achievement) => _buildCompletionStats(achievement, controller, darkMode),
      ),
      DataTableColumn<AchievementModel>(
        label: 'Created/Updated',
        field: 'updatedAt',
        minWidth: 140,
        flex: 2,
        sortable: true,
        builder: (achievement) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${achievement.updatedAt.day}/${achievement.updatedAt.month}/${achievement.updatedAt.year}',
              style: TextStyle(
                fontSize: 12,
                color: TAdminColors.getOnSurfaceColor(darkMode),
              ),
            ),
            Text(
              TFormatter.formatElapsedTime(achievement.updatedAt),
              style: TextStyle(
                fontSize: 10,
                color: TAdminColors.getOnSurfaceVariantColor(darkMode),
              ),
            ),
          ],
        ),
      ),
      DataTableColumn<AchievementModel>(
        label: 'Status',
        field: 'isActive',
        minWidth: 85,
        flex: 2,
        sortable: true,
        builder: (achievement) => _buildStatusChip(achievement, darkMode),
      ),
      DataTableColumn<AchievementModel>(
        label: 'Actions',
        field: 'actions',
        minWidth: 120,
        flex: 2,
        sortable: false,
        builder: (achievement) => _buildActionButtons(achievement, controller, darkMode),
      ),
    ];
  }

  Widget _buildDefaultAchievementIcon(AchievementModel achievement, bool darkMode) {
    final iconData = IconData(achievement.iconCodePoint, fontFamily: 'MaterialIcons');

    // 根据成就类型设置不同的背景色
    Color backgroundColor;
    Color iconColor;

    switch (achievement.achievementType) {
      case AchievementType.periodic:
        backgroundColor = TAdminColors.warning.withOpacity(0.1);
        iconColor = TAdminColors.warning;
        break;
      case AchievementType.permanent:
        backgroundColor = TAdminColors.primary.withOpacity(0.1);
        iconColor = TAdminColors.primary;
        break;
      default:
        backgroundColor = TAdminColors.getSurfaceVariantColor(darkMode);
        iconColor = TAdminColors.getOnSurfaceVariantColor(darkMode);
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        // border: Border.all(
        //   color: TAdminColors.getBorderColor(darkMode),
        //   width: 1,
        // ),
      ),
      child: Center(
        child: Icon(
          iconData,
          size: 20,
          color: iconColor,
        ),
      ),
    );
  }

  Widget _buildTypeChip(AchievementType achievementType, bool darkMode) {
    Color chipColor;
    IconData chipIcon;

    switch (achievementType) {
      case AchievementType.periodic:
        chipColor = TAdminColors.warning;
        chipIcon = Iconsax.calendar_bold;
        break;
      case AchievementType.permanent:
        chipColor = TAdminColors.primary;
        chipIcon = Iconsax.award_bold;
        break;
      default:
        chipColor = TAdminColors.getOnSurfaceVariantColor(darkMode);
        chipIcon = Iconsax.medal_bold;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: chipColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: chipColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                chipIcon,
                size: 12,
                color: chipColor,
              ),
              const SizedBox(width: 4),
              Text(
                achievementType.displayName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: chipColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelsInfo(AchievementModel achievement, bool darkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${achievement.levels.length} Level${achievement.levels.length == 1 ? '' : 's'}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: TAdminColors.getOnSurfaceColor(darkMode),
          ),
        ),
        if (achievement.levels.isNotEmpty)
          Text(
            achievement.achievementType == AchievementType.periodic
                ? 'Bronze, Silver, Gold'
                : achievement.levels.first.level.displayName,
            style: TextStyle(
              fontSize: 10,
              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
            ),
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildCompletionStats(AchievementModel achievement, AchievementManagementController controller, bool darkMode) {
    // Get completion stats from controller
    final completionStats = controller.getCompletionStats(achievement);
    final totalCompletions = completionStats['total'] ?? 0;

    return InkWell(
      // onTap: () => _showCompletionDetails(achievement, controller),
      onTap: null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: TAdminColors.info.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: TAdminColors.info.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Iconsax.people_bold,
                  size: 12,
                  color: TAdminColors.info,
                ),
                const SizedBox(width: 4),
                Text(
                  '$totalCompletions',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: TAdminColors.info,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(AchievementModel achievement, bool darkMode) {
    Color statusColor = achievement.isActive ? TAdminColors.success : TAdminColors.error;
    String statusText = achievement.isActive ? 'Active' : 'Disabled';
    IconData statusIcon = achievement.isActive ? Iconsax.eye_bold : Iconsax.eye_slash_bold;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 85),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                statusIcon,
                size: 12,
                color: statusColor,
              ),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(AchievementModel achievement, AchievementManagementController controller, bool darkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // View Details Button
        IconButton(
          onPressed: () => _showAchievementDetailDialog(achievement, controller),
          icon: const Icon(Iconsax.eye_bold, size: 16),
          tooltip: 'View Details',
          style: IconButton.styleFrom(
            backgroundColor: TAdminColors.info.withOpacity(0.1),
            foregroundColor: TAdminColors.info,
            minimumSize: const Size(32, 32),
          ),
        ),
        const SizedBox(width: 4),
        // Edit Button
        IconButton(
          onPressed: () => controller.openEditAchievementDialog(achievement),
          icon: const Icon(Iconsax.edit_bold, size: 16),
          tooltip: 'Edit Achievement',
          style: IconButton.styleFrom(
            backgroundColor: TAdminColors.warning.withOpacity(0.1),
            foregroundColor: TAdminColors.warning,
            minimumSize: const Size(32, 32),
          ),
        ),
        const SizedBox(width: 4),
        if (achievement.isActive) ...[
          // Disable Button
          IconButton(
            onPressed: () {
              ConfirmationDialog.show(
                title: 'Disable Achievement',
                message: 'Are you sure you want to disable this achievement? It will no longer be available to users.',
                confirmButtonText: 'Disable',
                customIcon: Iconsax.eye_slash_bold,
                iconColor: TAdminColors.error,
                confirmButtonColor: TAdminColors.error,
                onConfirm: () => controller.disableAchievement(achievement),
              );
            },
            icon: const Icon(Iconsax.eye_slash_bold, size: 16),
            tooltip: 'Disable Achievement',
            style: IconButton.styleFrom(
              backgroundColor: TAdminColors.error.withOpacity(0.1),
              foregroundColor: TAdminColors.error,
              minimumSize: const Size(32, 32),
            ),
          ),
        ] else ...[
          // Enable Button
          IconButton(
            onPressed: () {
              ConfirmationDialog.show(
                title: 'Enable Achievement',
                message: 'Are you sure you want to enable this achievement? It will be available to users again.',
                confirmButtonText: 'Enable',
                customIcon: Iconsax.eye_bold,
                iconColor: TAdminColors.success,
                confirmButtonColor: TAdminColors.success,
                onConfirm: () => controller.enableAchievement(achievement),
              );
            },
            icon: const Icon(Iconsax.eye_bold, size: 16),
            tooltip: 'Enable Achievement',
            style: IconButton.styleFrom(
              backgroundColor: TAdminColors.success.withOpacity(0.1),
              foregroundColor: TAdminColors.success,
              minimumSize: const Size(32, 32),
            ),
          ),
        ],
      ],
    );
  }

  void _showAchievementDetailDialog(AchievementModel achievement, AchievementManagementController controller) {
    Get.dialog(AchievementDetailDialog(
      achievement: achievement,
      controller: controller,
    ));
  }

  void _showCompletionDetails(AchievementModel achievement, AchievementManagementController controller) {
    // TODO: Show completion details dialog
    controller.showCompletionBreakdown(achievement);
  }
}