import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../../utils/constants/admin_colors.dart';
import '../../../../../utils/helpers/export_helper.dart';
import '../../../../../utils/helpers/helper_functions.dart';

class AdminBarChart extends StatelessWidget {
  final List<BarChartGroupData> barGroups;
  final List<String> xLabels;
  final double minY;
  final double maxY;
  final String yAxisUnit;
  final String title;
  final String timeRange;
  final Color barColor;
  final GlobalKey? chartKey;
  final String? periodFilter;
  final String? trendFilter;
  final String yAxisLabel;
  final bool showEmptyState; // New parameter

  const AdminBarChart({
    super.key,
    required this.barGroups,
    required this.xLabels,
    required this.minY,
    required this.maxY,
    required this.yAxisUnit,
    required this.title,
    required this.timeRange,
    this.barColor = TAdminColors.primary,
    this.chartKey,
    this.periodFilter,
    this.trendFilter,
    this.yAxisLabel = '',
    this.showEmptyState = false,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return RepaintBoundary(
      key: chartKey,
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
                // Bar chart with axes
                BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    minY: minY,
                    barTouchData: BarTouchData(
                      enabled: !showEmptyState,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) =>
                            TAdminColors.getSurfaceColor(darkMode),
                        tooltipBorder: BorderSide(
                          color: TAdminColors.getBorderColor(darkMode),
                        ),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final index = group.x.toInt();
                          final label =
                          index < xLabels.length ? xLabels[index] : 'Unknown';
                          return BarTooltipItem(
                            '$label\n',
                            TextStyle(
                              color: TAdminColors.getOnSurfaceColor(darkMode),
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: '${rod.toY.toInt()} $yAxisUnit',
                                style: TextStyle(
                                  color: barColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          interval: _calculateLeftTitleInterval(),
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                value.toInt().toString(),
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
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: _calculateGridInterval(),
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: TAdminColors.getBorderColor(darkMode).withOpacity(
                              showEmptyState ? 0.15 : 0.3),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    barGroups: showEmptyState
                        ? [] // Don't show bars if empty
                        : barGroups,
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
                            Icons.bar_chart_outlined,
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
    );
  }

  double _calculateLeftTitleInterval() {
    final range = maxY - minY;
    if (range <= 0) return 1;

    double interval = range / 4;

    if (interval <= 1) return 1;
    if (interval <= 5) return 5;
    if (interval <= 10) return 10;
    if (interval <= 25) return 25;
    if (interval <= 50) return 50;
    if (interval <= 100) return 100;

    return (interval / 100).ceil() * 100;
  }

  double _calculateGridInterval() {
    final range = maxY - minY;
    if (range <= 0) return 1;

    double interval = range / 4;

    if (interval <= 1) return 1;
    if (interval <= 5) return 5;
    if (interval <= 10) return 10;
    if (interval <= 25) return 25;
    if (interval <= 50) return 50;
    if (interval <= 100) return 100;

    return (interval / 100).ceil() * 100;
  }

  ChartExportData getExportData() {
    final exportData = <Map<String, dynamic>>[];

    for (final group in barGroups) {
      final index = group.x.toInt();
      final label = index < xLabels.length ? xLabels[index] : 'Bar ${index + 1}';
      final value = group.barRods.isNotEmpty ? group.barRods.first.toY : 0;

      exportData.add({
        'Period': label,
        'Value': '${value.toInt()} $yAxisUnit',
      });
    }

    return ChartExportData(
      title: title,
      data: exportData,
      chartKey: chartKey!,
      timeRange: timeRange,
      periodFilter: periodFilter,
      trendFilter: trendFilter,
      hasData: !showEmptyState &&
          barGroups.isNotEmpty &&
          barGroups.any((group) =>
          group.barRods.isNotEmpty && group.barRods.first.toY > 0),
    );
  }
}