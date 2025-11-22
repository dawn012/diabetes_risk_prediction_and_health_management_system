import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/health_log/health_log_repository.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/health_data_range.dart';
import '../models/health_data_model.dart';
import '../views/health_data_analytics/widgets/health_data_list_screen.dart';
import '../views/health_data_entry/health_data_entry_screen.dart';
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

  // 自定义日期范围
  final customStartDate = Rxn<DateTime>();
  final customEndDate = Rxn<DateTime>();

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
  final bpTrendsOriginalDateTimes = <DateTime>[].obs; // 血压原始日期时间
  final pulseTrendsOriginalDateTimes = <DateTime>[].obs; // 脉搏原始日期时间

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
    resetCustomDateRange();
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

    // Calculate blood pressure statistics
    if (bpFilteredData.isEmpty) {
      systolicLowest.value = -1;
      systolicHighest.value = -1;
      systolicAverage.value = -1;
      diastolicLowest.value = -1;
      diastolicHighest.value = -1;
      diastolicAverage.value = -1;
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

      // 只要有记录就显示数值，即使只有一条
      if (systolicValues.isNotEmpty) {
        systolicLowest.value = systolicValues.reduce((a, b) => a < b ? a : b);
        systolicHighest.value = systolicValues.reduce((a, b) => a > b ? a : b);
        systolicAverage.value = systolicValues.reduce((a, b) => a + b) / systolicValues.length;
      } else {
        systolicLowest.value = -1;
        systolicHighest.value = -1;
        systolicAverage.value = -1;
      }

      if (diastolicValues.isNotEmpty) {
        diastolicLowest.value = diastolicValues.reduce((a, b) => a < b ? a : b);
        diastolicHighest.value = diastolicValues.reduce((a, b) => a > b ? a : b);
        diastolicAverage.value = diastolicValues.reduce((a, b) => a + b) / diastolicValues.length;
      } else {
        diastolicLowest.value = -1;
        diastolicHighest.value = -1;
        diastolicAverage.value = -1;
      }

      _calculateDistribution(bpFilteredData);
    }

    // Calculate pulse statistics
    if (pulseFilteredData.isEmpty) {
      pulseLowest.value = -1;
      pulseHighest.value = -1;
      pulseAverage.value = -1;
    } else {
      final pulseValues = pulseFilteredData
          .where((d) => d.bloodPressure.pulse > 0)
          .map((d) => d.bloodPressure.pulse)
          .toList();

      // 只要有记录就显示数值，即使只有一条
      if (pulseValues.isNotEmpty) {
        pulseLowest.value = pulseValues.reduce((a, b) => a < b ? a : b);
        pulseHighest.value = pulseValues.reduce((a, b) => a > b ? a : b);
        pulseAverage.value = pulseValues.reduce((a, b) => a + b) / pulseValues.length;
      } else {
        pulseLowest.value = -1;
        pulseHighest.value = -1;
        pulseAverage.value = -1;
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
          case HealthLevel.normal:
            normal++;
            break;
          case HealthLevel.elevated:
            elevated++;
            break;
          case HealthLevel.high:
            high++;
            break;
          case HealthLevel.low:
            low++;
            break;
          case HealthLevel.invalid:
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
      bpTrendsOriginalDateTimes.clear(); // 清空血压原始日期时间
    } else {
      bpFilteredData.sort((a, b) => a.logDateTime.compareTo(b.logDateTime));
      final systolicSpots = <FlSpot>[];
      final diastolicSpots = <FlSpot>[];
      final bpOriginalDateTimes = <DateTime>[]; // 血压原始日期时间

      for (int i = 0; i < bpFilteredData.length; i++) {
        final data = bpFilteredData[i];
        // 只要有血压数据就记录日期时间
        if (data.bloodPressure.systolic > 0 || data.bloodPressure.diastolic > 0) {
          bpOriginalDateTimes.add(data.logDateTime);
        }
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
      bpTrendsOriginalDateTimes.value = bpOriginalDateTimes; // 设置血压原始日期时间
    }

    // 生成脉搏趋势数据
    if (pulseFilteredData.isEmpty) {
      pulseTrendsData.clear();
      trendsLabels.clear();
      pulseTrendsOriginalDateTimes.clear(); // 清空脉搏原始日期时间
    } else {
      pulseFilteredData.sort((a, b) => a.logDateTime.compareTo(b.logDateTime));
      final pulseSpots = <FlSpot>[];
      final labels = <String>[];
      final pulseOriginalDateTimes = <DateTime>[]; // 脉搏原始日期时间

      for (int i = 0; i < pulseFilteredData.length; i++) {
        final data = pulseFilteredData[i];
        if (data.bloodPressure.pulse > 0) {
          pulseSpots
              .add(FlSpot(i.toDouble(), data.bloodPressure.pulse.toDouble()));
          pulseOriginalDateTimes.add(data.logDateTime); // 存储脉搏原始日期时间
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
      pulseTrendsOriginalDateTimes.value = pulseOriginalDateTimes; // 设置脉搏原始日期时间
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

  /// 更新自定义日期范围
  void updateCustomDateRange(DateTime? start, DateTime? end) {
    customStartDate.value = start;
    customEndDate.value = end;

    if (start != null && end != null) {
      // 更新选中的时间范围为自定义
      selectedTimeRange.value = 'Custom Range';
      refreshData();
    }
  }

  /// 重置自定义日期范围
  void resetCustomDateRange() {
    customStartDate.value = null;
    customEndDate.value = null;
  }

  /// Get filtered data for blood pressure statistics
  List<HealthDataModel> _getBpFilteredData() {
    List<HealthDataModel> filtered = List.from(healthDataList);

    // 处理自定义日期范围
    if (selectedTimeRange.value == 'Custom Range' &&
        customStartDate.value != null &&
        customEndDate.value != null) {
      filtered = filtered
          .where((data) =>
      data.logDateTime.isAfter(customStartDate.value!.subtract(const Duration(days: 1))) &&
          data.logDateTime.isBefore(customEndDate.value!.add(const Duration(days: 1))))
          .toList();
    } else {
      // 原有的时间范围逻辑
      final now = DateTime.now();
      final cutoffDate = _getCutoffDate(now);
      filtered = filtered
          .where((data) =>
      data.logDateTime.isAfter(cutoffDate) &&
          (data.bloodPressure.systolic > 0 || data.bloodPressure.diastolic > 0))
          .toList();
    }

    if (selectedBpPeriodFilter.value != 'All') {
      filtered = _applyMealFilter(filtered, selectedBpPeriodFilter.value);
    }

    return filtered;
  }

  /// Get filtered data for blood pressure trends
  List<HealthDataModel> _getBpFilteredTrendsData() {
    List<HealthDataModel> filtered = List.from(healthDataList);

    // 处理自定义日期范围
    if (selectedTimeRange.value == 'Custom Range' &&
        customStartDate.value != null &&
        customEndDate.value != null) {
      filtered = filtered
          .where((data) =>
      data.logDateTime.isAfter(customStartDate.value!.subtract(const Duration(days: 1))) &&
          data.logDateTime.isBefore(customEndDate.value!.add(const Duration(days: 1))) &&
          (data.bloodPressure.systolic > 0 || data.bloodPressure.diastolic > 0))
          .toList();
    } else {
      // 原有的时间范围逻辑
      final now = DateTime.now();
      final cutoffDate = _getCutoffDate(now);
      filtered = filtered
          .where((data) =>
      data.logDateTime.isAfter(cutoffDate) &&
          (data.bloodPressure.systolic > 0 || data.bloodPressure.diastolic > 0))
          .toList();
    }

    if (selectedBpTrendFilter.value != 'All') {
      filtered = _applyMealFilter(filtered, selectedBpTrendFilter.value);
    }

    return filtered;
  }

  /// Get filtered data for pulse statistics
  List<HealthDataModel> _getPulseFilteredData() {
    List<HealthDataModel> filtered = List.from(healthDataList);

    // 处理自定义日期范围
    if (selectedTimeRange.value == 'Custom Range' &&
        customStartDate.value != null &&
        customEndDate.value != null) {
      filtered = filtered
          .where((data) =>
      data.logDateTime.isAfter(customStartDate.value!.subtract(const Duration(days: 1))) &&
          data.logDateTime.isBefore(customEndDate.value!.add(const Duration(days: 1))) &&
          data.bloodPressure.pulse > 0)
          .toList();
    } else {
      // 原有的时间范围逻辑
      final now = DateTime.now();
      final cutoffDate = _getCutoffDate(now);
      filtered = filtered
          .where((data) =>
      data.logDateTime.isAfter(cutoffDate) && data.bloodPressure.pulse > 0)
          .toList();
    }

    if (selectedPulsePeriodFilter.value != 'All') {
      filtered = _applyMealFilter(filtered, selectedPulsePeriodFilter.value);
    }

    return filtered;
  }

  /// Get filtered data for pulse trends
  List<HealthDataModel> _getPulseFilteredTrendsData() {
    List<HealthDataModel> filtered = List.from(healthDataList);

    // 处理自定义日期范围
    if (selectedTimeRange.value == 'Custom Range' &&
        customStartDate.value != null &&
        customEndDate.value != null) {
      filtered = filtered
          .where((data) =>
      data.logDateTime.isAfter(customStartDate.value!.subtract(const Duration(days: 1))) &&
          data.logDateTime.isBefore(customEndDate.value!.add(const Duration(days: 1))) &&
          data.bloodPressure.pulse > 0)
          .toList();
    } else {
      // 原有的时间范围逻辑
      final now = DateTime.now();
      final cutoffDate = _getCutoffDate(now);
      filtered = filtered
          .where((data) =>
      data.logDateTime.isAfter(cutoffDate) && data.bloodPressure.pulse > 0)
          .toList();
    }

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

  /// Get blood pressure category
  HealthLevel _getBPCategory(int systolic, int diastolic) {
    if (systolic < HealthDataRanges.minSystolic || systolic > HealthDataRanges.maxSystolic ||
        diastolic < HealthDataRanges.minDiastolic || diastolic > HealthDataRanges.maxDiastolic) {
      return HealthLevel.invalid;
    }

    if (systolic < 90 || diastolic < 60) {
      return HealthLevel.low;
    } else if (systolic < 120 && diastolic < 80) {
      return HealthLevel.normal;
    } else if (systolic >= 120 && systolic <= 129 && diastolic < 80) {
      return HealthLevel.elevated;
    } else {
      return HealthLevel.high;
    }
  }

  /// Get pulse category (4-level version matching BP categories)
  HealthLevel _getPulseCategory(int pulse) {
    if (pulse < HealthDataRanges.minPulse || pulse > HealthDataRanges.maxPulse) {
      return HealthLevel.invalid;
    }

    if (pulse < 60) {
      return HealthLevel.low; // Bradycardia
    } else if (pulse <= 100) {
      return HealthLevel.normal;
    } else if (pulse <= 120) {
      return HealthLevel.elevated; // Tachycardia
    } else {
      return HealthLevel.high; // Very High
    }
  }

  /// Get blood pressure level color
  Color getBPLevelColor(int systolic, int diastolic) {
    if (systolic == 0 && diastolic == 0) {
      return TColors.darkGrey; // For '-' display
    }

    final category = _getBPCategory(systolic, diastolic);
    switch (category) {
      case HealthLevel.low:
        return TColors.bpLow;
      case HealthLevel.normal:
        return TColors.bpNormal;
      case HealthLevel.elevated:
        return TColors.bpElevated;
      case HealthLevel.high:
        return TColors.bpHigh;
      case HealthLevel.invalid:
        return TColors.darkGrey;
    }
  }

  /// Get pulse level color (using same color scheme as BP)
  Color getPulseLevelColor(int pulse) {
    if (pulse == 0) {
      return TColors.darkGrey; // For '-' display
    }

    final category = _getPulseCategory(pulse);
    switch (category) {
      case HealthLevel.low:
        return TColors.bpLow; // Same as BP low
      case HealthLevel.normal:
        return TColors.bpNormal; // Same as BP normal
      case HealthLevel.elevated:
        return TColors.bpElevated; // Same as BP elevated
      case HealthLevel.high:
        return TColors.bpHigh; // Same as BP high
      case HealthLevel.invalid:
        return TColors.darkGrey;
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
    Get.to(() => const HealthDataListScreen(
      title: 'All Blood Pressure Records',
      healthDataType: HealthDataType.bloodPressure,
      filterType: 'all',
    ));
  }

  void showAllPulseRecords() {
    Get.to(() => const HealthDataListScreen(
      title: 'All Pulse Records',
      healthDataType: HealthDataType.bloodPressure,
      filterType: 'all',
    ));
  }

  void showNormalRecords() {
    Get.to(() => const HealthDataListScreen(
      title: 'Normal Blood Pressure Records',
      healthDataType: HealthDataType.bloodPressure,
      filterType: 'normal',
    ));
  }

  void showElevatedRecords() {
    Get.to(() => const HealthDataListScreen(
      title: 'Elevated Blood Pressure Records',
      healthDataType: HealthDataType.bloodPressure,
      filterType: 'elevated',
    ));
  }

  void showHighRecords() {
    Get.to(() => const HealthDataListScreen(
      title: 'High Blood Pressure Records',
      healthDataType: HealthDataType.bloodPressure,
      filterType: 'high',
    ));
  }

  void showLowRecords() {
    Get.to(() => const HealthDataListScreen(
      title: 'Low Blood Pressure Records',
      healthDataType: HealthDataType.bloodPressure,
      filterType: 'low',
    ));
  }

  /// Get filtered data based on current filters (for HealthDataListScreen)
  List<HealthDataModel> getFilteredData() {
    return _getBpFilteredData();
  }

  /// Get BP level enum
  String getBPLevel(int systolic, int diastolic) {
    final category = _getBPCategory(systolic, diastolic);
    switch (category) {
      case HealthLevel.low:
        return 'low';
      case HealthLevel.normal:
        return 'normal';
      case HealthLevel.elevated:
        return 'elevated';
      case HealthLevel.high:
        return 'high';
      default:
        return 'normal';
    }
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