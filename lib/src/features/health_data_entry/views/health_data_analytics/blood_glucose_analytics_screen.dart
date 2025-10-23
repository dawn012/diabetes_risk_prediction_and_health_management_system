import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/blood_glucose_controller.dart';
import '../health_data_entry/health_data_entry_screen.dart';
import 'widgets/health_analytics_time_range_selector.dart';
import 'widgets/health_distribution_chart.dart';
import 'widgets/health_statistics_table.dart';
import 'widgets/health_trends_chart.dart';
import 'widgets/period_filter.dart';

class BloodGlucoseAnalyticsScreen extends StatelessWidget {
  const BloodGlucoseAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BloodGlucoseController>();
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: darkMode ? TColors.dark : TColors.light,
      appBar: AppBar(
        backgroundColor: TColors.primary,
        foregroundColor: TColors.white,
        title: const Text(
          'Blood Glucose',
          style: TextStyle(fontWeight: FontWeight.bold, color: TColors.white,),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            controller.resetFilters();
            Get.back();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            color: TColors.white,
            onPressed: () {
              Get.to(() => const HealthDataEntryScreen(initialSections: ['Blood Glucose'],));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// Time Range Selector
            Obx(() => HealthAnalyticsTimeRangeSelector(
              selectedTimeRange: controller.selectedTimeRange.value,
              onTap: () => _showTimeRangePicker(context, controller, darkMode),
            )),

            /// Last Record Info
            Obx(() => _buildLastRecordInfo(context, controller, darkMode)),

            /// Legend
            _buildLegend(context, darkMode),

            const SizedBox(height: TSizes.defaultSpace),

            /// Statistics Cards
            Obx(() => HealthStatisticsTable(
              title: 'Blood Glucose',
              selectedFilter: controller.selectedPeriodFilter.value,
              onFilterTap: () => PeriodFilter.show(
                context: context,
                selectedValue: controller.selectedPeriodFilter.value,
                onValueChanged: (filter) {
                  controller.updatePeriodFilter(filter);
                },
                options: PhysiologicalTimePeriod.getAllDisplayNames(),
              ),
              statisticsRows: [
                StatisticsRow(
                  label: 'Glucose Level',
                  lowestValue: controller.lowestValue.value.toStringAsFixed(1),
                  highestValue: controller.highestValue.value.toStringAsFixed(1),
                  averageValue: controller.averageValue.value.toStringAsFixed(1),
                  lowestColor: TColors.glucoseLow,
                  highestColor: TColors.glucoseHigh,
                  averageColor: TColors.glucoseGood,
                  onLowestTap: () => controller.navigateToLowestRecord(),
                  onHighestTap: () => controller.navigateToHighestRecord(),
                  onAverageTap: () => controller.showAllRecords(),
                ),
              ],
            )),

            const SizedBox(height: TSizes.defaultSpace),

            /// Distribution Chart
            Obx(() => HealthDistributionChart(
              title: 'Distribution',
              distributionData: [
                DistributionData(
                  label: 'Good',
                  count: controller.goodCount.value,
                  color: TColors.glucoseGood,
                  onTap: () => controller.showGoodRecords(),
                ),
                DistributionData(
                  label: 'High',
                  count: controller.highCount.value,
                  color: TColors.glucoseHigh,
                  onTap: () => controller.showHighRecords(),
                ),
                DistributionData(
                  label: 'Low',
                  count: controller.lowCount.value,
                  color: TColors.glucoseLow,
                  onTap: () => controller.showLowRecords(),
                ),
                DistributionData(
                  label: 'Total',
                  count: controller.totalCount.value,
                  color: darkMode ? TColors.grey : TColors.darkGrey,
                  onTap: () => controller.showAllRecords(),
                ),
              ],
              pieChartSections: controller.totalCount.value > 0 ? [
                PieChartSectionData(
                  value: controller.goodCount.value.toDouble(),
                  color: TColors.glucoseGood,
                  radius: 25,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: controller.highCount.value.toDouble(),
                  color: TColors.glucoseHigh,
                  radius: 25,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: controller.lowCount.value.toDouble(),
                  color: TColors.glucoseLow,
                  radius: 25,
                  showTitle: false,
                ),
              ] : [],
              hasData: controller.totalCount.value > 0,
            )),

            const SizedBox(height: TSizes.defaultSpace),

            /// Trends Chart
            Obx(() => HealthTrendsChart(
              title: 'Blood Glucose Trends',
              selectedFilter: controller.selectedTrendFilter.value,
              onFilterTap: () => PeriodFilter.show(
                context: context,
                selectedValue: controller.selectedTrendFilter.value,
                onValueChanged: (filter) {
                  controller.updateTrendFilter(filter);
                },
                options: [
                  'All',
                  'Before Meal',
                  'After Meal',
                  'Before Exercise',
                  'After Exercise',
                  'Wake-up',
                  'Bedtime',
                  'Others'
                ],
              ),
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
              maxY: 30,
              yAxisUnit: '',
              hasData: controller.trendsData.isNotEmpty,
              timeRange: controller.selectedTimeRange.value,
              periodFilter: controller.selectedPeriodFilter.value,
              trendFilter: controller.selectedTrendFilter.value,
              legendItems: [
                LegendItem(label: 'Blood Glucose', color: TColors.primary),
              ],
            )),

            const SizedBox(height: TSizes.defaultSpace),

            /// Comparison Chart (Before/After Meals)
            Obx(() => _buildComparisonChart(context, controller, darkMode)),

            const SizedBox(height: TSizes.defaultSpace),
          ],
        ),
      ),
    );
  }

  /// Last Record Info
  Widget _buildLastRecordInfo(BuildContext context, BloodGlucoseController controller, bool darkMode) {
    if (controller.lastRecord.value == null) {
      return const SizedBox.shrink();
    }

    final lastRecord = controller.lastRecord.value!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Last Record: ${DateFormat('HH:mm').format(lastRecord.logDateTime)}',
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
          _buildLegendItem('Low', TColors.glucoseLow, darkMode),
          const SizedBox(width: TSizes.md),
          _buildLegendItem('Good', TColors.glucoseGood, darkMode),
          const SizedBox(width: TSizes.md),
          _buildLegendItem('High', TColors.glucoseHigh, darkMode),
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

  /// Comparison Chart (Before vs After Meals)
  Widget _buildComparisonChart(BuildContext context, BloodGlucoseController controller, bool darkMode) {
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
          Row(
            children: [
              Text(
                'Comparison',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: darkMode ? TColors.white : TColors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showComparisonFilter(context, controller, darkMode),
                child: Row(
                  children: [
                    Obx(() => Text(
                      controller.selectedComparisonFilter.value,
                      style: const TextStyle(
                        color: TColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    )),
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
          const SizedBox(height: TSizes.md),

          /// Comparison Indicators
          if (controller.comparisonData.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: controller.comparisonData.entries.map((entry) {
                final difference = entry.value;
                final isPositive = difference > 0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: TSizes.xs),
                  decoration: BoxDecoration(
                    color: isPositive ? TColors.glucoseHighLight : TColors.glucoseLowLight,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    '${isPositive ? '+' : ''}${difference.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: isPositive ? TColors.glucoseHigh : TColors.glucoseLow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: TSizes.md),
          ],

          /// Bar Chart
          SizedBox(
            height: 200,
            child: controller.comparisonBarData.isNotEmpty
                ? BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: darkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: darkMode ? TColors.white : TColors.black,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < controller.comparisonLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              controller.comparisonLabels[value.toInt()],
                              style: TextStyle(
                                fontSize: 10,
                                color: darkMode ? TColors.white : TColors.black,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                maxY: 40,
                barGroups: controller.comparisonBarData,
                barTouchData: BarTouchData(
                  touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
                    if (response?.spot != null) {
                      // TODO: Show details for this comparison data
                    }
                  },
                ),
              ),
            )
                : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 48,
                    color: darkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                  ),
                  const SizedBox(height: TSizes.sm),
                  Text(
                    'No Comparison Data',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: darkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show Time Range Picker
  void _showTimeRangePicker(BuildContext context, BloodGlucoseController controller, bool darkMode) {
    final timeRanges = ['Past 7 Days', 'Past 14 Days', 'Past 30 Days', 'Past 60 Days', 'Past 90 Days', 'Custom Range'];

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
            ...timeRanges.map((range) => ListTile(
              title: Text(
                range,
                style: TextStyle(
                  color: darkMode ? TColors.white : TColors.black,
                  fontWeight: range == controller.selectedTimeRange.value ? FontWeight.bold : FontWeight.normal,
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
            )).toList(),

            const SizedBox(height: TSizes.defaultSpace),
          ],
        ),
      ),
    );
  }

  /// Show Comparison Filter
  void _showComparisonFilter(BuildContext context, BloodGlucoseController controller, bool darkMode) {
    final comparisonFilters = ['Before vs. After Meal', 'Morning vs. Evening', 'Pre vs. Post Exercise'];

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
                    'Comparison Type',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            /// Comparison Filter Options
            ...comparisonFilters.map((filter) => ListTile(
              title: Text(
                filter,
                style: TextStyle(
                  color: darkMode ? TColors.white : TColors.black,
                  fontWeight: filter == controller.selectedComparisonFilter.value ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: filter == controller.selectedComparisonFilter.value,
              selectedTileColor: TColors.primary.withOpacity(0.1),
              onTap: () {
                controller.updateComparisonFilter(filter);
                Get.back();
              },
              trailing: filter == controller.selectedComparisonFilter.value
                  ? const Icon(Icons.check, color: TColors.primary)
                  : null,
            )).toList(),

            const SizedBox(height: TSizes.defaultSpace),
          ],
        ),
      ),
    );
  }
}