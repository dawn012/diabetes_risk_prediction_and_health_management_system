import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/export_helper.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import 'chart_export_button.dart';

// Data models
class ChartBarData {
  final String label;
  final double value;
  final List<StackData>? stackData;
  final DateTime? startDate;    // 时间段的开始日期
  final DateTime? endDate;      // 时间段的结束日期

  ChartBarData({
    required this.label,
    required this.value,
    this.stackData,
    this.startDate,
    this.endDate,
  });
}

class StackData {
  final double value;
  final Color color;

  StackData({
    required this.value,
    required this.color,
  });
}

class LegendItem {
  final Color color;
  final String label;

  const LegendItem({
    required this.color,
    required this.label,
  });
}

// Main chart widget with export functionality
class ActivityBarChart extends StatelessWidget {
  final List<ChartBarData> data;
  final bool isWeekView;
  final double maxValue;
  final double? goalValue;
  final bool showLegend;
  final List<LegendItem> legendItems;
  final Color? singleColor;
  final String? unit;
  final bool showNoData;
  final String title;
  final String timeRange;
  final String? periodFilter;
  final String? trendFilter;

  ActivityBarChart({
    super.key,
    required this.data,
    required this.isWeekView,
    required this.maxValue,
    this.goalValue,
    this.showLegend = false,
    this.legendItems = const [],
    this.singleColor,
    this.unit,
    this.showNoData = false,
    this.title = 'Activity Chart',
    this.timeRange = '',
    this.periodFilter,
    this.trendFilter,
  });

  // Global key for chart capture
  final GlobalKey _chartKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);
    final hasValidData = !showNoData && data.isNotEmpty && data.any((item) => item.value > 0);

    // Check if we should show "No Data"
    if (showNoData || (data.isNotEmpty && data.every((item) => item.value == 0))) {
      return Column(
        children: [
          // Header with export button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Legend
              if (showLegend && legendItems.isNotEmpty)
                Expanded(
                  child: Wrap(
                    spacing: TSizes.md,
                    runSpacing: TSizes.xs,
                    children: legendItems
                        .map((item) => _buildLegendItem(item, darkMode))
                        .toList(),
                  ),
                ),

              // Export Button
              ChartExportButton(
                exportData: _buildExportData(),
                tooltip: 'Export $title',
              ),
            ],
          ),

          if (showLegend && legendItems.isNotEmpty)
            const SizedBox(height: TSizes.md),

          // Goal line text
          if (goalValue != null) ...[
            Row(
              children: [
                Container(
                  width: 20,
                  height: 2,
                  child: CustomPaint(
                    painter: DashedLinePainter(color: TColors.primary),
                  ),
                ),
                const SizedBox(width: TSizes.xs),
                Text(
                  'Daily Goal: ${goalValue!.toInt()} ${unit ?? 'steps'}',
                  style: TextStyle(
                    color: TColors.primary,
                    fontSize: TSizes.fontSizeSm,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TSizes.md),
          ],

          // No Data Message
          SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 48,
                    color: TColors.textSecondary,
                  ),
                  const SizedBox(height: TSizes.md),
                  Text(
                    'No Data',
                    style: TextStyle(
                      color: TColors.textSecondary,
                      fontSize: TSizes.fontSizeLg,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        // Header with Legend and Export
        Row(
          children: [
            // Legend
            if (showLegend && legendItems.isNotEmpty)
              Expanded(
                child: Wrap(
                  spacing: TSizes.md,
                  runSpacing: TSizes.xs,
                  children: legendItems
                      .map((item) => _buildLegendItem(item, darkMode))
                      .toList(),
                ),
              ),

            // Export Button
            ChartExportButton(
              exportData: _buildExportData(),
              tooltip: 'Export $title',
            ),
          ],
        ),

        if (showLegend && legendItems.isNotEmpty)
          const SizedBox(height: TSizes.md),

        // Goal line text (only for steps)
        if (goalValue != null && unit == 'steps') ...[
          Row(children: [
            Container(
              width: 20,
              height: 2,
              child: CustomPaint(
                painter: DashedLinePainter(color: TColors.primary),
              ),
            ),
            const SizedBox(width: TSizes.xs),
            Text(
              'Daily Goal: ${goalValue!.toInt()} ${unit ?? 'steps'}',
              style: TextStyle(
                color: TColors.primary,
                fontSize: TSizes.fontSizeSm,
              ),
            ),
          ]),
          const SizedBox(height: TSizes.md),
        ],

        // Weekly goal line text (for exercise)
        if (goalValue != null && unit == 'min') ...[
          Row(
            children: [
              Container(
                width: 20,
                height: 2,
                child: CustomPaint(
                  painter: DashedLinePainter(color: TColors.primary),
                ),
              ),
              const SizedBox(width: TSizes.xs),
              Text(
                'Weekly goal: ${goalValue!.toInt()} ${unit ?? 'min'}',
                style: TextStyle(
                  color: TColors.primary,
                  fontSize: TSizes.fontSizeSm,
                ),
              ),
            ],
          ),
          const SizedBox(height: TSizes.md),
        ],

        // Chart - 这是主要的图表显示部分
        SizedBox(
          height: 200,
          child: Padding(
            padding: const EdgeInsets.only(
              top: TSizes.md,
              right: TSizes.md,
            ),
            child: RepaintBoundary(
              key: _chartKey,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxValue,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) =>
                      darkMode ? TColors.darkContainer : Colors.white,
                      tooltipBorder: BorderSide(
                        color: darkMode
                            ? TColors.borderPrimary
                            : TColors.borderSecondary,
                      ),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        if (group.x.toInt() >= 0 &&
                            group.x.toInt() < data.length) {
                          final chartData = data[group.x.toInt()];
                          if (chartData.stackData != null &&
                              chartData.stackData!.isNotEmpty) {
                            // Stacked bar tooltip
                            return BarTooltipItem(
                              '${chartData.label}\n',
                              TextStyle(
                                color: darkMode ? TColors.white : TColors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              children: chartData.stackData!
                                  .map((stackItem) => TextSpan(
                                text:
                                '${stackItem.value.toInt()} ${unit ?? 'min'}\n',
                                style: TextStyle(
                                  color: stackItem.color,
                                  fontWeight: FontWeight.normal,
                                ),
                              ))
                                  .toList(),
                            );
                          } else {
                            // Single bar tooltip
                            return BarTooltipItem(
                              '${chartData.label}\n${chartData.value.toInt()} ${unit ?? 'steps'}',
                              TextStyle(
                                color: darkMode ? TColors.white : TColors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value.toInt() >= 0 && value.toInt() < data.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: TSizes.xs),
                              child: Text(
                                data[value.toInt()].label,
                                style: TextStyle(
                                  color: darkMode
                                      ? TColors.white
                                      : TColors.textPrimary,
                                  fontSize: TSizes.fontSizeSm,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        interval: maxValue / 4,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: TSizes.xs),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    color: darkMode
                                        ? TColors.white
                                        : TColors.textPrimary,
                                    fontSize: TSizes.fontSizeSm,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                                if (value == 0) // Show unit label only at bottom
                                  Text(
                                    unit ?? '',
                                    style: TextStyle(
                                      color: darkMode
                                          ? TColors.textSecondary
                                          : TColors.textSecondary,
                                      fontSize: TSizes.fontSizeSm,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxValue / 4,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: darkMode ? TColors.darkGrey : TColors.grey,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: goalValue != null
                        ? [
                      HorizontalLine(
                        y: goalValue!,
                        color: TColors.primary,
                        strokeWidth: 2,
                        dashArray: [5, 5],
                      ),
                    ]
                        : [],
                  ),
                  barGroups: _generateBarGroups(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(LegendItem item, bool darkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: item.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: TSizes.xs),
        Text(
          item.label,
          style: TextStyle(
            color: darkMode ? TColors.white : TColors.textPrimary,
            fontSize: TSizes.fontSizeSm,
          ),
        ),
      ],
    );
  }

  List<BarChartGroupData> _generateBarGroups() {
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final chartData = entry.value;

      if (chartData.stackData != null && chartData.stackData!.isNotEmpty) {
        // Stacked bar (same day, different intensities)
        double currentY = 0;
        final barRods = <BarChartRodData>[];

        for (final stackItem in chartData.stackData!) {
          barRods.add(BarChartRodData(
            fromY: currentY,
            toY: currentY + stackItem.value,
            color: stackItem.color,
            width: isWeekView ? 20 : 16,
            borderRadius: currentY == 0
                ? const BorderRadius.only(
              bottomLeft: Radius.circular(2),
              bottomRight: Radius.circular(2),
            )
                : stackItem == chartData.stackData!.last
                ? const BorderRadius.only(
              topLeft: Radius.circular(2),
              topRight: Radius.circular(2),
            )
                : BorderRadius.zero,
          ));
          currentY += stackItem.value;
        }

        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: currentY,
              color: Colors.transparent,
              width: isWeekView ? 20 : 16,
              rodStackItems: chartData.stackData!.map((stackItem) {
                final startY = chartData.stackData!
                    .take(chartData.stackData!.indexOf(stackItem))
                    .fold(0.0, (sum, item) => sum + item.value);
                return BarChartRodStackItem(
                    startY, startY + stackItem.value, stackItem.color);
              }).toList(),
            ),
          ],
        );
      } else {
        // Single bar
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: chartData.value,
              color: singleColor ?? TColors.primary,
              width: isWeekView ? 20 : 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2),
                topRight: Radius.circular(2),
              ),
            ),
          ],
        );
      }
    }).toList();
  }

  /// Build export data from chart data
  ChartExportData _buildExportData() {
    final exportData = <Map<String, dynamic>>[];

    debugPrint('=== Chart Data Debug ===');
    debugPrint('isWeekView: $isWeekView');
    debugPrint('data length: ${data.length}');
    for (int i = 0; i < data.length; i++) {
      debugPrint('Data $i - label: "${data[i].label}", value: ${data[i].value}');
      debugPrint('Data $i - startDate: ${data[i].startDate}, endDate: ${data[i].endDate}');
    }

    // 计算总计
    double totalValue = 0;
    double totalLowIntensity = 0;
    double totalModerateIntensity = 0;
    double totalHighIntensity = 0;

    for (int i = 0; i < data.length; i++) {
      final chartData = data[i];
      final Map<String, dynamic> row = {};

      // 使用传入的日期信息生成正确的 Period 格式
      if (isWeekView) {
        // 周视图: Sun (10/26), Mon (10/27) 等
        row['Period'] = _getWeeklyExportPeriodLabel(i, chartData);
      } else {
        // 月视图: Week 1 (10/26 - 11/1), Week 2 (11/2 - 11/8) 等
        row['Period'] = _getMonthlyExportPeriodLabel(i, chartData);
      }

      if (chartData.stackData != null && chartData.stackData!.isNotEmpty) {
        // Stacked data - add each stack as separate column
        double rowTotalValue = 0;
        for (int j = 0; j < chartData.stackData!.length; j++) {
          final stackItem = chartData.stackData![j];
          final legendLabel = j < legendItems.length
              ? legendItems[j].label
              : 'Category ${j + 1}';
          row[legendLabel] = '${stackItem.value.toInt()} ${unit ?? ''}';
          rowTotalValue += stackItem.value;

          // 累加各强度类型的总计
          if (legendLabel.toLowerCase().contains('low')) {
            totalLowIntensity += stackItem.value;
          } else if (legendLabel.toLowerCase().contains('moderate')) {
            totalModerateIntensity += stackItem.value;
          } else if (legendLabel.toLowerCase().contains('high')) {
            totalHighIntensity += stackItem.value;
          }
        }
        row['Total'] = '${rowTotalValue.toInt()} ${unit ?? ''}';
        totalValue += rowTotalValue;

        // Goal Progress 计算
        if (goalValue != null) {
          final progress = (rowTotalValue / goalValue! * 100).toStringAsFixed(1);
          row['Goal Progress'] = '$progress%';
        }
      } else {
        // Single value data
        row['Value'] = '${chartData.value.toInt()} ${unit ?? ''}';
        totalValue += chartData.value;

        // Goal Progress 计算
        if (goalValue != null) {
          final progress = (chartData.value / goalValue! * 100).toStringAsFixed(1);
          row['Goal Progress'] = '$progress%';
        }
      }

      exportData.add(row);
    }

    // 添加总计行
    if (exportData.isNotEmpty) {
      final totalRow = <String, dynamic>{'Period': 'TOTAL'};

      if (legendItems.isNotEmpty) {
        // 如果有图例项，添加各强度类型的总计
        for (final legend in legendItems) {
          if (legend.label.toLowerCase().contains('low')) {
            totalRow[legend.label] = '${totalLowIntensity.toInt()} ${unit ?? ''}';
          } else if (legend.label.toLowerCase().contains('moderate')) {
            totalRow[legend.label] = '${totalModerateIntensity.toInt()} ${unit ?? ''}';
          } else if (legend.label.toLowerCase().contains('high')) {
            totalRow[legend.label] = '${totalHighIntensity.toInt()} ${unit ?? ''}';
          }
        }
      }

      totalRow['Total'] = '${totalValue.toInt()} ${unit ?? ''}';

      // 总计行的 Goal Progress 计算
      if (goalValue != null) {
        final totalProgress = (totalValue / goalValue! * 100).toStringAsFixed(1);
        totalRow['Goal Progress'] = '$totalProgress%';
      }

      exportData.add(totalRow);
    }

    // 调试信息：检查导出的数据
    debugPrint('=== Export Data Debug ===');
    debugPrint('Title: $title');
    debugPrint('Time Range: ${_getFormattedTimeRange()}');
    debugPrint('Data count: ${exportData.length}');
    if (exportData.isNotEmpty) {
      debugPrint('First row Period: ${exportData.first['Period']}');
      debugPrint('First row keys: ${exportData.first.keys.toList()}');
    }

    return ChartExportData(
      title: title,
      data: exportData,
      chartKey: _chartKey,
      timeRange: _getFormattedTimeRange(),
      periodFilter: periodFilter,
      trendFilter: trendFilter,
      hasData: !showNoData && data.isNotEmpty && data.any((item) => item.value > 0),
    );
  }

  /// 生成周视图导出的 Period 标签（使用传入的日期）
  String _getWeeklyExportPeriodLabel(int index, ChartBarData chartData) {
    if (chartData.startDate != null) {
      // 使用传入的日期，格式: "Mon (10/28)"
      final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      final dayName = days[chartData.startDate!.weekday % 7];
      return '$dayName (${chartData.startDate!.month}/${chartData.startDate!.day})';
    }

    // 回退到原来的逻辑
    return chartData.label;
  }

  /// 生成月视图导出的 Period 标签（使用传入的日期）
  String _getMonthlyExportPeriodLabel(int index, ChartBarData chartData) {
    if (chartData.startDate != null && chartData.endDate != null) {
      // 导出也使用简化的开始日期，与图表显示保持一致
      return '${chartData.startDate!.month}/${chartData.startDate!.day}';
    }

    // 回退到原来的逻辑
    return chartData.label;
  }

  /// 格式化时间范围，添加年份
  String _getFormattedTimeRange() {
    if (timeRange.isEmpty) return '';

    // 检查是否已经包含年份
    if (timeRange.contains(RegExp(r'\d{4}'))) {
      return timeRange;
    }

    final currentYear = DateTime.now().year;

    // 处理不同的时间范围格式
    if (timeRange.contains('-')) {
      // 格式如: "10/26 - 11/1"
      final parts = timeRange.split(' - ');
      if (parts.length == 2) {
        return '${parts[0]}/$currentYear - ${parts[1]}/$currentYear';
      }
    } else if (timeRange.contains(' to ')) {
      // 格式如: "Oct 26 to Nov 1"
      final parts = timeRange.split(' to ');
      if (parts.length == 2) {
        return '${parts[0]} $currentYear to ${parts[1]} $currentYear';
      }
    }

    // 如果无法解析，直接添加年份
    return '$timeRange $currentYear';
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 3.0;
    const dashSpace = 2.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}