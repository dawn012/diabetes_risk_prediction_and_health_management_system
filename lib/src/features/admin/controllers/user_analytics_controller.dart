import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../data/repositories/user/user_repository.dart';
import '../../../features/authentication/models/user_model.dart';
import '../../../utils/constants/admin_colors.dart';
import '../../../utils/constants/enums.dart';

class UserAnalyticsController extends GetxController {
  static UserAnalyticsController get instance => Get.find();

  final UserRepository _userRepository = UserRepository.instance;
  final GlobalKey chartKey = GlobalKey();

  var isLoading = false.obs;
  var selectedPeriod = ReportPeriod.yearly.obs;
  var selectedYear = DateTime.now().year.obs;
  var selectedMonth = DateTime.now().month.obs;
  var chartType = ChartType.line.obs;
  var users = <UserModel>[].obs;

  bool get hasValidSelection =>
      selectedYear.value > 0 &&
          (selectedPeriod.value == ReportPeriod.yearly || selectedMonth.value > 0);

  bool get canExport {
    if (!hasValidSelection) return false;

    // Check based on current chart type
    if (chartType.value == ChartType.line) {
      return _getActiveUsers().isNotEmpty;
    } else {
      return _getNewUsers().isNotEmpty;
    }
  }

  // Separate getters for active and new users
  List<UserModel> _getActiveUsers() {
    if (users.isEmpty) return [];

    DateTime startDate;
    DateTime endDate;

    if (selectedPeriod.value == ReportPeriod.monthly) {
      startDate = DateTime(selectedYear.value, selectedMonth.value, 1);
      endDate = DateTime(selectedYear.value, selectedMonth.value + 1, 0, 23, 59, 59);
    } else {
      startDate = DateTime(selectedYear.value, 1, 1);
      endDate = DateTime(selectedYear.value, 12, 31, 23, 59, 59);
    }

    return users.where((user) {
      if (user.lastActive == 0) return false;
      final lastActiveDate = DateTime.fromMillisecondsSinceEpoch(user.lastActive);
      return lastActiveDate.isAfter(startDate) && lastActiveDate.isBefore(endDate);
    }).toList();
  }

  List<UserModel> _getNewUsers() {
    if (users.isEmpty) return [];

    DateTime startDate;
    DateTime endDate;

    if (selectedPeriod.value == ReportPeriod.monthly) {
      startDate = DateTime(selectedYear.value, selectedMonth.value, 1);
      endDate = DateTime(selectedYear.value, selectedMonth.value + 1, 0, 23, 59, 59);
    } else {
      startDate = DateTime(selectedYear.value, 1, 1);
      endDate = DateTime(selectedYear.value, 12, 31, 23, 59, 59);
    }

    return users.where((user) {
      final joinDate = user.joinDate;
      return joinDate.isAfter(startDate) && joinDate.isBefore(endDate);
    }).toList();
  }

  int get totalActiveUsers => _getActiveUsers().length;
  int get totalNewUsers => _getNewUsers().length;

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
    loadUserData();
  }

  // Filter methods - Auto apply on change
  void setPeriod(ReportPeriod period) {
    selectedPeriod.value = period;
    if (period == ReportPeriod.yearly) {
      selectedMonth.value = 0;
    } else {
      selectedMonth.value = DateTime.now().month;
    }
    // Auto apply
    loadUserData();
  }

  void setYear(int year) {
    selectedYear.value = year;
    if (selectedPeriod.value == ReportPeriod.monthly) {
      final maxMonth = year == DateTime.now().year ? DateTime.now().month : 12;
      if (selectedMonth.value > maxMonth) {
        selectedMonth.value = maxMonth;
      }
    }
    // Auto apply
    loadUserData();
  }

  void setMonth(int month) {
    selectedMonth.value = month;
    // Auto apply
    loadUserData();
  }

  void setChartType(ChartType type) {
    chartType.value = type;
  }

  void resetFilters() {
    selectedPeriod.value = ReportPeriod.yearly;
    selectedYear.value = DateTime.now().year;
    selectedMonth.value = DateTime.now().month;
    chartType.value = ChartType.line;
    loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      isLoading.value = true;

      final allUsers = await _userRepository.getRegularUsers();

      users.value = allUsers.where((user) =>
      !user.isDeleted && user.accountAvailable
      ).toList();

      users.sort((a, b) => a.joinDate.compareTo(b.joinDate));
    } catch (e) {
      print('Error loading user data: $e');
      users.clear();
    } finally {
      isLoading.value = false;
    }
  }

  String getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String getChartTitle() {
    final metricType = chartType.value == ChartType.line ? 'Active Users' : 'New User Signups';

    if (selectedPeriod.value == ReportPeriod.monthly) {
      return 'Weekly $metricType - ${getMonthName(selectedMonth.value)} ${selectedYear.value}';
    } else {
      return 'Monthly $metricType - ${selectedYear.value}';
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

  // Week calculation methods
  DateTime _findFirstDayOfWeek(DateTime date) {
    int daysToSubtract = date.weekday % 7;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysToSubtract));
  }

  DateTime _findFirstSundayOfMonth(int year, int month) {
    DateTime firstDay = DateTime(year, month, 1);
    int daysToFirstSunday = (7 - firstDay.weekday) % 7;
    return firstDay.add(Duration(days: daysToFirstSunday));
  }

  DateTime getFirstDayOfWeek(int weekIndex, int year, int month) {
    DateTime firstSunday = _findFirstSundayOfMonth(year, month);
    DateTime result = firstSunday.add(Duration(days: weekIndex * 7));
    return result;
  }

  DateTime getLastDayOfWeek(int weekIndex, int year, int month) {
    DateTime firstDay = getFirstDayOfWeek(weekIndex, year, month);
    return firstDay.add(Duration(days: 6));
  }

  bool _isWeekInMonth(int weekIndex, int year, int month) {
    final firstDay = getFirstDayOfWeek(weekIndex, year, month);
    final lastDay = getLastDayOfWeek(weekIndex, year, month);

    int daysInMonth = 0;
    DateTime currentDay = firstDay;
    while (currentDay.isBefore(lastDay.add(const Duration(days: 1)))) {
      if (currentDay.month == month) {
        daysInMonth++;
      }
      currentDay = currentDay.add(const Duration(days: 1));
    }

    return daysInMonth >= 4;
  }

  int getCalendarWeekOfMonth(DateTime date) {
    DateTime sunday = _findFirstDayOfWeek(date);
    DateTime firstSundayOfMonth = _findFirstSundayOfMonth(date.year, date.month);
    int weekOfMonth = sunday.difference(firstSundayOfMonth).inDays ~/ 7;

    if (sunday.isBefore(firstSundayOfMonth)) {
      weekOfMonth = 0;
    }

    if (!_isWeekInMonth(weekOfMonth, date.year, date.month)) {
      return -1;
    }

    return weekOfMonth.clamp(0, 5);
  }

  String getWeekRangeText(int weekIndex, int year, int month) {
    final firstDay = getFirstDayOfWeek(weekIndex, year, month);
    final lastDay = getLastDayOfWeek(weekIndex, year, month);

    if (weekIndex == 0 && firstDay.day == 1 && firstDay.weekday != 7) {
      return '${formatDateShort(firstDay)}';
    }

    return '${formatDateShort(firstDay)} - ${formatDateShort(lastDay)}';
  }

  String formatDateShort(DateTime date) {
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = monthNames[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    return '$month $day';
  }

  List<int> _getValidWeekIndices() {
    if (selectedPeriod.value != ReportPeriod.monthly) {
      return List.generate(12, (index) => index);
    }

    final List<int> validWeeks = [];
    for (int weekIndex = 0; weekIndex <= 5; weekIndex++) {
      if (_isWeekInMonth(weekIndex, selectedYear.value, selectedMonth.value)) {
        validWeeks.add(weekIndex);
      }
    }

    return validWeeks;
  }

  List<String> getXAxisLabels() {
    if (selectedPeriod.value == ReportPeriod.monthly) {
      final validWeeks = _getValidWeekIndices();

      if (validWeeks.isEmpty) {
        return ['No Data'];
      }

      return validWeeks.map((weekIndex) {
        final weekRange = getWeekRangeText(weekIndex, selectedYear.value, selectedMonth.value);
        return 'Week ${weekIndex + 1}\n($weekRange)';
      }).toList();
    } else {
      return ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    }
  }

  // Chart data for Line Chart (Active Users) - Only count users with lastActive
  List<FlSpot> getChartData() {
    Map<int, int> groupedData = {};
    final activeUsers = _getActiveUsers();

    if (activeUsers.isNotEmpty) {
      if (selectedPeriod.value == ReportPeriod.monthly) {
        for (var user in activeUsers) {
          final lastActiveDate = DateTime.fromMillisecondsSinceEpoch(user.lastActive);
          final weekOfMonth = getCalendarWeekOfMonth(lastActiveDate);
          if (weekOfMonth >= 0) {
            groupedData[weekOfMonth] = (groupedData[weekOfMonth] ?? 0) + 1;
          }
        }
      } else {
        for (var user in activeUsers) {
          final lastActiveDate = DateTime.fromMillisecondsSinceEpoch(user.lastActive);
          final month = lastActiveDate.month - 1;
          groupedData[month] = (groupedData[month] ?? 0) + 1;
        }
      }
    }

    if (selectedPeriod.value == ReportPeriod.monthly) {
      final validWeeks = _getValidWeekIndices();
      List<FlSpot> spots = [];
      for (int i = 0; i < validWeeks.length; i++) {
        final weekIndex = validWeeks[i];
        spots.add(FlSpot(i.toDouble(), (groupedData[weekIndex] ?? 0).toDouble()));
      }
      return spots;
    } else {
      List<FlSpot> spots = [];
      for (int i = 0; i <= 11; i++) {
        spots.add(FlSpot(i.toDouble(), (groupedData[i] ?? 0).toDouble()));
      }
      return spots;
    }
  }

  // Chart data for Bar Chart (New Users) - Only count new users
  List<BarChartGroupData> getBarChartData() {
    Map<int, int> groupedData = {};
    final newUsers = _getNewUsers();

    if (newUsers.isNotEmpty) {
      if (selectedPeriod.value == ReportPeriod.monthly) {
        for (var user in newUsers) {
          final joinDate = user.joinDate;
          final weekOfMonth = getCalendarWeekOfMonth(joinDate);
          if (weekOfMonth >= 0) {
            groupedData[weekOfMonth] = (groupedData[weekOfMonth] ?? 0) + 1;
          }
        }
      } else {
        for (var user in newUsers) {
          final joinDate = user.joinDate;
          final month = joinDate.month - 1;
          groupedData[month] = (groupedData[month] ?? 0) + 1;
        }
      }
    }

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
                color: TAdminColors.success,
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
                color: TAdminColors.success,
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
    double maxValue;
    Map<int, int> groupedData = {};

    if (chartType.value == ChartType.line) {
      final activeUsers = _getActiveUsers();
      if (activeUsers.isEmpty) return 10;

      if (selectedPeriod.value == ReportPeriod.monthly) {
        for (var user in activeUsers) {
          final lastActiveDate = DateTime.fromMillisecondsSinceEpoch(user.lastActive);
          final weekOfMonth = getCalendarWeekOfMonth(lastActiveDate);
          if (weekOfMonth >= 0) {
            groupedData[weekOfMonth] = (groupedData[weekOfMonth] ?? 0) + 1;
          }
        }
      } else {
        for (var user in activeUsers) {
          final lastActiveDate = DateTime.fromMillisecondsSinceEpoch(user.lastActive);
          final month = lastActiveDate.month - 1;
          groupedData[month] = (groupedData[month] ?? 0) + 1;
        }
      }
    } else {
      final newUsers = _getNewUsers();
      if (newUsers.isEmpty) return 10;

      if (selectedPeriod.value == ReportPeriod.monthly) {
        for (var user in newUsers) {
          final joinDate = user.joinDate;
          final weekOfMonth = getCalendarWeekOfMonth(joinDate);
          if (weekOfMonth >= 0) {
            groupedData[weekOfMonth] = (groupedData[weekOfMonth] ?? 0) + 1;
          }
        }
      } else {
        for (var user in newUsers) {
          final joinDate = user.joinDate;
          final month = joinDate.month - 1;
          groupedData[month] = (groupedData[month] ?? 0) + 1;
        }
      }
    }

    maxValue = groupedData.values.isEmpty
        ? 0
        : groupedData.values.reduce((a, b) => a > b ? a : b).toDouble();

    if (maxValue == 0.0) return 10;

    return _calculateMaxYBasedOnInterval(maxValue);
  }

  double calculateNiceInterval(double value) {
    if (value <= 0) return 1;

    if (value <= 10) return 2;
    if (value <= 20) return 5;
    if (value <= 50) return 10;
    if (value <= 100) return 20;
    if (value <= 200) return 50;
    if (value <= 500) return 100;
    if (value <= 1000) return 200;
    if (value <= 2000) return 500;
    if (value <= 5000) return 1000;

    return (value / 5).ceilToDouble();
  }

  double calculateHorizontalInterval() {
    final range = getMaxY() - 0;
    if (range <= 0) return 1;
    return calculateNiceInterval(range);
  }

  double calculateLeftTitleInterval() {
    return calculateHorizontalInterval();
  }

  double calculateGridInterval() {
    return calculateHorizontalInterval();
  }

  double _calculateMaxYBasedOnInterval(double actualMax) {
    if (actualMax <= 0) return 10;

    double interval = calculateNiceInterval(actualMax);
    final numberOfIntervals = (actualMax / interval).ceil();
    final calculatedMax = numberOfIntervals * interval;
    final finalMax = calculatedMax < interval ? interval : calculatedMax;

    return finalMax;
  }

  String getYAxisUnit() {
    return 'users';
  }

  String getYAxisLabel() {
    return chartType.value == ChartType.line
        ? 'Active Users Count'
        : 'New Users Count';
  }

  // Table data - Only show relevant users based on chart type
  List<Map<String, dynamic>> getTableData() {
    Map<int, Map<String, dynamic>> groupedData = {};

    if (chartType.value == ChartType.line) {
      final activeUsers = _getActiveUsers();
      if (activeUsers.isEmpty) return [];

      if (selectedPeriod.value == ReportPeriod.monthly) {
        for (var user in activeUsers) {
          final lastActiveDate = DateTime.fromMillisecondsSinceEpoch(user.lastActive);
          final weekOfMonth = getCalendarWeekOfMonth(lastActiveDate);
          if (weekOfMonth >= 0) {
            if (!groupedData.containsKey(weekOfMonth)) {
              final weekRange = getWeekRangeText(weekOfMonth, selectedYear.value, selectedMonth.value);
              groupedData[weekOfMonth] = {
                'period': 'Week ${weekOfMonth + 1} ($weekRange)',
                'count': 0,
              };
            }
            groupedData[weekOfMonth]!['count']++;
          }
        }
      } else {
        for (var user in activeUsers) {
          final lastActiveDate = DateTime.fromMillisecondsSinceEpoch(user.lastActive);
          final month = lastActiveDate.month - 1;
          if (!groupedData.containsKey(month)) {
            groupedData[month] = {
              'period': getMonthName(month + 1),
              'count': 0,
            };
          }
          groupedData[month]!['count']++;
        }
      }
    } else {
      final newUsers = _getNewUsers();
      if (newUsers.isEmpty) return [];

      if (selectedPeriod.value == ReportPeriod.monthly) {
        for (var user in newUsers) {
          final joinDate = user.joinDate;
          final weekOfMonth = getCalendarWeekOfMonth(joinDate);
          if (weekOfMonth >= 0) {
            if (!groupedData.containsKey(weekOfMonth)) {
              final weekRange = getWeekRangeText(weekOfMonth, selectedYear.value, selectedMonth.value);
              groupedData[weekOfMonth] = {
                'period': 'Week ${weekOfMonth + 1} ($weekRange)',
                'count': 0,
              };
            }
            groupedData[weekOfMonth]!['count']++;
          }
        }
      } else {
        for (var user in newUsers) {
          final joinDate = user.joinDate;
          final month = joinDate.month - 1;
          if (!groupedData.containsKey(month)) {
            groupedData[month] = {
              'period': getMonthName(month + 1),
              'count': 0,
            };
          }
          groupedData[month]!['count']++;
        }
      }
    }

    List<Map<String, dynamic>> tableData = groupedData.values.toList();

    if (selectedPeriod.value == ReportPeriod.monthly) {
      tableData.sort((a, b) {
        final aWeek = int.parse(a['period'].toString().split(' ')[1]);
        final bWeek = int.parse(b['period'].toString().split(' ')[1]);
        return aWeek.compareTo(bWeek);
      });
    } else {
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

  // Export data - Only export relevant users based on chart type
  List<Map<String, dynamic>> getExportData() {
    List<Map<String, dynamic>> exportData = [];

    List<UserModel> usersToExport;
    if (chartType.value == ChartType.line) {
      usersToExport = _getActiveUsers();
    } else {
      usersToExport = _getNewUsers();
    }

    for (var user in usersToExport) {
      exportData.add({
        'User ID': user.userId,
        'Username': user.username,
        'Email': user.email,
        'Join Date': user.joinDate.toIso8601String().split('T')[0],
        'Last Active': user.lastActive != 0
            ? DateTime.fromMillisecondsSinceEpoch(user.lastActive)
            .toIso8601String()
            .split('T')[0]
            : 'Never',
        'Verified': user.isVerify ? 'Yes' : 'No',
      });
    }

    return exportData;
  }
}