import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/health_log/health_log_repository.dart';
import '../../../common/loaders/loaders.dart';
import '../../../services/step_tracking_service.dart';
import '../../../utils/constants/enums.dart';
import '../models/health_data_model.dart';
import '../views/health_data_analytics/widgets/activity_bar_chart.dart';

class ExerciseController extends GetxController with GetTickerProviderStateMixin {
  late TabController tabController;

  // Repositories
  final _healthLogRepo = HealthLogRepository.instance;
  final _authRepo = AuthenticationRepository.instance;

  // Service
  final _stepTrackingService = StepTrackingService.instance;

  // Stream subscription
  StreamSubscription<List<HealthDataModel>>? _healthDataSubscription;

  // Observables
  final selectedTimeRange = 'This Week'.obs;
  final selectedPeriodFilter = 'All'.obs;
  final selectedTrendFilter = 'All'.obs;
  final isConnected = true.obs;
  final isLoading = false.obs;

  // Exercise data
  final exerciseProgress = 0.0.obs;
  final remainingMinutes = 0.obs;
  final lowIntensityMinutes = 0.obs;
  final moderateIntensityMinutes = 0.obs;
  final highIntensityMinutes = 0.obs;

  // Steps data
  final hasStepsData = false.obs;
  final averageSteps = 0.obs;

  // Dashboard data
  final weeklyExerciseMinutes = 0.obs;
  final todaySteps = 0.obs;

  // Goals
  final dailyStepsGoal = 7500.obs;
  final weeklyExerciseGoal = 150.obs;

  // Chart data
  final exerciseChartData = <ChartBarData>[].obs;
  final stepsChartData = <ChartBarData>[].obs;
  final rawStepsData = <double>[].obs;

  // Keep track of the time ranges for each tab
  String weekTimeRange = 'This Week';
  String monthTimeRange = 'Sep 2025';

  // Data from Firestore
  final healthDataList = <HealthDataModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    _initializeDataStream();

    tabController.addListener(() {
      _updateForTabChange();
    });
  }

  @override
  void onClose() {
    _healthDataSubscription?.cancel();
    tabController.dispose();
    super.onClose();
  }

  /// Initialize data stream
  void _initializeDataStream() {
    final userId = _authRepo.authUser?.uid;
    if (userId == null) return;

    isLoading.value = true;

    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 90));

    _healthDataSubscription = _healthLogRepo
        .getPhysicalActivityLogsStream(userId, startDate, endDate)
        .listen(
          (filteredLogs) {
        healthDataList.value = filteredLogs;

        _updateDashboardData();
        _initializeChartData();
        _updateExerciseSummary();

        isLoading.value = false;
      },
      onError: (error) {
        TLoaders.errorSnackBar(
          title: 'Error',
          message: 'Failed to load exercise data: ${error.toString()}',
        );
        isLoading.value = false;
      },
    );

    // 步数监听
    _stepTrackingService.todaySteps.listen((steps) {
      todaySteps.value = steps;
      _updateStepsChartData();
    });
  }

  /// Update dashboard data
  void _updateDashboardData() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    int weeklyMinutes = 0;
    for (var data in healthDataList) {
      if (data.logDateTime.isAfter(startOfWeek) &&
          data.logDateTime.isBefore(endOfWeek)) {
        weeklyMinutes += data.physicalActivity.duration;
      }
    }
    weeklyExerciseMinutes.value = weeklyMinutes;

    // Note: Steps data would come from a fitness tracking API
    // For now, we keep it as mock data or set to 0
    todaySteps.value = 0;
  }

  void _initializeChartData() {
    _generateExerciseWeekData();
    _generateStepsWeekData();
  }

  void _updateForTabChange() {
    if (tabController.index == 0) {
      selectedTimeRange.value = weekTimeRange;
      _updateDataForTimeRange(weekTimeRange);
    } else {
      selectedTimeRange.value = monthTimeRange;
      _updateDataForTimeRange(monthTimeRange);
    }
  }

  /// Generate exercise week data from Firestore
  void _generateExerciseWeekData() {
    final range = selectedTimeRange.value;
    final now = DateTime.now();
    DateTime startDate;

    if (range == 'This Week') {
      startDate = now.subtract(Duration(days: now.weekday));
    } else if (range == 'Last Week') {
      startDate = now.subtract(Duration(days: now.weekday + 7));
    } else {
      _generateEmptyData();
      return;
    }

    final chartData = <ChartBarData>[];
    for (int i = 0; i < 7; i++) {
      final currentDate = startDate.add(Duration(days: i));
      final dayData = _getExerciseDataForDate(currentDate);

      chartData.add(ChartBarData(
        label: _getWeekDayLabel(i),
        value: dayData['total']?.toDouble() ?? 0,
        stackData: dayData['stackData'],
      ));
    }

    exerciseChartData.value = chartData;
    _updateExerciseSummary();
  }

  /// Get exercise data for a specific date
  Map<String, dynamic> _getExerciseDataForDate(DateTime date) {
    int lowIntensity = 0;
    int moderateIntensity = 0;
    int highIntensity = 0;

    for (var data in healthDataList) {
      if (_isSameDay(data.logDateTime, date)) {
        switch (data.physicalActivity.intensityLevel) {
          case IntensityLevel.low:
            lowIntensity += data.physicalActivity.duration;
            break;
          case IntensityLevel.moderate:
            moderateIntensity += data.physicalActivity.duration;
            break;
          case IntensityLevel.high:
            highIntensity += data.physicalActivity.duration;
            break;
        }
      }
    }

    final total = lowIntensity + moderateIntensity + highIntensity;
    final stackData = [
      StackData(value: lowIntensity.toDouble(), color: const Color(0xFF06B6D4)),
      StackData(value: moderateIntensity.toDouble(), color: const Color(0xFFF59E0B)),
      StackData(value: highIntensity.toDouble(), color: const Color(0xFFEF4444)),
    ];

    return {
      'total': total,
      'stackData': stackData,
      'low': lowIntensity,
      'moderate': moderateIntensity,
      'high': highIntensity,
    };
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _updateExerciseSummary() {
    int low = 0;
    int moderate = 0;
    int high = 0;

    for (var chartData in exerciseChartData) {
      if (chartData.stackData != null) {
        for (var stack in chartData.stackData!) {
          if (stack.color == const Color(0xFF06B6D4)) low += stack.value.toInt();
          if (stack.color == const Color(0xFFF59E0B)) moderate += stack.value.toInt();
          if (stack.color == const Color(0xFFEF4444)) high += stack.value.toInt();
        }
      }
    }

    lowIntensityMinutes.value = low;
    moderateIntensityMinutes.value = moderate;
    highIntensityMinutes.value = high;
    _updateExerciseProgress();
  }

  /// Generate steps week data (mock for now - would need fitness API)
  void _generateStepsWeekData() {
    // Steps data would come from a fitness tracking API integration
    // For now, generate empty data
    stepsChartData.value = List.generate(
        7, (index) => ChartBarData(label: _getWeekDayLabel(index), value: 0));

    rawStepsData.value = List.filled(7, 0);
    hasStepsData.value = false;
    averageSteps.value = 0;
  }

  // 更新步数图表
  void _updateStepsChartData() {
    // 这里需要从 Firebase 加载最近7天的步数数据
    // 然后更新 stepsChartData 和 rawStepsData
    _loadWeekStepsData();
  }

  // 加载一周步数数据的方法
  Future<void> _loadWeekStepsData() async {
    final userId = _authRepo.authUser?.uid;
    if (userId == null) return;

    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: now.weekday));

    final chartData = <ChartBarData>[];
    final rawData = <double>[];

    for (int i = 0; i < 7; i++) {
      final currentDate = startDate.add(Duration(days: i));
      final dayStart = DateTime(currentDate.year, currentDate.month, currentDate.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final logs = await _healthLogRepo.findLogsInTimeRange(
        userId: userId,
        startTime: dayStart,
        endTime: dayEnd,
        physiologicalTimePeriod: PhysiologicalTimePeriod.wakeUp,
      );

      double steps = logs.isNotEmpty && logs.first.steps != null ? logs.first.steps!.toDouble() : 0;

      chartData.add(ChartBarData(
        label: _getWeekDayLabel(i),
        value: steps,
      ));

      rawData.add(steps);
    }

    stepsChartData.value = chartData;
    rawStepsData.value = rawData;
    hasStepsData.value = rawData.any((step) => step > 0);

    if (hasStepsData.value) {
      final total = rawData.reduce((a, b) => a + b);
      averageSteps.value = (total / 7).round();
    }
  }

  void _generateEmptyData() {
    exerciseChartData.value = List.generate(
        7, (index) => ChartBarData(label: _getWeekDayLabel(index), value: 0));

    stepsChartData.value = List.generate(
        7, (index) => ChartBarData(label: _getWeekDayLabel(index), value: 0));

    rawStepsData.value = List.filled(7, 0);
    hasStepsData.value = false;
    averageSteps.value = 0;

    lowIntensityMinutes.value = 0;
    moderateIntensityMinutes.value = 0;
    highIntensityMinutes.value = 0;
    _updateExerciseProgress();
  }

  String _getWeekDayLabel(int index) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[index];
  }

  void _updateExerciseProgress() {
    final totalMinutes = totalExerciseMinutes;
    exerciseProgress.value =
        (totalMinutes / weeklyExerciseGoal.value).clamp(0.0, 1.0);
    remainingMinutes.value =
        (weeklyExerciseGoal.value - totalMinutes).clamp(0, weeklyExerciseGoal.value);
  }

  // Public methods
  void updateTimeRange(String range) {
    selectedTimeRange.value = range;

    if (tabController.index == 0) {
      weekTimeRange = range;
    } else {
      monthTimeRange = range;
    }

    _updateDataForTimeRange(range);
  }

  void _updateDataForTimeRange(String range) {
    if (tabController.index == 0) {
      _generateExerciseWeekData();
      _generateStepsWeekData();
    } else {
      // Month view logic would go here
      _generateExerciseWeekData();
      _generateStepsWeekData();
    }
  }

  void updatePeriodFilter(String period) {
    selectedPeriodFilter.value = period;
  }

  void updateTrendFilter(String filter) {
    selectedTrendFilter.value = filter;
  }

  void connectApp() {
    isConnected.value = true;
    _stepTrackingService.startTracking();
  }

  void disconnectApp() {
    isConnected.value = false;
    _stepTrackingService.stopTracking();
  }

  void updateDailyStepsGoal(int newGoal) {
    dailyStepsGoal.value = newGoal;
  }

  void updateWeeklyExerciseGoal(int newGoal) {
    weeklyExerciseGoal.value = newGoal;
    _updateExerciseProgress();
  }

  /// Refresh data from Firestore
  Future<void> refreshData() async {
    _updateDashboardData();
    _initializeChartData();
    _updateExerciseSummary();
  }

  // Getters
  int get totalExerciseMinutes =>
      lowIntensityMinutes.value +
          moderateIntensityMinutes.value +
          highIntensityMinutes.value;
  double get weeklyGoal => weeklyExerciseGoal.value.toDouble();
  bool get goalAchieved => totalExerciseMinutes >= weeklyGoal;
  bool get shouldShowConnectionCard => !isConnected.value;
}