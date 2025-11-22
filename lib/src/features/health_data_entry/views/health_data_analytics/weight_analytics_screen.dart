import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/constants/health_data_range.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/formatters/formatter.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/weight_controller.dart';
import '../health_data_entry/health_data_entry_screen.dart';
import 'widgets/health_analytics_time_range_selector.dart';
import 'widgets/health_statistics_table.dart';
import 'widgets/health_trends_chart.dart';
import 'widgets/period_filter.dart';
import 'widgets/range_date_picker.dart';

class WeightAnalyticsScreen extends StatelessWidget {
  const WeightAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WeightController>();
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: darkMode ? const Color(0xFF0A0A0B) : TColors.light,
      appBar: TAppBar(
        backgroundColor: TColors.primary,
        title: const Text(
          'Weight',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                  initialSections: ['Weight & Body Fat']));
            },
          ),
        ],
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

            /// Weight BMI Legend
            _buildWeightLegend(context, darkMode),

            const SizedBox(height: TSizes.spaceBtwSections),

            /// Weight Statistics
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
                  label: 'Weight',
                  lowestValue: controller.weightLowest.value > 0
                      ? controller.weightLowest.value.toStringAsFixed(1)
                      : '-',
                  highestValue: controller.weightHighest.value > 0
                      ? controller.weightHighest.value.toStringAsFixed(1)
                      : '-',
                  averageValue: controller.weightCurrent.value > 0
                      ? controller.weightCurrent.value.toStringAsFixed(1)
                      : '-',
                  lowestColor: controller.weightLowest.value > 0
                      ? controller.getWeightStatusColor(controller.weightLowest.value)
                      : TColors.darkGrey,
                  highestColor: controller.weightHighest.value > 0
                      ? controller.getWeightStatusColor(controller.weightHighest.value)
                      : TColors.darkGrey,
                  averageColor: controller.weightCurrent.value > 0
                      ? controller.getWeightStatusColor(controller.weightCurrent.value)
                      : TColors.darkGrey,
                  onLowestTap: controller.weightLowest.value > 0
                      ? () => controller.navigateToLowestWeightRecord()
                      : null,
                  onHighestTap: controller.weightHighest.value > 0
                      ? () => controller.navigateToHighestWeightRecord()
                      : null,
                  onAverageTap: controller.weightCurrent.value > 0
                      ? () => controller.showAllWeightRecords()
                      : null,
                  averageLabel: 'Current',
                ),
              ],
            )),

            const SizedBox(height: TSizes.spaceBtwSections),

            /// Weight Trends Chart
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
                  color: TColors.primary,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                  ),
                  belowBarData: BarAreaData(show: false),
                  spots: controller.weightTrendsData,
                ),
              ],
              labels: controller.weightTrendsLabels,
              minY: HealthDataRanges.minWeightKg,
              maxY: HealthDataRanges.maxWeightKg,
              yAxisUnit: 'kg',
              hasData: controller.weightTrendsData.isNotEmpty,
              timeRange: controller.selectedTimeRange.value,
              periodFilter: controller.selectedWeightPeriodFilter.value,
              trendFilter: controller.selectedWeightTrendFilter.value,
              legendItems: [
                LegendItem(label: 'Weight', color: TColors.info),
              ],
              trendValue: controller.weightTrendValue.value,
              trendDirection: controller.weightTrendDirection.value,
              originalDateTimes: controller.weightTrendsOriginalDateTimes,
            )),

            const SizedBox(height: TSizes.spaceBtwSections),

            /// Body Fat Legend
            _buildBodyFatLegend(context, darkMode),

            const SizedBox(height: TSizes.spaceBtwSections),

            /// Body Fat Statistics
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
                  lowestValue: controller.bodyFatLowest.value > 0
                      ? controller.bodyFatLowest.value.toStringAsFixed(1)
                      : '-',
                  highestValue: controller.bodyFatHighest.value > 0
                      ? controller.bodyFatHighest.value.toStringAsFixed(1)
                      : '-',
                  averageValue: controller.bodyFatCurrent.value > 0
                      ? controller.bodyFatCurrent.value.toStringAsFixed(1)
                      : '-',
                  lowestColor: controller.bodyFatLowest.value > 0
                      ? controller.getBodyFatStatusColor(controller.bodyFatLowest.value)
                      : TColors.darkGrey,
                  highestColor: controller.bodyFatHighest.value > 0
                      ? controller.getBodyFatStatusColor(controller.bodyFatHighest.value)
                      : TColors.darkGrey,
                  averageColor: controller.bodyFatCurrent.value > 0
                      ? controller.getBodyFatStatusColor(controller.bodyFatCurrent.value)
                      : TColors.darkGrey,
                  onLowestTap: controller.bodyFatLowest.value > 0
                      ? () => controller.navigateToLowestBodyFatRecord()
                      : null,
                  onHighestTap: controller.bodyFatHighest.value > 0
                      ? () => controller.navigateToHighestBodyFatRecord()
                      : null,
                  onAverageTap: controller.bodyFatCurrent.value > 0
                      ? () => controller.showAllBodyFatRecords()
                      : null,
                  averageLabel: 'Current',
                ),
              ],
            )),

            const SizedBox(height: TSizes.spaceBtwSections),

            /// Body Fat Trends Chart
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
                  color: TColors.primary,
                  barWidth: 3,
                  dotData: FlDotData(show: true,),
                  belowBarData: BarAreaData(show: false),
                  spots: controller.bodyFatTrendsData,
                ),
              ],
              labels: controller.bodyFatTrendsLabels,
              minY: HealthDataRanges.minBodyFatPercent,
              maxY: HealthDataRanges.maxBodyFatPercent,
              yAxisUnit: '%',
              hasData: controller.bodyFatTrendsData.isNotEmpty,
              timeRange: controller.selectedTimeRange.value,
              periodFilter: controller.selectedBodyFatPeriodFilter.value,
              trendFilter: controller.selectedBodyFatTrendFilter.value,
              legendItems: [
                LegendItem(label: 'Body Fat', color: TColors.info),
              ],
              trendValue: controller.bodyFatTrendValue.value,
              trendDirection: controller.bodyFatTrendDirection.value,
              originalDateTimes: controller.bodyFatTrendsOriginalDateTimes,
            )),

            const SizedBox(height: TSizes.spaceBtwSections),
          ],
        ),
      ),
    );
  }

  /// Last Record Info
  Widget _buildLastRecordInfo(
      BuildContext context, WeightController controller, bool darkMode) {
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

  /// Weight BMI Legend
  Widget _buildWeightLegend(BuildContext context, bool darkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: TSizes.md, // 水平间距
        runSpacing: 8.0,   // 垂直间距
        children: [
          _buildLegendItem('Underweight', TColors.weightUnderweight, darkMode),
          _buildLegendItem('Normal', TColors.weightNormal, darkMode),
          _buildLegendItem('Overweight', TColors.weightOverweight, darkMode),
          _buildLegendItem('Obese', TColors.weightObese, darkMode),
        ],
      ),
    );
  }

  /// Body Fat Legend
  Widget _buildBodyFatLegend(BuildContext context, bool darkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem('Low', TColors.bodyFatLow, darkMode),
          const SizedBox(width: TSizes.md),
          _buildLegendItem('Normal', TColors.bodyFatNormal, darkMode),
          const SizedBox(width: TSizes.md),
          _buildLegendItem('Elevated', TColors.bodyFatElevated, darkMode),
          const SizedBox(width: TSizes.md),
          _buildLegendItem('High', TColors.bodyFatHigh, darkMode),
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
    final timeRanges = [
      'Past 7 Days',
      'Past 14 Days',
      'Past 30 Days',
      'Past 60 Days',
      'Past 90 Days',
      'Custom Range'
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
                  children: [
                    ...timeRanges.map((range) => ListTile(
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示自定义日期范围选择器
  void _showCustomDateRangePicker(
      BuildContext context, WeightController controller, bool darkMode) {
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
                    ],
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