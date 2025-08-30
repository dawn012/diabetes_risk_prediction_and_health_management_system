import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../common/widgets/dialogs/common_confirmation_dialog.dart';
import '../../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../../utils/constants/admin_colors.dart';
import '../../../../../utils/helpers/helper_functions.dart';
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

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    itemCount: controller.menuItems.length,
                    itemBuilder: (context, index) {
                      final item = controller.menuItems[index];
                      return _buildMenuItem(
                        context: context,
                        icon: _getIconData(item['icon']),
                        title: item['title'],
                        index: item['index'],
                        isSelected:
                            controller.selectedIndex.value == item['index'],
                        isDark: darkMode,
                        isExpanded: controller.sidebarExpanded.value,
                        onTap: () => controller.selectMenuItem(item['index']),
                      );
                    },
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
                                    AuthenticationRepository
                                            .instance.authUser?.displayName ??
                                        'Admin',
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
                                onConfirm: () {
                                  AuthenticationRepository.instance.logout();
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

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'dashboard':
        return Iconsax.element_3_bold;
      case 'user_management':
        return Iconsax.people_bold;
      case 'community':
        return Iconsax.messages_3_bold;
      case 'achievement':
        return Iconsax.award_bold;
      case 'analytics':
        return Iconsax.chart_bold;
      case 'settings':
        return Iconsax.setting_bold;
      default:
        return Iconsax.element_3_bold;
    }
  }
}
