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

  ChartBarData({
    required this.label,
    required this.value,
    this.stackData,
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

        // Chart
        SizedBox(
          height: 200,
          child: Padding(
            padding: const EdgeInsets.only(right: TSizes.md),
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

    for (final chartData in data) {
      final Map<String, dynamic> row = {
        'Period': chartData.label,
      };

      if (chartData.stackData != null && chartData.stackData!.isNotEmpty) {
        // Stacked data - add each stack as separate column
        double totalValue = 0;
        for (int i = 0; i < chartData.stackData!.length; i++) {
          final stackItem = chartData.stackData![i];
          final legendLabel = i < legendItems.length
              ? legendItems[i].label
              : 'Category ${i + 1}';
          row[legendLabel] = '${stackItem.value.toInt()} ${unit ?? ''}';
          totalValue += stackItem.value;
        }
        row['Total'] = '${totalValue.toInt()} ${unit ?? ''}';
      } else {
        // Single value data
        row['Value'] = '${chartData.value.toInt()} ${unit ?? ''}';
      }

      // Add goal comparison if applicable
      if (goalValue != null) {
        final progress = (chartData.value / goalValue! * 100).toStringAsFixed(1);
        row['Goal Progress'] = '$progress%';
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
      hasData: !showNoData && data.isNotEmpty && data.any((item) => item.value > 0),
    );
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