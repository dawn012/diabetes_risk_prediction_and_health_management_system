import 'dart:async';

import 'package:diabetes_risk_prediction_and_health_management_system/src/features/personalization/controllers/user_controller.dart';
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
  final UserController _userController = UserController.instance;

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
  RxBool get isConnected => _stepTrackingService.isConnected;
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

  int get dailyStepsGoal => _userController.user.value.profile.dailyStepsGoal > 0
      ? _userController.user.value.profile.dailyStepsGoal
      : 7500;

  int get weeklyExerciseGoal => _userController.user.value.profile.weeklyExerciseTime > 0
      ? _userController.user.value.profile.weeklyExerciseTime
      : 150;

  // Chart data
  final exerciseChartData = <ChartBarData>[].obs;
  final stepsChartData = <ChartBarData>[].obs;
  final rawStepsData = <double>[].obs;

  // Keep track of the time ranges for each tab
  String weekTimeRange = 'This Week';
  String monthTimeRange = 'Oct 2025';

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

    // 监听 UserController 的用户数据变化
    ever(_userController.user, (user) {
      print('User data updated in ExerciseController');
      // 当用户数据更新时，重新计算进度
      _updateExerciseProgress();
      update(); // 通知 UI 更新
    });

    // Listen to step tracking service
    ever(_stepTrackingService.isConnected, (connected) {
      print('Connection status changed in ExerciseController: $connected');
      if (connected) {
        _updateStepsChartData();
      }
    });

    // Listen to step tracking service
    _stepTrackingService.todaySteps.listen((steps) {
      todaySteps.value = steps;
      _updateStepsChartData();
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

    final endDate = DateTime.now().add(const Duration(days: 1));
    final startDate = endDate.subtract(const Duration(days: 90));

    _healthDataSubscription = _healthLogRepo
        .getPhysicalActivityLogsStream(userId, startDate, endDate)
        .listen(
          (filteredLogs) {
        healthDataList.value = filteredLogs;

        refreshData();

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

    todaySteps.value = 0;
  }

  void _initializeChartData() {
    if (tabController.index == 0) {
      _generateExerciseDataForRange(selectedTimeRange.value);
      _generateStepsDataForRange(selectedTimeRange.value);
    } else {
      _generateExerciseMonthData(selectedTimeRange.value);
      _generateStepsMonthData(selectedTimeRange.value);
    }
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

  void _updateDataForTimeRange(String range) {
    if (tabController.index == 0) {
      // Week view
      _generateExerciseDataForRange(range);
      _generateStepsDataForRange(range);
    } else {
      // Month view
      _generateExerciseMonthData(range);
      _generateStepsMonthData(range);
    }
  }

  /// 根据任意时间范围生成运动数据（Week视图）
  void _generateExerciseDataForRange(String range) {
    final DateTime startDate = _parseWeekRange(range);
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

  /// 根据任意时间范围生成步数数据（Week视图）
  Future<void> _generateStepsDataForRange(String range) async {
    final userId = _authRepo.authUser?.uid;
    if (userId == null) return;

    final DateTime startDate = _parseWeekRange(range);
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

      double steps = logs.isNotEmpty && logs.first.steps != null
          ? logs.first.steps!.toDouble()
          : 0;

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
    } else {
      averageSteps.value = 0;
    }
  }

  /// 解析 Week 时间范围字符串，返回该周的开始日期
  DateTime _parseWeekRange(String range) {
    final now = DateTime.now();

    if (range == 'This Week') {
      return now.subtract(Duration(days: now.weekday % 7));
    } else if (range == 'Last Week') {
      return now.subtract(Duration(days: now.weekday % 7 + 7));
    } else {
      // 解析 "9/15 - 9/21" 格式
      try {
        final parts = range.split(' - ');
        if (parts.length == 2) {
          final startParts = parts[0].split('/');
          if (startParts.length == 2) {
            final month = int.parse(startParts[0]);
            final day = int.parse(startParts[1]);

            // 确定年份（如果是未来月份，则是去年）
            int year = now.year;
            if (month > now.month) {
              year = now.year - 1;
            }

            return DateTime(year, month, day);
          }
        }
      } catch (e) {
        print('Error parsing week range: $e');
      }

      // 默认返回本周
      return now.subtract(Duration(days: now.weekday % 7));
    }
  }

  /// 生成月度运动数据（Month视图）
  void _generateExerciseMonthData(String range) {
    final DateTime monthStart = _parseMonthRange(range);
    final chartData = <ChartBarData>[];

    // 生成该月的4周数据
    for (int weekIndex = 0; weekIndex < 4; weekIndex++) {
      final weekStart = monthStart.add(Duration(days: weekIndex * 7));
      final weekEnd = weekStart.add(const Duration(days: 6));

      int weekLowIntensity = 0;
      int weekModerateIntensity = 0;
      int weekHighIntensity = 0;

      // 累计这一周的数据
      for (var data in healthDataList) {
        if (data.logDateTime.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            data.logDateTime.isBefore(weekEnd.add(const Duration(days: 1)))) {
          switch (data.physicalActivity.intensityLevel) {
            case IntensityLevel.low:
              weekLowIntensity += data.physicalActivity.duration;
              break;
            case IntensityLevel.moderate:
              weekModerateIntensity += data.physicalActivity.duration;
              break;
            case IntensityLevel.high:
              weekHighIntensity += data.physicalActivity.duration;
              break;
          }
        }
      }

      final stackData = [
        StackData(value: weekLowIntensity.toDouble(), color: const Color(0xFF06B6D4)),
        StackData(value: weekModerateIntensity.toDouble(), color: const Color(0xFFF59E0B)),
        StackData(value: weekHighIntensity.toDouble(), color: const Color(0xFFEF4444)),
      ];

      chartData.add(ChartBarData(
        label: 'Week ${weekIndex + 1}',
        value: (weekLowIntensity + weekModerateIntensity + weekHighIntensity).toDouble(),
        stackData: stackData,
      ));
    }

    exerciseChartData.value = chartData;
    _updateExerciseSummary();
  }

  /// 生成月度步数数据（Month视图）
  Future<void> _generateStepsMonthData(String range) async {
    final userId = _authRepo.authUser?.uid;
    if (userId == null) return;

    final DateTime monthStart = _parseMonthRange(range);
    final chartData = <ChartBarData>[];
    final rawData = <double>[];

    for (int weekIndex = 0; weekIndex < 4; weekIndex++) {
      final weekStart = monthStart.add(Duration(days: weekIndex * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));

      final logs = await _healthLogRepo.findLogsInTimeRange(
        userId: userId,
        startTime: weekStart,
        endTime: weekEnd,
        physiologicalTimePeriod: PhysiologicalTimePeriod.wakeUp,
      );

      double weekSteps = 0;
      for (var log in logs) {
        if (log.steps != null) {
          weekSteps += log.steps!;
        }
      }

      chartData.add(ChartBarData(
        label: 'Week ${weekIndex + 1}',
        value: weekSteps,
      ));

      rawData.add(weekSteps);
    }

    stepsChartData.value = chartData;
    rawStepsData.value = rawData;
    hasStepsData.value = rawData.any((step) => step > 0);

    if (hasStepsData.value) {
      final total = rawData.reduce((a, b) => a + b);
      averageSteps.value = (total / 4).round(); // 4周平均
    } else {
      averageSteps.value = 0;
    }
  }

  /// 解析 Month 时间范围字符串，返回该月的第一天
  DateTime _parseMonthRange(String range) {
    final now = DateTime.now();

    try {
      // 解析 "Oct 2025" 格式
      final parts = range.split(' ');
      if (parts.length == 2) {
        final monthMap = {
          'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4,
          'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8,
          'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
        };

        final month = monthMap[parts[0]];
        final year = int.parse(parts[1]);

        if (month != null) {
          return DateTime(year, month, 1);
        }
      }
    } catch (e) {
      print('Error parsing month range: $e');
    }

    // 默认返回当前月份
    return DateTime(now.year, now.month, 1);
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

  // 更新步数图表
  void _updateStepsChartData() {
    if (tabController.index == 0) {
      _generateStepsDataForRange(selectedTimeRange.value);
    } else {
      _generateStepsMonthData(selectedTimeRange.value);
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
    final goal = weeklyExerciseGoal;

    // 计算进度
    exerciseProgress.value = (totalMinutes / goal).clamp(0.0, 1.0);

    // 修复剩余时间计算：如果已经超过目标，剩余时间为0
    if (totalMinutes >= goal) {
      remainingMinutes.value = 0;
    } else {
      remainingMinutes.value = goal - totalMinutes;
    }

    print('Progress: $totalMinutes / $goal = ${exerciseProgress.value}');
    print('Remaining: ${remainingMinutes.value} minutes');
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

  void updatePeriodFilter(String period) {
    selectedPeriodFilter.value = period;
  }

  void updateTrendFilter(String filter) {
    selectedTrendFilter.value = filter;
  }

  void connectApp() async {
    await _stepTrackingService.startTracking();
  }

  void disconnectApp() {
    _stepTrackingService.stopTracking();
  }

  Future<void> deleteHealthRecord(String logId) async {
    try {
      final userId = _authRepo.authUser?.uid;
      if (userId == null) return;

      await _healthLogRepo.deleteHealthLog(userId, logId);

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Exercise record deleted successfully',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to delete record: ${e.toString()}',
      );
    }
  }

  /// Refresh data from Firestore
  Future<void> refreshData() async {
    _updateDashboardData();
    _initializeChartData();
    _updateExerciseSummary();
    _updateExerciseProgress();
  }

  // Getters
  int get totalExerciseMinutes =>
      lowIntensityMinutes.value +
          moderateIntensityMinutes.value +
          highIntensityMinutes.value;

  double get weeklyGoal => weeklyExerciseGoal.toDouble();

  bool get goalAchieved => totalExerciseMinutes >= weeklyGoal;

  bool get shouldShowConnectionCard => !_stepTrackingService.isConnected.value;

  List<HealthDataModel> get allExerciseLogs => healthDataList;
}