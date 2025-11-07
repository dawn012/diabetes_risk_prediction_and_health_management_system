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

  // Get X-axis labels for charts
  List<String> getXAxisLabels() {
    if (selectedPeriod.value == ReportPeriod.monthly) {
      return ['Week 1', 'Week 2', 'Week 3', 'Week 4', 'Week 5'];
    } else {
      return [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
    }
  }

  // Chart data processing for Line Chart (Revenue)
  List<FlSpot> getChartData() {
    Map<int, double> groupedData = {}; // Changed to double for revenue

    if (transactions.isNotEmpty) {
      if (selectedPeriod.value == ReportPeriod.monthly) {
        // Group by weeks in the month (revenue)
        for (var transaction in transactions) {
          final dayOfMonth = transaction.transactionDateTime.day;
          final weekOfMonth = ((dayOfMonth - 1) ~/ 7).clamp(0, 4);
          groupedData[weekOfMonth] =
              (groupedData[weekOfMonth] ?? 0.0) + transaction.amount;
        }
      } else {
        // Group by months in the year (revenue)
        for (var transaction in transactions) {
          final month =
              transaction.transactionDateTime.month - 1; // 0-based (0-11)
          groupedData[month] = (groupedData[month] ?? 0.0) + transaction.amount;
        }
      }
    }

    List<FlSpot> spots = [];
    final maxIndex = selectedPeriod.value == ReportPeriod.monthly ? 4 : 11;

    for (int i = 0; i <= maxIndex; i++) {
      spots.add(FlSpot(i.toDouble(), groupedData[i] ?? 0.0));
    }

    return spots;
  }

  // Chart data processing for Bar Chart (Transaction Count)
  List<BarChartGroupData> getBarChartData() {
    Map<int, int> groupedData = {}; // Keep as int for transaction count

    if (transactions.isNotEmpty) {
      if (selectedPeriod.value == ReportPeriod.monthly) {
        // Group by weeks in the month (count)
        for (var transaction in transactions) {
          final dayOfMonth = transaction.transactionDateTime.day;
          final weekOfMonth = ((dayOfMonth - 1) ~/ 7).clamp(0, 4);
          groupedData[weekOfMonth] = (groupedData[weekOfMonth] ?? 0) + 1;
        }
      } else {
        // Group by months in the year (count)
        for (var transaction in transactions) {
          final month =
              transaction.transactionDateTime.month - 1; // 0-based (0-11)
          groupedData[month] = (groupedData[month] ?? 0) + 1;
        }
      }
    }

    List<BarChartGroupData> barGroups = [];
    final maxIndex = selectedPeriod.value == ReportPeriod.monthly ? 4 : 11;

    for (int i = 0; i <= maxIndex; i++) {
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

  double getMaxY() {
    if (transactions.isEmpty) return 10;

    if (chartType.value == ChartType.line) {
      // For line chart (revenue), calculate max revenue
      Map<int, double> groupedData = {};

      if (selectedPeriod.value == ReportPeriod.monthly) {
        for (var transaction in transactions) {
          final dayOfMonth = transaction.transactionDateTime.day;
          final weekOfMonth = ((dayOfMonth - 1) ~/ 7).clamp(0, 4);
          groupedData[weekOfMonth] =
              (groupedData[weekOfMonth] ?? 0.0) + transaction.amount;
        }
      } else {
        for (var transaction in transactions) {
          final month = transaction.transactionDateTime.month - 1;
          groupedData[month] = (groupedData[month] ?? 0.0) + transaction.amount;
        }
      }

      final maxValue = groupedData.values.isEmpty
          ? 0.0
          : groupedData.values.reduce((a, b) => a > b ? a : b);
      return maxValue == 0.0 ? 10 : maxValue * 1.2; // Add 20% padding
    } else {
      // For bar chart (transaction count), calculate max count
      Map<int, int> groupedData = {};

      if (selectedPeriod.value == ReportPeriod.monthly) {
        for (var transaction in transactions) {
          final dayOfMonth = transaction.transactionDateTime.day;
          final weekOfMonth = ((dayOfMonth - 1) ~/ 7).clamp(0, 4);
          groupedData[weekOfMonth] = (groupedData[weekOfMonth] ?? 0) + 1;
        }
      } else {
        for (var transaction in transactions) {
          final month = transaction.transactionDateTime.month - 1;
          groupedData[month] = (groupedData[month] ?? 0) + 1;
        }
      }

      final maxValue = groupedData.values.isEmpty
          ? 0
          : groupedData.values.reduce((a, b) => a > b ? a : b);
      return maxValue == 0
          ? 10
          : (maxValue * 1.2).roundToDouble(); // Add 20% padding and round
    }
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
      // Group by weeks
      for (var transaction in transactions) {
        final dayOfMonth = transaction.transactionDateTime.day;
        final weekOfMonth = ((dayOfMonth - 1) ~/ 7).clamp(0, 4);

        if (!groupedData.containsKey(weekOfMonth)) {
          groupedData[weekOfMonth] = {
            'period': 'Week ${weekOfMonth + 1}',
            'count': 0,
            'revenue': 0.0,
          };
        }

        groupedData[weekOfMonth]!['count']++;
        groupedData[weekOfMonth]!['revenue'] += transaction.amount;
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

    // Sort by period name
    if (selectedPeriod.value == ReportPeriod.monthly) {
      // Sort weeks by number
      tableData.sort((a, b) {
        final aWeek = int.parse(a['period'].toString().replaceAll('Week ', ''));
        final bWeek = int.parse(b['period'].toString().replaceAll('Week ', ''));
        return aWeek.compareTo(bWeek);
      });
    } else {
      // Sort months by order
      const monthOrder = [
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
        'Payment Method': transaction.paymentMethod,
        'Status': transaction.status,
      });
    }

    return exportData;
  }
}
