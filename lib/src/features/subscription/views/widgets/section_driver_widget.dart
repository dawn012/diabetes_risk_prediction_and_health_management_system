import 'package:flutter/material.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';

class SectionDividerWidget extends StatelessWidget {
  final bool darkMode;

  const SectionDividerWidget({
    super.key,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TSizes.md),
      child: Divider(
        color: darkMode
            ? TColors.darkGrey.withOpacity(0.3)
            : TColors.grey.withOpacity(0.3),
        height: 1,
      ),
    );
  }
}
