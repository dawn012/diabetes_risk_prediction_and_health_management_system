import 'package:flutter/material.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';

class SectionCardWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool darkMode;

  const SectionCardWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: darkMode ? TColors.black : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: darkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(TSizes.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(TSizes.sm),
                  decoration: BoxDecoration(
                    color: TColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: TColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: TSizes.sm),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: darkMode ? TColors.white : TColors.dark,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}