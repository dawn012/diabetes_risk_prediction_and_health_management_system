import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/formatters/formatter.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/diabetes_risk_controller.dart';
import 'widgets/health_analytics_time_range_selector.dart';
import 'widgets/health_distribution_chart.dart';
import 'widgets/health_statistics_table.dart';
import 'widgets/health_trends_chart.dart';

class DiabetesRiskAnalyticsScreen extends StatelessWidget {
  const DiabetesRiskAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DiabetesRiskController>();
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: darkMode ? const Color(0xFF0A0A0B) : TColors.light,
      appBar: TAppBar(
        backgroundColor: TColors.primary,
        title: const Text(
          'Diabetes Risk Score',
          style: TextStyle(fontWeight: FontWeight.bold, color: TColors.white),
        ),
        showBackArrow: true,
        customBackAction: () {
          controller.resetFilters();
          Get.back();
        },
        iconTheme: IconThemeData(color: TColors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// Time Range Selector
            Obx(() => HealthAnalyticsTimeRangeSelector(
              selectedTimeRange: controller.selectedTimeRange.value,
              onTap: () =>
                  _showTimeRangePicker(context, controller, darkMode),
            )),

            /// Last Record Info
            Obx(() => _buildLastRecordInfo(context, controller, darkMode)),

            /// Legend
            _buildLegend(context, darkMode),

            const SizedBox(height: TSizes.defaultSpace),

            /// Statistics Cards
            Obx(() {
              final lowestDisplay = controller.lowestScore.value > 0
                  ? controller.lowestScore.value.toStringAsFixed(1)
                  : '-';
              final highestDisplay = controller.highestScore.value > 0
                  ? controller.highestScore.value.toStringAsFixed(1)
                  : '-';
              final currentDisplay = controller.currentScore.value > 0
                  ? controller.currentScore.value.toStringAsFixed(1)
                  : '-';

              final hasRecords = controller.totalCount.value > 0;

              return Column(
                children: [
                  HealthStatisticsTable(
                    title: 'Risk Score',
                    selectedFilter: 'All',
                    showFilterButton: false,
                    statisticsRows: [
                      StatisticsRow(
                        label: 'Risk Score',
                        lowestValue: lowestDisplay,
                        highestValue: highestDisplay,
                        averageValue: currentDisplay,
                        averageLabel: 'Current',
                        lowestColor: controller
                            .getRiskLevelColor(controller.lowestScore.value),
                        highestColor: controller
                            .getRiskLevelColor(controller.highestScore.value),
                        averageColor: controller
                            .getRiskLevelColor(controller.currentScore.value),
                        onLowestTap: hasRecords ? () => controller.navigateToLowestRecord() : null,
                        onHighestTap: hasRecords ? () => controller.navigateToHighestRecord() : null,
                        onAverageTap: hasRecords ? () => controller.navigateToCurrentRecord() : null,
                      ),
                    ],
                  ),
                ],
              );
            }),

            const SizedBox(height: TSizes.defaultSpace),

            /// Distribution Chart
            Obx(() => HealthDistributionChart(
              title: 'Distribution',
              distributionData: [
                DistributionData(
                  label: 'Low',
                  count: controller.lowCount.value,
                  color: TColors.success,
                  onTap: () => controller.showLowRecords(),
                ),
                DistributionData(
                  label: 'Medium',
                  count: controller.mediumCount.value,
                  color: TColors.warning,
                  onTap: () => controller.showMediumRecords(),
                ),
                DistributionData(
                  label: 'High',
                  count: controller.highCount.value,
                  color: TColors.error,
                  onTap: () => controller.showHighRecords(),
                ),
                DistributionData(
                  label: 'Total',
                  count: controller.totalCount.value,
                  color: darkMode ? TColors.grey : TColors.darkGrey,
                  onTap: () => controller.showAllRecords(),
                ),
              ],
              pieChartSections: controller.totalCount.value > 0
                  ? [
                PieChartSectionData(
                  value: controller.lowCount.value.toDouble(),
                  color: TColors.success,
                  radius: 25,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: controller.mediumCount.value.toDouble(),
                  color: TColors.warning,
                  radius: 25,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: controller.highCount.value.toDouble(),
                  color: TColors.error,
                  radius: 25,
                  showTitle: false,
                ),
              ]
                  : [],
              hasData: controller.totalCount.value > 0,
            )),

            const SizedBox(height: TSizes.defaultSpace),

            /// Trends Chart
            Obx(() => HealthTrendsChart(
              title: 'Risk Score Trends',
              selectedFilter: 'All',
              showFilterButton: false,
              lineBarData: [
                LineChartBarData(
                  isCurved: true,
                  color: TColors.primary,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(show: false),
                  spots: controller.trendsData,
                ),
              ],
              labels: controller.trendsLabels,
              minY: 0,
              maxY: 100,
              yAxisUnit: 'pts',
              hasData: controller.trendsData.isNotEmpty,
              timeRange: controller.selectedTimeRange.value,
              periodFilter: 'All',
              trendFilter: 'All',
              legendItems: [
                LegendItem(label: 'Risk Score', color: TColors.primary),
              ],
              originalDateTimes: controller.trendsOriginalDateTimes,
            )),

            const SizedBox(height: TSizes.defaultSpace),
          ],
        ),
      ),
    );
  }

  /// Last Record Info
  Widget _buildLastRecordInfo(
      BuildContext context, DiabetesRiskController controller, bool darkMode) {
    final lastPrediction = controller.latestPrediction.value;
    if (lastPrediction == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Last Assessment: ${TFormatter.formatLastRecordDate(lastPrediction.predictionDateTime)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: darkMode ? TColors.grey : TColors.darkGrey,
            ),
          ),
        ],
      ),
    );
  }

  /// Legend
  Widget _buildLegend(BuildContext context, bool darkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem('Low (0-30)', TColors.success, darkMode),
          const SizedBox(width: TSizes.md),
          _buildLegendItem('Medium (31-60)', TColors.warning, darkMode),
          const SizedBox(width: TSizes.md),
          _buildLegendItem('High (61-100)', TColors.error, darkMode),
        ],
      ),
    );
  }

  /// Legend Item
  Widget _buildLegendItem(String label, Color color, bool darkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: TSizes.xs),
        Text(
          label,
          style: TextStyle(
            color: darkMode ? TColors.white : TColors.black,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Show Time Range Picker
  void _showTimeRangePicker(
      BuildContext context, DiabetesRiskController controller, bool darkMode) {
    final timeRanges = [
      'Past 7 Days',
      'Past 14 Days',
      'Past 30 Days',
      'Past 60 Days',
      'Past 90 Days',
    ];

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: darkMode ? TColors.dark : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(TSizes.cardRadiusLg),
            topRight: Radius.circular(TSizes.cardRadiusLg),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Header
            Container(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              decoration: BoxDecoration(
                color: TColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(TSizes.cardRadiusLg),
                  topRight: Radius.circular(TSizes.cardRadiusLg),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Select Time Range',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            /// Time Range Options
            ...timeRanges
                .map((range) => ListTile(
              title: Text(
                range,
                style: TextStyle(
                  color: darkMode ? TColors.white : TColors.black,
                  fontWeight:
                  range == controller.selectedTimeRange.value
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              selected: range == controller.selectedTimeRange.value,
              selectedTileColor: TColors.primary.withOpacity(0.1),
              onTap: () {
                controller.updateTimeRange(range);
                Get.back();
              },
              trailing: range == controller.selectedTimeRange.value
                  ? const Icon(Icons.check, color: TColors.primary)
                  : null,
            ))
                .toList(),

            const SizedBox(height: TSizes.defaultSpace),
          ],
        ),
      ),
    );
  }
}