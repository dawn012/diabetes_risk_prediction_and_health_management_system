import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/health_log/health_log_repository.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/health_data_range.dart';
import '../models/health_data_model.dart';
import '../views/health_data_analytics/widgets/health_data_list_screen.dart';
import '../views/health_data_entry/health_data_entry_screen.dart';

class BloodGlucoseController extends GetxController {
  // Repositories
  final _healthLogRepo = HealthLogRepository.instance;
  final _authRepo = AuthenticationRepository.instance;

  // Stream subscription
  StreamSubscription<List<HealthDataModel>>? _healthDataSubscription;

  // Observable variables
  final selectedTimeRange = 'Past 14 Days'.obs;
  final selectedPeriodFilter = 'All'.obs;
  final selectedTrendFilter = 'All'.obs;
  final selectedComparisonFilter = 'Before vs. After Meal'.obs;

  final healthDataList = <HealthDataModel>[].obs;
  final lastRecord = Rxn<HealthDataModel>();
  final isLoading = false.obs;

  // Statistics
  final lowestValue = 0.0.obs;
  final highestValue = 0.0.obs;
  final averageValue = 0.0.obs;
  final normalCount = 0.obs;
  final highCount = 0.obs;
  final lowCount = 0.obs;
  final totalCount = 0.obs;

  // Dashboard specific
  final todayCount = 0.obs;
  final weekCount = 0.obs;
  final past14DaysCount = 0.obs;

  // Chart data
  final trendsData = <FlSpot>[].obs;
  final trendsLabels = <String>[].obs;
  final trendsOriginalDateTimes = <DateTime>[].obs;
  final comparisonData = <String, double>{}.obs;
  final comparisonBarData = <BarChartGroupData>[].obs;
  final comparisonLabels = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initializeDataStream();
  }

  @override
  void onClose() {
    _healthDataSubscription?.cancel();
    super.onClose();
  }

  /// Reset filters to default values (for Dashboard)
  void resetFilters() {
    selectedTimeRange.value = 'Past 14 Days';
    selectedPeriodFilter.value = 'All';
    selectedTrendFilter.value = 'All';
    selectedComparisonFilter.value = 'Before vs. After Meal';
    refreshData();
  }

  /// Initialize data stream
  void _initializeDataStream() {
    final userId = _authRepo.authUser?.uid;
    if (userId == null) return;

    isLoading.value = true;

    final endDate = DateTime.now().add(const Duration(days: 1));
    final startDate = endDate.subtract(const Duration(days: 90));

    _healthDataSubscription = _healthLogRepo
        .getBloodGlucoseLogsStream(userId, startDate, endDate)
        .listen(
          (filteredLogs) {
        healthDataList.value = filteredLogs;

        if (filteredLogs.isNotEmpty) {
          lastRecord.value = filteredLogs.first;
        } else {
          lastRecord.value = null;
        }

        refreshData();
        isLoading.value = false;
      },
      onError: (error) {
        TLoaders.errorSnackBar(
          title: 'Error',
          message: 'Failed to load health data: ${error.toString()}',
        );
        isLoading.value = false;
      },
    );
  }

  /// Update dashboard counts
  void _updateDashboardCounts() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    todayCount.value = healthDataList
        .where((data) =>
    data.logDateTime.isAfter(today) &&
        data.bloodGlucose.glucoseLevel > 0)
        .length;

    weekCount.value = healthDataList
        .where((data) =>
    data.logDateTime.isAfter(weekStart) &&
        data.bloodGlucose.glucoseLevel > 0)
        .length;
  }

  void _updatePast14DaysCount() {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 14));
    past14DaysCount.value = healthDataList
        .where((data) =>
    data.logDateTime.isAfter(cutoffDate) &&
        data.bloodGlucose.glucoseLevel > 0)
        .length;
  }

  /// Calculate statistics based on current filters
  void _calculateStatistics() {
    final filteredData = getFilteredData();

    if (filteredData.isEmpty) {
      _resetStatistics();
      return;
    }

    final glucoseValues = filteredData
        .map((data) => data.bloodGlucose.glucoseLevel)
        .where((level) => level > 0)
        .toList();

    if (glucoseValues.isEmpty) {
      _resetStatistics();
      return;
    }

    if (glucoseValues.isNotEmpty) {
      lowestValue.value = glucoseValues.reduce((a, b) => a < b ? a : b);
      highestValue.value = glucoseValues.reduce((a, b) => a > b ? a : b);
      averageValue.value = glucoseValues.reduce((a, b) => a + b) / glucoseValues.length;
    }

    totalCount.value = glucoseValues.length;

    // Calculate level distribution
    int normal = 0, high = 0, low = 0;
    for (final value in glucoseValues) {
      final level = getGlucoseLevel(value);
      switch (level) {
        case HealthLevel.normal:
          normal++;
          break;
        case HealthLevel.high:
          high++;
          break;
        case HealthLevel.low:
          low++;
          break;
        case HealthLevel.invalid:
        case HealthLevel.elevated:
          break;
      }
    }

    normalCount.value = normal;
    highCount.value = high;
    lowCount.value = low;
  }

  /// Reset statistics to zero
  void _resetStatistics() {
    lowestValue.value = -1;
    highestValue.value = -1;
    averageValue.value = -1;
    normalCount.value = 0;
    highCount.value = 0;
    lowCount.value = 0;
    totalCount.value = 0;
  }

  /// Get filtered data based on current filters
  List<HealthDataModel> getFilteredData() {
    List<HealthDataModel> filtered = List.from(healthDataList);

    final timeRangeDays = _getTimeRangeDays(selectedTimeRange.value);
    if (timeRangeDays > 0) {
      final cutoffDate = DateTime.now().subtract(Duration(days: timeRangeDays));
      filtered = filtered
          .where((data) => data.logDateTime.isAfter(cutoffDate))
          .toList();
    }

    if (selectedPeriodFilter.value != 'All') {
      filtered = filtered
          .where((data) =>
      data.physiologicalTimePeriod.displayName ==
          selectedPeriodFilter.value)
          .toList();
    }

    return filtered;
  }

  /// Get time range in days
  int _getTimeRangeDays(String timeRange) {
    switch (timeRange) {
      case 'Past 7 Days':
        return 7;
      case 'Past 14 Days':
        return 14;
      case 'Past 30 Days':
        return 30;
      case 'Past 60 Days':
        return 60;
      case 'Past 90 Days':
        return 90;
      default:
        return 14;
    }
  }

  /// Update charts data
  void _updateChartsData() {
    _updateTrendsData();
    _updateComparisonData();
  }

  /// Update trends chart data
  void _updateTrendsData() {
    final filteredData = getFilteredData();

    List<HealthDataModel> trendFilteredData = filteredData;
    if (selectedTrendFilter.value != 'All') {
      trendFilteredData = filteredData.where((data) {
        final periodName = data.physiologicalTimePeriod.displayName.toLowerCase();

        switch (selectedTrendFilter.value.toLowerCase()) {
          case 'before meal':
            return periodName.contains('before') &&
                (periodName.contains('breakfast') ||
                    periodName.contains('lunch') ||
                    periodName.contains('dinner') ||
                    periodName.contains('snack'));
          case 'after meal':
            return periodName.contains('after') &&
                (periodName.contains('breakfast') ||
                    periodName.contains('lunch') ||
                    periodName.contains('dinner') ||
                    periodName.contains('snack'));
          case 'before exercise':
            return periodName == 'before exercise';
          case 'after exercise':
            return periodName == 'after exercise';
          case 'wake-up':
            return periodName == 'wake-up';
          case 'bedtime':
            return periodName == 'bedtime';
          case 'others':
            return periodName == 'others';
          default:
            return true;
        }
      }).toList();
    }

    if (trendFilteredData.isEmpty) {
      trendsData.clear();
      trendsLabels.clear();
      trendsOriginalDateTimes.clear(); // 清空原始日期时间
      return;
    }

    trendFilteredData.sort((a, b) => a.logDateTime.compareTo(b.logDateTime));

    final spots = <FlSpot>[];
    final labels = <String>[];
    final originalDateTimes = <DateTime>[];

    for (int i = 0; i < trendFilteredData.length; i++) {
      final data = trendFilteredData[i];
      if (data.bloodGlucose.glucoseLevel > 0) {
        spots.add(FlSpot(i.toDouble(), data.bloodGlucose.glucoseLevel));
        labels.add('${data.logDateTime.month}/${data.logDateTime.day}');
        originalDateTimes.add(data.logDateTime);
      }
    }

    trendsData.value = spots;
    trendsLabels.value = labels;
    trendsOriginalDateTimes.value = originalDateTimes;
  }

  /// Update comparison chart data
  void _updateComparisonData() {
    final filteredData = getFilteredData();

    switch (selectedComparisonFilter.value) {
      case 'Before vs. After Meal':
        _updateMealComparisonData(filteredData);
        break;
      case 'Before vs. After Exercise':
        _updateExerciseComparisonData(filteredData);
        break;
    }
  }

  /// Update meal comparison data with new logic
  void _updateMealComparisonData(List<HealthDataModel> data) {
    final mealTypes = ['Breakfast', 'Lunch', 'Snack', 'Dinner'];
    final barGroups = <BarChartGroupData>[];
    final labels = <String>[];
    final differences = <String, double>{};

    int barIndex = 0;

    for (final meal in mealTypes) {
      // Group by date
      final Map<String, List<HealthDataModel>> beforeByDate = {};
      final Map<String, List<HealthDataModel>> afterByDate = {};

      for (final record in data) {
        final dateKey = '${record.logDateTime.month}/${record.logDateTime.day}';
        final periodName = record.physiologicalTimePeriod.displayName;

        if (periodName == 'Before $meal' && record.bloodGlucose.glucoseLevel > 0) {
          beforeByDate.putIfAbsent(dateKey, () => []).add(record);
        } else if (periodName == 'After $meal' && record.bloodGlucose.glucoseLevel > 0) {
          afterByDate.putIfAbsent(dateKey, () => []).add(record);
        }
      }

      // Find dates that have both before and after records
      final commonDates = beforeByDate.keys.toSet().intersection(afterByDate.keys.toSet());

      for (final date in commonDates) {
        // Get the latest record for before and after
        final beforeRecords = beforeByDate[date]!;
        final afterRecords = afterByDate[date]!;

        beforeRecords.sort((a, b) => b.logDateTime.compareTo(a.logDateTime));
        afterRecords.sort((a, b) => b.logDateTime.compareTo(a.logDateTime));

        final beforeValue = beforeRecords.first.bloodGlucose.glucoseLevel;
        final afterValue = afterRecords.first.bloodGlucose.glucoseLevel;

        barGroups.add(
          BarChartGroupData(
            x: barIndex,
            barRods: [
              BarChartRodData(
                toY: beforeValue,
                color: TColors.primary.withOpacity(0.7),
                width: 15,
              ),
              BarChartRodData(
                toY: afterValue,
                color: TColors.primary,
                width: 15,
              ),
            ],
          ),
        );

        // Use full meal name instead of abbreviation
        labels.add('$date\n$meal');
        differences['${meal.substring(0, 1)}$date'] = afterValue - beforeValue;
        barIndex++;
      }
    }

    comparisonBarData.value = barGroups;
    comparisonLabels.value = labels;
    comparisonData.value = differences;
  }

  /// Update exercise comparison data with new logic
  void _updateExerciseComparisonData(List<HealthDataModel> data) {
    // Group by date
    final Map<String, List<HealthDataModel>> beforeByDate = {};
    final Map<String, List<HealthDataModel>> afterByDate = {};

    for (final record in data) {
      final dateKey = '${record.logDateTime.month}/${record.logDateTime.day}';
      final periodName = record.physiologicalTimePeriod.displayName;

      if (periodName == 'Before Exercise' && record.bloodGlucose.glucoseLevel > 0) {
        beforeByDate.putIfAbsent(dateKey, () => []).add(record);
      } else if (periodName == 'After Exercise' && record.bloodGlucose.glucoseLevel > 0) {
        afterByDate.putIfAbsent(dateKey, () => []).add(record);
      }
    }

    // Find dates that have both before and after records
    final commonDates = beforeByDate.keys.toSet().intersection(afterByDate.keys.toSet());

    if (commonDates.isEmpty) {
      comparisonBarData.clear();
      comparisonLabels.clear();
      comparisonData.clear();
      return;
    }

    final barGroups = <BarChartGroupData>[];
    final labels = <String>[];
    final differences = <String, double>{};

    int barIndex = 0;

    for (final date in commonDates) {
      // Get the latest record for before and after
      final beforeRecords = beforeByDate[date]!;
      final afterRecords = afterByDate[date]!;

      beforeRecords.sort((a, b) => b.logDateTime.compareTo(a.logDateTime));
      afterRecords.sort((a, b) => b.logDateTime.compareTo(a.logDateTime));

      final beforeValue = beforeRecords.first.bloodGlucose.glucoseLevel;
      final afterValue = afterRecords.first.bloodGlucose.glucoseLevel;

      barGroups.add(
        BarChartGroupData(
          x: barIndex,
          barRods: [
            BarChartRodData(
              toY: beforeValue,
              color: TColors.primary.withOpacity(0.7),
              width: 15,
            ),
            BarChartRodData(
              toY: afterValue,
              color: TColors.primary,
              width: 15,
            ),
          ],
        ),
      );

      labels.add('$date\nExercise');
      differences['E$date'] = afterValue - beforeValue;
      barIndex++;
    }

    comparisonBarData.value = barGroups;
    comparisonLabels.value = labels;
    comparisonData.value = differences;
  }

  /// Determine glucose level category
  HealthLevel getGlucoseLevel(double glucose) {
    if (glucose < HealthDataRanges.minGlucoseMmolL || glucose > HealthDataRanges.maxGlucoseMmolL) {
      return HealthLevel.invalid;
    }

    if (glucose < 4.5) {
      return HealthLevel.low;
    } else if (glucose <= 10.0) {
      return HealthLevel.normal;
    } else {
      return HealthLevel.high;
    }
  }

  /// Get glucose level color
  Color getGlucoseLevelColor(double glucose) {
    final level = getGlucoseLevel(glucose);
    switch (level) {
      case HealthLevel.low:
        return TColors.glucoseLow;
      case HealthLevel.normal:
        return TColors.glucoseNormal;
      case HealthLevel.high:
        return TColors.glucoseHigh;
      case HealthLevel.invalid:
      case HealthLevel.elevated:
        return TColors.darkGrey;
    }
  }

  /// Update time range
  void updateTimeRange(String timeRange) {
    selectedTimeRange.value = timeRange;
    _calculateStatistics();
    _updateChartsData();
  }

  /// Update period filter
  void updatePeriodFilter(String period) {
    selectedPeriodFilter.value = period;
    _calculateStatistics();
    _updateChartsData();
  }

  /// Update trend filter
  void updateTrendFilter(String filter) {
    selectedTrendFilter.value = filter;
    _updateChartsData();
  }

  /// Update comparison filter
  void updateComparisonFilter(String filter) {
    selectedComparisonFilter.value = filter;
    _updateChartsData();
  }

  /// Navigation methods
  void navigateToLowestRecord() {
    final filteredData = getFilteredData();
    final lowestRecord = filteredData
        .where((data) => data.bloodGlucose.glucoseLevel == lowestValue.value)
        .first;

    Get.to(() => HealthDataEntryScreen(editData: lowestRecord));
  }

  void navigateToHighestRecord() {
    final filteredData = getFilteredData();
    final highestRecord = filteredData
        .where((data) => data.bloodGlucose.glucoseLevel == highestValue.value)
        .first;

    Get.to(() => HealthDataEntryScreen(editData: highestRecord));
  }

  void showAllRecords() {
    Get.to(() => const HealthDataListScreen(
      title: 'All Records',
      healthDataType: HealthDataType.bloodGlucose,
      filterType: 'all',
    ));
  }

  void showNormalRecords() {
    Get.to(() => const HealthDataListScreen(
      title: 'Normal Records',
      healthDataType: HealthDataType.bloodGlucose,
      filterType: 'normal',
    ));
  }

  void showHighRecords() {
    Get.to(() => const HealthDataListScreen(
      title: 'High Records',
      healthDataType: HealthDataType.bloodGlucose,
      filterType: 'high',
    ));
  }

  void showLowRecords() {
    Get.to(() => const HealthDataListScreen(
      title: 'Low Records',
      healthDataType: HealthDataType.bloodGlucose,
      filterType: 'low',
    ));
  }

  /// Delete health data record
  void deleteHealthRecord(String logId) async {
    try {
      final userId = _authRepo.authUser?.uid;
      if (userId == null) return;

      await _healthLogRepo.deleteHealthLog(userId, logId);
      TLoaders.successSnackBar(
          title: 'Success', message: 'Record deleted successfully');
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Error', message: 'Failed to delete record');
    }
  }

  /// Refresh data
  Future<void> refreshData() async {
    _calculateStatistics();
    _updateChartsData();
    _updateDashboardCounts();
    _updatePast14DaysCount();
  }
}