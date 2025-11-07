import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/health_log/health_log_repository.dart';
import '../../../utils/constants/colors.dart';
import '../models/health_data_model.dart';
import '../views/health_data_analytics/widgets/health_data_list_screen.dart';
import '../views/health_data_entry/health_data_entry_screen.dart';
import 'blood_glucose_controller.dart';
import '../../../common/loaders/loaders.dart';

class WeightController extends GetxController {
  // Repositories
  final _healthLogRepo = HealthLogRepository.instance;
  final _authRepo = AuthenticationRepository.instance;

  /// Stream subscription
  StreamSubscription<List<HealthDataModel>>? _healthDataSubscription;

  /// Observable states
  final selectedTimeRange = 'Past 14 Days'.obs;

  final selectedWeightPeriodFilter = 'All'.obs;      // 体重统计周期过滤器
  final selectedWeightTrendFilter = 'All'.obs;       // 体重趋势过滤器
  final selectedBodyFatPeriodFilter = 'All'.obs;     // 体脂统计周期过滤器
  final selectedBodyFatTrendFilter = 'All'.obs;      // 体脂趋势过滤器

  final isLoading = false.obs;

  // Data list
  final healthDataList = <HealthDataModel>[].obs;

  /// Weight Statistics
  final weightLowest = 0.0.obs;
  final weightHighest = 0.0.obs;
  final weightAverage = 0.0.obs;

  /// Body Fat Statistics
  final bodyFatLowest = 0.0.obs;
  final bodyFatHighest = 0.0.obs;
  final bodyFatAverage = 0.0.obs;
  final bodyFatCurrent = 0.0.obs;

  /// Trends data
  final weightTrendsData = <FlSpot>[].obs;
  final bodyFatTrendsData = <FlSpot>[].obs;
  final trendsLabels = <String>[].obs;

  /// Last record
  final lastRecord = Rx<HealthDataModel?>(null);

  /// Dashboard specific
  final past14DaysCount = 0.obs;
  final weightCurrent = 0.0.obs;
  final weightEarliest = 0.0.obs;
  final latestWeightRecord = Rx<HealthDataModel?>(null);

  /// User height and gender
  final height = 170.obs;
  final gender = 'male'.obs;

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
    selectedWeightPeriodFilter.value = 'All';
    selectedWeightTrendFilter.value = 'All';
    selectedBodyFatPeriodFilter.value = 'All';
    selectedBodyFatTrendFilter.value = 'All';
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
        .getBodyCompositionLogsStream(userId, startDate, endDate)
        .listen(
          (filteredLogs) {
        healthDataList.value = filteredLogs;

        _calculateStatistics();
        _generateTrendsData();
        _findLastRecord();
        _updatePast14DaysCount();
        _updateWeightValues();

        isLoading.value = false;
      },
      onError: (error) {
        TLoaders.errorSnackBar(
          title: 'Error',
          message: 'Failed to load weight data: ${error.toString()}',
        );
        isLoading.value = false;
      },
    );
  }

  void _updatePast14DaysCount() {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 14));
    past14DaysCount.value = healthDataList
        .where((data) =>
    data.logDateTime.isAfter(cutoffDate) &&
        data.bodyComposition.weight > 0)
        .length;
  }

  void _updateWeightValues() {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 14));
    final past14DaysData = healthDataList
        .where((data) =>
    data.logDateTime.isAfter(cutoffDate) &&
        data.bodyComposition.weight > 0)
        .toList();

    if (past14DaysData.isEmpty) {
      weightEarliest.value = 0.0;
      weightCurrent.value = 0.0;
      return;
    }

    past14DaysData.sort((a, b) => a.logDateTime.compareTo(b.logDateTime));

    weightEarliest.value = past14DaysData.first.bodyComposition.weight;
    weightCurrent.value = past14DaysData.last.bodyComposition.weight;
    latestWeightRecord.value = past14DaysData.last;
  }

  /// Calculate weight and body fat statistics
  void _calculateStatistics() {
    final weightFilteredData = _getWeightFilteredData();
    final bodyFatFilteredData = _getBodyFatFilteredData();

    // 计算体重统计
    if (weightFilteredData.isEmpty) {
      weightLowest.value = 0.0;
      weightHighest.value = 0.0;
      weightAverage.value = 0.0;
    } else {
      final weightValues = weightFilteredData
          .where((d) => d.bodyComposition.weight > 0)
          .map((d) => d.bodyComposition.weight)
          .toList();

      if (weightValues.isNotEmpty) {
        weightLowest.value = weightValues.reduce((a, b) => a < b ? a : b);
        weightHighest.value = weightValues.reduce((a, b) => a > b ? a : b);
        weightAverage.value =
            weightValues.reduce((a, b) => a + b) / weightValues.length;
      }
    }

    // 计算体脂统计
    if (bodyFatFilteredData.isEmpty) {
      bodyFatLowest.value = 0.0;
      bodyFatHighest.value = 0.0;
      bodyFatAverage.value = 0.0;
    } else {
      final bodyFatValues = bodyFatFilteredData
          .where((d) => d.bodyComposition.bodyFat > 0)
          .map((d) => d.bodyComposition.bodyFat)
          .toList();

      if (bodyFatValues.isNotEmpty) {
        bodyFatLowest.value = bodyFatValues.reduce((a, b) => a < b ? a : b);
        bodyFatHighest.value = bodyFatValues.reduce((a, b) => a > b ? a : b);
        bodyFatAverage.value =
            bodyFatValues.reduce((a, b) => a + b) / bodyFatValues.length;
      }
    }
  }

  /// Generate trends data for charts
  void _generateTrendsData() {
    final weightFilteredData = _getWeightFilteredTrendsData();
    final bodyFatFilteredData = _getBodyFatFilteredTrendsData();

    // 生成体重趋势数据
    if (weightFilteredData.isEmpty) {
      weightTrendsData.clear();
    } else {
      weightFilteredData.sort((a, b) => a.logDateTime.compareTo(b.logDateTime));
      final weightSpots = <FlSpot>[];
      final labels = <String>[];

      for (int i = 0; i < weightFilteredData.length; i++) {
        final data = weightFilteredData[i];
        if (data.bodyComposition.weight > 0) {
          weightSpots.add(FlSpot(i.toDouble(), data.bodyComposition.weight));
        }

        String label;
        if (selectedTimeRange.value == 'Past 7 Days' ||
            selectedTimeRange.value == 'Past 14 Days') {
          label = DateFormat('M/d').format(data.logDateTime);
          if (selectedWeightTrendFilter.value == 'All') {
            label += '\n${DateFormat('HH:mm').format(data.logDateTime)}';
          }
        } else {
          label = DateFormat('M/d').format(data.logDateTime);
        }
        labels.add(label);
      }
      weightTrendsData.value = weightSpots;
    }

    // 生成体脂趋势数据
    if (bodyFatFilteredData.isEmpty) {
      bodyFatTrendsData.clear();
      trendsLabels.clear();
    } else {
      bodyFatFilteredData.sort((a, b) => a.logDateTime.compareTo(b.logDateTime));
      final bodyFatSpots = <FlSpot>[];
      final labels = <String>[];

      for (int i = 0; i < bodyFatFilteredData.length; i++) {
        final data = bodyFatFilteredData[i];
        if (data.bodyComposition.bodyFat > 0) {
          bodyFatSpots.add(FlSpot(i.toDouble(), data.bodyComposition.bodyFat));
        }

        String label;
        if (selectedTimeRange.value == 'Past 7 Days' ||
            selectedTimeRange.value == 'Past 14 Days') {
          label = DateFormat('M/d').format(data.logDateTime);
          if (selectedBodyFatTrendFilter.value == 'All') {
            label += '\n${DateFormat('HH:mm').format(data.logDateTime)}';
          }
        } else {
          label = DateFormat('M/d').format(data.logDateTime);
        }
        labels.add(label);
      }
      bodyFatTrendsData.value = bodyFatSpots;
      trendsLabels.value = labels;
    }
  }

  /// Find last recorded data
  void _findLastRecord() {
    if (healthDataList.isNotEmpty) {
      final sortedData = List<HealthDataModel>.from(healthDataList);
      sortedData.sort((a, b) => b.logDateTime.compareTo(a.logDateTime));

      final record = sortedData.firstWhereOrNull((d) =>
      d.bodyComposition.weight > 0 || (d.bodyComposition.bodyFat > 0));

      lastRecord.value = record;
    }
  }

  /// Get filtered data for weight statistics
  List<HealthDataModel> _getWeightFilteredData() {
    final now = DateTime.now();
    final cutoffDate = _getCutoffDate(now);

    var filtered = healthDataList
        .where((data) =>
    data.logDateTime.isAfter(cutoffDate) && data.bodyComposition.weight > 0)
        .toList();

    if (selectedWeightPeriodFilter.value != 'All') {
      filtered = _applyMealFilter(filtered, selectedWeightPeriodFilter.value);
    }

    return filtered;
  }

  /// Get filtered data for weight trends
  List<HealthDataModel> _getWeightFilteredTrendsData() {
    final now = DateTime.now();
    final cutoffDate = _getCutoffDate(now);

    var filtered = healthDataList
        .where((data) =>
    data.logDateTime.isAfter(cutoffDate) && data.bodyComposition.weight > 0)
        .toList();

    if (selectedWeightTrendFilter.value != 'All') {
      filtered = _applyMealFilter(filtered, selectedWeightTrendFilter.value);
    }

    return filtered;
  }

  /// Get filtered data for body fat statistics
  List<HealthDataModel> _getBodyFatFilteredData() {
    final now = DateTime.now();
    final cutoffDate = _getCutoffDate(now);

    var filtered = healthDataList
        .where((data) =>
    data.logDateTime.isAfter(cutoffDate) && data.bodyComposition.bodyFat > 0)
        .toList();

    if (selectedBodyFatPeriodFilter.value != 'All') {
      filtered = _applyMealFilter(filtered, selectedBodyFatPeriodFilter.value);
    }

    return filtered;
  }

  /// Get filtered data for body fat trends
  List<HealthDataModel> _getBodyFatFilteredTrendsData() {
    final now = DateTime.now();
    final cutoffDate = _getCutoffDate(now);

    var filtered = healthDataList
        .where((data) =>
    data.logDateTime.isAfter(cutoffDate) && data.bodyComposition.bodyFat > 0)
        .toList();

    if (selectedBodyFatTrendFilter.value != 'All') {
      filtered = _applyMealFilter(filtered, selectedBodyFatTrendFilter.value);
    }

    return filtered;
  }

  /// Apply meal filter to data
  List<HealthDataModel> _applyMealFilter(List<HealthDataModel> data, String filter) {
    return data.where((data) {
      final periodName = data.physiologicalTimePeriod.displayName.toLowerCase();

      switch (filter.toLowerCase()) {
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
          return data.physiologicalTimePeriod.displayName == filter;
      }
    }).toList();
  }

  /// Get cutoff date based on selected time range
  DateTime _getCutoffDate(DateTime now) {
    switch (selectedTimeRange.value) {
      case 'Past 7 Days':
        return now.subtract(const Duration(days: 7));
      case 'Past 14 Days':
        return now.subtract(const Duration(days: 14));
      case 'Past 30 Days':
        return now.subtract(const Duration(days: 30));
      case 'Past 60 Days':
        return now.subtract(const Duration(days: 60));
      case 'Past 90 Days':
        return now.subtract(const Duration(days: 90));
      default:
        return now.subtract(const Duration(days: 14));
    }
  }

  /// Reset statistics to zero
  void _resetStatistics() {
    weightLowest.value = 0.0;
    weightHighest.value = 0.0;
    weightAverage.value = 0.0;
    bodyFatLowest.value = 0.0;
    bodyFatHighest.value = 0.0;
    bodyFatAverage.value = 0.0;
  }

  /// Get weight status color based on BMI categories
  Color getWeightStatusColor(double weight) {
    if (weight == 0.0 || height.value == 0.0) return TColors.grey;

    final bmi = weight / ((height.value / 100) * (height.value / 100));
    if (bmi < 18.5) return TColors.weightUnderweight;
    if (bmi < 25) return TColors.weightNormal;
    if (bmi < 30) return TColors.weightOverweight;
    return TColors.weightObese;
  }

  /// Get body fat status color
  Color getBodyFatStatusColor(double bodyFat) {
    if (bodyFat == 0.0) return TColors.grey;

    if (gender.value.toLowerCase() == 'female') {
      if (bodyFat < 16) return TColors.weightUnderweight;
      if (bodyFat <= 30) return TColors.weightNormal;
      if (bodyFat <= 35) return TColors.weightOverweight;
      return TColors.weightObese;
    } else {
      if (bodyFat < 8) return TColors.weightUnderweight;
      if (bodyFat <= 25) return TColors.weightNormal;
      if (bodyFat <= 30) return TColors.weightOverweight;
      return TColors.weightObese;
    }
  }

  /// Chart range calculations
  double getMinWeightForChart() {
    if (weightTrendsData.isEmpty) return 40;
    final minWeight =
    weightTrendsData.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    return (minWeight - 2).clamp(40, double.infinity);
  }

  double getMaxWeightForChart() {
    if (weightTrendsData.isEmpty) return 80;
    final maxWeight =
    weightTrendsData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    return (maxWeight + 2).clamp(0, 120);
  }

  double getMinBodyFatForChart() {
    if (bodyFatTrendsData.isEmpty) return 20;
    final minBodyFat = bodyFatTrendsData
        .map((spot) => spot.y)
        .reduce((a, b) => a < b ? a : b);
    return (minBodyFat - 1).clamp(15, double.infinity);
  }

  double getMaxBodyFatForChart() {
    if (bodyFatTrendsData.isEmpty) return 35;
    final maxBodyFat = bodyFatTrendsData
        .map((spot) => spot.y)
        .reduce((a, b) => a > b ? a : b);
    return (maxBodyFat + 1).clamp(0, 50);
  }

  /// Update time range
  void updateTimeRange(String timeRange) {
    selectedTimeRange.value = timeRange;
    refreshData();
  }

  /// Update period filter for weight
  void updateWeightPeriodFilter(String period) {
    selectedWeightPeriodFilter.value = period;
    refreshData();
  }

  /// Update trend filter for weight
  void updateWeightTrendFilter(String filter) {
    selectedWeightTrendFilter.value = filter;
    _generateTrendsData();
  }

  /// Update period filter for body fat
  void updateBodyFatPeriodFilter(String period) {
    selectedBodyFatPeriodFilter.value = period;
    refreshData();
  }

  /// Update trend filter for body fat
  void updateBodyFatTrendFilter(String filter) {
    selectedBodyFatTrendFilter.value = filter;
    _generateTrendsData();
  }

  /// Refresh all data
  void refreshData() {
    _calculateStatistics();
    _generateTrendsData();
    _findLastRecord();
  }

  /// Navigation methods - 更新为使用对应的过滤器
  void navigateToLowestWeightRecord() {
    final filteredData = _getWeightFilteredData();
    if (filteredData.isEmpty) return;

    final lowestRecord = filteredData
        .where((data) => data.bodyComposition.weight == weightLowest.value)
        .first;
    Get.to(() => HealthDataEntryScreen(editData: lowestRecord));
  }

  void navigateToHighestWeightRecord() {
    final filteredData = _getWeightFilteredData();
    if (filteredData.isEmpty) return;

    final highestRecord = filteredData
        .where((data) => data.bodyComposition.weight == weightHighest.value)
        .first;
    Get.to(() => HealthDataEntryScreen(editData: highestRecord));
  }

  void navigateToLowestBodyFatRecord() {
    final filteredData = _getBodyFatFilteredData();
    if (filteredData.isEmpty) return;

    final lowestRecord = filteredData
        .where((data) => data.bodyComposition.bodyFat == bodyFatLowest.value)
        .first;
    Get.to(() => HealthDataEntryScreen(editData: lowestRecord));
  }

  void navigateToHighestBodyFatRecord() {
    final filteredData = _getBodyFatFilteredData();
    if (filteredData.isEmpty) return;

    final highestRecord = filteredData
        .where((data) => data.bodyComposition.bodyFat == bodyFatHighest.value)
        .first;
    Get.to(() => HealthDataEntryScreen(editData: highestRecord));
  }

  void showAllWeightRecords() {
    Get.to(() => const HealthDataListScreen(
      title: 'All Weight Records',
      healthDataType: HealthDataType.bodyComposition,
      filterType: 'all',
    ));
  }

  void showAllBodyFatRecords() {
    Get.to(() => const HealthDataListScreen(
      title: 'All Body Fat Records',
      healthDataType: HealthDataType.bodyComposition,
      filterType: 'all',
    ));
  }

  /// Get filtered data based on current filters (for HealthDataListScreen)
  List<HealthDataModel> getFilteredData() {
    return _getWeightFilteredData();
  }

  /// Delete health record
  void deleteHealthRecord(String logId) async {
    try {
      final userId = _authRepo.authUser?.uid;
      if (userId == null) return;

      await _healthLogRepo.deleteHealthLog(userId, logId);
      TLoaders.successSnackBar(
          title: 'Success', message: 'Record deleted successfully');
    } catch (e) {
      TLoaders.errorSnackBar(
          title: 'Error', message: 'Failed to delete record');
    }
  }
}