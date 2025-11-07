import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';

class FilterChipsWidget extends StatelessWidget {
  const FilterChipsWidget({
    super.key,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.getFilterLabel,
    this.spaceBetweenChips = 0,
  });

  final List<String> filters;
  final RxString selectedFilter;
  final Function(String) onFilterSelected;
  final String Function(String) getFilterLabel;
  final double spaceBetweenChips;

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        // color: isDark ? TColors.darkContainer : TColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? TColors.borderPrimary.withOpacity(0.3)
                : TColors.borderPrimary.withOpacity(0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Center(
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: TSizes.md),
          itemCount: filters.length,
          itemBuilder: (context, index) {
            return Obx(() {
              final filterType = filters[index];
              final isSelected = selectedFilter.value == filterType;

              return Container(
                margin: EdgeInsets.only(
                  right: index == filters.length - 1 ? 0 :
                  (spaceBetweenChips > 0 ? spaceBetweenChips : TSizes.sm),
                ),
                child: FilterChip(
                  label: Text(
                    getFilterLabel(filterType),
                    style: TextStyle(
                      color: isSelected
                          ? TColors.white
                          : (isDark ? TColors.lightGrey : TColors.textPrimary),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    onFilterSelected(filterType);
                  },
                  backgroundColor: isDark
                      ? TColors.darkGrey.withOpacity(0.3)
                      : TColors.lightGrey,
                  selectedColor: TColors.primary,
                  showCheckmark: false,
                  checkmarkColor: Colors.transparent,
                  side: BorderSide(
                    color: isSelected
                        ? TColors.primary
                        : (isDark
                        ? TColors.borderPrimary.withOpacity(0.3)
                        : TColors.borderPrimary),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              );
            });
          },
        ),
      ),
    );
  }
}