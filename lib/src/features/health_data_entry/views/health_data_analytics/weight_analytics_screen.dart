import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/weight_controller.dart';
import '../health_data_entry/health_data_entry_screen.dart';
import 'widgets/health_analytics_time_range_selector.dart';
import 'widgets/health_statistics_table.dart';
import 'widgets/health_trends_chart.dart';
import 'widgets/period_filter.dart';

class WeightAnalyticsScreen extends StatelessWidget {
  const WeightAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WeightController>();
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: darkMode ? TColors.dark : TColors.light,
      appBar: AppBar(
        backgroundColor: TColors.primary,
        title: const Text(
          'Weight',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            controller.resetFilters();
            Get.back();
          }
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Get.to(() => const HealthDataEntryScreen(initialSections: ['Weight & Body Fat']));
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

            const SizedBox(height: TSizes.spaceBtwSections),

            /// Weight Statistics - 使用体重过滤器
            Obx(() => HealthStatisticsTable(
              title: 'Weight',
              selectedFilter: controller.selectedWeightPeriodFilter.value,
              onFilterTap: () => PeriodFilter.show(
                context: context,
                selectedValue: controller.selectedWeightPeriodFilter.value,
                onValueChanged: (filter) {
                  controller.updateWeightPeriodFilter(filter);
                },
                options: PhysiologicalTimePeriod.getAllDisplayNames(),
              ),
              statisticsRows: [
                StatisticsRow(
                  label: 'Lowest',
                  lowestValue: controller.weightLowest.value > 0 ? controller.weightLowest.value.toStringAsFixed(1) : '-',
                  highestValue: controller.weightHighest.value > 0 ? controller.weightHighest.value.toStringAsFixed(1) : '-',
                  averageValue: controller.weightCurrent.value > 0 ? controller.weightCurrent.value.toStringAsFixed(1) : '-',
                  lowestColor: controller.getWeightStatusColor(controller.weightLowest.value),
                  highestColor: controller.getWeightStatusColor(controller.weightHighest.value),
                  averageColor: controller.getWeightStatusColor(controller.weightCurrent.value),
                  onLowestTap: () => controller.navigateToLowestWeightRecord(),
                  onHighestTap: () => controller.navigateToHighestWeightRecord(),
                  onAverageTap: () => controller.showAllWeightRecords(),
                ),
              ],
            )),

            const SizedBox(height: TSizes.spaceBtwSections),

            /// Weight Trends Chart - 使用体重趋势过滤器
            Obx(() => HealthTrendsChart(
              title: 'Weight Trends',
              selectedFilter: controller.selectedWeightTrendFilter.value,
              onFilterTap: () => PeriodFilter.show(
                context: context,
                selectedValue: controller.selectedWeightTrendFilter.value,
                onValueChanged: (filter) {
                  controller.updateWeightTrendFilter(filter);
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
                  color: TColors.darkGrey,
                  barWidth: 2,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 3,
                        color: TColors.primary,
                        strokeWidth: 0,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(show: false),
                  spots: controller.weightTrendsData,
                ),
              ],
              labels: controller.trendsLabels,
              minY: controller.getMinWeightForChart(),
              maxY: controller.getMaxWeightForChart(),
              yAxisUnit: ' kg',
              hasData: controller.weightTrendsData.isNotEmpty,
              timeRange: controller.selectedTimeRange.value,
              periodFilter: controller.selectedWeightPeriodFilter.value,
              trendFilter: controller.selectedWeightTrendFilter.value,
              legendItems: [],
            )),

            const SizedBox(height: TSizes.spaceBtwSections),

            /// Body Fat Statistics - 使用体脂过滤器
            Obx(() => HealthStatisticsTable(
              title: 'Body Fat',
              selectedFilter: controller.selectedBodyFatPeriodFilter.value,
              onFilterTap: () => PeriodFilter.show(
                context: context,
                selectedValue: controller.selectedBodyFatPeriodFilter.value,
                onValueChanged: (filter) {
                  controller.updateBodyFatPeriodFilter(filter);
                },
                options: PhysiologicalTimePeriod.getAllDisplayNames(),
              ),
              statisticsRows: [
                StatisticsRow(
                  label: 'Body Fat',
                  lowestValue: controller.bodyFatLowest.value.toStringAsFixed(1),
                  highestValue: controller.bodyFatHighest.value.toStringAsFixed(1),
                  averageValue: controller.bodyFatCurrent.value.toStringAsFixed(1),
                  lowestColor: controller.getBodyFatStatusColor(controller.bodyFatLowest.value),
                  highestColor: controller.getBodyFatStatusColor(controller.bodyFatHighest.value),
                  averageColor: controller.getBodyFatStatusColor(controller.bodyFatCurrent.value),
                  onLowestTap: () => controller.navigateToLowestBodyFatRecord(),
                  onHighestTap: () => controller.navigateToHighestBodyFatRecord(),
                  onAverageTap: () => controller.showAllBodyFatRecords(),
                ),
              ],
            )),

            const SizedBox(height: TSizes.spaceBtwSections),

            /// Body Fat Trends Chart - 使用体脂趋势过滤器
            Obx(() => HealthTrendsChart(
              title: 'Body Fat Trends',
              selectedFilter: controller.selectedBodyFatTrendFilter.value,
              onFilterTap: () => PeriodFilter.show(
                context: context,
                selectedValue: controller.selectedBodyFatTrendFilter.value,
                onValueChanged: (filter) {
                  controller.updateBodyFatTrendFilter(filter);
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
                  color: TColors.darkGrey,
                  barWidth: 2,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 3,
                        color: TColors.primary,
                        strokeWidth: 0,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(show: false),
                  spots: controller.bodyFatTrendsData,
                ),
              ],
              labels: controller.trendsLabels,
              minY: controller.getMinBodyFatForChart(),
              maxY: controller.getMaxBodyFatForChart(),
              yAxisUnit: ' %',
              hasData: controller.bodyFatTrendsData.isNotEmpty,
              timeRange: controller.selectedTimeRange.value,
              periodFilter: controller.selectedBodyFatPeriodFilter.value,
              trendFilter: controller.selectedBodyFatTrendFilter.value,
              legendItems: [],
            )),

            const SizedBox(height: TSizes.spaceBtwSections),
          ],
        ),
      ),
    );
  }

  /// Last Record Info
  Widget _buildLastRecordInfo(BuildContext context, WeightController controller, bool darkMode) {
    if (controller.lastRecord.value == null) {
      return const SizedBox.shrink();
    }

    final lastRecord = controller.lastRecord.value!;
    final daysAgo = DateTime.now().difference(lastRecord.logDateTime).inDays;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Last Record : $daysAgo days ago',
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
          _buildLegendItem('Low', TColors.weightUnderweight, darkMode),
          const SizedBox(width: TSizes.md),
          _buildLegendItem('Good', TColors.weightNormal, darkMode),
          const SizedBox(width: TSizes.md),
          _buildLegendItem('High', TColors.weightOverweight, darkMode),
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
  void _showTimeRangePicker(BuildContext context, WeightController controller, bool darkMode) {
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
}