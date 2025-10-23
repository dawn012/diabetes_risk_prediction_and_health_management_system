import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../utils/constants/sizes.dart';

class TProfileMenu extends StatelessWidget {
  const TProfileMenu({
    super.key,
    required this.onTap,
    required this.title,
    required this.value,
    this.icon,
  });

  final VoidCallback onTap;
  final String title, value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: TSizes.spaceBtwItems / 1.5),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text(title, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.visible)),
            Expanded(flex: 5, child: Text(value, style: Theme.of(context).textTheme.bodyMedium, overflow: TextOverflow.visible)),
            Expanded(child: Icon(icon, size: 18)),
          ],
        ),
      ),
    );
  }
}
