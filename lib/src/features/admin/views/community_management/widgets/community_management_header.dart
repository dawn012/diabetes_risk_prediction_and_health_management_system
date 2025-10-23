import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../utils/constants/admin_colors.dart';
import '../../../../../utils/constants/enums.dart'; // 导入枚举
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/community_management_controller.dart';

class CommunityManagementHeader extends StatelessWidget {
  final CommunityManagementController controller;

  const CommunityManagementHeader({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return Column(
      children: [
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
                        'Community Management',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: TAdminColors.getOnSurfaceColor(darkMode),
                        ),
                      ),
                      SizedBox(width: 16),
                      Obx(() => Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: TAdminColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: TAdminColors.primary.withOpacity(0.3)),
                        ),
                        child: Text(
                          '${controller.filteredPosts.length} ${controller.showingActivePosts.value ? 'Active' : 'Disabled'}',
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
                    'Review and moderate community posts, manage content visibility',
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
                      hintText: 'Search posts by content, poster, or ID...',
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
                              color:
                              TAdminColors.getOnSurfaceVariantColor(
                                  darkMode),
                              size: 20,
                            ),
                            onPressed: () {
                              controller.searchController.clear();
                              controller.filterPosts();
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
                    onPressed: controller.refreshPosts,
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
                    tooltip: 'Refresh posts',
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
            // Post status tabs
            Container(
              decoration: BoxDecoration(
                color: TAdminColors.getSurfaceVariantColor(darkMode),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() => _buildTabButton(
                    'Active Posts',
                    controller.showingActivePosts.value,
                        () => controller.showActivePosts(),
                    darkMode,
                  )),
                  SizedBox(width: 4),
                  Obx(() => _buildTabButton(
                    'Disabled Posts',
                    !controller.showingActivePosts.value,
                        () => controller.showDisabledPosts(),
                    darkMode,
                  )),
                ],
              ),
            ),

            SizedBox(width: 16),

            // Type filter dropdown
            Container(
              height: 48, // Same height as status buttons
              child: Obx(() => _buildTypeFilter(darkMode)),
            ),

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
                  height: 48, // Same height as other controls
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
      ],
    );
  }

  Widget _buildTabButton(
      String text, bool isSelected, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? TAdminColors.getSurfaceColor(isDark)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color:
              isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ]
              : null,
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

  Widget _buildTypeFilter(bool darkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceVariantColor(darkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: TAdminColors.getBorderColor(darkMode),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PostType?>(
          value: controller.selectedPostType.value,
          onChanged: (value) => controller.changePostTypeFilter(value),
          items: [
            // All types option
            DropdownMenuItem<PostType?>(
              value: null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Iconsax.element_4_bold,
                    size: 16,
                    color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'All Types',
                    style: TextStyle(
                      color: TAdminColors.getOnSurfaceColor(darkMode),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 8),
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: TAdminColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${controller.allPosts.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: TAdminColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Individual post types
            ...PostType.values.map((type) {
              IconData icon;
              Color iconColor;

              switch (type) {
                case PostType.general:
                  icon = Iconsax.messages_1_bold;
                  iconColor = TAdminColors.info;
                  break;
                case PostType.tips:
                  icon = Iconsax.lamp_bold;
                  iconColor = TAdminColors.warning;
                  break;
                case PostType.recipe:
                  icon = Iconsax.cake_bold;
                  iconColor = TAdminColors.success;
                  break;
                case PostType.story:
                  icon = Iconsax.book_1_bold;
                  iconColor = TAdminColors.secondary;
                  break;
              }

              final count = controller.allPosts
                  .where((post) => post.postType == type)
                  .length;

              return DropdownMenuItem<PostType?>(
                value: type,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: iconColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      type.displayName,
                      style: TextStyle(
                        color: TAdminColors.getOnSurfaceColor(darkMode),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 8),
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
          style: TextStyle(
            color: TAdminColors.getOnSurfaceColor(darkMode),
          ),
          dropdownColor: TAdminColors.getSurfaceColor(darkMode),
          borderRadius: BorderRadius.circular(8),
          icon: Icon(
            Iconsax.arrow_down_1_bold,
            color: TAdminColors.getOnSurfaceVariantColor(darkMode),
          ),
        ),
      ),
    );
  }
}