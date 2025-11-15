import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../../common/widgets/dialogs/common_confirmation_dialog.dart';
import '../../../../common/widgets/pagination/pagination_widget.dart';
import '../../../../common/widgets/table/reusable_data_table.dart';
import '../../../../utils/constants/admin_colors.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../authentication/models/admin_model.dart';
import '../../controllers/manager_management_controller.dart';
import '../user_management/widgets/batch_action_bar.dart';
import 'manager_detail_dialog.dart';
import 'widgets/manager_management_header.dart';

class ManagerManagementScreen extends StatelessWidget {
  const ManagerManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ManagerManagementController());
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
                    ManagerManagementHeader(controller: controller),
                    const SizedBox(height: 24),

                    Obx(() {
                      return controller.selectedManagers.isNotEmpty
                          ? BatchActionsBar(
                        selectedItems: controller.selectedManagers,
                        showingActive: controller.showingActiveManagers,
                        onClearSelection: () => controller.toggleSelectAll(false),
                        onBatchBan: () => controller.batchBanManagers(),
                        onBatchRestore: () => controller.batchRestoreManagers(),
                        itemLabel: 'manager',
                        getUserName: (manager) => manager.username,
                        getUserEmail: (manager) => manager.email,
                      )
                      : const SizedBox.shrink();
                    }),
                    const SizedBox(height: 16),

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
                            Expanded(
                              child: Obx(() {
                                return ReusableDataTable<AdminModel>(
                                  data: controller.filteredManagers,
                                  columns: _getManagerTableColumns(controller, darkMode),
                                  isLoading: controller.isLoading.value,
                                  onSelectAll: (selected) => controller.toggleSelectAll(selected),
                                  selectedItems: controller.selectedManagers,
                                  onItemSelect: (manager, selected) =>
                                      controller.toggleManagerSelection(manager, selected),
                                  searchQuery: controller.searchController.text,
                                  sortColumnIndex: controller.sortColumnIndex.value,
                                  sortAscending: controller.sortAscending.value,
                                  onSort: (columnIndex, ascending) =>
                                      controller.sortManagers(columnIndex, ascending),
                                );
                              }),
                            ),

                            Obx(() => PaginationWidget(
                              currentPage: controller.currentPage.value,
                              totalPages: controller.totalPages.value,
                              onPageChanged: controller.changePage,
                              totalItems: controller.allManagers.length,
                              itemsPerPage: controller.itemsPerPage.value,
                              startIndex: ((controller.currentPage.value - 1) *
                                  controller.itemsPerPage.value) + 1,
                              endIndex: (controller.currentPage.value *
                                  controller.itemsPerPage.value).clamp(0, controller.allManagers.length),
                            )),
                          ]
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

  List<DataTableColumn<AdminModel>> _getManagerTableColumns(
      ManagerManagementController controller, bool darkMode) {
    return [
      DataTableColumn<AdminModel>(
        label: 'User ID',
        field: 'userId',
        minWidth: 100,
        flex: 2,
        sortable: true,
        builder: (manager) {
          final query = controller.searchController.text;
          return RichText(
            text: TextSpan(
              children: controller.getHighlightedText(manager.userId, query),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: TAdminColors.getOnSurfaceVariantColor(darkMode),
              ),
            ),
          );
        },
      ),
      DataTableColumn<AdminModel>(
        label: 'Profile',
        field: 'profile',
        minWidth: 60,
        flex: 1,
        sortable: false,
        builder: (manager) => CircleAvatar(
          radius: 20,
          backgroundImage: manager.profileImg.isNotEmpty
              ? NetworkImage(manager.profileImg)
              : null,
          backgroundColor: manager.profileImg.isEmpty
              ? TAdminColors.getRoleColor(manager.userType).withOpacity(0.2)
              : null,
          child: manager.profileImg.isEmpty
              ? Icon(
            Iconsax.user_bold,
            size: 16,
            color: TAdminColors.getRoleColor(manager.userType),
          )
              : null,
        ),
      ),
      DataTableColumn<AdminModel>(
        label: 'Username',
        field: 'username',
        minWidth: 100,
        flex: 2,
        sortable: true,
        builder: (manager) {
          final query = controller.searchController.text;
          final textColor = TAdminColors.getOnSurfaceColor(darkMode);
          return RichText(
            text: TextSpan(
              children: controller.getHighlightedText(manager.username, query, textColor: textColor),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          );
        },
      ),
      DataTableColumn<AdminModel>(
        label: 'Email',
        field: 'email',
        minWidth: 150,
        flex: 3,
        sortable: true,
        builder: (manager) {
          final query = controller.searchController.text;
          final textColor = TAdminColors.getOnSurfaceColor(darkMode);

          return RichText(
            text: TextSpan(
              children: controller.getHighlightedText(manager.email, query, textColor: textColor),
              style: TextStyle(
                color: textColor,
              ),
            ),
          );
        },
      ),
      DataTableColumn<AdminModel>(
        label: 'Phone',
        field: 'phoneNumber',
        minWidth: 100,
        flex: 2,
        sortable: true,
        builder: (manager) {
          final query = controller.searchController.text;
          final textColor = TAdminColors.getOnSurfaceColor(darkMode);
          final phoneText = manager.formattedPhoneNo.isNotEmpty ? manager.formattedPhoneNo : 'Not provided';

          return RichText(
            text: TextSpan(
              children: controller.getHighlightedText(phoneText, query, textColor: textColor),
              style: TextStyle(
                color: textColor,
              ),
            ),
          );
        },
      ),
      DataTableColumn<AdminModel>(
        label: 'Role',
        field: 'userType',
        minWidth: 120,
        flex: 2,
        sortable: true,
        builder: (manager) => _buildRoleChip(manager, darkMode),
      ),
      DataTableColumn<AdminModel>(
        label: 'Join Date',
        field: 'joinDate',
        minWidth: 90,
        flex: 2,
        sortable: true,
        builder: (manager) => Text(
          '${manager.joinDate.day}/${manager.joinDate.month}/${manager.joinDate.year}',
          style: TextStyle(
            color: TAdminColors.getOnSurfaceColor(darkMode),
          ),
        ),
      ),
      DataTableColumn<AdminModel>(
        label: 'Status',
        field: 'status',
        minWidth: 100,
        flex: 3,
        sortable: true,
        builder: (manager) => _buildStatusChip(manager, darkMode),
      ),
      DataTableColumn<AdminModel>(
        label: 'Actions',
        field: 'actions',
        minWidth: 120,
        flex: 2,
        sortable: false,
        builder: (manager) => _buildActionButtons(manager, controller, darkMode),
      ),
    ];
  }

  Widget _buildRoleChip(AdminModel manager, bool isDark) {
    final roleColor = TAdminColors.getRoleColor(manager.userType);
    final displayRole = manager.userType.split(' ').map((word) =>
    word[0].toUpperCase() + word.substring(1)
    ).join(' ');

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: roleColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: roleColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Iconsax.shield_tick_bold,
                size: 12,
                color: roleColor,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  displayRole,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: roleColor,
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

  Widget _buildStatusChip(AdminModel manager, bool isDark) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (!manager.accountAvailable) {
      statusColor = TAdminColors.banned;
      statusText = 'Banned';
      statusIcon = Iconsax.user_remove_bold;
    } else if (manager.isVerify) {
      statusColor = TAdminColors.success;
      statusText = 'Verified';
      statusIcon = Iconsax.shield_tick_bold;
    } else {
      statusColor = TAdminColors.error;
      statusText = 'Not Verified';
      statusIcon = Iconsax.shield_cross_bold;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 120),
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
              Flexible(
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
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

  Widget _buildActionButtons(AdminModel manager, ManagerManagementController controller, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: manager.accountAvailable ? MainAxisAlignment.spaceAround : MainAxisAlignment.start,
      children: [
        // Detail Button
        IconButton(
          onPressed: () => _showManagerDetailDialog(manager, isDark),
          icon: const Icon(Iconsax.eye_bold, size: 16),
          tooltip: 'View Details',
          style: IconButton.styleFrom(
            backgroundColor: TAdminColors.info.withOpacity(0.1),
            foregroundColor: TAdminColors.info,
            minimumSize: const Size(32, 32),
          ),
        ),
        const SizedBox(width: 4),

        if (manager.accountAvailable) ...[
          // Edit Button (only for active managers)
          IconButton(
            onPressed: () => controller.openEditManagerDialog(manager),
            icon: const Icon(Iconsax.edit_bold, size: 16),
            tooltip: 'Edit Manager',
            style: IconButton.styleFrom(
              backgroundColor: TAdminColors.warning.withOpacity(0.1),
              foregroundColor: TAdminColors.warning,
              minimumSize: const Size(32, 32),
            ),
          ),
          const SizedBox(width: 4),
          // Ban Button
          IconButton(
            onPressed: () {
              ConfirmationDialog.show(
                title: 'Ban Manager',
                message: 'Are you sure you want to ban ${manager.username}? This action will disable their account.',
                confirmButtonText: 'Ban Manager',
                customIcon: Iconsax.user_remove_bold,
                iconColor: TAdminColors.error,
                confirmButtonColor: TAdminColors.error,
                onConfirm: () => controller.banManager(manager),
              );
            },
            icon: const Icon(Iconsax.user_remove_bold, size: 16),
            tooltip: 'Ban Manager',
            style: IconButton.styleFrom(
              backgroundColor: TAdminColors.error.withOpacity(0.1),
              foregroundColor: TAdminColors.error,
              minimumSize: const Size(32, 32),
            ),
          ),
        ] else ...[
          // Restore Button (only for banned managers)
          IconButton(
            onPressed: () {
              ConfirmationDialog.show(
                title: 'Restore Manager',
                message: 'Are you sure you want to restore ${manager.username}? This will reactivate their account.',
                confirmButtonText: 'Restore Manager',
                customIcon: Iconsax.refresh_bold,
                iconColor: TAdminColors.success,
                confirmButtonColor: TAdminColors.success,
                onConfirm: () => controller.restoreManager(manager),
              );
            },
            icon: const Icon(Iconsax.refresh_bold, size: 16),
            tooltip: 'Restore Manager',
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

  void _showManagerDetailDialog(AdminModel manager, bool isDark) {
    Get.dialog(ManagerDetailDialog(manager: manager));
  }
}