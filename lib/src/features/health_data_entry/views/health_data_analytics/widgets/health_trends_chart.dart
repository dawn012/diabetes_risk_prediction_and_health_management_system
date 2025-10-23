import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/export_helper.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import 'chart_export_button.dart';

class HealthTrendsChart extends StatelessWidget {
  final String title;
  final String selectedFilter;
  final VoidCallback onFilterTap;
  final List<LineChartBarData> lineBarData;
  final List<String> labels;
  final double minY;
  final double maxY;
  final String yAxisUnit;
  final bool hasData;
  final List<LegendItem>? legendItems;
  final String timeRange;
  final String? periodFilter;
  final String? trendFilter;

  HealthTrendsChart({
    super.key,
    required this.title,
    required this.selectedFilter,
    required this.onFilterTap,
    required this.lineBarData,
    required this.labels,
    required this.minY,
    required this.maxY,
    required this.yAxisUnit,
    required this.hasData,
    this.legendItems,
    required this.timeRange,
    this.periodFilter,
    this.trendFilter,
  });

  // Global key for chart capture
  final GlobalKey _chartKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    // 动态计算 Y 轴范围（基于实际数据）
    double calculateDynamicMinY() {
      if (lineBarData.isEmpty) return 0;

      // 收集所有数据点的 Y 值
      final allValues = <double>[];
      for (final lineData in lineBarData) {
        allValues.addAll(lineData.spots.map((spot) => spot.y));
      }

      if (allValues.isEmpty) return 0;

      final minValue = allValues.reduce((a, b) => a < b ? a : b);
      // 向下取整到最近的10，但确保最小值不小于0
      double calculatedMin = (minValue ~/ 10) * 10 - 10;
      return calculatedMin < 0 ? 0 : calculatedMin; // 确保最小值不小于0
    }

    double calculateDynamicMaxY() {
      if (lineBarData.isEmpty) return 100;

      // 收集所有数据点的 Y 值
      final allValues = <double>[];
      for (final lineData in lineBarData) {
        allValues.addAll(lineData.spots.map((spot) => spot.y));
      }

      if (allValues.isEmpty) return 100;

      final maxValue = allValues.reduce((a, b) => a > b ? a : b);
      // 向上取整到最近的10，并留一些边距
      return (maxValue ~/ 10 + 1) * 10 + 10;
    }

    double calculateYInterval(double minY, double maxY) {
      final range = maxY - minY;
      if (range <= 20) return 5;
      if (range <= 50) return 10;
      if (range <= 100) return 20;
      return 50;
    }

    // 使用动态计算的 Y 轴范围
    final dynamicMinY = calculateDynamicMinY();
    final dynamicMaxY = calculateDynamicMaxY();
    final yInterval = calculateYInterval(dynamicMinY, dynamicMaxY);

    // 处理 X 轴标签：只显示日期部分，去掉时间
    List<String> getDateOnlyLabels() {
      return labels.map((label) {
        // 如果标签包含换行符（日期和时间），只取日期部分
        if (label.contains('\n')) {
          return label.split('\n')[0];
        }
        // 如果已经是纯日期，直接返回
        return label;
      }).toList();
    }

    final dateOnlyLabels = getDateOnlyLabels();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: darkMode ? TColors.darkerGrey : TColors.white,
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
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: darkMode ? TColors.white : TColors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Export Button
              ChartExportButton(
                exportData: _buildExportData(),
                tooltip: 'Export $title',
              ),
              const SizedBox(width: TSizes.xs),
              GestureDetector(
                onTap: onFilterTap,
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
          const SizedBox(height: TSizes.sm),

          /// Chart Legend
          if (legendItems != null && legendItems!.isNotEmpty)
            Wrap(
              spacing: TSizes.md,
              children: legendItems!.map((item) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: TSizes.xs),
                  Text(
                    item.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: darkMode ? TColors.grey : TColors.darkGrey,
                    ),
                  ),
                ],
              )).toList(),
            ),

          if (legendItems != null && legendItems!.isNotEmpty)
            const SizedBox(height: TSizes.md),

          /// Line Chart
          SizedBox(
            height: 200,
            child: hasData
                ? RepaintBoundary(
              key: _chartKey,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: yInterval, // 使用动态间隔
                    verticalInterval: dateOnlyLabels.length > 1 ? 1 : 0.5,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: darkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: darkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: yInterval, // 使用动态间隔
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}$yAxisUnit',
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
                        reservedSize: 30,
                        interval: 1, // 每个数据点都显示标签
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < dateOnlyLabels.length) {
                            return Text(
                              dateOnlyLabels[index],
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
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: (dateOnlyLabels.length - 1).toDouble(),
                  minY: dynamicMinY, // 使用动态计算的最小值
                  maxY: dynamicMaxY, // 使用动态计算的最大值
                  lineBarsData: lineBarData,
                  lineTouchData: LineTouchData(
                    touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                      if (response?.lineBarSpots != null && response!.lineBarSpots!.isNotEmpty) {
                        // Handle touch event
                      }
                    },
                  ),
                ),
              ),
            )
                : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.insert_chart_outlined,
                    size: 48,
                    color: darkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                  ),
                  const SizedBox(height: TSizes.sm),
                  Text(
                    'No Data Available',
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

  /// Build export data from chart data
  ChartExportData _buildExportData() {
    final exportData = <Map<String, dynamic>>[];

    // Convert chart data to exportable format
    for (int i = 0; i < labels.length; i++) {
      final Map<String, dynamic> row = {
        'Date/Time': labels[i], // 导出时保留完整信息
      };

      // Add data from each line series
      if (legendItems != null) {
        for (int lineIndex = 0; lineIndex < lineBarData.length && lineIndex < legendItems!.length; lineIndex++) {
          final lineData = lineBarData[lineIndex];
          final legendItem = legendItems![lineIndex];

          // Find spot data for this time point
          final spot = lineData.spots.firstWhere(
                (spot) => spot.x.toInt() == i,
            orElse: () => FlSpot(i.toDouble(), 0),
          );

          row[legendItem.label] = '${spot.y.toStringAsFixed(1)}$yAxisUnit';
        }
      } else {
        // Single line chart
        if (lineBarData.isNotEmpty) {
          final spot = lineBarData.first.spots.firstWhere(
                (spot) => spot.x.toInt() == i,
            orElse: () => FlSpot(i.toDouble(), 0),
          );
          row['Value'] = '${spot.y.toStringAsFixed(1)}$yAxisUnit';
        }
      }

      exportData.add(row);
    }

    return ChartExportData(
      title: title,
      data: exportData,
      chartKey: _chartKey,
      timeRange: timeRange,
      periodFilter: periodFilter,
      trendFilter: trendFilter,
      hasData: hasData,
    );
  }
}

class LegendItem {
  final String label;
  final Color color;

  LegendItem({
    required this.label,
    required this.color,
  });
}