import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/health_log/health_log_repository.dart';
import '../../../utils/constants/colors.dart';
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
  final goodCount = 0.obs;
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
          lastRecord.value = filteredLogs.first; // Most recent
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

    // Calculate basic statistics
    lowestValue.value = glucoseValues.reduce((a, b) => a < b ? a : b);
    highestValue.value = glucoseValues.reduce((a, b) => a > b ? a : b);
    averageValue.value =
        glucoseValues.reduce((a, b) => a + b) / glucoseValues.length;
    totalCount.value = glucoseValues.length;

    // Calculate level distribution
    int good = 0, high = 0, low = 0;
    for (final value in glucoseValues) {
      final level = getGlucoseLevel(value);
      switch (level) {
        case GlucoseLevel.good:
          good++;
          break;
        case GlucoseLevel.high:
          high++;
          break;
        case GlucoseLevel.low:
          low++;
          break;
      }
    }

    goodCount.value = good;
    highCount.value = high;
    lowCount.value = low;
  }

  /// Reset statistics to zero
  void _resetStatistics() {
    lowestValue.value = 0.0;
    highestValue.value = 0.0;
    averageValue.value = 0.0;
    goodCount.value = 0;
    highCount.value = 0;
    lowCount.value = 0;
    totalCount.value = 0;
  }

  /// Get filtered data based on current filters
  List<HealthDataModel> getFilteredData() {
    List<HealthDataModel> filtered = List.from(healthDataList);

    // Apply time range filter
    final timeRangeDays = _getTimeRangeDays(selectedTimeRange.value);
    if (timeRangeDays > 0) {
      final cutoffDate = DateTime.now().subtract(Duration(days: timeRangeDays));
      filtered = filtered
          .where((data) => data.logDateTime.isAfter(cutoffDate))
          .toList();
    }

    // Apply period filter
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

    // Filter by trend filter
    List<HealthDataModel> trendFilteredData = filteredData;
    if (selectedTrendFilter.value != 'All') {
      trendFilteredData = filteredData.where((data) {
        final periodName = data.physiologicalTimePeriod.displayName.toLowerCase();

        switch (selectedTrendFilter.value.toLowerCase()) {
          case 'before meal':
          // Include: Before Breakfast, Before Lunch, Before Dinner, Before Snack
            return periodName.contains('before') &&
                (periodName.contains('breakfast') ||
                    periodName.contains('lunch') ||
                    periodName.contains('dinner') ||
                    periodName.contains('snack'));
          case 'after meal':
          // Include: After Breakfast, After Lunch, After Dinner, After Snack
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
      return;
    }

    // Sort by date
    trendFilteredData.sort((a, b) => a.logDateTime.compareTo(b.logDateTime));

    // Create spots for line chart
    final spots = <FlSpot>[];
    final labels = <String>[];

    for (int i = 0; i < trendFilteredData.length; i++) {
      final data = trendFilteredData[i];
      if (data.bloodGlucose.glucoseLevel > 0) {
        spots.add(FlSpot(i.toDouble(), data.bloodGlucose.glucoseLevel));
        labels.add('${data.logDateTime.month}/${data.logDateTime.day}');
      }
    }

    trendsData.value = spots;
    trendsLabels.value = labels;
  }

  /// Update comparison chart data
  void _updateComparisonData() {
    final filteredData = getFilteredData();

    switch (selectedComparisonFilter.value) {
      case 'Before vs. After Meal':
        _updateMealComparisonData(filteredData);
        break;
      case 'Morning vs. Evening':
        _updateTimeComparisonData(filteredData);
        break;
      case 'Pre vs. Post Exercise':
        _updateExerciseComparisonData(filteredData);
        break;
    }
  }

  /// Update meal comparison data
  void _updateMealComparisonData(List<HealthDataModel> data) {
    final mealTypes = ['Breakfast', 'Lunch', 'Dinner'];
    final barGroups = <BarChartGroupData>[];
    final labels = <String>[];
    final differences = <String, double>{};

    for (int i = 0; i < mealTypes.length; i++) {
      final meal = mealTypes[i];
      final beforeData = data
          .where((d) =>
      d.physiologicalTimePeriod.displayName == 'Before $meal' &&
          d.bloodGlucose.glucoseLevel > 0)
          .toList();
      final afterData = data
          .where((d) =>
      d.physiologicalTimePeriod.displayName == 'After $meal' &&
          d.bloodGlucose.glucoseLevel > 0)
          .toList();

      if (beforeData.isNotEmpty && afterData.isNotEmpty) {
        final beforeAvg = beforeData
            .map((d) => d.bloodGlucose.glucoseLevel)
            .reduce((a, b) => a + b) /
            beforeData.length;
        final afterAvg = afterData
            .map((d) => d.bloodGlucose.glucoseLevel)
            .reduce((a, b) => a + b) /
            afterData.length;

        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: beforeAvg,
                color: TColors.primary.withOpacity(0.7),
                width: 15,
              ),
              BarChartRodData(
                toY: afterAvg,
                color: TColors.primary,
                width: 15,
              ),
            ],
          ),
        );

        labels.add(meal);
        differences['${meal.substring(0, 1)}'] = afterAvg - beforeAvg;
      }
    }

    comparisonBarData.value = barGroups;
    comparisonLabels.value = labels;
    comparisonData.value = differences;
  }

  /// Update time comparison data
  void _updateTimeComparisonData(List<HealthDataModel> data) {
    final morningData = data
        .where((d) =>
    d.logDateTime.hour < 12 && d.bloodGlucose.glucoseLevel > 0)
        .toList();
    final eveningData = data
        .where((d) =>
    d.logDateTime.hour >= 18 && d.bloodGlucose.glucoseLevel > 0)
        .toList();

    if (morningData.isNotEmpty && eveningData.isNotEmpty) {
      final morningAvg = morningData
          .map((d) => d.bloodGlucose.glucoseLevel)
          .reduce((a, b) => a + b) /
          morningData.length;
      final eveningAvg = eveningData
          .map((d) => d.bloodGlucose.glucoseLevel)
          .reduce((a, b) => a + b) /
          eveningData.length;

      comparisonBarData.value = [
        BarChartGroupData(
          x: 0,
          barRods: [
            BarChartRodData(
              toY: morningAvg,
              color: TColors.primary,
              width: 30,
            ),
          ],
        ),
        BarChartGroupData(
          x: 1,
          barRods: [
            BarChartRodData(
              toY: eveningAvg,
              color: TColors.primary.withOpacity(0.7),
              width: 30,
            ),
          ],
        ),
      ];

      comparisonLabels.value = ['Morning', 'Evening'];
      comparisonData.value = {'Diff': eveningAvg - morningAvg};
    } else {
      comparisonBarData.clear();
      comparisonLabels.clear();
      comparisonData.clear();
    }
  }

  /// Update exercise comparison data
  void _updateExerciseComparisonData(List<HealthDataModel> data) {
    final preExerciseData = data
        .where((d) =>
    d.physiologicalTimePeriod.displayName == 'Before Exercise' &&
        d.bloodGlucose.glucoseLevel > 0)
        .toList();
    final postExerciseData = data
        .where((d) =>
    d.physiologicalTimePeriod.displayName == 'After Exercise' &&
        d.bloodGlucose.glucoseLevel > 0)
        .toList();

    if (preExerciseData.isNotEmpty && postExerciseData.isNotEmpty) {
      final preAvg = preExerciseData
          .map((d) => d.bloodGlucose.glucoseLevel)
          .reduce((a, b) => a + b) /
          preExerciseData.length;
      final postAvg = postExerciseData
          .map((d) => d.bloodGlucose.glucoseLevel)
          .reduce((a, b) => a + b) /
          postExerciseData.length;

      comparisonBarData.value = [
        BarChartGroupData(
          x: 0,
          barRods: [
            BarChartRodData(
              toY: preAvg,
              color: TColors.primary,
              width: 30,
            ),
          ],
        ),
        BarChartGroupData(
          x: 1,
          barRods: [
            BarChartRodData(
              toY: postAvg,
              color: TColors.primary.withOpacity(0.7),
              width: 30,
            ),
          ],
        ),
      ];

      comparisonLabels.value = ['Before Exercise', 'After Exercise'];
      comparisonData.value = {'Diff': postAvg - preAvg};
    } else {
      comparisonBarData.clear();
      comparisonLabels.clear();
      comparisonData.clear();
    }
  }

  /// Determine glucose level category
  GlucoseLevel getGlucoseLevel(double glucose) {
    if (glucose < 4.0) {
      return GlucoseLevel.low;
    } else if (glucose <= 10.0) {
      return GlucoseLevel.good;
    } else {
      return GlucoseLevel.high;
    }
  }

  /// Get glucose level color
  Color getGlucoseLevelColor(double glucose) {
    final level = getGlucoseLevel(glucose);
    switch (level) {
      case GlucoseLevel.low:
        return TColors.glucoseLow;
      case GlucoseLevel.good:
        return TColors.glucoseGood;
      case GlucoseLevel.high:
        return TColors.glucoseHigh;
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
    final filteredData = getFilteredData();
    Get.to(() => HealthDataListScreen(
      title: 'All Records',
      healthDataList: filteredData,
      healthDataType: HealthDataType.bloodGlucose,
    ));
  }

  void showGoodRecords() {
    final filteredData = getFilteredData();
    final goodRecords = filteredData
        .where((data) =>
    getGlucoseLevel(data.bloodGlucose.glucoseLevel) ==
        GlucoseLevel.good)
        .toList();

    Get.to(() => HealthDataListScreen(
      title: 'Good Records',
      healthDataList: goodRecords,
      healthDataType: HealthDataType.bloodGlucose,
    ));
  }

  void showHighRecords() {
    final filteredData = getFilteredData();
    final highRecords = filteredData
        .where((data) =>
    getGlucoseLevel(data.bloodGlucose.glucoseLevel) ==
        GlucoseLevel.high)
        .toList();

    Get.to(() => HealthDataListScreen(
      title: 'High Records',
      healthDataList: highRecords,
      healthDataType: HealthDataType.bloodGlucose,
    ));
  }

  void showLowRecords() {
    final filteredData = getFilteredData();
    final lowRecords = filteredData
        .where((data) =>
    getGlucoseLevel(data.bloodGlucose.glucoseLevel) == GlucoseLevel.low)
        .toList();

    Get.to(() => HealthDataListScreen(
      title: 'Low Records',
      healthDataList: lowRecords,
      healthDataType: HealthDataType.bloodGlucose,
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
      // Stream will automatically update the data
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Error', message: 'Failed to delete record');
    }
  }

  /// Refresh data (Stream handles this automatically, but kept for compatibility)
  Future<void> refreshData() async {
    // Stream already handles real-time updates
    // This method is kept for manual refresh if needed
    _calculateStatistics();
    _updateChartsData();
    _updateDashboardCounts();
    _updatePast14DaysCount();
  }
}

/// Glucose Level Enum
enum GlucoseLevel {
  low,
  good,
  high,
}

/// Health Data Type Enum
enum HealthDataType {
  bloodGlucose,
  bloodPressure,
  bodyComposition,
  physicalActivity,
}