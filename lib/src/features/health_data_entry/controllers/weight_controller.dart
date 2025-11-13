import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/health_log/health_log_repository.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/helpers/bmi_calculator.dart';
import '../../../utils/helpers/body_fat_calculator.dart';
import '../../personalization/controllers/user_controller.dart';
import '../models/health_data_model.dart';
import '../views/health_data_analytics/widgets/health_data_list_screen.dart';
import '../views/health_data_entry/health_data_entry_screen.dart';
import '../../../common/loaders/loaders.dart';

class WeightController extends GetxController {
  // Repositories
  final _healthLogRepo = HealthLogRepository.instance;
  final _authRepo = AuthenticationRepository.instance;
  final _userController = UserController.instance;

  /// Stream subscription
  StreamSubscription<List<HealthDataModel>>? _healthDataSubscription;

  /// Observable states
  final selectedTimeRange = 'Past 14 Days'.obs;

  final selectedWeightPeriodFilter = 'All'.obs;
  final selectedWeightTrendFilter = 'All'.obs;
  final selectedBodyFatPeriodFilter = 'All'.obs;
  final selectedBodyFatTrendFilter = 'All'.obs;

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
  final weightTrendsLabels = <String>[].obs;
  final bodyFatTrendsLabels = <String>[].obs;

  /// Trend indicators
  final weightTrendValue = 0.0.obs;
  final weightTrendDirection = ''.obs; // 'up', 'down', or 'no change'
  final bodyFatTrendValue = 0.0.obs;
  final bodyFatTrendDirection = ''.obs;
  final weightTrendsOriginalDateTimes = <DateTime>[].obs; // 体重原始日期时间
  final bodyFatTrendsOriginalDateTimes = <DateTime>[].obs; // 体脂原始日期时间

  /// Last record
  final lastRecord = Rx<HealthDataModel?>(null);

  /// Dashboard specific
  final past14DaysCount = 0.obs;
  final weightCurrent = 0.0.obs;
  final weightEarliest = 0.0.obs;
  final latestWeightRecord = Rx<HealthDataModel?>(null);

  /// User height and gender
  double get height => _userController.user.value.profile.height;
  String get gender => _userController.user.value.profile.gender;
  int? get ageInMonths => _userController.user.value.profile.ageInMonths;

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
        _calculateTrends();
        _findLastRecord();
        _updatePast14DaysCount();
        _updateWeightValues();
        _updateBodyFatValues();

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
    final filteredData = _getWeightFilteredData();

    if (filteredData.isEmpty) {
      weightEarliest.value = 0.0;
      weightCurrent.value = 0.0;
      latestWeightRecord.value = null;
      return;
    }

    // 确保数据按时间排序
    filteredData.sort((a, b) => a.logDateTime.compareTo(b.logDateTime));

    // 只取有有效体重的记录
    final validWeightData = filteredData.where((d) => d.bodyComposition.weight > 0).toList();

    if (validWeightData.isNotEmpty) {
      weightEarliest.value = validWeightData.first.bodyComposition.weight;
      weightCurrent.value = validWeightData.last.bodyComposition.weight;
      latestWeightRecord.value = validWeightData.last;
    } else {
      weightEarliest.value = 0.0;
      weightCurrent.value = 0.0;
      latestWeightRecord.value = null;
    }
  }

  void _updateBodyFatValues() {
    final filteredData = _getBodyFatFilteredData();

    if (filteredData.isEmpty) {
      bodyFatCurrent.value = 0.0;
      return;
    }

    filteredData.sort((a, b) => a.logDateTime.compareTo(b.logDateTime));

    // 只取有有效体脂的记录
    final validBodyFatData = filteredData.where((d) => d.bodyComposition.bodyFat > 0).toList();

    if (validBodyFatData.isNotEmpty) {
      bodyFatCurrent.value = validBodyFatData.last.bodyComposition.bodyFat;
    } else {
      bodyFatCurrent.value = 0.0;
    }
  }

  /// Calculate weight and body fat statistics
  void _calculateStatistics() {
    final weightFilteredData = _getWeightFilteredData();
    final bodyFatFilteredData = _getBodyFatFilteredData();

    // Calculate weight statistics
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
        weightAverage.value = weightValues.reduce((a, b) => a + b) / weightValues.length;
      } else {
        weightLowest.value = 0.0;
        weightHighest.value = 0.0;
        weightAverage.value = 0.0;
      }
    }

    // Calculate body fat statistics
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
        bodyFatAverage.value = bodyFatValues.reduce((a, b) => a + b) / bodyFatValues.length;
      } else {
        bodyFatLowest.value = 0.0;
        bodyFatHighest.value = 0.0;
        bodyFatAverage.value = 0.0;
      }
    }
  }

  /// Calculate trends (difference between current and earliest)
  void _calculateTrends() {
    // Weight trend
    final weightFilteredData = _getWeightFilteredTrendsData();
    if (weightFilteredData.isNotEmpty && weightFilteredData.length >= 2) {
      weightFilteredData.sort((a, b) => a.logDateTime.compareTo(b.logDateTime));
      final earliest = weightFilteredData.first.bodyComposition.weight;
      final current = weightFilteredData.last.bodyComposition.weight;
      final diff = current - earliest;

      weightTrendValue.value = diff.abs();
      if (diff > 0) {
        weightTrendDirection.value = 'up';
      } else if (diff < 0) {
        weightTrendDirection.value = 'down';
      } else {
        weightTrendDirection.value = 'no change';
      }
    } else {
      weightTrendValue.value = 0.0;
      weightTrendDirection.value = '';
    }

    // Body fat trend
    final bodyFatFilteredData = _getBodyFatFilteredTrendsData();
    if (bodyFatFilteredData.isNotEmpty && bodyFatFilteredData.length >= 2) {
      bodyFatFilteredData.sort((a, b) => a.logDateTime.compareTo(b.logDateTime));
      final earliest = bodyFatFilteredData.first.bodyComposition.bodyFat;
      final current = bodyFatFilteredData.last.bodyComposition.bodyFat;
      final diff = current - earliest;

      bodyFatTrendValue.value = diff.abs();
      if (diff > 0) {
        bodyFatTrendDirection.value = 'up';
      } else if (diff < 0) {
        bodyFatTrendDirection.value = 'down';
      } else {
        bodyFatTrendDirection.value = 'no change';
      }
    } else {
      bodyFatTrendValue.value = 0.0;
      bodyFatTrendDirection.value = '';
    }
  }

  /// Generate trends data for charts
  void _generateTrendsData() {
    final weightFilteredData = _getWeightFilteredTrendsData();
    final bodyFatFilteredData = _getBodyFatFilteredTrendsData();

    // Generate weight trends data
    if (weightFilteredData.isEmpty) {
      weightTrendsData.clear();
      weightTrendsLabels.clear();
      weightTrendsOriginalDateTimes.clear(); // 清空体重原始日期时间
    } else {
      weightFilteredData.sort((a, b) => a.logDateTime.compareTo(b.logDateTime));
      final weightSpots = <FlSpot>[];
      final weightLabels = <String>[];
      final weightOriginalDateTimes = <DateTime>[]; // 体重原始日期时间

      for (int i = 0; i < weightFilteredData.length; i++) {
        final data = weightFilteredData[i];
        if (data.bodyComposition.weight > 0) {
          weightSpots.add(FlSpot(i.toDouble(), data.bodyComposition.weight));
          weightOriginalDateTimes.add(data.logDateTime); // 存储体重原始日期时间
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
        weightLabels.add(label);
      }
      weightTrendsData.value = weightSpots;
      weightTrendsLabels.value = weightLabels;
      weightTrendsOriginalDateTimes.value = weightOriginalDateTimes; // 设置体重原始日期时间
    }

    // Generate body fat trends data
    if (bodyFatFilteredData.isEmpty) {
      bodyFatTrendsData.clear();
      bodyFatTrendsLabels.clear();
      bodyFatTrendsOriginalDateTimes.clear(); // 清空体脂原始日期时间
    } else {
      bodyFatFilteredData.sort((a, b) => a.logDateTime.compareTo(b.logDateTime));
      final bodyFatSpots = <FlSpot>[];
      final bodyFatLabels = <String>[];
      final bodyFatOriginalDateTimes = <DateTime>[]; // 体脂原始日期时间

      for (int i = 0; i < bodyFatFilteredData.length; i++) {
        final data = bodyFatFilteredData[i];
        if (data.bodyComposition.bodyFat > 0) {
          bodyFatSpots.add(FlSpot(i.toDouble(), data.bodyComposition.bodyFat));
          bodyFatOriginalDateTimes.add(data.logDateTime); // 存储体脂原始日期时间
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
        bodyFatLabels.add(label);
      }
      bodyFatTrendsData.value = bodyFatSpots;
      bodyFatTrendsLabels.value = bodyFatLabels;
      bodyFatTrendsOriginalDateTimes.value = bodyFatOriginalDateTimes; // 设置体脂原始日期时间
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
    if (weight == 0.0 || height == 0) return TColors.grey;

    final category = BMICalculator.getBMICategory(
      weight: weight,
      height: height.toDouble(),
      ageInMonths: ageInMonths,
      gender: gender,
    );

    switch (category.level) {
      case 1: // Underweight
        return TColors.weightUnderweight;
      case 2: // Normal
        return TColors.weightNormal;
      case 3: // Overweight
        return TColors.weightOverweight;
      case 4: // Obese
        return TColors.weightObese;
      default:
        return TColors.grey;
    }
  }

  /// Get body fat status color
  Color getBodyFatStatusColor(double bodyFat) {
    if (bodyFat == 0.0 || ageInMonths == null) return TColors.grey;

    final level = BodyFatCalculator.getBodyFatLevel(
      bodyFatPercentage: bodyFat,
      gender: gender,
      age: (ageInMonths! / 12).floor(),
    );

    switch (level) {
      case HealthLevel.low:
        return TColors.bodyFatLow;
      case HealthLevel.normal:
        return TColors.bodyFatNormal;
      case HealthLevel.elevated:
        return TColors.bodyFatElevated;
      case HealthLevel.high:
        return TColors.bodyFatHigh;
      default:
        return TColors.grey;
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
    _calculateTrends();
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
    _calculateTrends();
  }

  /// Refresh all data
  void refreshData() {
    _calculateStatistics();
    _generateTrendsData();
    _calculateTrends();
    _findLastRecord();
    _updateWeightValues();
    _updateBodyFatValues();
  }

  /// Navigation methods
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