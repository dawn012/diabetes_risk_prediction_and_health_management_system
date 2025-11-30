import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../services/tutorial_flow_manager.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/constants/health_data_range.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/formatters/formatter.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/blood_glucose_controller.dart';
import '../health_data_entry/health_data_entry_screen.dart';
import 'widgets/health_analytics_time_range_selector.dart';
import 'widgets/health_data_list_screen.dart';
import 'widgets/health_distribution_chart.dart';
import 'widgets/health_statistics_table.dart';
import 'widgets/health_trends_chart.dart';
import 'widgets/period_filter.dart';
import 'widgets/range_date_picker.dart';

class BloodGlucoseAnalyticsScreen extends StatelessWidget {
  const BloodGlucoseAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BloodGlucoseController>();
    final darkMode = THelperFunctions.isDarkMode(context);
    final flowManager = TutorialFlowManager.instance;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted &&
          flowManager.isTutorialActive.value &&
          flowManager.shouldShowTutorialFor(TutorialStep.analyticsTimeRange)) {
        print('🎬 Showing analytics tutorial for: ${flowManager.currentStep.value}');

        // 延迟确保页面完全加载
        Future.delayed(const Duration(milliseconds: 600), () {
          if (context.mounted && !flowManager.showOverlay.value) {
            flowManager.showCurrentStepOverlay(context);
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: darkMode ? const Color(0xFF0A0A0B) : TColors.light,
      appBar: TAppBar(
        backgroundColor: TColors.primary,
        title: const Text(
          'Blood Glucose',
          style: TextStyle(fontWeight: FontWeight.bold, color: TColors.white),
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
                  initialSections: ['Blood Glucose']));
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

              // Add date range to Custom Range label
              if (controller.selectedTimeRange.value == 'Custom Range' &&
                  controller.customStartDate.value != null &&
                  controller.customEndDate.value != null) {
                final start = controller.customStartDate.value!;
                final end = controller.customEndDate.value!;
                displayText =
                'Custom Range (${start.day}/${start.month}/${start.year % 100} - ${end.day}/${end.month}/${end.year % 100})';
              }

              Widget timeRangeContent = HealthAnalyticsTimeRangeSelector(
                selectedTimeRange: displayText,
                onTap: () => _showTimeRangePicker(context, controller, darkMode),
              );

              // 在教学模式下包装 Showcase
              if (flowManager.shouldShowTutorialFor(TutorialStep.analyticsTimeRange)) {
                return Container(
                  key: flowManager.timeRangeKey,
                  child: timeRangeContent,
                );
              }

              return timeRangeContent;
            }),

            /// Last Record Info
            Obx(() {
              Widget lastRecordContent = _buildLastRecordInfo(context, controller, darkMode);

              // 在教学模式下包装 Showcase
              if (flowManager.shouldShowTutorialFor(TutorialStep.analyticsLastRecord)) {
                return Container(
                  key: flowManager.lastRecordLabelKey,
                  child: lastRecordContent,
                );
              }

              return lastRecordContent;
            }),

            /// Legend
            _buildLegend(context, darkMode),

            const SizedBox(height: TSizes.defaultSpace),

            /// Statistics Cards
            Obx(() {
              final lowestDisplay = controller.lowestValue.value >= 0
                  ? controller.lowestValue.value.toStringAsFixed(1)
                  : '-';
              final highestDisplay = controller.highestValue.value >= 0
                  ? controller.highestValue.value.toStringAsFixed(1)
                  : '-';
              final averageDisplay = controller.averageValue.value >= 0
                  ? controller.averageValue.value.toStringAsFixed(1)
                  : '-';
              final hasRecords = controller.totalCount.value > 0;

              Widget statisticsContent = HealthStatisticsTable(
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
                    lowestValue: lowestDisplay,
                    highestValue: highestDisplay,
                    averageValue: averageDisplay,
                    lowestColor: controller.getGlucoseLevelColor(controller.lowestValue.value),
                    highestColor: controller.getGlucoseLevelColor(controller.highestValue.value),
                    averageColor: controller.getGlucoseLevelColor(controller.averageValue.value),
                    onLowestTap: hasRecords ? () => controller.navigateToLowestRecord() : null,
                    onHighestTap: hasRecords ? () => controller.navigateToHighestRecord() : null,
                    onAverageTap: hasRecords ? () => controller.showAllRecords() : null,
                  ),
                ],
              );

              // 只有在教学模式下才包装 Showcase
              if (flowManager.shouldShowTutorialFor(TutorialStep.analyticsStatistics)) {
                statisticsContent = Container(
                  key: flowManager.analyticsStatisticsKey,
                  child: statisticsContent,
                );
              }

              return statisticsContent;
            }),

            const SizedBox(height: TSizes.defaultSpace),

            /// Distribution Chart
            Obx(() {
              Widget distributionContent = HealthDistributionChart(
                title: 'Distribution',
                distributionData: [
                  DistributionData(
                    label: 'Normal',
                    count: controller.normalCount.value,
                    color: TColors.glucoseNormal,
                    onTap: () => controller.showNormalRecords(),
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
                    onTap: () async {  // 改为 async
                      final flowManager = TutorialFlowManager.instance;

                      // 在教学模式下处理点击Total
                      if (flowManager.shouldShowTutorialFor(TutorialStep.analyticsClickTotal)) {
                        print('🎯 Total clicked in tutorial mode');

                        // 按照 Dashboard 的模式：先隐藏 overlay，推进步骤，然后直接导航
                        flowManager.hideOverlay();
                        flowManager.currentStep.value = TutorialStep.analyticsDeleteRecord;
                        flowManager.saveCurrentStep();

                        // 直接导航，不需要异步等待
                        Get.to(() => HealthDataListScreen(
                          title: 'All Glucose Records',
                          healthDataType: HealthDataType.bloodGlucose,
                          filterType: 'all',
                        ));
                      } else {
                        // 正常模式：使用原有功能
                        controller.showAllRecords();
                      }
                    },
                  ),
                ],
                pieChartSections: controller.totalCount.value > 0
                    ? [
                  PieChartSectionData(
                    value: controller.normalCount.value.toDouble(),
                    color: TColors.glucoseNormal,
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
                ]
                    : [],
                hasData: controller.totalCount.value > 0,
              );

              // 根据不同步骤使用不同的 key
              if (flowManager.shouldShowTutorialFor(TutorialStep.analyticsDistribution)) {
                // Distribution 步骤：使用 analyticsDistributionKey
                distributionContent = Container(
                  key: flowManager.analyticsDistributionKey,
                  child: distributionContent,
                );
              } else if (flowManager.shouldShowTutorialFor(TutorialStep.analyticsClickTotal)) {
                // Click Total 步骤：使用 analyticsClickTotalKey
                distributionContent = Container(
                  key: flowManager.analyticsClickTotalKey,
                  child: distributionContent,
                );
              }

              return distributionContent;
            }),

            const SizedBox(height: TSizes.defaultSpace),

            /// Trends Chart
            Obx(() {
              Widget trendsContent = HealthTrendsChart(
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
                maxY: HealthDataRanges.maxGlucoseMmolL,
                yAxisUnit: 'mmol/L',
                hasData: controller.trendsData.isNotEmpty,
                timeRange: controller.selectedTimeRange.value,
                periodFilter: controller.selectedPeriodFilter.value,
                trendFilter: controller.selectedTrendFilter.value,
                legendItems: [
                  LegendItem(label: 'Blood Glucose', color: TColors.primary),
                ],
                originalDateTimes: controller.trendsOriginalDateTimes,
              );

              // 只有在教学模式下才包装 Showcase
              if (flowManager.shouldShowTutorialFor(TutorialStep.analyticsTrends)) {
                trendsContent = Container(
                  key: flowManager.analyticsTrendsKey,
                  child: trendsContent,
                );
              }

              return trendsContent;
            }),

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
  Widget _buildLastRecordInfo(
      BuildContext context, BloodGlucoseController controller, bool darkMode) {
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
          _buildLegendItem('Low', TColors.glucoseLow, darkMode),
          const SizedBox(width: TSizes.md),
          _buildLegendItem('Normal', TColors.glucoseNormal, darkMode),
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
  Widget _buildComparisonChart(
      BuildContext context, BloodGlucoseController controller, bool darkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: darkMode ? TColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        border: Border.all(
          color: darkMode ? TColors.dark : Colors.grey.shade200,
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
                onTap: () =>
                    _showComparisonFilter(context, controller, darkMode),
                child: Row(
                  children: [
                    Obx(() => Text(
                      controller.selectedComparisonFilter.value,
                      style: const TextStyle(
                        color: TColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12
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

          /// Bar Chart with difference indicators
          SizedBox(
            height: 240, // Increased height to accommodate difference indicators
            child: controller.comparisonBarData.isNotEmpty
                ? Stack(
              children: [
                BarChart(
                  BarChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: _getComparisonChartInterval(controller),
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: darkMode
                            ? Colors.grey.shade700
                            : Colors.grey.shade300,
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: _getComparisonChartInterval(controller), // Use dynamic interval
                          getTitlesWidget: (value, meta) {
                            // Show labels based on the interval
                            final interval = _getComparisonChartInterval(controller);
                            if (value % interval == 0) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: darkMode ? TColors.white : TColors.black,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50, // Increased for longer labels
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() <
                                controller.comparisonLabels.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  controller.comparisonLabels[value.toInt()],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: darkMode
                                        ? TColors.white
                                        : TColors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: true),
                    maxY: _getComparisonChartMaxY(controller),
                    minY: 0,
                    barGroups: controller.comparisonBarData,
                    barTouchData: BarTouchData(
                      touchCallback:
                          (FlTouchEvent event, BarTouchResponse? response) {
                        if (response?.spot != null) {
                          // TODO: Show details for this comparison data
                        }
                      },
                    ),
                  ),
                ),

                // Difference indicators positioned above bars (outside the chart area)
                IgnorePointer(
                  child: CustomPaint(
                    painter: _DifferenceIndicatorPainter(
                      barGroups: controller.comparisonBarData,
                      differences: controller.comparisonData.entries.toList(),
                      maxY: _getComparisonChartMaxY(controller),
                      chartWidth: MediaQuery.of(context).size.width - TSizes.defaultSpace * 2 - TSizes.md * 2,
                    ),
                  ),
                ),
              ],
            )
                : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 48,
                    color: darkMode
                        ? Colors.grey.shade600
                        : Colors.grey.shade300,
                  ),
                  const SizedBox(height: TSizes.sm),
                  Text(
                    'No Comparison Data',
                    style:
                    Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: darkMode
                          ? Colors.grey.shade500
                          : Colors.grey.shade400,
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

  /// Get dynamic max Y value for comparison chart
  double _getComparisonChartMaxY(BloodGlucoseController controller) {
    if (controller.comparisonBarData.isEmpty) return 30;

    double maxValue = 0;
    for (final group in controller.comparisonBarData) {
      for (final rod in group.barRods) {
        if (rod.toY > maxValue) {
          maxValue = rod.toY;
        }
      }
    }

    // Always add extra space for difference indicators
    // If max value is 20, we want to show up to 30
    // If max value is 25, we want to show up to 30
    // If max value is 30, we want to show up to 40
    double roundedMax = (maxValue / 10).ceil() * 10.0;

    // Ensure we have enough space for the highest value plus some padding
    if (maxValue <= roundedMax - 5) {
      // If there's enough space, use the current rounded max
      return roundedMax;
    } else {
      // If the max value is too close to the rounded max, go to the next level
      return roundedMax + 10;
    }
  }

  /// Get dynamic interval for comparison chart
  double _getComparisonChartInterval(BloodGlucoseController controller) {
    final maxY = _getComparisonChartMaxY(controller);

    if (maxY <= 10) return 2;    // 0, 2, 4, 6, 8, 10
    if (maxY <= 20) return 5;    // 0, 5, 10, 15, 20
    if (maxY <= 30) return 10;   // 0, 10, 20, 30
    if (maxY <= 40) return 10;   // 0, 10, 20, 30, 40
    return 10;
  }

  /// Show Time Range Picker
  void _showTimeRangePicker(
      BuildContext context, BloodGlucoseController controller, bool darkMode) {
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
          maxHeight: MediaQuery.of(context).size.height * 0.8,
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
              /// Fixed Header
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

              /// Scrollable List
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

              const SizedBox(height: TSizes.defaultSpace),
            ],
          ),
        ),
      ),
    );
  }

  /// Show Custom Date Range Picker
  void _showCustomDateRangePicker(
      BuildContext context, BloodGlucoseController controller, bool darkMode) {
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
                vertical: TSizes.sm, // Reduced padding
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
                    padding: EdgeInsets.zero, // Remove extra padding
                    constraints: const BoxConstraints(), // Remove default constraints
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
                vertical: TSizes.sm, // Reduced padding
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
                          fontSize: 11, // Smaller font
                        ),
                      ),
                      const SizedBox(height: 2), // Reduced spacing
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
                          fontSize: 11, // Smaller font
                        ),
                      ),
                      const SizedBox(height: 2), // Reduced spacing
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

            /// Date Range Picker - Give it most of the space
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

  /// Show Comparison Filter
  void _showComparisonFilter(
      BuildContext context, BloodGlucoseController controller, bool darkMode) {
    final comparisonFilters = [
      'Before vs. After Meal',
      'Before vs. After Exercise'
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
            ...comparisonFilters
                .map((filter) => ListTile(
              title: Text(
                filter,
                style: TextStyle(
                  color: darkMode ? TColors.white : TColors.black,
                  fontWeight: filter ==
                      controller.selectedComparisonFilter.value
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              selected:
              filter == controller.selectedComparisonFilter.value,
              selectedTileColor: TColors.primary.withOpacity(0.1),
              onTap: () {
                controller.updateComparisonFilter(filter);
                Get.back();
              },
              trailing:
              filter == controller.selectedComparisonFilter.value
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

/// Custom painter to draw difference indicators above bars
class _DifferenceIndicatorPainter extends CustomPainter {
  final List<BarChartGroupData> barGroups;
  final List<MapEntry<String, double>> differences;
  final double maxY;
  final double chartWidth;

  _DifferenceIndicatorPainter({
    required this.barGroups,
    required this.differences,
    required this.maxY,
    required this.chartWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (barGroups.isEmpty || differences.isEmpty) return;

    final barWidth = 30.0; // Width of bar group
    final spacing = (chartWidth + 35 - (barGroups.length * barWidth)) / (barGroups.length + 1);

    for (int i = 0; i < barGroups.length; i++) {
      if (i < differences.length) {
        final difference = differences[i].value;
        final isPositive = difference > 0;

        // Calculate x position for the center of the bar group
        final x = spacing + (i * (barWidth + spacing)) + (barWidth / 2);

        // Find the maximum value in this bar group to position the indicator above it
        double maxBarValue = 0;
        for (final rod in barGroups[i].barRods) {
          if (rod.toY > maxBarValue) {
            maxBarValue = rod.toY;
          }
        }

        // Position the indicator above the highest bar with some margin
        // Using fixed position at the top of the chart area (outside the bars)
        final y = 15; // Fixed position at the top

        // Draw difference indicator
        final textSpan = TextSpan(
          text: '${isPositive ? '+' : ''}${difference.toStringAsFixed(1)}',
          style: TextStyle(
            color: isPositive ? TColors.glucoseHigh : TColors.glucoseLow,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        );

        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        // Draw background with border
        final backgroundRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, y.toDouble()),
            width: textPainter.width + 8,
            height: textPainter.height + 4,
          ),
          const Radius.circular(8),
        );

        final paint = Paint()
          ..color = isPositive ? TColors.glucoseHighLight : TColors.glucoseLowLight
          ..style = PaintingStyle.fill;

        // Draw border
        final borderPaint = Paint()
          ..color = isPositive ? TColors.glucoseHigh : TColors.glucoseLow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

        canvas.drawRRect(backgroundRect, paint);
        canvas.drawRRect(backgroundRect, borderPaint);

        // Draw text
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, y - textPainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}