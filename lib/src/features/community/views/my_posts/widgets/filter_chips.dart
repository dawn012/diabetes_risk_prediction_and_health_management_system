import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/my_post_controller.dart';

class MyPostsFilterChips extends StatelessWidget {
  const MyPostsFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = MyPostController.instance;
    final darkMode = THelperFunctions.isDarkMode(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Post Type Filter
        Text(
          'Post Type',
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: TSizes.xs),
        Obx(() {
          return Wrap(
            spacing: TSizes.sm,
            runSpacing: TSizes.xs,
            children: controller.postTypeFilters.map((type) {
              final isSelected = controller.selectedPostType.value == type;
              return FilterChip(
                label: Text(controller.getPostTypeLabel(type)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    controller.filterByPostType(type);
                  }
                },
                backgroundColor: darkMode
                    ? TColors.chipBackgroundDark
                    : TColors.chipBackground,
                selectedColor: TColors.chipSelected.withOpacity(0.2),
                checkmarkColor: TColors.chipSelected,
                labelStyle: TextStyle(
                  color: isSelected
                      ? TColors.chipSelected
                      : (darkMode ? TColors.white : TColors.black),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected
                      ? TColors.chipSelected
                      : (darkMode ? TColors.darkGrey : TColors.grey),
                  width: 1,
                ),
              );
            }).toList(),
          );
        }),

        SizedBox(height: TSizes.md),

        // Status Filter
        Text(
          'Post Status',
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: TSizes.xs),
        Obx(() {
          return Wrap(
            spacing: TSizes.sm,
            runSpacing: TSizes.xs,
            children: controller.statusFilters.map((status) {
              final isSelected = controller.selectedStatus.value == status;
              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status != 'all') ...[
                      Icon(
                        status == 'active'
                            ? Icons.check_circle
                            : Icons.block,
                        size: 16,
                        color: isSelected
                            ? TColors.chipSelected
                            : (status == 'active'
                            ? TColors.success
                            : TColors.postDisabled),
                      ),
                      SizedBox(width: 4),
                    ],
                    Text(controller.getStatusLabel(status)),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    controller.filterByStatus(status);
                  }
                },
                backgroundColor: darkMode
                    ? TColors.chipBackgroundDark
                    : TColors.chipBackground,
                selectedColor: TColors.chipSelected.withOpacity(0.2),
                checkmarkColor: TColors.chipSelected,
                labelStyle: TextStyle(
                  color: isSelected
                      ? TColors.chipSelected
                      : (darkMode ? TColors.white : TColors.black),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected
                      ? TColors.chipSelected
                      : (darkMode ? TColors.darkGrey : TColors.grey),
                  width: 1,
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }
}