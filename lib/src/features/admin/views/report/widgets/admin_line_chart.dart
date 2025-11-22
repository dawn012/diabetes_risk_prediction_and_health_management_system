import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../../utils/constants/admin_colors.dart';
import '../../../../../utils/helpers/export_helper.dart';
import '../../../../../utils/helpers/helper_functions.dart';

class AdminLineChart extends StatelessWidget {
  final List<FlSpot> spots;
  final List<String> xLabels;
  final double minY;
  final double maxY;
  final String yAxisUnit;
  final String title;
  final String timeRange;
  final Color lineColor;
  final bool showDots;
  final bool showArea;
  final GlobalKey? chartKey;
  final String? periodFilter;
  final String? trendFilter;
  final String yAxisLabel;
  final double horizontalInterval;
  final double leftTitleInterval;
  final bool showEmptyState; // New parameter

  const AdminLineChart({
    super.key,
    required this.spots,
    required this.xLabels,
    required this.minY,
    required this.maxY,
    required this.yAxisUnit,
    required this.title,
    required this.timeRange,
    this.lineColor = TAdminColors.primary,
    this.showDots = true,
    this.showArea = true,
    this.chartKey,
    this.periodFilter,
    this.trendFilter,
    this.yAxisLabel = '',
    required this.horizontalInterval,
    required this.leftTitleInterval,
    this.showEmptyState = false,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return RepaintBoundary(
      key: chartKey,
      child: Container(
        padding: const EdgeInsets.only(right: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (yAxisLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 8),
                child: Text(
                  yAxisLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                  ),
                ),
              ),
            Expanded(
              child: Stack(
                children: [
                  // Line chart with axes
                  LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: horizontalInterval,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: TAdminColors.getBorderColor(darkMode).withOpacity(
                                showEmptyState ? 0.15 : 0.3),
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: TAdminColors.getBorderColor(darkMode).withOpacity(
                                showEmptyState ? 0.15 : 0.3),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            interval: leftTitleInterval,
                            getTitlesWidget: (value, meta) {
                              String displayValue;
                              if (yAxisUnit.toLowerCase().contains('rm') ||
                                  yAxisUnit.toLowerCase().contains('revenue')) {
                                displayValue = 'RM${value.toInt()}';
                              } else {
                                displayValue = value.toInt().toString();
                              }

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  displayValue,
                                  style: TextStyle(
                                    color: TAdminColors.getOnSurfaceVariantColor(
                                        darkMode).withOpacity(showEmptyState ? 0.4 : 1.0),
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < xLabels.length) {
                                final label = xLabels[index];

                                if (label.contains('\n')) {
                                  final parts = label.split('\n');
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: SizedBox(
                                      height: 40,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            parts[0],
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: TAdminColors
                                                  .getOnSurfaceVariantColor(darkMode)
                                                  .withOpacity(showEmptyState ? 0.4 : 1.0),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            parts[1],
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: TAdminColors
                                                  .getOnSurfaceVariantColor(darkMode)
                                                  .withOpacity(showEmptyState ? 0.3 : 0.7),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                } else {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      label,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: TAdminColors
                                            .getOnSurfaceVariantColor(darkMode)
                                            .withOpacity(showEmptyState ? 0.4 : 1.0),
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                }
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: TAdminColors.getBorderColor(darkMode).withOpacity(
                              showEmptyState ? 0.3 : 1.0),
                        ),
                      ),
                      minX: 0,
                      maxX: (xLabels.length - 1).toDouble(),
                      minY: minY,
                      maxY: maxY,
                      lineBarsData: showEmptyState
                          ? [] // Don't show line if empty
                          : [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: lineColor,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: showDots,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: lineColor,
                                strokeWidth: 2,
                                strokeColor: TAdminColors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: showArea,
                            color: lineColor.withOpacity(0.1),
                            cutOffY: minY,
                            applyCutOffY: true,
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        enabled: !showEmptyState,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (touchedSpot) =>
                              TAdminColors.getSurfaceColor(darkMode),
                          tooltipBorder: BorderSide(
                            color: TAdminColors.getBorderColor(darkMode),
                          ),
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((touchedSpot) {
                              final index = touchedSpot.x.toInt();
                              final label = index < xLabels.length
                                  ? xLabels[index]
                                  : 'Unknown';
                              String valueText;
                              if (yAxisUnit.toLowerCase().contains('rm') ||
                                  yAxisUnit.toLowerCase().contains('revenue')) {
                                valueText = 'RM${touchedSpot.y.toStringAsFixed(2)}';
                              } else {
                                valueText = '${touchedSpot.y.toInt()} $yAxisUnit';
                              }
                              return LineTooltipItem(
                                '$label\n$valueText',
                                TextStyle(
                                  color: TAdminColors.getOnSurfaceColor(darkMode),
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),

                  // Empty state overlay
                  if (showEmptyState)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.show_chart_outlined,
                              size: 48,
                              color: TAdminColors.getOnSurfaceVariantColor(darkMode)
                                  .withOpacity(0.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No Data Available',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: TAdminColors.getOnSurfaceColor(darkMode)
                                    .withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Try adjusting your filters',
                              style: TextStyle(
                                fontSize: 13,
                                color: TAdminColors.getOnSurfaceVariantColor(darkMode)
                                    .withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ChartExportData getExportData() {
    final exportData = <Map<String, dynamic>>[];

    for (int i = 0; i < spots.length; i++) {
      final spot = spots[i];
      final label = i < xLabels.length ? xLabels[i] : 'Point ${i + 1}';

      String valueText;
      if (yAxisUnit.toLowerCase().contains('rm') ||
          yAxisUnit.toLowerCase().contains('revenue')) {
        valueText = 'RM${spot.y.toStringAsFixed(2)}';
      } else {
        valueText = '${spot.y.toInt()} $yAxisUnit';
      }

      exportData.add({
        'Period': label,
        'Value': valueText,
      });
    }

    return ChartExportData(
      title: title,
      data: exportData,
      chartKey: chartKey!,
      timeRange: timeRange,
      periodFilter: periodFilter,
      trendFilter: trendFilter,
      hasData: !showEmptyState && spots.isNotEmpty && spots.any((spot) => spot.y > 0),
    );
  }
}