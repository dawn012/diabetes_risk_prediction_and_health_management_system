import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';

/// Profile Section Header
class ProfileSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onActionTap;

  const ProfileSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(TSizes.xs),
          decoration: BoxDecoration(
            color: TColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
          ),
          child: Icon(
            icon,
            size: 20,
            color: TColors.primary,
          ),
        ),
        SizedBox(width: TSizes.sm),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (onActionTap != null)
          IconButton(
            onPressed: onActionTap,
            icon: Icon(Iconsax.edit_2_bold, size: 18),
            tooltip: 'Edit $title',
          ),
      ],
    );
  }
}