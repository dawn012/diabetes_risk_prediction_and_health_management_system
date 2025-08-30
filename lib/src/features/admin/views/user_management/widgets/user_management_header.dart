import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../utils/constants/admin_colors.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/user_management_controller.dart';

class UserManagementHeader extends StatelessWidget {
  final UserManagementController controller;

  const UserManagementHeader({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and description
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'User Management',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: TAdminColors.getOnSurfaceColor(darkMode),
                    ),
                  ),
                  SizedBox(width: 16),
                  Obx(() => Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: TAdminColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: TAdminColors.primary.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${controller.filteredUsers.length} ${controller.showingActiveUsers.value ? 'Active' : 'Banned'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: TAdminColors.primary,
                      ),
                    ),
                  )),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Manage user accounts, permissions, and view user activities',
                style: TextStyle(
                  fontSize: 16,
                  color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                ),
              ),
            ],
          ),
        ),

        SizedBox(width: 24),

        // Search and actions
        Row(
          children: [
            // Search bar
            Container(
              width: 320,
              child: TextField(
                controller: controller.searchController,
                decoration: InputDecoration(
                  hintText: 'Search users by name, email, or ID...',
                  hintStyle: TextStyle(
                    color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                  ),
                  prefixIcon: Icon(
                    Iconsax.search_normal_1_bold,
                    color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                    size: 20,
                  ),
                  suffixIcon: ValueListenableBuilder(
                    valueListenable: controller.searchController,
                    builder: (context, value, child) {
                      return value.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(
                          Iconsax.close_circle_bold,
                          color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                          size: 20,
                        ),
                        onPressed: () {
                          controller.searchController.clear();
                          controller.filterUsers();
                        },
                      )
                          : const SizedBox.shrink();
                    },
                  ),
                  filled: true,
                  fillColor: TAdminColors.getSurfaceVariantColor(darkMode),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: TAdminColors.primary, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: TextStyle(
                  color: TAdminColors.getOnSurfaceColor(darkMode),
                ),
              ),
            ),

            SizedBox(width: 16),

            // Refresh button
            Container(
              decoration: BoxDecoration(
                color: TAdminColors.getSurfaceVariantColor(darkMode),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: TAdminColors.getBorderColor(darkMode),
                ),
              ),
              child: IconButton(
                onPressed: controller.refreshUsers,
                icon: Obx(() => AnimatedRotation(
                  turns: controller.isLoading.value ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 1000),
                  child: Icon(
                    Iconsax.refresh_bold,
                    color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                    size: 20,
                  ),
                )),
                tooltip: 'Refresh users',
                style: IconButton.styleFrom(
                  minimumSize: Size(48, 48),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}