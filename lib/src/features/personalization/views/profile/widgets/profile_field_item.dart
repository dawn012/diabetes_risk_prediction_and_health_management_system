import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/colors.dart';

class ProfileFieldItem extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final IconData? icon;
  final VoidCallback? onInfoTap;
  final int maxLines;

  const ProfileFieldItem({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.icon,
    this.onInfoTap,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: TSizes.spaceBtwItems / 1.5,
          horizontal: TSizes.xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title (Label) with info icon
            Expanded(
              flex: 3,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                  if (icon != null && onInfoTap != null) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: onInfoTap,
                      child: Icon(
                        icon,
                        size: 14,
                        color: TColors.info,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: TSizes.sm),

            // Value with subtitle
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                    maxLines: maxLines,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: TColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: TSizes.sm),

            // Trailing (arrow or locked badge) - Fixed width for alignment
            SizedBox(
              width: 70, // Fixed width to keep values aligned
              child: trailing != null
                  ? Align(
                alignment: Alignment.centerRight,
                child: trailing!,
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}