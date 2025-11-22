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
import 'widgets/range_date_picker.dart';

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
            Obx(() {
              String displayText = controller.selectedTimeRange.value;

              // 为自定义范围添加日期信息
              if (controller.selectedTimeRange.value == 'Custom Range' &&
                  controller.customStartDate.value != null &&
                  controller.customEndDate.value != null) {
                final start = controller.customStartDate.value!;
                final end = controller.customEndDate.value!;
                displayText =
                'Custom Range (${start.day}/${start.month}/${start.year % 100} - ${end.day}/${end.month}/${end.year % 100})';
              }

              return HealthAnalyticsTimeRangeSelector(
                selectedTimeRange: displayText,
                onTap: () => _showTimeRangePicker(context, controller, darkMode),
              );
            }),

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
          const SizedBox(width: TSizes.sm),
          _buildLegendItem('Medium (31-60)', TColors.warning, darkMode),
          const SizedBox(width: TSizes.sm),
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
          width: 11,
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
            fontSize: 11,
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
      'Custom Range',
    ];

    Get.bottomSheet(
      ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Container(
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
              /// 固定 Header
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

              /// 可滚动列表
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: timeRanges.map((range) => ListTile(
                    title: Text(
                      range,
                      style: TextStyle(
                        color: darkMode ? TColors.white : TColors.black,
                        fontWeight: range == controller.selectedTimeRange.value
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: range == controller.selectedTimeRange.value,
                    selectedTileColor: TColors.primary.withOpacity(0.1),
                    onTap: () {
                      if (range == 'Custom Range') {
                        // 显示自定义日期范围选择器
                        _showCustomDateRangePicker(context, controller, darkMode);
                      } else {
                        controller.resetCustomDateRange();
                        controller.updateTimeRange(range);
                        Get.back();
                      }
                    },
                    trailing: range == controller.selectedTimeRange.value
                        ? const Icon(Icons.check, color: TColors.primary)
                        : null,
                  )).toList(),
                ),
              ),

              const SizedBox(height: TSizes.defaultSpace),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示自定义日期范围选择器
  void _showCustomDateRangePicker(
      BuildContext context, DiabetesRiskController controller, bool darkMode) {
    DateTime? startDate = controller.customStartDate.value;
    DateTime? endDate = controller.customEndDate.value;

    // 设置默认日期范围（最近30天）
    final defaultEndDate = DateTime.now();
    final defaultStartDate = defaultEndDate.subtract(const Duration(days: 30));

    startDate ??= defaultStartDate;
    endDate ??= defaultEndDate;

    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.80,
        decoration: BoxDecoration(
          color: darkMode ? TColors.dark : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(TSizes.cardRadiusLg),
            topRight: Radius.circular(TSizes.cardRadiusLg),
          ),
        ),
        child: Column(
          children: [
            /// Header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: TSizes.md,
                vertical: TSizes.sm,
              ),
              decoration: BoxDecoration(
                color: TColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(TSizes.cardRadiusLg),
                  topRight: Radius.circular(TSizes.cardRadiusLg),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Get.back(); // 返回时间范围选择
                    },
                  ),
                  const SizedBox(width: TSizes.sm),
                  Expanded(
                    child: Text(
                      'Select Date Range',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      controller.updateCustomDateRange(startDate, endDate);
                      Get.back(); // 关闭自定义日期选择
                      Get.back(); // 关闭时间范围选择
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: TSizes.sm),
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// Selected Dates Display
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: TSizes.md,
                vertical: TSizes.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Start Date',
                        style: TextStyle(
                          color: darkMode ? TColors.grey : TColors.darkGrey,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        startDate != null
                            ? '${startDate.day}/${startDate.month}/${startDate.year}'
                            : 'Not selected',
                        style: TextStyle(
                          color: darkMode ? TColors.white : TColors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'End Date',
                        style: TextStyle(
                          color: darkMode ? TColors.grey : TColors.darkGrey,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        endDate != null
                            ? '${endDate.day}/${endDate.month}/${endDate.year}'
                            : 'Not selected',
                        style: TextStyle(
                          color: darkMode ? TColors.white : TColors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ]
                  ),
                ],
              ),
            ),

            /// Date Range Picker
            Expanded(
              child: RangeDatePicker(
                startDate: startDate,
                endDate: endDate,
                onDateRangeChanged: (DateTime start, DateTime end) {
                  startDate = start;
                  endDate = end;
                },
                darkMode: darkMode,
              ),
            ),
          ],
        ),
      ),
      isDismissible: true,
      isScrollControlled: true,
    );
  }
}