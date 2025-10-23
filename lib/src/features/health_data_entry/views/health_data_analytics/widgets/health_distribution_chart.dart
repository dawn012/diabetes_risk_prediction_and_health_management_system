import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';

class HealthDistributionChart extends StatelessWidget {
  final String title;
  final List<DistributionData> distributionData;
  final List<PieChartSectionData> pieChartSections;
  final bool hasData;

  const HealthDistributionChart({
    super.key,
    required this.title,
    required this.distributionData,
    required this.pieChartSections,
    required this.hasData,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: darkMode ? TColors.darkerGrey : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        border: Border.all(
          color: darkMode ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: darkMode ? TColors.white : TColors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: TSizes.md),

          Row(
            children: [
              /// Distribution Table
              Expanded(
                flex: 3,
                child: Table(
                  border: TableBorder.all(
                    color: darkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                  children: distributionData.map((data) =>
                      _buildTableRow(data.label, data.count, data.color, darkMode, data.onTap)
                  ).toList(),
                ),
              ),

              const SizedBox(width: TSizes.md),

              /// Pie Chart
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 120,
                  child: hasData
                      ? PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      sections: pieChartSections,
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          // 添加边界检查
                          if (pieTouchResponse?.touchedSection == null) {
                            return;
                          }

                          final sectionIndex = pieTouchResponse!.touchedSection!.touchedSectionIndex;

                          // 检查索引是否在有效范围内
                          if (sectionIndex < 0 || sectionIndex >= distributionData.length) {
                            return;
                          }

                          // 确保对应的 distributionData 有 onTap 回调
                          if (distributionData[sectionIndex].onTap != null) {
                            distributionData[sectionIndex].onTap!.call();
                          }
                        },
                      ),
                    ),
                  )
                      : Center(
                    child: Text(
                      'No Data',
                      style: TextStyle(
                        color: darkMode ? TColors.grey : TColors.darkGrey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String label, int count, Color color, bool darkMode, VoidCallback? onTap) {
    return TableRow(
      children: [
        TableCell(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Text(
                label,
                style: TextStyle(
                  color: darkMode ? TColors.white : TColors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        TableCell(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(8),
              alignment: Alignment.center,
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DistributionData {
  final String label;
  final int count;
  final Color color;
  final VoidCallback? onTap;

  DistributionData({
    required this.label,
    required this.count,
    required this.color,
    this.onTap,
  });
}