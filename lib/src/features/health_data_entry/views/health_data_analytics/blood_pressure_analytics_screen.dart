import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/constants/health_data_range.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/formatters/formatter.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/blood_pressure_controller.dart';
import '../health_data_entry/health_data_entry_screen.dart';
import 'widgets/health_analytics_time_range_selector.dart';
import 'widgets/health_statistics_table.dart';
import 'widgets/health_distribution_chart.dart';
import 'widgets/health_trends_chart.dart';
import 'widgets/period_filter.dart';

class BloodPressureAnalyticsScreen extends StatelessWidget {
  const BloodPressureAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BloodPressureController>();
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: darkMode ? const Color(0xFF0A0A0B) : TColors.light,
      appBar: TAppBar(
        backgroundColor: TColors.primary,
        title: const Text(
          'Blood Pressure',
          style: TextStyle(fontWeight: FontWeight.bold, color: TColors.white,),
        ),
        showBackArrow: true,
        customBackAction: () {
          controller.resetFilters();
          Get.back();
        },
        iconTheme: IconThemeData(color: TColors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            color: TColors.white,
            onPressed: () {
              Get.to(() => const HealthDataEntryScreen(
                  initialSections: ['Blood Pressure & Pulse']));
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

            /// Blood Pressure Statistics
            Obx(() {
              final systolicLowestDisplay = controller.systolicLowest.value >= 0
                  ? controller.systolicLowest.value.toString()
                  : '-';
              final systolicHighestDisplay = controller.systolicHighest.value >= 0
                  ? controller.systolicHighest.value.toString()
                  : '-';
              final systolicAverageDisplay = controller.systolicAverage.value >= 0
                  ? controller.systolicAverage.value.toStringAsFixed(0)
                  : '-';

              final diastolicLowestDisplay = controller.diastolicLowest.value >= 0
                  ? controller.diastolicLowest.value.toString()
                  : '-';
              final diastolicHighestDisplay = controller.diastolicHighest.value >= 0
                  ? controller.diastolicHighest.value.toString()
                  : '-';
              final diastolicAverageDisplay = controller.diastolicAverage.value >= 0
                  ? controller.diastolicAverage.value.toStringAsFixed(0)
                  : '-';

              final hasRecords = controller.totalCount.value > 0;

              return Column(
                children: [
                  HealthStatisticsTable(
                    title: 'Blood Pressure',
                    selectedFilter: controller.selectedBpPeriodFilter.value,
                    onFilterTap: () => PeriodFilter.show(
                      context: context,
                      selectedValue: controller.selectedBpPeriodFilter.value,
                      onValueChanged: (filter) {
                        controller.updateBpPeriodFilter(filter);
                      },
                      options: PhysiologicalTimePeriod.getAllDisplayNames(),
                    ),
                    statisticsRows: [
                      StatisticsRow(
                        label: 'Systolic',
                        lowestValue: systolicLowestDisplay,
                        highestValue: systolicHighestDisplay,
                        averageValue: systolicAverageDisplay,
                        lowestColor: controller.getBPLevelColor(
                            controller.systolicLowest.value, controller.diastolicLowest.value),
                        highestColor: controller.getBPLevelColor(
                            controller.systolicHighest.value, controller.diastolicHighest.value),
                        averageColor: controller.getBPLevelColor(
                            controller.systolicAverage.value.round(),
                            controller.diastolicAverage.value.round()),
                        onLowestTap: controller.systolicLowest.value > 0
                            ? () => controller.navigateToLowestSystolicRecord()
                            : null,
                        onHighestTap: controller.systolicHighest.value > 0
                            ? () => controller.navigateToHighestSystolicRecord()
                            : null,
                        onAverageTap: controller.systolicAverage.value > 0
                            ? () => controller.showAllBPRecords()
                            : null,
                      ),
                      StatisticsRow(
                        label: 'Diastolic',
                        lowestValue: diastolicLowestDisplay,
                        highestValue: diastolicHighestDisplay,
                        averageValue: diastolicAverageDisplay,
                        lowestColor: controller.getBPLevelColor(
                            controller.systolicLowest.value, controller.diastolicLowest.value),
                        highestColor: controller.getBPLevelColor(
                            controller.systolicHighest.value, controller.diastolicHighest.value),
                        averageColor: controller.getBPLevelColor(
                            controller.systolicAverage.value.round(),
                            controller.diastolicAverage.value.round()),
                        onLowestTap: hasRecords
                            ? () => controller.navigateToLowestDiastolicRecord()
                            : null,
                        onHighestTap: hasRecords
                            ? () => controller.navigateToHighestDiastolicRecord()
                            : null,
                        onAverageTap: hasRecords
                            ? () => controller.showAllBPRecords()
                            : null,
                      ),
                    ],
                  ),
                ],
              );
            }),

            const SizedBox(height: TSizes.defaultSpace),

            /// Distribution Chart
            Obx(() => HealthDistributionChart(
              title: 'Blood Pressure Distribution',
              distributionData: [
                DistributionData(
                  label: 'Normal',
                  count: controller.normalCount.value,
                  color: TColors.bpNormal,
                  onTap: () => controller.showNormalRecords(),
                ),
                DistributionData(
                  label: 'Elevated',
                  count: controller.elevatedCount.value,
                  color: TColors.bpElevated,
                  onTap: () => controller.showElevatedRecords(),
                ),
                DistributionData(
                  label: 'High',
                  count: controller.highCount.value,
                  color: TColors.bpHigh,
                  onTap: () => controller.showHighRecords(),
                ),
                DistributionData(
                  label: 'Low',
                  count: controller.lowCount.value,
                  color: TColors.bpLow,
                  onTap: () => controller.showLowRecords(),
                ),
                DistributionData(
                  label: 'Total',
                  count: controller.totalCount.value,
                  color: darkMode ? TColors.grey : TColors.darkGrey,
                  onTap: () => controller.showAllBPRecords(),
                ),
              ],
              pieChartSections: controller.totalCount.value > 0 ? [
                PieChartSectionData(
                  value: controller.normalCount.value.toDouble(),
                  color: TColors.bpNormal,
                  radius: 25,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: controller.elevatedCount.value.toDouble(),
                  color: TColors.bpElevated,
                  radius: 25,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: controller.highCount.value.toDouble(),
                  color: TColors.bpHigh,
                  radius: 25,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: controller.lowCount.value.toDouble(),
                  color: TColors.bpLow,
                  radius: 25,
                  showTitle: false,
                ),
              ] : [],
              hasData: controller.totalCount.value > 0,
            )),

            const SizedBox(height: TSizes.defaultSpace),

            /// Blood Pressure Trends Chart
            Obx(() => HealthTrendsChart(
              title: 'Blood Pressure Trends',
              selectedFilter: controller.selectedBpTrendFilter.value,
              onFilterTap: () => PeriodFilter.show(
                context: context,
                selectedValue: controller.selectedBpTrendFilter.value,
                onValueChanged: (filter) {
                  controller.updateBpTrendFilter(filter);
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
                  color: TColors.bpHigh,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(show: false),
                  spots: controller.systolicTrendsData,
                ),
                LineChartBarData(
                  isCurved: true,
                  color: TColors.bpNormal,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(show: false),
                  spots: controller.diastolicTrendsData,
                ),
              ],
              labels: controller.trendsLabels,
              minY: HealthDataRanges.minDiastolic.toDouble(),
              maxY: HealthDataRanges.maxSystolic.toDouble(),
              yAxisUnit: 'mmHg',
              hasData: controller.systolicTrendsData.isNotEmpty || controller.diastolicTrendsData.isNotEmpty,
              timeRange: controller.selectedTimeRange.value,
              periodFilter: controller.selectedBpPeriodFilter.value,
              trendFilter: controller.selectedBpTrendFilter.value,
              legendItems: [
                LegendItem(label: 'Systolic', color: TColors.bpHigh),
                LegendItem(label: 'Diastolic', color: TColors.bpNormal),
              ],
              originalDateTimes: controller.bpTrendsOriginalDateTimes,
            )),

            const SizedBox(height: TSizes.defaultSpace),

            /// Pulse Statistics
            Obx(() {
              final pulseLowestDisplay = controller.pulseLowest.value >= 0
                  ? controller.pulseLowest.value.toString()
                  : '-';
              final pulseHighestDisplay = controller.pulseHighest.value >= 0
                  ? controller.pulseHighest.value.toString()
                  : '-';
              final pulseAverageDisplay = controller.pulseAverage.value >= 0
                  ? controller.pulseAverage.value.toStringAsFixed(0)
                  : '-';

              final hasRecords = controller.totalCount.value > 0;

              return Column(
                children: [
                  HealthStatisticsTable(
                    title: 'Pulse',
                    selectedFilter: controller.selectedPulsePeriodFilter.value,
                    onFilterTap: () => PeriodFilter.show(
                      context: context,
                      selectedValue: controller.selectedPulsePeriodFilter.value,
                      onValueChanged: (filter) {
                        controller.updatePulsePeriodFilter(filter);
                      },
                      options: PhysiologicalTimePeriod.getAllDisplayNames(),
                    ),
                    statisticsRows: [
                      StatisticsRow(
                        label: 'Pulse',
                        lowestValue: pulseLowestDisplay,
                        highestValue: pulseHighestDisplay,
                        averageValue: pulseAverageDisplay,
                        lowestColor: controller.getPulseLevelColor(controller.pulseLowest.value),
                        highestColor: controller.getPulseLevelColor(controller.pulseHighest.value),
                        averageColor: controller.getPulseLevelColor(
                            controller.pulseAverage.value.round()),
                        onLowestTap: hasRecords
                            ? () => controller.navigateToLowestPulseRecord()
                            : null,
                        onHighestTap: hasRecords
                            ? () => controller.navigateToHighestPulseRecord()
                            : null,
                        onAverageTap: hasRecords
                            ? () => controller.showAllPulseRecords()
                            : null,
                      ),
                    ],
                  ),
                ],
              );
            }),

            const SizedBox(height: TSizes.defaultSpace),

            /// Pulse Trends Chart
            Obx(() => HealthTrendsChart(
              title: 'Pulse Trends',
              selectedFilter: controller.selectedPulseTrendFilter.value,
              onFilterTap: () => PeriodFilter.show(
                context: context,
                selectedValue: controller.selectedPulseTrendFilter.value,
                onValueChanged: (filter) {
                  controller.updatePulseTrendFilter(filter);
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
                  color: TColors.info,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(show: false),
                  spots: controller.pulseTrendsData,
                ),
              ],
              labels: controller.trendsLabels,
              minY: HealthDataRanges.minPulse.toDouble(),
              maxY: HealthDataRanges.maxPulse.toDouble(),
              yAxisUnit: 'bpm',
              hasData: controller.pulseTrendsData.isNotEmpty,
              timeRange: controller.selectedTimeRange.value,
              periodFilter: controller.selectedPulsePeriodFilter.value,
              trendFilter: controller.selectedPulseTrendFilter.value,
              legendItems: [
                LegendItem(label: 'Pulse Rate', color: TColors.info),
              ],
              originalDateTimes: controller.pulseTrendsOriginalDateTimes,
            )),

            const SizedBox(height: TSizes.defaultSpace),
          ],
        ),
      ),
    );
  }

  /// Last Record Info
  Widget _buildLastRecordInfo(
      BuildContext context, BloodPressureController controller, bool darkMode) {
    final lastRecord = controller.lastRecord.value;
    if (lastRecord == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Last Record: ${TFormatter.formatLastRecordDate(lastRecord.logDateTime)}',
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
          _buildLegendItem('Low', TColors.bpLow, darkMode),
          const SizedBox(width: TSizes.md),
          _buildLegendItem('Normal', TColors.bpNormal, darkMode),
          const SizedBox(width: TSizes.md),
          _buildLegendItem('Elevated', TColors.bpElevated, darkMode),
          const SizedBox(width: TSizes.md),
          _buildLegendItem('High', TColors.bpHigh, darkMode),
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
  void _showTimeRangePicker(BuildContext context, BloodPressureController controller, bool darkMode) {
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