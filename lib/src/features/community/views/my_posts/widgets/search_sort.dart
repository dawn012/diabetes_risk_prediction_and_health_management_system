import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/my_post_controller.dart';

class MyPostsSearchSort extends StatelessWidget {
  const MyPostsSearchSort({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = MyPostController.instance;
    final darkMode = THelperFunctions.isDarkMode(context);

    return Column(
      children: [
        // Search Bar
        Container(
          decoration: BoxDecoration(
            color: darkMode
                ? TColors.searchBarBackgroundDark
                : TColors.searchBarBackground,
            borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
            border: Border.all(
              color: darkMode ? TColors.darkGrey : TColors.grey,
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller.searchController,
            onChanged: (value) {
              // Debounce search
              Future.delayed(Duration(milliseconds: 500), () {
                if (controller.searchController.text == value) {
                  controller.performSearch(value);
                }
              });
            },
            decoration: InputDecoration(
              hintText: 'Search your posts...',
              hintStyle: TextStyle(
                color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
              ),
              prefixIcon: Icon(
                Iconsax.search_normal_bold,
                color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
              ),
              suffixIcon: Obx(() {
                return controller.searchQuery.value.isNotEmpty
                    ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                  ),
                  onPressed: controller.clearSearch,
                )
                    : SizedBox.shrink();
              }),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: TSizes.md,
                vertical: TSizes.sm,
              ),
            ),
          ),
        ),

        SizedBox(height: TSizes.md),

        // Sort and Filter Row
        Row(
          children: [
            // Sort Dropdown
            Expanded(
              child: Obx(() {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: TSizes.sm),
                  decoration: BoxDecoration(
                    color: darkMode ? TColors.dark : TColors.white,
                    borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
                    border: Border.all(
                      color: darkMode ? TColors.darkGrey : TColors.grey,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: controller.sortBy.value,
                      icon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            controller.sortDescending.value
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            size: 16,
                            color: TColors.primary,
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_drop_down),
                        ],
                      ),
                      isExpanded: true,
                      items: controller.sortOptions.map((option) {
                        return DropdownMenuItem<String>(
                          value: option['value'] as String,
                          child: Row(
                            children: [
                              Icon(
                                _getSortIcon(option['value'] as String),
                                size: 18,
                                color: TColors.primary,
                              ),
                              SizedBox(width: TSizes.sm),
                              Text(
                                option['label'] as String,
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          controller.updateSortBy(value);
                        }
                      },
                    ),
                  ),
                );
              }),
            ),

            SizedBox(width: TSizes.sm),

            // Reset Filters Button
            Container(
              decoration: BoxDecoration(
                color: darkMode ? TColors.dark : TColors.white,
                borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
                border: Border.all(
                  color: darkMode ? TColors.darkGrey : TColors.grey,
                ),
              ),
              child: IconButton(
                icon: Icon(
                  Iconsax.refresh_bold,
                  color: TColors.primary,
                ),
                onPressed: controller.resetFilters,
                tooltip: 'Reset Filters',
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getSortIcon(String sortBy) {
    switch (sortBy) {
      case 'createdAt':
        return Icons.calendar_today;
      case 'updatedAt':
        return Icons.update;
      case 'likes':
        return Icons.favorite;
      case 'commentCount':
        return Icons.comment;
      default:
        return Icons.sort;
    }
  }
}