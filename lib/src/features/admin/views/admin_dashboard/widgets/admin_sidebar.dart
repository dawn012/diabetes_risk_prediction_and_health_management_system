import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../common/widgets/dialogs/common_confirmation_dialog.dart';
import '../../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../../utils/constants/admin_colors.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../../personalization/controllers/user_controller.dart';
import '../../../controllers/admin_dashboard_controller.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminDashboardController>();
    final darkMode = THelperFunctions.isDarkMode(context);

    return Obx(() => AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: controller.sidebarExpanded.value ? 280 : 87,
      height: double.infinity,
      decoration: BoxDecoration(
          color: TAdminColors.getSurfaceColor(darkMode),
          border: Border(
            right: BorderSide(
              color: TAdminColors.getBorderColor(darkMode),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color:
              darkMode ? Colors.black26 : Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(2, 0),
            )
          ]),
      child: Column(
        children: [
          // Logo / Header
          Container(
            height: 80,
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: TAdminColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Iconsax.shield_tick_bold,
                    color: TAdminColors.white,
                    size: 24,
                  ),
                ),
                if (controller.sidebarExpanded.value) ...[
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Admin Panel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: TAdminColors.getOnSurfaceColor(darkMode),
                          ),
                        ),
                        Obx(() => Text(
                          controller.currentUserRole.capitalizeFirst ??
                              'Loading...',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                            TAdminColors.getOnSurfaceVariantColor(
                                darkMode),
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Collapse button
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: controller.toggleSidebar,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: controller.sidebarExpanded.value
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.center,
                    children: [
                      AnimatedRotation(
                        turns: controller.sidebarExpanded.value ? 0.5 : 0,
                        duration: Duration(milliseconds: 300),
                        child: Icon(
                          Iconsax.arrow_left_2_bold,
                          color: TAdminColors.getOnSurfaceVariantColor(
                              darkMode),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Divider(color: TAdminColors.getBorderColor(darkMode)),

          // Menu Items
          Expanded(
            child: Obx(() {
              print('Obx rebuilding: ${controller.selectedIndex.value}');
              print('User role: ${controller.userRole.value}');

              return ListView(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                children: [
                  // Dashboard - 所有角色都有
                  _buildMenuItem(
                    context: context,
                    icon: Iconsax.element_3_bold,
                    title: 'Dashboard',
                    index: 0,
                    isSelected: controller.selectedIndex.value == 0,
                    isDark: darkMode,
                    isExpanded: controller.sidebarExpanded.value,
                    onTap: () => controller.selectMenuItem(0),
                  ),

                  // User Management - 只有 admin 和 user manager 能看到
                  if (controller.canAccessUserManagement())
                    _buildMenuItem(
                      context: context,
                      icon: Iconsax.people_bold,
                      title: 'User Management',
                      index: 1,
                      isSelected: controller.selectedIndex.value == 1,
                      isDark: darkMode,
                      isExpanded: controller.sidebarExpanded.value,
                      onTap: () => controller.selectMenuItem(1),
                    ),

                  // Manager Management - 只有 admin 能看到
                  if (controller.isAdmin)
                    _buildMenuItem(
                      context: context,
                      icon: Iconsax.people_bold,
                      title: 'Manager Management',
                      index: 2,
                      isSelected: controller.selectedIndex.value == 2,
                      isDark: darkMode,
                      isExpanded: controller.sidebarExpanded.value,
                      onTap: () => controller.selectMenuItem(2),
                    ),

                  // Community - 只有 admin 和 community manager 能看到
                  if (controller.canAccessCommunityManagement())
                    _buildMenuItem(
                      context: context,
                      icon: Iconsax.messages_3_bold,
                      title: 'Community',
                      index: 3,
                      isSelected: controller.selectedIndex.value == 3,
                      isDark: darkMode,
                      isExpanded: controller.sidebarExpanded.value,
                      onTap: () => controller.selectMenuItem(3),
                    ),

                  // Achievement - 只有 admin 和 achievement manager 能看到
                  if (controller.canAccessAchievementManagement())
                    _buildMenuItem(
                      context: context,
                      icon: Iconsax.award_bold,
                      title: 'Achievement',
                      index: 4,
                      isSelected: controller.selectedIndex.value == 4,
                      isDark: darkMode,
                      isExpanded: controller.sidebarExpanded.value,
                      onTap: () => controller.selectMenuItem(4),
                    ),

                  // Analytics (Expandable) - 所有角色都有，但内容不同
                  if (controller.canAccessUserAnalytics() || controller.isAdmin)
                    _buildExpandableMenuItem(
                      context: context,
                      icon: Iconsax.chart_bold,
                      title: 'Analytics',
                      isDark: darkMode,
                      isExpanded: controller.sidebarExpanded.value,
                      isMenuExpanded: controller.analyticsExpanded.value,
                      onToggle: () => controller.toggleAnalyticsMenu(),
                      children: [
                        // Transaction Reports - 只有 admin 能看到
                        if (controller.canAccessTransactionReports())
                          _buildSubMenuItem(
                            context: context,
                            icon: Iconsax.receipt_text_bold,
                            title: 'Transaction Reports',
                            index: 51,
                            isSelected: controller.selectedIndex.value == 51,
                            isDark: darkMode,
                            isExpanded: controller.sidebarExpanded.value,
                            onTap: () => controller.selectMenuItem(51),
                          ),

                        // User Analytics - admin 和 user manager 能看到
                        if (controller.canAccessUserAnalytics())
                          _buildSubMenuItem(
                            context: context,
                            icon: Iconsax.people_bold,
                            title: 'User Analytics',
                            index: 52,
                            isSelected: controller.selectedIndex.value == 52,
                            isDark: darkMode,
                            isExpanded: controller.sidebarExpanded.value,
                            onTap: () => controller.selectMenuItem(52),
                          ),

                        // // Performance Reports - 只有 admin 能看到
                        // if (controller.canAccessPerformanceReports())
                        //   _buildSubMenuItem(
                        //     context: context,
                        //     icon: Iconsax.trend_up_bold,
                        //     title: 'Performance Reports',
                        //     index: 53,
                        //     isSelected: controller.selectedIndex.value == 53,
                        //     isDark: darkMode,
                        //     isExpanded: controller.sidebarExpanded.value,
                        //     onTap: () => controller.selectMenuItem(53),
                        //   ),
                      ],
                    ),

                  // Profile - 所有角色都有
                  _buildMenuItem(
                    context: context,
                    icon: Iconsax.user_bold,
                    title: 'Profile',
                    index: 6,
                    isSelected: controller.selectedIndex.value == 6,
                    isDark: darkMode,
                    isExpanded: controller.sidebarExpanded.value,
                    onTap: () => controller.selectMenuItem(6),
                  ),
                ],
              );
            }),
          ),

          if (!controller.sidebarExpanded.value) ...[
            Divider(color: TAdminColors.getBorderColor(darkMode)),

            // Compact logout button
            Padding(
              padding: EdgeInsets.all(16),
              child: IconButton(
                onPressed: () {
                  ConfirmationDialog.showLogout(
                      onConfirm: () {
                        AuthenticationRepository.instance.logout();
                      }
                  );
                },
                icon: Icon(
                  Iconsax.logout_1_bold,
                  color: TAdminColors.error,
                ),
                tooltip: 'Logout',
                style: IconButton.styleFrom(
                  backgroundColor: TAdminColors.error.withOpacity(0.1),
                  side: BorderSide(color: TAdminColors.error),
                  minimumSize: Size(48, 48),
                ),
              ),
            ),
          ],

          if (controller.sidebarExpanded.value) ...[
            Divider(color: TAdminColors.getBorderColor(darkMode)),

            // User Profile & Logout (Expanded)
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Section
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: TAdminColors.getSurfaceVariantColor(darkMode),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: TAdminColors.primary,
                          child: Icon(
                            Iconsax.user_bold,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                UserController.instance.user.value.username,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: TAdminColors.getOnSurfaceColor(
                                      darkMode),
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Online',
                                style: TextStyle(
                                  color: TAdminColors.success,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ConfirmationDialog.showLogout(
                            onConfirm: () async {
                              await AuthenticationRepository.instance.logout();
                            }
                        );
                      },
                      icon: Icon(
                        Iconsax.logout_1_bold,
                        size: 18,
                        color: TAdminColors.error,
                      ),
                      label: Text(
                        'Logout',
                        style: TextStyle(color: TAdminColors.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        side: BorderSide(color: TAdminColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ));
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required int index,
    required bool isSelected,
    required bool isDark,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? TAdminColors.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: TAdminColors.primary.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? TAdminColors.primary
                      : TAdminColors.getOnSurfaceVariantColor(isDark),
                ),
                if (isExpanded) ...[
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? TAdminColors.primary
                            : TAdminColors.getOnSurfaceColor(isDark),
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: TAdminColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool isDark,
    required bool isExpanded,
    required bool isMenuExpanded,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    final hasSelectedChild = Get.find<AdminDashboardController>().selectedIndex.value >= 40 &&
        Get.find<AdminDashboardController>().selectedIndex.value < 50;

    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(vertical: 2),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isExpanded ? onToggle : null,
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: hasSelectedChild || isMenuExpanded
                      ? TAdminColors.primary.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: hasSelectedChild || isMenuExpanded
                      ? Border.all(color: TAdminColors.primary.withOpacity(0.3))
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: hasSelectedChild || isMenuExpanded
                          ? TAdminColors.primary
                          : TAdminColors.getOnSurfaceVariantColor(isDark),
                    ),
                    if (isExpanded) ...[
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: hasSelectedChild || isMenuExpanded
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: hasSelectedChild || isMenuExpanded
                                ? TAdminColors.primary
                                : TAdminColors.getOnSurfaceColor(isDark),
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: isMenuExpanded ? 0.5 : 0,
                        duration: Duration(milliseconds: 300),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 20,
                          color: hasSelectedChild || isMenuExpanded
                              ? TAdminColors.primary
                              : TAdminColors.getOnSurfaceVariantColor(isDark),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),

        // Submenu items
        if (isExpanded)
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            height: isMenuExpanded ? children.length * 48.0 : 0,
            child: ClipRect(
              child: Column(
                children: children,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required int index,
    required bool isSelected,
    required bool isDark,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.only(left: 48, right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? TAdminColors.primary.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected
                      ? TAdminColors.primary
                      : TAdminColors.getOnSurfaceVariantColor(isDark),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? TAdminColors.primary
                          : TAdminColors.getOnSurfaceColor(isDark),
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: TAdminColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}