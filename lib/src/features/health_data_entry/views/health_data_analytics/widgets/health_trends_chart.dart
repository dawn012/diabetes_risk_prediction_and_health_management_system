import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/formatters/formatter.dart';
import '../../../../../utils/helpers/export_helper.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import 'chart_export_button.dart';

class HealthTrendsChart extends StatelessWidget {
  final String title;
  final String selectedFilter;
  final VoidCallback? onFilterTap;
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
  final double trendValue;
  final String trendDirection;
  final List<DateTime>? originalDateTimes;
  final bool showFilterButton;

  HealthTrendsChart({
    super.key,
    required this.title,
    required this.selectedFilter,
    this.onFilterTap,
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
    this.trendValue = 0.0,
    this.trendDirection = '',
    this.originalDateTimes,
    this.showFilterButton = true, // 默认为 true
  });

  final GlobalKey _chartKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    // 智能计算最小值
    double _calculateOptimalMin(double minValue) {
      if (minValue <= 0) return 0;

      // 根据数值范围确定合适的下限
      if (minValue <= 10) return 0;
      if (minValue <= 50) return (minValue ~/ 10) * 10 - 10;
      if (minValue <= 100) return (minValue ~/ 10) * 10 - 20;
      return (minValue ~/ 50) * 50 - 50;
    }

    // 智能计算最大值
    double _calculateOptimalMax(double maxValue) {
      if (maxValue <= 10) return (maxValue.ceilToDouble() ~/ 2) * 2 + 2;
      if (maxValue <= 50) return (maxValue.ceilToDouble() ~/ 5) * 5 + 5;
      if (maxValue <= 100) return (maxValue.ceilToDouble() ~/ 10) * 10 + 10;
      if (maxValue <= 500) return (maxValue.ceilToDouble() ~/ 25) * 25 + 25;
      return (maxValue.ceilToDouble() ~/ 50) * 50 + 50;
    }

    double calculateDynamicMinY() {
      if (lineBarData.isEmpty) return 0;

      final allValues = <double>[];
      for (final lineData in lineBarData) {
        allValues.addAll(lineData.spots.map((spot) => spot.y));
      }

      if (allValues.isEmpty) return 0;

      final minValue = allValues.reduce((a, b) => a < b ? a : b);
      // 使用更智能的最小值计算
      double calculatedMin = _calculateOptimalMin(minValue);
      return calculatedMin < 0 ? 0 : calculatedMin;
    }

    double calculateDynamicMaxY() {
      if (lineBarData.isEmpty) return 100;

      final allValues = <double>[];
      for (final lineData in lineBarData) {
        allValues.addAll(lineData.spots.map((spot) => spot.y));
      }

      if (allValues.isEmpty) return 100;

      final maxValue = allValues.reduce((a, b) => a > b ? a : b);
      // 使用更智能的最大值计算
      return _calculateOptimalMax(maxValue);
    }

    // 根据range确定合适的间隔
    double calculateOptimalInterval(double range) {
      if (range <= 10) return 2;
      if (range <= 20) return 5;
      if (range <= 50) return 10;
      if (range <= 100) return 20;
      if (range <= 200) return 25;
      if (range <= 500) return 50;
      return 100;
    }

    // 生成所有Y轴标签值，确保显示完整
    List<double> generateYAxisValues(double minY, double maxY) {
      final range = maxY - minY;
      final interval = calculateOptimalInterval(range);

      final List<double> values = [];
      double current = minY;

      // 确保不超过最大值
      while (current <= maxY + interval) {
        values.add(current);
        current += interval;

        // 防止无限循环
        if (values.length > 20) break;
      }

      return values;
    }

    final dynamicMinY = calculateDynamicMinY();
    final dynamicMaxY = calculateDynamicMaxY();
    final yAxisValues = generateYAxisValues(dynamicMinY, dynamicMaxY);

    List<String> getDateOnlyLabels() {
      return labels.map((label) {
        if (label.contains('\n')) {
          return label.split('\n')[0];
        }
        return label;
      }).toList();
    }

    final dateOnlyLabels = getDateOnlyLabels();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: darkMode ? TColors.dark : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        border: Border.all(
          color: darkMode ? TColors.dark : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              /// Title and trend indicator section
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    /// Title
                    Expanded(
                      child: Text(
                        title,
                        style: Theme
                            .of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                          color: darkMode ? TColors.white : TColors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    /// Trend indicator
                    if (trendDirection.isNotEmpty) ...[
                      const SizedBox(width: TSizes.sm),
                      if (trendDirection == 'no change')
                        Text(
                          '--',
                          style: Theme
                              .of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                            color: TColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              trendDirection == 'up'
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: TColors.primary,
                              size: 16,
                            ),
                            const SizedBox(width: TSizes.xs),
                            Text(
                              trendValue.toStringAsFixed(1),
                              style: Theme
                                  .of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                color: darkMode
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: TSizes.md),

              /// Export button and filter
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChartExportButton(
                    exportData: _buildExportData(),
                    tooltip: 'Export $title',
                  ),
                  const SizedBox(width: TSizes.xs),

                  /// Filter - 根据 showFilterButton 决定是否显示
                  if (showFilterButton)
                    GestureDetector(
                      onTap: onFilterTap, // 直接使用，如果为 null 则不会响应点击
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery
                                  .of(context)
                                  .size
                                  .width * 0.25,
                            ),
                            child: Text(
                              selectedFilter,
                              style: const TextStyle(
                                color: TColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
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
            ],
          ),

          const SizedBox(height: TSizes.sm),

          /// Legend items
          if (legendItems != null && legendItems!.isNotEmpty)
            Wrap(
              spacing: TSizes.md,
              children: legendItems!.map((item) =>
                  Row(
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
                        style: Theme
                            .of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                          color: darkMode ? TColors.grey : TColors.darkGrey,
                        ),
                      ),
                    ],
                  )).toList(),
            ),

          if (legendItems != null && legendItems!.isNotEmpty)
            const SizedBox(height: TSizes.md),

          /// Y轴单位标签
          if (hasData && yAxisUnit.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 40, bottom: 4),
              child: Text(
                yAxisUnit,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: darkMode ? TColors.white : TColors.black,
                ),
              ),
            ),

          /// Line Chart
          SizedBox(
            height: 220,
            child: hasData
                ? RepaintBoundary(
              key: _chartKey,
              child: Padding(
                padding: const EdgeInsets.only(
                  right: 12, // 右边增加内边距
                  top: 12, // 顶部增加内边距
                  bottom: 8,
                ),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: 1,
                      verticalInterval: dateOnlyLabels.length > 1 ? 1 : 0.5,
                      getDrawingHorizontalLine: (value) {
                        if (yAxisValues.contains(value)) {
                          return FlLine(
                            color: darkMode ? Colors.grey.shade700 : Colors.grey
                                .shade300,
                            strokeWidth: 1,
                          );
                        }
                        return const FlLine(color: Colors.transparent);
                      },
                      getDrawingVerticalLine: (value) =>
                          FlLine(
                            color: darkMode ? Colors.grey.shade700 : Colors.grey
                                .shade300,
                            strokeWidth: 1,
                          ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 45, // 增加左边保留空间
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (yAxisValues.contains(value)) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: darkMode ? TColors.white : TColors
                                        .black,
                                  ),
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
                          reservedSize: 35, // 增加底部保留空间
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < dateOnlyLabels.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  dateOnlyLabels[index],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: darkMode ? TColors.white : TColors
                                        .black,
                                  ),
                                ),
                              );
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
                        color: darkMode ? Colors.grey.shade700 : Colors.grey
                            .shade300,
                        width: 1,
                      ),
                    ),
                    minX: 0,
                    maxX: (dateOnlyLabels.length - 1).toDouble(),
                    minY: dynamicMinY,
                    maxY: dynamicMaxY,
                    lineBarsData: lineBarData,
                    lineTouchData: LineTouchData(
                      touchCallback: (FlTouchEvent event,
                          LineTouchResponse? response) {
                        if (response?.lineBarSpots != null &&
                            response!.lineBarSpots!.isNotEmpty) {
                          // Handle touch event
                        }
                      },
                    ),
                    clipData: const FlClipData.none(),
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
                    color: darkMode ? Colors.grey.shade600 : Colors.grey
                        .shade300,
                  ),
                  const SizedBox(height: TSizes.sm),
                  Text(
                    'No Data Available',
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                      color: darkMode ? Colors.grey.shade500 : Colors.grey
                          .shade400,
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

  ChartExportData _buildExportData() {
    final exportData = <Map<String, dynamic>>[];

    // 检查是否有原始日期时间数据
    if (originalDateTimes != null && originalDateTimes!.isNotEmpty) {
      print("Using original date times for export");

      for (int i = 0; i < originalDateTimes!.length; i++) {
        String formattedDateTime = TFormatter.formatDateTime(originalDateTimes![i]);
        final Map<String, dynamic> row = {'Date & Time': formattedDateTime};

        // 强制检查血压数据的列生成
        if (lineBarData.isNotEmpty) {
          for (int lineIndex = 0; lineIndex < lineBarData.length; lineIndex++) {
            final lineData = lineBarData[lineIndex];

            String columnLabel;
            if (legendItems != null && lineIndex < legendItems!.length) {
              final legendItem = legendItems![lineIndex];
              columnLabel = '${legendItem.label} ($yAxisUnit)';
            } else if (lineBarData.length == 1) {
              columnLabel = 'Value ($yAxisUnit)';
            } else {
              columnLabel = 'Series ${lineIndex + 1} ($yAxisUnit)';
            }

            double? value;
            if (i < lineData.spots.length) {
              value = lineData.spots[i].y;
            }

            if (value != null) {
              row[columnLabel] = yAxisUnit == 'mmHg' || yAxisUnit == 'bpm'
                  ? value.toStringAsFixed(0)
                  : value.toStringAsFixed(1);
            } else {
              row[columnLabel] = '';
            }

            // 特别标记血压数据
            if (columnLabel.contains('Systolic') || columnLabel.contains('Diastolic')) {
              print("💉 BLOOD PRESSURE COLUMN: $columnLabel = ${row[columnLabel]}");
            }
          }
        }

        exportData.add(row);
      }
    } else {
      print("Using label parsing for export");
      // 回退方案：使用标签解析
      for (int i = 0; i < labels.length; i++) {
        // 格式化日期时间为 "17 Oct 2025 21:28" 格式
        String formattedDateTime = _formatDateTimeLabel(labels[i]);

        final Map<String, dynamic> row = {
          'Date & Time': formattedDateTime,
        };

        // 动态生成数据列
        if (lineBarData.isNotEmpty) {
          for (int lineIndex = 0; lineIndex < lineBarData.length; lineIndex++) {
            final lineData = lineBarData[lineIndex];

            // 获取对应的图例标签
            String columnLabel;
            if (legendItems != null && lineIndex < legendItems!.length) {
              final legendItem = legendItems![lineIndex];
              columnLabel = '${legendItem.label} ($yAxisUnit)';
            } else if (lineBarData.length == 1) {
              columnLabel = 'Value ($yAxisUnit)';
            } else {
              columnLabel = 'Series ${lineIndex + 1} ($yAxisUnit)';
            }

            // 获取数据点
            double? value;
            if (i < lineData.spots.length) {
              value = lineData.spots[i].y;
            }

            // 添加数据列
            if (value != null) {
              if (yAxisUnit == 'mmHg' || yAxisUnit == 'bpm') {
                row[columnLabel] = value.toStringAsFixed(0);
              } else {
                row[columnLabel] = value.toStringAsFixed(1);
              }
            } else {
              row[columnLabel] = '';
            }

            print("Row $i, Column $columnLabel: ${row[columnLabel]}");
          }
        }

        exportData.add(row);
      }
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

  /// 格式化日期时间标签为 "17 Oct 2025 21:28" 格式
  String _formatDateTimeLabel(String label) {
    try {
      print("Label: $label");

      // 如果标签包含换行符，先合并
      String cleanLabel = label.replaceAll('\n', ' ');

      // 首先尝试解析 "MM/dd" 格式（从您的日志看是这种格式）
      if (cleanLabel.contains('/')) {
        final parts = cleanLabel.split(' ');
        if (parts.isNotEmpty) {
          final dateParts = parts[0].split('/');
          if (dateParts.length == 2) {
            final now = DateTime.now();
            final month = int.tryParse(dateParts[0]);
            final day = int.tryParse(dateParts[1]);

            if (month != null && day != null) {
              DateTime dateTime = DateTime(now.year, month, day);

              // 如果有时间部分，尝试解析
              if (parts.length >= 2 && parts[1].contains(':')) {
                final timeParts = parts[1].split(':');
                if (timeParts.length == 2) {
                  final hour = int.tryParse(timeParts[0]);
                  final minute = int.tryParse(timeParts[1]);
                  if (hour != null && minute != null) {
                    dateTime = DateTime(now.year, month, day, hour, minute);
                  }
                }
              }

              // 使用 TFormatter.formatDateTime
              return TFormatter.formatDateTime(dateTime);
            }
          }
        }
      }

      // 尝试解析 ISO 格式
      DateTime? dateTime = DateTime.tryParse(cleanLabel);

      // 如果解析成功，使用 TFormatter 格式化
      if (dateTime != null) {
        return TFormatter.formatDateTime(dateTime);
      }

      // 简单的回退：返回原始标签但确保是一行
      return cleanLabel;
    } catch (e) {
      print("Error formatting date label: $e");
      // 如果格式化失败，返回原始标签（确保是一行）
      return label.replaceAll('\n', ' ');
    }
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