import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../../common/widgets/dialogs/common_confirmation_dialog.dart';
import '../../../../common/widgets/pagination/pagination_widget.dart';
import '../../../../common/widgets/table/reusable_data_table.dart';
import '../../../../utils/constants/admin_colors.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../authentication/models/user_model.dart';
import '../../controllers/user_management_controller.dart';
import 'user_detail_dialog.dart';
import 'widgets/user_batch_action_bar.dart';
import 'widgets/user_management_header.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UserManagementController());
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
                    // Header with search and add button
                    UserManagementHeader(controller: controller),
                    const SizedBox(height: 24),

                    // Batch Actions Bar
                    Obx(() {
                      return controller.selectedUsers.isNotEmpty
                          ? UserBatchActionsBar(controller: controller)
                          : const SizedBox.shrink();
                    }),
                    const SizedBox(height: 16),

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
                          Expanded(
                            child: Obx(() {
                              print('Obx rebuilding - filteredUsers length: ${controller.filteredUsers.length}');

                              return ReusableDataTable<UserModel>(
                                data: controller.filteredUsers,
                                columns: _getUserTableColumns(controller, darkMode),
                                isLoading: controller.isLoading.value,
                                onSelectAll: (selected) => controller.toggleSelectAll(selected),
                                selectedItems: controller.selectedUsers,
                                onItemSelect: (user, selected) => controller.toggleUserSelection(user, selected),
                                searchQuery: controller.searchController.text,
                                sortColumnIndex: controller.sortColumnIndex.value,
                                sortAscending: controller.sortAscending.value,
                                onSort: (columnIndex, ascending) => controller.sortUsers(columnIndex, ascending),
                              );
                            }),
                          ),

                          // Pagination
                          Obx(() => PaginationWidget(
                            currentPage: controller.currentPage.value,
                            totalPages: controller.totalPages.value,
                            onPageChanged: controller.changePage,
                            totalItems: controller.allUsers.length,
                            itemsPerPage: controller.itemsPerPage.value,
                            startIndex: ((controller.currentPage.value - 1) *
                                controller.itemsPerPage.value) + 1,
                            endIndex: (controller.currentPage.value *
                                controller.itemsPerPage.value).clamp(0, controller.allUsers.length),
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

  List<DataTableColumn<UserModel>> _getUserTableColumns(UserManagementController controller, bool darkMode) {
    return [
      DataTableColumn<UserModel>(
        label: 'User ID',
        field: 'userId',
        minWidth: 100,
        flex: 2,
        sortable: true,
        builder: (user) {
          final query = controller.searchController.text;
          return RichText(
            text: TextSpan(
              children: controller.getHighlightedText(user.userId, query),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: TAdminColors.getOnSurfaceVariantColor(darkMode),
              ),
            ),
          );
        },
      ),
      DataTableColumn<UserModel>(
        label: 'Profile',
        field: 'profile',
        minWidth: 60,
        flex: 1,
        sortable: false,
        builder: (user) => CircleAvatar(
          radius: 20,
          backgroundImage: user.profileImg.isNotEmpty ? NetworkImage(user.profileImg) : null,
          backgroundColor: user.profileImg.isEmpty ? TAdminColors.primary.withOpacity(0.2) : null,
          child: user.profileImg.isEmpty ? const Icon(Iconsax.user_bold, size: 16) : null,
        ),
      ),
      DataTableColumn<UserModel>(
        label: 'Username',
        field: 'username',
        minWidth: 100,
        flex: 2,
        sortable: true,
        builder: (user) {
          final query = controller.searchController.text;
          final textColor = TAdminColors.getOnSurfaceColor(darkMode);
          return RichText(
            text: TextSpan(
              children: controller.getHighlightedText(user.username, query, textColor: textColor),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          );
        },
      ),
      DataTableColumn<UserModel>(
        label: 'Email',
        field: 'email',
        minWidth: 150,
        flex: 3,
        sortable: true,
        builder: (user) {
          final query = controller.searchController.text;
          final textColor = TAdminColors.getOnSurfaceColor(darkMode);

          return RichText(
            text: TextSpan(
              children: controller.getHighlightedText(user.email, query, textColor: textColor),
              style: TextStyle(
                color: textColor,
              ),
            ),
          );
        },
      ),
      DataTableColumn<UserModel>(
        label: 'Phone',
        field: 'phoneNumber',
        minWidth: 100,
        flex: 2,
        sortable: true,
        builder: (user) {
          final query = controller.searchController.text;
          final textColor = TAdminColors.getOnSurfaceColor(darkMode);

          return RichText(
            text: TextSpan(
              children: controller.getHighlightedText(user.formattedPhoneNo, query, textColor: textColor),
              style: TextStyle(
                color: textColor,
              ),
            ),
          );
        },
      ),
      DataTableColumn<UserModel>(
        label: 'Join Date',
        field: 'joinDate',
        minWidth: 90,
        flex: 2,
        sortable: true,
        builder: (user) => Text(
          '${user.joinDate.day}/${user.joinDate.month}/${user.joinDate.year}',
          style: TextStyle(
            color: TAdminColors.getOnSurfaceColor(darkMode),
          ),
        ),
      ),
      DataTableColumn<UserModel>(
        label: 'Status',
        field: 'status',
        minWidth: 85,
        flex: 2,
        sortable: true,
        builder: (user) => _buildStatusChip(user, darkMode),
      ),
      DataTableColumn<UserModel>(
        label: 'Score',
        field: 'totalScore',
        minWidth: 80,
        flex: 1,
        sortable: true,
        builder: (user) => Text(
          '${user.totalScore}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: TAdminColors.primary,
          ),
        ),
      ),
      DataTableColumn<UserModel>(
        label: 'Actions',
        field: 'actions',
        minWidth: 120,
        flex: 2,
        sortable: false,
        builder: (user) => _buildActionButtons(user, controller, darkMode),
      ),
    ];
  }

  Widget _buildStatusChip(UserModel user, bool isDark) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (!user.accountAvailable) {
      statusColor = TAdminColors.banned;
      statusText = 'Banned';
      statusIcon = Iconsax.user_remove_bold;
    } else if (user.isVerify) {
      statusColor = TAdminColors.success;
      statusText = 'Verified';
      statusIcon = Iconsax.shield_tick_bold;
    } else {
      statusColor = TAdminColors.warning;
      statusText = 'Pending';
      statusIcon = Iconsax.shield_tick_bold;
    }

    return Align(  // 用来脱离父级的宽度约束，不跟着整行的 cell 撑开
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

  Widget _buildActionButtons(UserModel user, UserManagementController controller, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: (user.accountAvailable == true) ? MainAxisAlignment.spaceAround : MainAxisAlignment.start,
      children: [
        // Detail Button
        IconButton(
          onPressed: () => _showUserDetailDialog(user, isDark),
          icon: const Icon(Iconsax.eye_bold, size: 16),
          tooltip: 'View Details',
          style: IconButton.styleFrom(
            backgroundColor: TAdminColors.info.withOpacity(0.1),
            foregroundColor: TAdminColors.info,
            minimumSize: const Size(32, 32),
          ),
        ),
        const SizedBox(width: 4),
        if (user.accountAvailable) ...[
          // Edit Button (only for active users)
          IconButton(
            onPressed: () => controller.editUser(user),
            icon: const Icon(Iconsax.edit_bold, size: 16),
            tooltip: 'Edit User',
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
              ConfirmationDialog.showBanUser(
                user.username,
                () => controller.banUser(user),
              );
            },
            icon: const Icon(Iconsax.user_remove_bold, size: 16),
            tooltip: 'Ban User',
            style: IconButton.styleFrom(
              backgroundColor: TAdminColors.error.withOpacity(0.1),
              foregroundColor: TAdminColors.error,
              minimumSize: const Size(32, 32),
            ),
          ),
        ] else ...[
          // Restore Button (only for banned users)
          IconButton(
            onPressed: () {
              ConfirmationDialog.showRestoreUser(
                user.username,
                () => controller.restoreUser(user),
              );
            },
            icon: const Icon(Iconsax.refresh_bold, size: 16),
            tooltip: 'Restore User',
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

  void _showUserDetailDialog(UserModel user, bool isDark) {
    Get.dialog(UserDetailDialog(user: user));
  }
}