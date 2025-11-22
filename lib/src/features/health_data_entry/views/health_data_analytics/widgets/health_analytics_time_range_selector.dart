import 'package:flutter/material.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';

class HealthAnalyticsTimeRangeSelector extends StatelessWidget {
  final String selectedTimeRange;
  final VoidCallback onTap;

  const HealthAnalyticsTimeRangeSelector({
    super.key,
    required this.selectedTimeRange,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(TSizes.defaultSpace),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm),
          decoration: BoxDecoration(
            color: TColors.primary,
            borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown, // 自动缩小文字
                  child: Text(
                    selectedTimeRange,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16, // 最大字体
                    ),
                  ),
                ),
              ),
              const SizedBox(width: TSizes.xs),
              const Icon(
                Icons.keyboard_arrow_down,
                color: TColors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}