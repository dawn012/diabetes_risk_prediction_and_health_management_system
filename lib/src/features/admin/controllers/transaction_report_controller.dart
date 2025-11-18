import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../data/repositories/subscription/payment_repository.dart';
import '../../../utils/constants/admin_colors.dart';
import '../../../utils/constants/enums.dart';
import '../../subscription/models/payment_transaction_model.dart';

class TransactionReportController extends GetxController {
  static TransactionReportController get instance => Get.find();

  final PaymentRepository _paymentRepository = Get.put(PaymentRepository());
  final GlobalKey chartKey = GlobalKey();

  // Observables
  var isLoading = false.obs;
  var selectedPeriod = ReportPeriod.yearly.obs;
  var selectedYear = DateTime.now().year.obs;
  var selectedMonth = DateTime.now().month.obs;
  var chartType = ChartType.line.obs;
  var transactions = <PaymentTransactionModel>[].obs;

  // Computed properties
  bool get hasValidSelection =>
      selectedYear.value > 0 &&
          (selectedPeriod.value == ReportPeriod.yearly || selectedMonth.value > 0);

  bool get canExport => transactions.isNotEmpty && hasValidSelection;

  int get totalTransactions => transactions.length;

  double get totalRevenue => transactions.fold(0.0, (sum, t) => sum + t.amount);

  // Available options
  List<int> get availableYears {
    final currentYear = DateTime.now().year;
    return List.generate(5, (index) => currentYear - index);
  }

  List<int> get availableMonths {
    final currentYear = DateTime.now().year;
    final currentMonth = DateTime.now().month;

    if (selectedYear.value == currentYear) {
      return List.generate(currentMonth, (index) => index + 1);
    } else {
      return List.generate(12, (index) => index + 1);
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Load initial data
    loadTransactionData();
  }

  // Filter methods
  void setPeriod(ReportPeriod period) {
    selectedPeriod.value = period;
    if (period == ReportPeriod.yearly) {
      selectedMonth.value = 0;
    } else {
      selectedMonth.value = DateTime.now().month;
    }
  }

  void setYear(int year) {
    selectedYear.value = year;
    // Reset month if selected year changed and current month is invalid
    if (selectedPeriod.value == ReportPeriod.monthly) {
      final maxMonth = year == DateTime.now().year ? DateTime.now().month : 12;
      if (selectedMonth.value > maxMonth) {
        selectedMonth.value = maxMonth;
      }
    }
  }

  void setMonth(int month) {
    selectedMonth.value = month;
  }

  void setChartType(ChartType type) {
    chartType.value = type;
  }

  void resetFilters() {
    selectedPeriod.value = ReportPeriod.yearly;
    selectedYear.value = DateTime.now().year;
    selectedMonth.value = DateTime.now().month;
    chartType.value = ChartType.line;
    transactions.clear();
  }

  // Data loading
  Future<void> loadTransactionData() async {
    try {
      isLoading.value = true;

      DateTime startDate;
      DateTime endDate;

      if (selectedPeriod.value == ReportPeriod.monthly) {
        startDate = DateTime(selectedYear.value, selectedMonth.value, 1);
        endDate = DateTime(
            selectedYear.value, selectedMonth.value + 1, 0, 23, 59, 59);
      } else {
        startDate = DateTime(selectedYear.value, 1, 1);
        endDate = DateTime(selectedYear.value, 12, 31, 23, 59, 59);
      }

      // Fetch successful transactions only
      final allTransactions =
      await _paymentRepository.getTransactionsByDateRange(
        startDate,
        endDate,
      );

      // Filter only successful transactions
      transactions.value = allTransactions
          .where((transaction) => transaction.status == PaymentStatus.succeeded)
          .toList();

      // Sort by date
      transactions.sort(
              (a, b) => a.transactionDateTime.compareTo(b.transactionDateTime));
    } catch (e) {
      print('Error loading transaction data: $e');
      transactions.clear();
    } finally {
      isLoading.value = false;
    }
  }

  // Helper methods
  String getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  String getChartTitle() {
    if (selectedPeriod.value == ReportPeriod.monthly) {
      return 'Weekly Subscription Trends - ${getMonthName(selectedMonth.value)} ${selectedYear.value}';
    } else {
      return 'Monthly Subscription Trends - ${selectedYear.value}';
    }
  }

  String getReportTitle() {
    if (selectedPeriod.value == ReportPeriod.monthly) {
      return '${getMonthName(selectedMonth.value)} ${selectedYear.value}';
    } else {
      return 'Year ${selectedYear.value}';
    }
  }

  String getTimeRangeText() {
    if (selectedPeriod.value == ReportPeriod.monthly) {
      return '${getMonthName(selectedMonth.value)} ${selectedYear.value}';
    } else {
      return 'January - December ${selectedYear.value}';
    }
  }

  // ========== 修正的周计算方法 ==========

  /// 找到某一天所在周的第一天（星期日）
  DateTime _findFirstDayOfWeek(DateTime date) {
    // DateTime.weekday: 1=Monday, 7=Sunday
    // 计算需要回退多少天到本周星期日
    // 如果 date.weekday = 7 (星期日)，daysToSubtract = 0
    // 如果 date.weekday = 1 (星期一)，daysToSubtract = 1
    // 如果 date.weekday = 6 (星期六)，daysToSubtract = 6
    int daysToSubtract = date.weekday % 7;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysToSubtract));
  }

  /// 找到该月第一个周日
  DateTime _findFirstSundayOfMonth(int year, int month) {
    DateTime firstDay = DateTime(year, month, 1);

    // 找到第一个周日
    // 如果 firstDay.weekday = 7 (周日)，daysToFirstSunday = 0
    // 如果 firstDay.weekday = 1 (周一)，daysToFirstSunday = 6
    // 如果 firstDay.weekday = 6 (周六)，daysToFirstSunday = 1
    int daysToFirstSunday = (7 - firstDay.weekday) % 7;
    return firstDay.add(Duration(days: daysToFirstSunday));
  }

  /// 获取指定周的第一天日期（周日）
  DateTime getFirstDayOfWeek(int weekIndex, int year, int month) {
    DateTime firstSunday = _findFirstSundayOfMonth(year, month);
    DateTime result = firstSunday.add(Duration(days: weekIndex * 7));
    return result;
  }

  /// 获取指定周的最后一天日期（周六）
  DateTime getLastDayOfWeek(int weekIndex, int year, int month) {
    DateTime firstDay = getFirstDayOfWeek(weekIndex, year, month);
    return firstDay.add(Duration(days: 6));
  }

  /// 判断一周是否属于当前月份（基于大部分天数原则）
  bool _isWeekInMonth(int weekIndex, int year, int month) {
    final firstDay = getFirstDayOfWeek(weekIndex, year, month);
    final lastDay = getLastDayOfWeek(weekIndex, year, month);

    // 计算该周在当前月份的天数
    int daysInMonth = 0;
    DateTime currentDay = firstDay;
    while (currentDay.isBefore(lastDay.add(const Duration(days: 1)))) {
      if (currentDay.month == month) {
        daysInMonth++;
      }
      currentDay = currentDay.add(const Duration(days: 1));
    }

    // 如果该周有4天或更多在当前月份，则属于该月
    return daysInMonth >= 4;
  }

  /// 获取日历周的周数（基于周日为一周的开始，且周属于大部分天数所在的月份）
  int getCalendarWeekOfMonth(DateTime date) {
    // 找到该日期所在周的周日
    DateTime sunday = _findFirstDayOfWeek(date);

    // 找到该月第一个周日
    DateTime firstSundayOfMonth = _findFirstSundayOfMonth(date.year, date.month);

    // 计算两个周日之间的周数差
    int weekOfMonth = sunday.difference(firstSundayOfMonth).inDays ~/ 7;

    // 如果日期在第一个周日之前，属于第0周
    if (sunday.isBefore(firstSundayOfMonth)) {
      weekOfMonth = 0;
    }

    // 检查该周是否真正属于本月（基于大部分天数原则）
    if (!_isWeekInMonth(weekOfMonth, date.year, date.month)) {
      // 如果不属于本月，返回-1表示无效
      return -1;
    }

    return weekOfMonth.clamp(0, 5);
  }

  /// 获取指定周的完整日期范围字符串
  String getWeekRangeText(int weekIndex, int year, int month) {
    final firstDay = getFirstDayOfWeek(weekIndex, year, month);
    final lastDay = getLastDayOfWeek(weekIndex, year, month);

    // 如果第一周的第一天是1号，且不是周日，说明这是不完整的第一周
    if (weekIndex == 0 && firstDay.day == 1 && firstDay.weekday != 7) {
      return '${formatDateShort(firstDay)}';
    }

    // 完整周显示日期范围
    return '${formatDateShort(firstDay)} - ${formatDateShort(lastDay)}';
  }

  // 格式化日期为 "MMM dd" 格式（如 "Jan 01"）
  String formatDateShort(DateTime date) {
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = monthNames[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    return '$month $day';
  }

  /// 获取属于当前月份的有效周索引列表
  List<int> _getValidWeekIndices() {
    if (selectedPeriod.value != ReportPeriod.monthly) return List.generate(12, (index) => index);

    final List<int> validWeeks = [];

    // 检查可能的周（0-5周）
    for (int weekIndex = 0; weekIndex <= 5; weekIndex++) {
      if (_isWeekInMonth(weekIndex, selectedYear.value, selectedMonth.value)) {
        validWeeks.add(weekIndex);
      }
    }

    return validWeeks;
  }

  // Get X-axis labels for charts
  List<String> getXAxisLabels() {
    if (selectedPeriod.value == ReportPeriod.monthly) {
      final validWeeks = _getValidWeekIndices();

      // 确保至少有一个周
      if (validWeeks.isEmpty) {
        return ['No Data'];
      }

      return validWeeks.map((weekIndex) {
        final weekRange = getWeekRangeText(weekIndex, selectedYear.value, selectedMonth.value);
        return 'Week ${weekIndex + 1}\n($weekRange)';
      }).toList();
    } else {
      return [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
    }
  }

  // Chart data processing for Line Chart (Revenue)
  List<FlSpot> getChartData() {
    Map<int, double> groupedData = {};

    if (transactions.isNotEmpty) {
      if (selectedPeriod.value == ReportPeriod.monthly) {
        // 使用修正的日历周计算（基于大部分天数原则）
        for (var transaction in transactions) {
          final weekOfMonth = getCalendarWeekOfMonth(transaction.transactionDateTime);
          // 只统计属于本月的周
          if (weekOfMonth >= 0) {
            groupedData[weekOfMonth] =
                (groupedData[weekOfMonth] ?? 0.0) + transaction.amount;
          }
        }
      } else {
        // 年度数据保持不变
        for (var transaction in transactions) {
          final month = transaction.transactionDateTime.month - 1;
          groupedData[month] = (groupedData[month] ?? 0.0) + transaction.amount;
        }
      }
    }

    // 动态确定周数（只使用有效的周）
    if (selectedPeriod.value == ReportPeriod.monthly) {
      final validWeeks = _getValidWeekIndices();
      List<FlSpot> spots = [];
      for (int i = 0; i < validWeeks.length; i++) {
        final weekIndex = validWeeks[i];
        spots.add(FlSpot(i.toDouble(), groupedData[weekIndex] ?? 0.0));
      }
      return spots;
    } else {
      List<FlSpot> spots = [];
      for (int i = 0; i <= 11; i++) {
        spots.add(FlSpot(i.toDouble(), groupedData[i] ?? 0.0));
      }
      return spots;
    }
  }

  // Chart data processing for Bar Chart (Transaction Count)
  List<BarChartGroupData> getBarChartData() {
    Map<int, int> groupedData = {};

    if (transactions.isNotEmpty) {
      if (selectedPeriod.value == ReportPeriod.monthly) {
        // 使用修正的日历周计算（基于大部分天数原则）
        for (var transaction in transactions) {
          final weekOfMonth = getCalendarWeekOfMonth(transaction.transactionDateTime);
          // 只统计属于本月的周
          if (weekOfMonth >= 0) {
            groupedData[weekOfMonth] = (groupedData[weekOfMonth] ?? 0) + 1;
          }
        }
      } else {
        // 年度数据保持不变
        for (var transaction in transactions) {
          final month = transaction.transactionDateTime.month - 1;
          groupedData[month] = (groupedData[month] ?? 0) + 1;
        }
      }
    }

    // 动态确定周数（只使用有效的周）
    if (selectedPeriod.value == ReportPeriod.monthly) {
      final validWeeks = _getValidWeekIndices();
      List<BarChartGroupData> barGroups = [];
      for (int i = 0; i < validWeeks.length; i++) {
        final weekIndex = validWeeks[i];
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: (groupedData[weekIndex] ?? 0).toDouble(),
                color: TAdminColors.primary,
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          ),
        );
      }
      return barGroups;
    } else {
      List<BarChartGroupData> barGroups = [];
      for (int i = 0; i <= 11; i++) {
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: (groupedData[i] ?? 0).toDouble(),
                color: TAdminColors.primary,
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          ),
        );
      }
      return barGroups;
    }
  }

  double getMaxY() {
    if (transactions.isEmpty) return 10;

    double maxValue;

    if (chartType.value == ChartType.line) {
      // For line chart (revenue), calculate max revenue
      Map<int, double> groupedData = {};

      if (selectedPeriod.value == ReportPeriod.monthly) {
        for (var transaction in transactions) {
          final weekOfMonth = getCalendarWeekOfMonth(transaction.transactionDateTime);
          if (weekOfMonth >= 0) {
            groupedData[weekOfMonth] =
                (groupedData[weekOfMonth] ?? 0.0) + transaction.amount;
          }
        }
      } else {
        for (var transaction in transactions) {
          final month = transaction.transactionDateTime.month - 1;
          groupedData[month] = (groupedData[month] ?? 0.0) + transaction.amount;
        }
      }

      maxValue = groupedData.values.isEmpty
          ? 0.0
          : groupedData.values.reduce((a, b) => a > b ? a : b);
    } else {
      // For bar chart (transaction count), calculate max count
      Map<int, int> groupedData = {};

      if (selectedPeriod.value == ReportPeriod.monthly) {
        for (var transaction in transactions) {
          final weekOfMonth = getCalendarWeekOfMonth(transaction.transactionDateTime);
          if (weekOfMonth >= 0) {
            groupedData[weekOfMonth] = (groupedData[weekOfMonth] ?? 0) + 1;
          }
        }
      } else {
        for (var transaction in transactions) {
          final month = transaction.transactionDateTime.month - 1;
          groupedData[month] = (groupedData[month] ?? 0) + 1;
        }
      }

      maxValue = groupedData.values.isEmpty
          ? 0
          : groupedData.values.reduce((a, b) => a > b ? a : b).toDouble();
    }

    if (maxValue == 0.0) return 10;

    // 使用基于间隔的计算方法
    return _calculateMaxYBasedOnInterval(maxValue);
  }

  double calculateNiceInterval(double value) {
    if (value <= 0) return 1;

    // 基于数值范围计算合适的间隔
    if (value <= 10) return 2;
    if (value <= 20) return 5;
    if (value <= 50) return 10;
    if (value <= 100) return 20;
    if (value <= 200) return 50;
    if (value <= 500) return 100;
    if (value <= 1000) return 200;
    if (value <= 2000) return 500;
    if (value <= 5000) return 1000;

    // 对于更大的数值，使用更通用的算法
    return (value / 5).ceilToDouble();
  }

  /// 计算水平网格线间隔
  double calculateHorizontalInterval() {
    final range = getMaxY() - 0; // minY 通常是 0
    if (range <= 0) return 1;

    // 使用统一的间隔计算逻辑
    return calculateNiceInterval(range);
  }

  /// 计算左侧标题间隔
  double calculateLeftTitleInterval() {
    // 使用相同的逻辑
    return calculateHorizontalInterval();
  }

  /// 计算网格间隔（用于 BarChart）
  double calculateGridInterval() {
    // 使用相同的逻辑
    return calculateHorizontalInterval();
  }

  double _calculateMaxYBasedOnInterval(double actualMax) {
    if (actualMax <= 0) return 10;

    // 计算合适的间隔 - 使用统一的 public 方法
    double interval = calculateNiceInterval(actualMax);

    // 计算需要多少个间隔来覆盖实际最大值
    final numberOfIntervals = (actualMax / interval).ceil();

    // 最大值 = 间隔数 × 间隔
    final calculatedMax = numberOfIntervals * interval;

    // 确保至少有一个间隔
    final finalMax = calculatedMax < interval ? interval : calculatedMax;

    return finalMax;
  }

  // Get Y-axis unit and label based on chart type
  String getYAxisUnit() {
    return chartType.value == ChartType.line ? 'RM' : 'transactions';
  }

  String getYAxisLabel() {
    return chartType.value == ChartType.line
        ? 'Revenue (RM)'
        : 'Number of Transactions';
  }

  // Table data
  List<Map<String, dynamic>> getTableData() {
    if (transactions.isEmpty) return [];

    Map<int, Map<String, dynamic>> groupedData = {};

    if (selectedPeriod.value == ReportPeriod.monthly) {
      // Group by calendar weeks (只统计属于本月的周)
      for (var transaction in transactions) {
        final weekOfMonth = getCalendarWeekOfMonth(transaction.transactionDateTime);

        // 只处理属于本月的周
        if (weekOfMonth >= 0) {
          if (!groupedData.containsKey(weekOfMonth)) {
            final weekRange = getWeekRangeText(weekOfMonth, selectedYear.value, selectedMonth.value);
            groupedData[weekOfMonth] = {
              'period': 'Week ${weekOfMonth + 1} ($weekRange)',
              'count': 0,
              'revenue': 0.0,
            };
          }

          groupedData[weekOfMonth]!['count']++;
          groupedData[weekOfMonth]!['revenue'] += transaction.amount;
        }
      }
    } else {
      // Group by months
      for (var transaction in transactions) {
        final month = transaction.transactionDateTime.month - 1;

        if (!groupedData.containsKey(month)) {
          groupedData[month] = {
            'period': getMonthName(month + 1),
            'count': 0,
            'revenue': 0.0,
          };
        }

        groupedData[month]!['count']++;
        groupedData[month]!['revenue'] += transaction.amount;
      }
    }

    // Convert to list and sort
    List<Map<String, dynamic>> tableData = groupedData.values.toList();

    // Sort by week number
    if (selectedPeriod.value == ReportPeriod.monthly) {
      tableData.sort((a, b) {
        final aWeek = int.parse(a['period'].toString().split(' ')[1]);
        final bWeek = int.parse(b['period'].toString().split(' ')[1]);
        return aWeek.compareTo(bWeek);
      });
    } else {
      // Sort months by order
      const monthOrder = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      tableData.sort((a, b) {
        final aIndex = monthOrder.indexOf(a['period'].toString());
        final bIndex = monthOrder.indexOf(b['period'].toString());
        return aIndex.compareTo(bIndex);
      });
    }

    return tableData;
  }

  // Export data
  List<Map<String, dynamic>> getExportData() {
    List<Map<String, dynamic>> exportData = [];

    for (var transaction in transactions) {
      exportData.add({
        'Transaction ID': transaction.transactionId,
        'Date': transaction.transactionDateTime.toIso8601String().split('T')[0],
        'Time': transaction.transactionDateTime
            .toIso8601String()
            .split('T')[1]
            .split('.')[0],
        'Amount': transaction.amount,
        'Currency': transaction.currency,
        'Payment Method': transaction.paymentMethod.capitalizeFirst,
        'Status': transaction.status.displayName,
      });
    }

    return exportData;
  }
}