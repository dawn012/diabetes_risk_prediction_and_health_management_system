import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';

class DetailRowWidget extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool darkMode;
  final bool copyable;
  final Color? valueColor;
  final VoidCallback? onCopy;

  const DetailRowWidget({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.darkMode,
    this.copyable = false,
    this.valueColor,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TSizes.md,
        vertical: TSizes.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: TColors.primary.withOpacity(0.7), size: 18),
          const SizedBox(width: TSizes.sm),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: darkMode ? TColors.grey : TColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: valueColor ??
                          (darkMode ? TColors.white : TColors.dark),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
                if (copyable && onCopy != null) ...[
                  const SizedBox(width: TSizes.xs),
                  GestureDetector(
                    onTap: onCopy,
                    child: Icon(
                      Iconsax.copy_bold,
                      color: TColors.primary,
                      size: 16,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}