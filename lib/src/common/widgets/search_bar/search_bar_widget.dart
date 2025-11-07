import 'package:flutter/material.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.hintText = 'Search...',
    this.hasText = false,
  });

  final TextEditingController controller;
  final Function(String) onChanged;
  final VoidCallback onClear;
  final String hintText;
  final bool hasText;

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: TSizes.md,
        vertical: TSizes.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkGrey.withOpacity(0.3) : TColors.lightGrey,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isDark
              ? TColors.borderPrimary.withOpacity(0.2)
              : TColors.borderPrimary.withOpacity(0.4),
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          color: isDark ? TColors.white : TColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: isDark ? TColors.darkGrey : TColors.textSecondary,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? TColors.darkGrey : TColors.textSecondary,
            size: 22,
          ),
          suffixIcon: hasText
              ? IconButton(
            icon: Icon(
              Icons.clear,
              color: isDark ? TColors.darkGrey : TColors.textSecondary,
              size: 20,
            ),
            onPressed: onClear,
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}