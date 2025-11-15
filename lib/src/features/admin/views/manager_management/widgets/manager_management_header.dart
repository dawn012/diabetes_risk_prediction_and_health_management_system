import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../utils/constants/admin_colors.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/manager_management_controller.dart';

class ManagerManagementHeader extends StatelessWidget {
  final ManagerManagementController controller;

  const ManagerManagementHeader({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return Column(children: [
      Row(
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
                      'Manager Management',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: TAdminColors.getOnSurfaceColor(darkMode),
                      ),
                    ),
                    SizedBox(width: 16),
                    Obx(() => Container(
                      padding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: TAdminColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: TAdminColors.primary.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${controller.filteredManagers.length} ${controller.showingActiveManagers.value ? 'Active' : 'Banned'}',
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
                  'Manage system administrators and managers',
                  style: TextStyle(
                    fontSize: 16,
                    color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 24),

          // Actions
          Row(
            children: [
              // Add Manager Button (left of search)
              ElevatedButton.icon(
                onPressed: controller.openAddManagerDialog,
                icon: Icon(Iconsax.user_add_bold, size: 20),
                label: Text('Add Manager'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TAdminColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),

              SizedBox(width: 16),

              // Search bar
              Container(
                width: 320,
                child: TextField(
                  controller: controller.searchController,
                  decoration: InputDecoration(
                    hintText: 'Search managers by name, email, or role...',
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
                            color: TAdminColors.getOnSurfaceVariantColor(
                                darkMode),
                            size: 20,
                          ),
                          onPressed: () {
                            controller.searchController.clear();
                            controller.filterManagers();
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
                      borderSide:
                      BorderSide(color: TAdminColors.primary, width: 2),
                    ),
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  onPressed: controller.refreshManagers,
                  icon: Obx(() => AnimatedRotation(
                    turns: controller.isLoading.value ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 1000),
                    child: Icon(
                      Iconsax.refresh_bold,
                      color:
                      TAdminColors.getOnSurfaceVariantColor(darkMode),
                      size: 20,
                    ),
                  )),
                  tooltip: 'Refresh managers',
                  style: IconButton.styleFrom(
                    minimumSize: Size(48, 48),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      SizedBox(height: 24),

      // Filter controls
      Row(
        children: [
          // Manager status tabs
          _buildManagerTypeTabs(controller, darkMode),

          const Spacer(),

          // Entries per page
          Row(
            children: [
              Text(
                'Show',
                style: TextStyle(
                  color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 48,
                child: Obx(() => DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: controller.itemsPerPage.value,
                    onChanged: controller.changeItemsPerPage,
                    items: controller.itemsPerPageOptions
                        .map((items) => DropdownMenuItem(
                      value: items,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Text(
                          '$items',
                          style: TextStyle(
                            color: TAdminColors.getOnSurfaceColor(
                                darkMode),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ))
                        .toList(),
                    style: TextStyle(
                      color: TAdminColors.getOnSurfaceColor(darkMode),
                    ),
                    dropdownColor: TAdminColors.getSurfaceColor(darkMode),
                    borderRadius: BorderRadius.circular(8),
                    icon: Icon(
                      Iconsax.arrow_down_1_bold,
                      color:
                      TAdminColors.getOnSurfaceVariantColor(darkMode),
                    ),
                  ),
                )),
              ),
              const SizedBox(width: 8),
              Text(
                'entries',
                style: TextStyle(
                  color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    ]);
  }

  Widget _buildManagerTypeTabs(ManagerManagementController controller, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceVariantColor(isDark),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() => _buildTabButton(
            'Active Managers',
            controller.showingActiveManagers.value,
                () => controller.showActiveManagers(),
            isDark,
          )),
          const SizedBox(width: 4),
          Obx(() => _buildTabButton(
            'Banned Managers',
            !controller.showingActiveManagers.value,
                () => controller.showBannedManagers(),
            isDark,
          )),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, bool isSelected, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? TAdminColors.getSurfaceColor(isDark) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? TAdminColors.getOnSurfaceColor(isDark)
                : TAdminColors.getOnSurfaceVariantColor(isDark),
          ),
        ),
      ),
    );
  }
}