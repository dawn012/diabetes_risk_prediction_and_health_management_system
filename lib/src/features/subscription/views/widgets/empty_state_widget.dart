import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool darkMode;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: darkMode ? TColors.darkGrey : TColors.grey,
          ),
          const SizedBox(height: TSizes.md),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: darkMode ? TColors.white : TColors.dark,
            ),
          ),
          const SizedBox(height: TSizes.sm),
          Text(
            subtitle,
            style: TextStyle(
              color: darkMode ? TColors.darkGrey : TColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
