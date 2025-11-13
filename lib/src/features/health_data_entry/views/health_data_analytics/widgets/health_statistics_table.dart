import 'package:flutter/material.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';

class HealthStatisticsTable extends StatelessWidget {
  final String title;
  final String selectedFilter;
  final VoidCallback? onFilterTap;
  final List<StatisticsRow> statisticsRows;
  final bool showFilterButton;

  const HealthStatisticsTable({
    super.key,
    required this.title,
    required this.selectedFilter,
    this.onFilterTap,
    required this.statisticsRows,
    this.showFilterButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      child: Column(
        children: [
          /// Statistics Header and Filter
          Container(
            padding: const EdgeInsets.all(TSizes.md),
            decoration: BoxDecoration(
              color: darkMode ? TColors.dark : TColors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(TSizes.cardRadiusLg),
                topRight: Radius.circular(TSizes.cardRadiusLg),
              ),
              border: Border.all(
                color: darkMode ? TColors.dark : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: darkMode ? TColors.white : TColors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // 根据 showFilterButton 决定是否显示过滤器按钮
                if (showFilterButton)
                  GestureDetector(
                    onTap: onFilterTap, // 直接使用，如果为 null 则不会响应点击
                    child: Row(
                      children: [
                        Text(
                          selectedFilter,
                          style: const TextStyle(
                            color: TColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: TSizes.xs),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: TColors.primary,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          /// Statistics Table
          Container(
            decoration: BoxDecoration(
              color: darkMode ? TColors.dark : Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(TSizes.cardRadiusLg),
                bottomRight: Radius.circular(TSizes.cardRadiusLg),
              ),
              border: Border.all(
                color: darkMode ? TColors.dark : Colors.grey.shade200,
              ),
            ),
            child: Column(
              children: [
                /// Header Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.sm),
                  child: Row(
                    children: [
                      const Expanded(child: SizedBox.shrink()),
                      Expanded(
                        child: Text(
                          'Lowest',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: darkMode ? TColors.grey : TColors.darkGrey,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Highest',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: darkMode ? TColors.grey : TColors.darkGrey,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          statisticsRows.isNotEmpty ? statisticsRows.first.averageLabel : 'Average',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: darkMode ? TColors.grey : TColors.darkGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                /// Statistics Rows
                ...statisticsRows.map((row) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.md),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: darkMode ? TColors.dark : Colors.grey.shade200,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          row.label,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: darkMode ? TColors.white : TColors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: row.onLowestTap,
                          child: Text(
                            row.lowestValue,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: row.lowestColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: row.onHighestTap,
                          child: Text(
                            row.highestValue,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: row.highestColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: row.onAverageTap,
                          child: Text(
                            row.averageValue,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: row.averageColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatisticsRow {
  final String label;
  final String lowestValue;
  final String highestValue;
  final String averageValue;
  final Color lowestColor;
  final Color highestColor;
  final Color averageColor;
  final VoidCallback? onLowestTap;
  final VoidCallback? onHighestTap;
  final VoidCallback? onAverageTap;
  final String averageLabel;

  StatisticsRow({
    required this.label,
    required this.lowestValue,
    required this.highestValue,
    required this.averageValue,
    required this.lowestColor,
    required this.highestColor,
    required this.averageColor,
    this.onLowestTap,
    this.onHighestTap,
    this.onAverageTap,
    this.averageLabel = 'Average',
  });
}