import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/export_helper.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import 'chart_export_button.dart';

// Data models (unchanged)
class ChartBarData {
  final String label;
  final double value;
  final List<StackData>? stackData;
  final DateTime? startDate;
  final DateTime? endDate;

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

  final GlobalKey _chartKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);
    final hasValidData = !showNoData && data.isNotEmpty && data.any((item) => item.value > 0);

    if (showNoData || (data.isNotEmpty && data.every((item) => item.value == 0))) {
      return _buildNoDataView(darkMode);
    }

    return Column(
      children: [
        _buildHeader(darkMode),
        if (showLegend && legendItems.isNotEmpty)
          const SizedBox(height: TSizes.md),
        _buildGoalText(),
        _buildChart(darkMode),
      ],
    );
  }

  Widget _buildNoDataView(bool darkMode) {
    return Column(
      children: [
        _buildHeader(darkMode),
        if (showLegend && legendItems.isNotEmpty)
          const SizedBox(height: TSizes.md),
        if (goalValue != null) ...[
          _buildGoalText(),
          const SizedBox(height: TSizes.md),
        ],
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

  Widget _buildHeader(bool darkMode) {
    return Row(
      children: [
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
        ChartExportButton(
          exportData: _buildExportData(),
          tooltip: 'Export $title',
        ),
      ],
    );
  }

  Widget _buildGoalText() {
    if (goalValue == null) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: TSizes.md),
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
              unit == 'steps'
                  ? 'Daily Goal: ${goalValue!.toInt()} $unit'
                  : 'Weekly goal: ${goalValue!.toInt()} $unit',
              style: TextStyle(
                color: TColors.primary,
                fontSize: TSizes.fontSizeSm,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChart(bool darkMode) {
    return SizedBox(
      height: 200,
      child: Padding(
        padding: const EdgeInsets.only(
          top: TSizes.lg,
          right: TSizes.md,
        ),
        child: RepaintBoundary(
          key: _chartKey,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxValue,
              barTouchData: _buildBarTouchData(darkMode),
              titlesData: _buildTitlesData(darkMode),
              borderData: FlBorderData(show: false),
              gridData: _buildGridData(darkMode),
              extraLinesData: _buildExtraLinesData(),
              barGroups: _generateBarGroups(),
            ),
          ),
        ),
      ),
    );
  }

  BarTouchData _buildBarTouchData(bool darkMode) {
    return BarTouchData(
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
          if (group.x.toInt() >= 0 && group.x.toInt() < data.length) {
            final chartData = data[group.x.toInt()];
            if (chartData.stackData != null && chartData.stackData!.isNotEmpty) {
              return BarTooltipItem(
                '${chartData.label}\n',
                TextStyle(
                  color: darkMode ? TColors.white : TColors.black,
                  fontWeight: FontWeight.bold,
                ),
                children: chartData.stackData!
                    .map((stackItem) => TextSpan(
                  text: '${stackItem.value.toInt()} ${unit ?? 'min'}\n',
                  style: TextStyle(
                    color: stackItem.color,
                    fontWeight: FontWeight.normal,
                  ),
                ))
                    .toList(),
              );
            } else {
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
    );
  }

  FlTitlesData _buildTitlesData(bool darkMode) {
    return FlTitlesData(
      show: true,
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                    color: darkMode ? TColors.white : TColors.textPrimary,
                    fontSize: isWeekView ? 11 : 10, // 减小字体大小
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }
            return const Text('');
          },
          reservedSize: 32, // 增加底部空间
          interval: 1, // 确保每个标签都显示
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
                      color: darkMode ? TColors.white : TColors.textPrimary,
                      fontSize: TSizes.fontSizeSm,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  if (value == 0)
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
    );
  }

  FlGridData _buildGridData(bool darkMode) {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: maxValue / 4,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: darkMode ? TColors.darkGrey : TColors.grey,
          strokeWidth: 1,
        );
      },
    );
  }

  ExtraLinesData _buildExtraLinesData() {
    return ExtraLinesData(
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

      // 根据视图类型调整柱宽
      final barWidth = isWeekView ? 24.0 : 18.0;

      if (chartData.stackData != null && chartData.stackData!.isNotEmpty) {
        double currentY = 0;

        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: chartData.value,
              color: Colors.transparent,
              width: barWidth,
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
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: chartData.value,
              color: singleColor ?? TColors.primary,
              width: barWidth,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        );
      }
    }).toList();
  }

  ChartExportData _buildExportData() {
    final exportData = <Map<String, dynamic>>[];

    double totalValue = 0;
    double totalLowIntensity = 0;
    double totalModerateIntensity = 0;
    double totalHighIntensity = 0;

    for (int i = 0; i < data.length; i++) {
      final chartData = data[i];
      final Map<String, dynamic> row = {};

      if (isWeekView) {
        row['Period'] = _getWeeklyExportPeriodLabel(i, chartData);
      } else {
        row['Period'] = _getMonthlyExportPeriodLabel(i, chartData);
      }

      if (chartData.stackData != null && chartData.stackData!.isNotEmpty) {
        double rowTotalValue = 0;
        for (int j = 0; j < chartData.stackData!.length; j++) {
          final stackItem = chartData.stackData![j];
          final legendLabel = j < legendItems.length
              ? legendItems[j].label
              : 'Category ${j + 1}';
          row[legendLabel] = '${stackItem.value.toInt()} ${unit ?? ''}';
          rowTotalValue += stackItem.value;

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

        if (goalValue != null) {
          final progress = (rowTotalValue / goalValue! * 100).toStringAsFixed(1);
          row['Goal Progress'] = '$progress%';
        }
      } else {
        row['Value'] = '${chartData.value.toInt()} ${unit ?? ''}';
        totalValue += chartData.value;

        if (goalValue != null) {
          final progress = (chartData.value / goalValue! * 100).toStringAsFixed(1);
          row['Goal Progress'] = '$progress%';
        }
      }

      exportData.add(row);
    }

    if (exportData.isNotEmpty) {
      final totalRow = <String, dynamic>{'Period': 'TOTAL'};

      if (legendItems.isNotEmpty) {
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

      if (goalValue != null) {
        final totalProgress = (totalValue / goalValue! * 100).toStringAsFixed(1);
        totalRow['Goal Progress'] = '$totalProgress%';
      }

      exportData.add(totalRow);
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

  String _getWeeklyExportPeriodLabel(int index, ChartBarData chartData) {
    if (chartData.startDate != null) {
      final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      final dayName = days[chartData.startDate!.weekday % 7];
      return '$dayName (${chartData.startDate!.month}/${chartData.startDate!.day})';
    }
    return chartData.label;
  }

  String _getMonthlyExportPeriodLabel(int index, ChartBarData chartData) {
    if (chartData.startDate != null && chartData.endDate != null) {
      return '${chartData.startDate!.month}/${chartData.startDate!.day}';
    }
    return chartData.label;
  }

  String _getFormattedTimeRange() {
    if (timeRange.isEmpty) return '';

    if (timeRange.contains(RegExp(r'\d{4}'))) {
      return timeRange;
    }

    final currentYear = DateTime.now().year;

    if (timeRange.contains('-')) {
      final parts = timeRange.split(' - ');
      if (parts.length == 2) {
        return '${parts[0]}/$currentYear - ${parts[1]}/$currentYear';
      }
    } else if (timeRange.contains(' to ')) {
      final parts = timeRange.split(' to ');
      if (parts.length == 2) {
        return '${parts[0]} $currentYear to ${parts[1]} $currentYear';
      }
    }

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