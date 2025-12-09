import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../../common/loaders/loaders.dart';
import '../../../../common/widgets/dialogs/common_confirmation_dialog.dart';
import '../../../../common/widgets/dialogs/image_preview_dialog.dart';
import '../../../../common/widgets/pagination/pagination_widget.dart';
import '../../../../common/widgets/table/reusable_data_table.dart';
import '../../../../utils/constants/admin_colors.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../authentication/models/user_model.dart';
import '../../controllers/user_management_controller.dart';
import 'user_detail_dialog.dart';
import 'widgets/batch_action_bar.dart';
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
                          ? BatchActionsBar(
                        selectedItems: controller.selectedUsers,
                        showingActive: (controller.selectedTabIndex.value == 0).obs,
                        onClearSelection: () => controller.toggleSelectAll(false),
                        onBatchBan: () => controller.batchBanUsers(),
                        onBatchRestore: () => controller.batchRestoreUsers(),
                        itemLabel: 'user',
                        getUserName: (user) => user.username,
                        getUserEmail: (user) => user.email,
                      )
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
        builder: (user) => _buildProfileAvatar(user, darkMode),
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
          final phoneText = user.formattedPhoneNo.isNotEmpty ? user.formattedPhoneNo : 'Not provided';

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
        minWidth: 100,
        flex: 3,
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

  Widget _buildProfileAvatar(UserModel user, bool isDark) {
    Widget avatarWidget;

    if (user.profileImg.isNotEmpty) {
      avatarWidget = CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(user.profileImg),
        backgroundColor: TAdminColors.primary.withOpacity(0.1),
      );
    } else {
      avatarWidget = CircleAvatar(
        radius: 20,
        backgroundColor: TAdminColors.primary.withOpacity(0.2),
        child: Icon(
          Iconsax.user_bold,
          size: 16,
          color: TAdminColors.primary,
        ),
      );
    }

    // 添加点击事件
    return GestureDetector(
      onTap: () {
        if (user.profileImg.isNotEmpty) {
          // 使用网络图片预览
          ImagePreviewDialog.showNetworkImage(
            context: Get.context!,
            imageUrl: user.profileImg,
            title: '${user.username}\'s Avatar',
            maxWidth: 400,
            maxHeight: 400,
          );
        } else {
          // 如果没有头像图片，显示一个提示
          TLoaders.modernSnackBar(
            title: 'No Profile Image',
            message: '${user.username} doesn\'t have a profile image',
          );
        }
      },
      child: avatarWidget,
    );
  }

  Widget _buildStatusChip(UserModel user, bool isDark) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (!user.accountAvailable) {
      statusColor = TAdminColors.banned;
      statusText = 'Banned';
      statusIcon = Iconsax.user_remove_bold;
    } else if (user.isDeleted) {
      statusColor = TAdminColors.offline;
      statusText = 'Inactive';
      statusIcon = Iconsax.slash_bold;
    } else if (user.isVerify) {
      statusColor = TAdminColors.success;
      statusText = 'Verified';
      statusIcon = Iconsax.shield_tick_bold;
    } else {
      statusColor = TAdminColors.error;
      statusText = 'Not verified';
      statusIcon = Iconsax.shield_cross_bold;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 100),
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

  Widget _buildActionButtons(UserModel user, UserManagementController controller, bool isDark) {
    // For inactive (deleted by user) users
    if (user.isDeleted) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Detail Button
          IconButton(
            onPressed: () => _showUserDetailDialog(user, controller, isDark),
            icon: const Icon(Iconsax.eye_bold, size: 16),
            tooltip: 'View Details',
            style: IconButton.styleFrom(
              backgroundColor: TAdminColors.info.withOpacity(0.1),
              foregroundColor: TAdminColors.info,
              minimumSize: const Size(32, 32),
            ),
          ),
          const SizedBox(width: 4),
          // Restore Button
          IconButton(
            onPressed: () {
              ConfirmationDialog.show(
                title: 'Restore User',
                message: 'Are you sure you want to restore ${user.username}? This will reactivate their account.',
                confirmButtonText: 'Restore User',
                customIcon: Iconsax.refresh_bold,
                iconColor: TAdminColors.success,
                confirmButtonColor: TAdminColors.success,
                onConfirm: () => controller.restoreUser(user),
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
      );
    }

    // For active users
    if (user.accountAvailable) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Detail Button
          IconButton(
            onPressed: () => _showUserDetailDialog(user, controller, isDark),
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
            onPressed: () => controller.openEditUserDialog(user),
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
        ],
      );
    }

    // For banned users
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Detail Button
        IconButton(
          onPressed: () => _showUserDetailDialog(user, controller, isDark),
          icon: const Icon(Iconsax.eye_bold, size: 16),
          tooltip: 'View Details',
          style: IconButton.styleFrom(
            backgroundColor: TAdminColors.info.withOpacity(0.1),
            foregroundColor: TAdminColors.info,
            minimumSize: const Size(32, 32),
          ),
        ),
        const SizedBox(width: 4),
        // Restore Button
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
    );
  }

  void _showUserDetailDialog(UserModel user, UserManagementController controller, bool isDark) {
    final isPremium = controller.isActiveSync(user.userId);

    Get.dialog(UserDetailDialog(user: user, isPremium: isPremium,));
  }
}