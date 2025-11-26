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
import '../../../reward/models/reward_model.dart';
import '../../controllers/reward_management_controller.dart';
import 'widgets/reward_batch_action_bar.dart';
import 'widgets/reward_management_header.dart';

class RewardManagementScreen extends StatelessWidget {
  const RewardManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RewardManagementController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
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
                    RewardManagementHeader(controller: controller),
                    const SizedBox(height: 24),

                    // Batch Actions Bar
                    Obx(() {
                      return controller.selectedRewards.isNotEmpty
                          ? Column(
                        children: [
                          RewardBatchActionsBar(controller: controller),
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
                              return ReusableDataTable<RewardModel>(
                                data: controller.paginatedRewards,
                                columns: _getRewardTableColumns(controller, darkMode),
                                isLoading: controller.isLoading.value,
                                onSelectAll: (selected) => controller.toggleSelectAll(selected),
                                selectedItems: controller.selectedRewards,
                                onItemSelect: (reward, selected) =>
                                    controller.toggleRewardSelection(reward, selected),
                                searchQuery: controller.searchController.text,
                                sortColumnIndex: controller.sortColumnIndex.value,
                                sortAscending: controller.sortAscending.value,
                                onSort: (columnIndex, ascending) =>
                                    controller.sortRewards(columnIndex, ascending),
                              );
                            }),
                          ),

                          // Pagination
                          Obx(() => PaginationWidget(
                            currentPage: controller.currentPage.value,
                            totalPages: controller.totalPages.value,
                            onPageChanged: controller.changePage,
                            totalItems: controller.allRewards.length,
                            itemsPerPage: controller.itemsPerPage.value,
                            startIndex: ((controller.currentPage.value - 1) *
                                controller.itemsPerPage.value) + 1,
                            endIndex: (controller.currentPage.value *
                                controller.itemsPerPage.value).clamp(0, controller.allRewards.length),
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

  List<DataTableColumn<RewardModel>> _getRewardTableColumns(
      RewardManagementController controller, bool darkMode) {
    return [
      DataTableColumn<RewardModel>(
        label: 'Reward',
        field: 'title',
        minWidth: 200,
        flex: 8,
        sortable: true,
        builder: (reward) {
          final query = controller.searchController.text;
          return Row(
            children: [
              // Reward Image
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: TAdminColors.getBorderColor(darkMode),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: reward.icon.isNotEmpty
                      ? Image.network(
                    reward.icon,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Iconsax.gallery_slash_bold,
                        size: 24,
                        color: TAdminColors.error,
                      );
                    },
                  )
                      : Icon(
                    Iconsax.gallery_bold,
                    size: 24,
                    color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                  ),
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
                          reward.title,
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
                      reward.description,
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
      DataTableColumn<RewardModel>(
        label: 'Type',
        field: 'rewardType',
        minWidth: 130,
        flex: 2,
        sortable: true,
        builder: (reward) => _buildTypeChip(reward.rewardType, darkMode),
      ),
      DataTableColumn<RewardModel>(
        label: 'Cost Points',
        field: 'costPoints',
        minWidth: 100,
        flex: 2,
        sortable: true,
        builder: (reward) => Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: TAdminColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Iconsax.coin_bold,
                  size: 14,
                  color: TAdminColors.warning,
                ),
                SizedBox(width: 4),
                Text(
                  '${reward.costPoints}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TAdminColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      DataTableColumn<RewardModel>(
        label: 'Available',
        field: 'availableQuantity',
        minWidth: 100,
        flex: 2,
        sortable: true,
        builder: (reward) {
          if (reward.availableQuantity == null) {
            return Text(
              'Unlimited',
              style: TextStyle(
                fontSize: 12,
                color: TAdminColors.success,
                fontWeight: FontWeight.w500,
              ),
            );
          }
          return Text(
            '${reward.availableQuantity}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: reward.availableQuantity! > 0
                  ? TAdminColors.getOnSurfaceColor(darkMode)
                  : TAdminColors.error,
            ),
          );
        },
      ),
      DataTableColumn<RewardModel>(
        label: 'Status',
        field: 'isActive',
        minWidth: 85,
        flex: 2,
        sortable: true,
        builder: (reward) => _buildStatusChip(reward, darkMode),
      ),
      DataTableColumn<RewardModel>(
        label: 'Created/Updated',
        field: 'updatedAt',
        minWidth: 140,
        flex: 2,
        sortable: true,
        builder: (reward) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${reward.updatedAt.day}/${reward.updatedAt.month}/${reward.updatedAt.year}',
              style: TextStyle(
                fontSize: 12,
                color: TAdminColors.getOnSurfaceColor(darkMode),
              ),
            ),
            Text(
              TFormatter.formatElapsedTime(reward.updatedAt),
              style: TextStyle(
                fontSize: 10,
                color: TAdminColors.getOnSurfaceVariantColor(darkMode),
              ),
            ),
          ],
        ),
      ),
      DataTableColumn<RewardModel>(
        label: 'Actions',
        field: 'actions',
        minWidth: 120,
        flex: 2,
        sortable: false,
        builder: (reward) => _buildActionButtons(reward, controller, darkMode),
      ),
    ];
  }

  Widget _buildTypeChip(RewardType rewardType, bool darkMode) {
    Color chipColor;
    IconData chipIcon;
    String label;

    switch (rewardType) {
      case RewardType.avatarFrame:
        chipColor = TAdminColors.primary;
        chipIcon = Iconsax.frame_bold;
        label = 'Avatar Frame';
        break;
      case RewardType.virtualItem:
        chipColor = TAdminColors.warning;
        chipIcon = Iconsax.medal_bold;
        label = 'Virtual Item';
        break;
      case RewardType.coupon:
        chipColor = TAdminColors.success;
        chipIcon = Iconsax.ticket_discount_bold;
        label = 'Coupon';
        break;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 130),
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
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: chipColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(RewardModel reward, bool darkMode) {
    Color statusColor = reward.isActive ? TAdminColors.success : TAdminColors.error;
    String statusText = reward.isActive ? 'Active' : 'Disabled';
    IconData statusIcon = reward.isActive ? Iconsax.eye_bold : Iconsax.eye_slash_bold;

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

  Widget _buildActionButtons(RewardModel reward, RewardManagementController controller, bool darkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // View Details Button
        IconButton(
          onPressed: () => controller.openViewRewardDetailDialog(reward),
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
          onPressed: () => controller.openEditRewardDialog(reward),
          icon: const Icon(Iconsax.edit_bold, size: 16),
          tooltip: 'Edit Reward',
          style: IconButton.styleFrom(
            backgroundColor: TAdminColors.warning.withOpacity(0.1),
            foregroundColor: TAdminColors.warning,
            minimumSize: const Size(32, 32),
          ),
        ),
        const SizedBox(width: 4),
        if (reward.isActive) ...[
          // Disable Button
          IconButton(
            onPressed: () {
              ConfirmationDialog.show(
                title: 'Disable Reward',
                message: 'Are you sure you want to disable this reward? It will no longer be available to users.',
                confirmButtonText: 'Disable',
                customIcon: Iconsax.eye_slash_bold,
                iconColor: TAdminColors.error,
                confirmButtonColor: TAdminColors.error,
                onConfirm: () => controller.disableReward(reward),
              );
            },
            icon: const Icon(Iconsax.eye_slash_bold, size: 16),
            tooltip: 'Disable Reward',
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
                title: 'Enable Reward',
                message: 'Are you sure you want to enable this reward? It will be available to users again.',
                confirmButtonText: 'Enable',
                customIcon: Iconsax.eye_bold,
                iconColor: TAdminColors.success,
                confirmButtonColor: TAdminColors.success,
                onConfirm: () => controller.enableReward(reward),
              );
            },
            icon: const Icon(Iconsax.eye_bold, size: 16),
            tooltip: 'Enable Reward',
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
}