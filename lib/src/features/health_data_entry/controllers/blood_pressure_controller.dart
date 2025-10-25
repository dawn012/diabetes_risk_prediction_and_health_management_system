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

class BloodPressureController extends GetxController {
  // Repositories
  final _healthLogRepo = HealthLogRepository.instance;
  final _authRepo = AuthenticationRepository.instance;

  // Stream subscription
  StreamSubscription<List<HealthDataModel>>? _healthDataSubscription;

  // Observable states
  final selectedTimeRange = 'Past 14 Days'.obs;

  final selectedBpPeriodFilter = 'All'.obs;      // 血压统计周期过滤器
  final selectedBpTrendFilter = 'All'.obs;       // 血压趋势过滤器
  final selectedPulsePeriodFilter = 'All'.obs;   // 脉搏统计周期过滤器
  final selectedPulseTrendFilter = 'All'.obs;    // 脉搏趋势过滤器

  final isLoading = false.obs;

  // Data list
  final healthDataList = <HealthDataModel>[].obs;

  // Blood Pressure Statistics
  final systolicLowest = 0.obs;
  final systolicHighest = 0.obs;
  final systolicAverage = 0.0.obs;
  final diastolicLowest = 0.obs;
  final diastolicHighest = 0.obs;
  final diastolicAverage = 0.0.obs;

  // Pulse Statistics
  final pulseLowest = 0.obs;
  final pulseHighest = 0.obs;
  final pulseAverage = 0.0.obs;

  // Distribution counts
  final normalCount = 0.obs;
  final elevatedCount = 0.obs;
  final highCount = 0.obs;
  final lowCount = 0.obs;
  final totalCount = 0.obs;

  // Dashboard specific
  final todayCount = 0.obs;
  final weekCount = 0.obs;
  final past14DaysCount = 0.obs;

  // Trends data
  final systolicTrendsData = <FlSpot>[].obs;
  final diastolicTrendsData = <FlSpot>[].obs;
  final pulseTrendsData = <FlSpot>[].obs;
  final trendsLabels = <String>[].obs;

  // Last record
  final lastRecord = Rx<HealthDataModel?>(null);

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
    selectedBpPeriodFilter.value = 'All';
    selectedBpTrendFilter.value = 'All';
    selectedPulsePeriodFilter.value = 'All';
    selectedPulseTrendFilter.value = 'All';
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
        .getBloodPressureLogsStream(userId, startDate, endDate)
        .listen(
          (filteredLogs) {
        healthDataList.value = filteredLogs;

        _calculateStatistics();
        _generateTrendsData();
        _findLastRecord();
        _updateDashboardCounts();
        _updatePast14DaysCount();

        isLoading.value = false;
      },
      onError: (error) {
        TLoaders.errorSnackBar(
          title: 'Error',
          message: 'Failed to load blood pressure data: ${error.toString()}',
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
        (data.bloodPressure.systolic > 0 || data.bloodPressure.diastolic > 0))
        .length;

    weekCount.value = healthDataList
        .where((data) =>
    data.logDateTime.isAfter(weekStart) &&
        (data.bloodPressure.systolic > 0 || data.bloodPressure.diastolic > 0))
        .length;
  }

  void _updatePast14DaysCount() {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 14));
    past14DaysCount.value = healthDataList
        .where((data) =>
    data.logDateTime.isAfter(cutoffDate) &&
        (data.bloodPressure.systolic > 0 || data.bloodPressure.diastolic > 0))
        .length;
  }

  /// Calculate blood pressure and pulse statistics
  void _calculateStatistics() {
    final bpFilteredData = _getBpFilteredData();
    final pulseFilteredData = _getPulseFilteredData();

    // 计算血压统计
    if (bpFilteredData.isEmpty) {
      systolicLowest.value = 0;
      systolicHighest.value = 0;
      systolicAverage.value = 0.0;
      diastolicLowest.value = 0;
      diastolicHighest.value = 0;
      diastolicAverage.value = 0.0;
      normalCount.value = 0;
      elevatedCount.value = 0;
      highCount.value = 0;
      lowCount.value = 0;
      totalCount.value = 0;
    } else {
      final systolicValues = bpFilteredData
          .where((d) => d.bloodPressure.systolic > 0)
          .map((d) => d.bloodPressure.systolic)
          .toList();

      final diastolicValues = bpFilteredData
          .where((d) => d.bloodPressure.diastolic > 0)
          .map((d) => d.bloodPressure.diastolic)
          .toList();

      if (systolicValues.isNotEmpty) {
        systolicLowest.value = systolicValues.reduce((a, b) => a < b ? a : b);
        systolicHighest.value = systolicValues.reduce((a, b) => a > b ? a : b);
        systolicAverage.value =
            systolicValues.reduce((a, b) => a + b) / systolicValues.length;
      }

      if (diastolicValues.isNotEmpty) {
        diastolicLowest.value = diastolicValues.reduce((a, b) => a < b ? a : b);
        diastolicHighest.value = diastolicValues.reduce((a, b) => a > b ? a : b);
        diastolicAverage.value =
            diastolicValues.reduce((a, b) => a + b) / diastolicValues.length;
      }

      _calculateDistribution(bpFilteredData);
    }

    // 计算脉搏统计
    if (pulseFilteredData.isEmpty) {
      pulseLowest.value = 0;
      pulseHighest.value = 0;
      pulseAverage.value = 0.0;
    } else {
      final pulseValues = pulseFilteredData
          .where((d) => d.bloodPressure.pulse > 0)
          .map((d) => d.bloodPressure.pulse)
          .toList();

      if (pulseValues.isNotEmpty) {
        pulseLowest.value = pulseValues.reduce((a, b) => a < b ? a : b);
        pulseHighest.value = pulseValues.reduce((a, b) => a > b ? a : b);
        pulseAverage.value =
            pulseValues.reduce((a, b) => a + b) / pulseValues.length;
      }
    }
  }

  /// Calculate blood pressure distribution
  void _calculateDistribution(List<HealthDataModel> data) {
    int normal = 0, elevated = 0, high = 0, low = 0;

    for (final record in data) {
      final sys = record.bloodPressure.systolic;
      final dia = record.bloodPressure.diastolic;

      if (sys > 0 || dia > 0) {
        final category = _getBPCategory(sys, dia);
        switch (category) {
          case 'Normal':
            normal++;
            break;
          case 'Elevated':
            elevated++;
            break;
          case 'High':
            high++;
            break;
          case 'Low':
            low++;
            break;
        }
      }
    }

    normalCount.value = normal;
    elevatedCount.value = elevated;
    highCount.value = high;
    lowCount.value = low;
    totalCount.value = normal + elevated + high + low;
  }

  /// Generate trends data for charts
  void _generateTrendsData() {
    final bpFilteredData = _getBpFilteredTrendsData();
    final pulseFilteredData = _getPulseFilteredTrendsData();

    // 生成血压趋势数据
    if (bpFilteredData.isEmpty) {
      systolicTrendsData.clear();
      diastolicTrendsData.clear();
    } else {
      bpFilteredData.sort((a, b) => a.logDateTime.compareTo(b.logDateTime));
      final systolicSpots = <FlSpot>[];
      final diastolicSpots = <FlSpot>[];

      for (int i = 0; i < bpFilteredData.length; i++) {
        final data = bpFilteredData[i];
        if (data.bloodPressure.systolic > 0) {
          systolicSpots.add(
              FlSpot(i.toDouble(), data.bloodPressure.systolic.toDouble()));
        }
        if (data.bloodPressure.diastolic > 0) {
          diastolicSpots.add(
              FlSpot(i.toDouble(), data.bloodPressure.diastolic.toDouble()));
        }
      }
      systolicTrendsData.value = systolicSpots;
      diastolicTrendsData.value = diastolicSpots;
    }

    // 生成脉搏趋势数据
    if (pulseFilteredData.isEmpty) {
      pulseTrendsData.clear();
      trendsLabels.clear();
    } else {
      pulseFilteredData.sort((a, b) => a.logDateTime.compareTo(b.logDateTime));
      final pulseSpots = <FlSpot>[];
      final labels = <String>[];

      for (int i = 0; i < pulseFilteredData.length; i++) {
        final data = pulseFilteredData[i];
        if (data.bloodPressure.pulse > 0) {
          pulseSpots
              .add(FlSpot(i.toDouble(), data.bloodPressure.pulse.toDouble()));
        }

        String label;
        if (selectedTimeRange.value == 'Past 7 Days' ||
            selectedTimeRange.value == 'Past 14 Days') {
          label = DateFormat('M/d').format(data.logDateTime);
          if (selectedPulseTrendFilter.value == 'All') {
            label += '\n${DateFormat('HH:mm').format(data.logDateTime)}';
          }
        } else {
          label = DateFormat('M/d').format(data.logDateTime);
        }
        labels.add(label);
      }
      pulseTrendsData.value = pulseSpots;
      trendsLabels.value = labels;
    }
  }

  /// Find last recorded data
  void _findLastRecord() {
    if (healthDataList.isNotEmpty) {
      final sortedData = List<HealthDataModel>.from(healthDataList);
      sortedData.sort((a, b) => b.logDateTime.compareTo(a.logDateTime));

      final record = sortedData.firstWhereOrNull((d) =>
      d.bloodPressure.systolic > 0 ||
          d.bloodPressure.diastolic > 0 ||
          d.bloodPressure.pulse > 0);

      lastRecord.value = record;
    }
  }

  /// Get filtered data for blood pressure statistics
  List<HealthDataModel> _getBpFilteredData() {
    final now = DateTime.now();
    final cutoffDate = _getCutoffDate(now);

    var filtered = healthDataList
        .where((data) =>
    data.logDateTime.isAfter(cutoffDate) &&
        (data.bloodPressure.systolic > 0 || data.bloodPressure.diastolic > 0))
        .toList();

    if (selectedBpPeriodFilter.value != 'All') {
      filtered = _applyMealFilter(filtered, selectedBpPeriodFilter.value);
    }

    return filtered;
  }

  /// Get filtered data for blood pressure trends
  List<HealthDataModel> _getBpFilteredTrendsData() {
    final now = DateTime.now();
    final cutoffDate = _getCutoffDate(now);

    var filtered = healthDataList
        .where((data) =>
    data.logDateTime.isAfter(cutoffDate) &&
        (data.bloodPressure.systolic > 0 || data.bloodPressure.diastolic > 0))
        .toList();

    if (selectedBpTrendFilter.value != 'All') {
      filtered = _applyMealFilter(filtered, selectedBpTrendFilter.value);
    }

    return filtered;
  }

  /// Get filtered data for pulse statistics
  List<HealthDataModel> _getPulseFilteredData() {
    final now = DateTime.now();
    final cutoffDate = _getCutoffDate(now);

    var filtered = healthDataList
        .where((data) =>
    data.logDateTime.isAfter(cutoffDate) && data.bloodPressure.pulse > 0)
        .toList();

    if (selectedPulsePeriodFilter.value != 'All') {
      filtered = _applyMealFilter(filtered, selectedPulsePeriodFilter.value);
    }

    return filtered;
  }

  /// Get filtered data for pulse trends
  List<HealthDataModel> _getPulseFilteredTrendsData() {
    final now = DateTime.now();
    final cutoffDate = _getCutoffDate(now);

    var filtered = healthDataList
        .where((data) =>
    data.logDateTime.isAfter(cutoffDate) && data.bloodPressure.pulse > 0)
        .toList();

    if (selectedPulseTrendFilter.value != 'All') {
      filtered = _applyMealFilter(filtered, selectedPulseTrendFilter.value);
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

  /// Get blood pressure category
  String _getBPCategory(int systolic, int diastolic) {
    if (systolic < 90 || diastolic < 60) {
      return 'Low';
    } else if (systolic < 120 && diastolic < 80) {
      return 'Normal';
    } else if (systolic < 130 && diastolic < 80) {
      return 'Elevated';
    } else {
      return 'High';
    }
  }

  /// Get blood pressure level color
  Color getBPLevelColor(int systolic, int diastolic) {
    final category = _getBPCategory(systolic, diastolic);
    switch (category) {
      case 'Low':
        return TColors.bpLow;
      case 'Normal':
        return TColors.bpNormal;
      case 'Elevated':
        return TColors.bpElevated;
      case 'High':
        return TColors.bpHigh;
      default:
        return TColors.bpNormal;
    }
  }

  /// Get pulse level color
  Color getPulseLevelColor(int pulse) {
    if (pulse < 60) {
      return TColors.bpLow;
    } else if (pulse <= 100) {
      return TColors.bpNormal;
    } else {
      return TColors.bpHigh;
    }
  }

  /// Update time range
  void updateTimeRange(String timeRange) {
    selectedTimeRange.value = timeRange;
    refreshData();
  }

  /// Update period filter for blood pressure
  void updateBpPeriodFilter(String period) {
    selectedBpPeriodFilter.value = period;
    refreshData();
  }

  /// Update trend filter for blood pressure
  void updateBpTrendFilter(String filter) {
    selectedBpTrendFilter.value = filter;
    _generateTrendsData();
  }

  /// Update period filter for pulse
  void updatePulsePeriodFilter(String period) {
    selectedPulsePeriodFilter.value = period;
    refreshData();
  }

  /// Update trend filter for pulse
  void updatePulseTrendFilter(String filter) {
    selectedPulseTrendFilter.value = filter;
    _generateTrendsData();
  }

  /// Refresh all data
  void refreshData() {
    _calculateStatistics();
    _generateTrendsData();
    _findLastRecord();
  }

  /// Navigation methods
  void navigateToLowestSystolicRecord() {
    final filteredData = _getBpFilteredData();
    if (filteredData.isEmpty) return;

    final lowestRecord = filteredData
        .where((data) => data.bloodPressure.systolic == systolicLowest.value)
        .first;
    Get.to(() => HealthDataEntryScreen(editData: lowestRecord));
  }

  void navigateToHighestSystolicRecord() {
    final filteredData = _getBpFilteredData();
    if (filteredData.isEmpty) return;

    final highestRecord = filteredData
        .where((data) => data.bloodPressure.systolic == systolicHighest.value)
        .first;
    Get.to(() => HealthDataEntryScreen(editData: highestRecord));
  }

  void navigateToLowestDiastolicRecord() {
    final filteredData = _getBpFilteredData();
    if (filteredData.isEmpty) return;

    final lowestRecord = filteredData
        .where((data) => data.bloodPressure.diastolic == diastolicLowest.value)
        .first;
    Get.to(() => HealthDataEntryScreen(editData: lowestRecord));
  }

  void navigateToHighestDiastolicRecord() {
    final filteredData = _getBpFilteredData();
    if (filteredData.isEmpty) return;

    final highestRecord = filteredData
        .where((data) => data.bloodPressure.diastolic == diastolicHighest.value)
        .first;
    Get.to(() => HealthDataEntryScreen(editData: highestRecord));
  }

  void navigateToLowestPulseRecord() {
    final filteredData = _getPulseFilteredData();
    if (filteredData.isEmpty) return;

    final lowestRecord = filteredData
        .where((data) => data.bloodPressure.pulse == pulseLowest.value)
        .first;
    Get.to(() => HealthDataEntryScreen(editData: lowestRecord));
  }

  void navigateToHighestPulseRecord() {
    final filteredData = _getPulseFilteredData();
    if (filteredData.isEmpty) return;

    final highestRecord = filteredData
        .where((data) => data.bloodPressure.pulse == pulseHighest.value)
        .first;
    Get.to(() => HealthDataEntryScreen(editData: highestRecord));
  }

  void showAllBPRecords() {
    final records = _getBpFilteredData();
    Get.to(() => HealthDataListScreen(
      title: 'All Blood Pressure Records',
      healthDataList: records,
      healthDataType: HealthDataType.bloodPressure,
    ));
  }

  void showAllPulseRecords() {
    final records = _getPulseFilteredData();
    Get.to(() => HealthDataListScreen(
      title: 'All Pulse Records',
      healthDataList: records,
      healthDataType: HealthDataType.bloodPressure,
    ));
  }

  void showNormalRecords() {
    final records = _getBpFilteredData()
        .where((d) =>
    _getBPCategory(d.bloodPressure.systolic, d.bloodPressure.diastolic) == 'Normal')
        .toList();
    Get.to(() => HealthDataListScreen(
      title: 'Normal Blood Pressure Records',
      healthDataList: records,
      healthDataType: HealthDataType.bloodPressure,
    ));
  }

  void showElevatedRecords() {
    final records = _getBpFilteredData()
        .where((d) =>
    _getBPCategory(d.bloodPressure.systolic, d.bloodPressure.diastolic) == 'Elevated')
        .toList();
    Get.to(() => HealthDataListScreen(
      title: 'Elevated Blood Pressure Records',
      healthDataList: records,
      healthDataType: HealthDataType.bloodPressure,
    ));
  }

  void showHighRecords() {
    final records = _getBpFilteredData()
        .where((d) =>
    _getBPCategory(d.bloodPressure.systolic, d.bloodPressure.diastolic) == 'High')
        .toList();
    Get.to(() => HealthDataListScreen(
      title: 'High Blood Pressure Records',
      healthDataList: records,
      healthDataType: HealthDataType.bloodPressure,
    ));
  }

  void showLowRecords() {
    final records = _getBpFilteredData()
        .where((d) =>
    _getBPCategory(d.bloodPressure.systolic, d.bloodPressure.diastolic) == 'Low')
        .toList();
    Get.to(() => HealthDataListScreen(
      title: 'Low Blood Pressure Records',
      healthDataList: records,
      healthDataType: HealthDataType.bloodPressure,
    ));
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