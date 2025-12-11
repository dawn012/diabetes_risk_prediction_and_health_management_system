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
  String monthTimeRange = 'Dec 2025';

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
      _updateExerciseProgress();
      update();
    });

    // Listen to step tracking service
    // ever(_stepTrackingService.isConnected, (connected) {
    //   print('Connection status changed in ExerciseController: $connected');
    //   if (connected) {
    //     _updateStepsChartData();
    //   }
    // });

    // Listen to step tracking service for real-time step updates
    _stepTrackingService.todaySteps.listen((steps) {
      todaySteps.value = steps;
      _updateTodayStepsInChart();
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

    // 步数监听 - 用于 Dashboard 显示
    _stepTrackingService.todaySteps.listen((steps) {
      todaySteps.value = steps;
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
      _generateExerciseDataForRange(range);
      _generateStepsDataForRange(range);
    } else {
      _generateExerciseMonthData(range);
      _generateStepsMonthData(range);
    }
  }

  // ==================== 运动数据方法 ====================

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
        startDate: currentDate,
        endDate: currentDate,
      ));
    }

    exerciseChartData.value = chartData;
    _updateExerciseSummary();
  }

  /// 生成月度运动数据（Month视图）
  void _generateExerciseMonthData(String range) {
    final DateTime monthStart = _parseMonthRange(range);
    final chartData = <ChartBarData>[];

    DateTime currentWeekStart = _findFirstDayOfWeek(monthStart);
    int weekIndex = 0;

    while (weekIndex < 6) {
      final weekStart = currentWeekStart;
      final weekEnd = weekStart.add(const Duration(days: 6));

      if (weekStart.month != monthStart.month && weekIndex > 0) break;

      int weekLowIntensity = 0;
      int weekModerateIntensity = 0;
      int weekHighIntensity = 0;

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

      final weekLabel = _getMonthChartLabel(weekStart);

      chartData.add(ChartBarData(
        label: weekLabel,
        value: (weekLowIntensity + weekModerateIntensity + weekHighIntensity).toDouble(),
        stackData: stackData,
        startDate: weekStart,
        endDate: weekEnd,
      ));

      currentWeekStart = currentWeekStart.add(const Duration(days: 7));
      weekIndex++;
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

  // ==================== 步数数据混合获取方法 ====================

  /// 根据任意时间范围生成步数数据（Week视图）- 混合获取
  Future<void> _generateStepsDataForRange(String range) async {
    final userId = _authRepo.authUser?.uid;
    if (userId == null) return;

    final DateTime startDate = _parseWeekRange(range);
    final chartData = <ChartBarData>[];
    final rawData = <double>[];

    for (int i = 0; i < 7; i++) {
      final currentDate = startDate.add(Duration(days: i));
      final today = DateTime.now();
      final isToday = _isSameDay(currentDate, today);

      double steps = 0;

      if (isToday) {
        // 今天的数据：优先使用本地实时数据
        steps = _stepTrackingService.todaySteps.value.toDouble();
        print('📊 Today steps - Local: $steps');

        // 如果本地数据为0，尝试从云端获取
        if (steps == 0) {
          steps = await _getStepsFromFirebase(userId, currentDate);
          print('📊 Today steps - Fallback to Firebase: $steps');
        }
      } else {
        // 历史数据：从云端获取
        steps = await _getStepsFromFirebase(userId, currentDate);
        print('📊 Historical steps ($currentDate) - Firebase: $steps');
      }

      chartData.add(ChartBarData(
        label: _getWeekDayLabel(i),
        value: steps,
        startDate: currentDate,
        endDate: currentDate,
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

    print('📈 Steps chart data updated: $rawData');
  }

  /// 生成月度步数数据（Month视图）- 混合获取
  Future<void> _generateStepsMonthData(String range) async {
    final userId = _authRepo.authUser?.uid;
    if (userId == null) return;

    final DateTime monthStart = _parseMonthRange(range);
    final chartData = <ChartBarData>[];
    final rawData = <double>[];

    DateTime currentWeekStart = _findFirstDayOfWeek(monthStart);
    int weekIndex = 0;

    while (weekIndex < 6) {
      final weekStart = currentWeekStart;
      final weekEnd = weekStart.add(const Duration(days: 7));

      if (weekStart.month != monthStart.month && weekIndex > 0) break;

      double weekSteps = 0;
      final today = DateTime.now();

      // 检查这一周是否包含今天
      final containsToday = !today.isBefore(weekStart) && !today.isAfter(weekEnd);

      if (containsToday) {
        // 如果包含今天，使用混合数据
        for (int i = 0; i < 7; i++) {
          final currentDate = weekStart.add(Duration(days: i));
          final isToday = _isSameDay(currentDate, today);

          double dailySteps = 0;
          if (isToday) {
            // 今天的数据使用本地实时数据
            dailySteps = _stepTrackingService.todaySteps.value.toDouble();
            if (dailySteps == 0) {
              dailySteps = await _getStepsFromFirebase(userId, currentDate);
            }
          } else {
            // 其他日期从云端获取
            dailySteps = await _getStepsFromFirebase(userId, currentDate);
          }
          weekSteps += dailySteps;
        }
      } else {
        // 不包含今天，完全从云端获取
        final logs = await _healthLogRepo.findLogsInTimeRange(
          userId: userId,
          startTime: weekStart,
          endTime: weekEnd,
          physiologicalTimePeriod: PhysiologicalTimePeriod.wakeUp,
        );

        for (var log in logs) {
          if (log.steps != null) {
            weekSteps += log.steps!;
          }
        }
      }

      final weekLabel = _getMonthChartLabel(weekStart);

      chartData.add(ChartBarData(
        label: weekLabel,
        value: weekSteps,
        startDate: weekStart,
        endDate: weekEnd,
      ));

      rawData.add(weekSteps);

      currentWeekStart = currentWeekStart.add(const Duration(days: 7));
      weekIndex++;
    }

    stepsChartData.value = chartData;
    rawStepsData.value = rawData;
    hasStepsData.value = rawData.any((step) => step > 0);

    if (hasStepsData.value) {
      final total = rawData.reduce((a, b) => a + b);
      averageSteps.value = (total / chartData.length).round();
    } else {
      averageSteps.value = 0;
    }
  }

  /// 从 Firebase 获取指定日期的步数
  Future<double> _getStepsFromFirebase(String userId, DateTime date) async {
    try {
      final startTime = DateTime(date.year, date.month, date.day);
      final endTime = DateTime(date.year, date.month, date.day + 1);
      // final dayEnd = date.add(const Duration(days: 1));

      final logs = await _healthLogRepo.findLogsInTimeRange(
        userId: userId,
        startTime: startTime,
        endTime: endTime,
        physiologicalTimePeriod: PhysiologicalTimePeriod.wakeUp,
      );

      if (logs.isEmpty) {
        print('📭 No step records found for $date');
        return 0;
      }

      final validLogs = logs.where((log) => log.steps != null && log.steps! > 0).toList();

      if (validLogs.isEmpty) {
        print('📭 No valid step records (steps > 0) found for $date');
        return 0;
      }

      // 由于同一天只有一个记录，直接取第一个
      final stepRecord = validLogs.first;
      final steps = stepRecord.steps!;

      print('📥 Loaded steps from Firebase: $steps for $date');

      return steps.toDouble();
    } catch (e) {
      print('❌ Error getting steps from Firebase: $e');
      return 0;
    }
  }

  /// 实时更新今天在图表中的步数
  void _updateTodayStepsInChart() {
    final today = DateTime.now();

    if (tabController.index == 0) {
      // Week view: 更新今天对应的柱状图
      final updatedChartData = List<ChartBarData>.from(stepsChartData.value);
      for (int i = 0; i < updatedChartData.length; i++) {
        final chartData = updatedChartData[i];
        if (chartData.startDate != null && _isSameDay(chartData.startDate!, today)) {
          updatedChartData[i] = ChartBarData(
            label: chartData.label,
            value: _stepTrackingService.todaySteps.value.toDouble(),
            startDate: chartData.startDate,
            endDate: chartData.endDate,
          );
          break;
        }
      }
      stepsChartData.value = updatedChartData;

      // 重新计算平均值
      final newRawData = updatedChartData.map((data) => data.value).toList();
      if (newRawData.any((step) => step > 0)) {
        final total = newRawData.reduce((a, b) => a + b);
        averageSteps.value = (total / 7).round();
      }
    } else {
      // Month view: 需要重新生成包含今天的周数据
      _generateStepsMonthData(selectedTimeRange.value);
    }
  }

  // ==================== 辅助方法 ====================

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

  void _updateStepsChartData() {
    if (tabController.index == 0) {
      _generateStepsDataForRange(selectedTimeRange.value);
    } else {
      _generateStepsMonthData(selectedTimeRange.value);
    }
  }

  /// 检查是否是同一天
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// 解析 Week 时间范围字符串，返回该周的开始日期
  DateTime _parseWeekRange(String range) {
    final now = DateTime.now();

    if (range == 'This Week') {
      return now.subtract(Duration(days: now.weekday % 7));
    } else if (range == 'Last Week') {
      return now.subtract(Duration(days: now.weekday % 7 + 7));
    } else {
      try {
        final parts = range.split(' - ');
        if (parts.length == 2) {
          final startParts = parts[0].split('/');
          if (startParts.length == 2) {
            final month = int.parse(startParts[0]);
            final day = int.parse(startParts[1]);

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

      return now.subtract(Duration(days: now.weekday % 7));
    }
  }

  /// 解析 Month 时间范围字符串，返回该月的第一天
  DateTime _parseMonthRange(String range) {
    final now = DateTime.now();

    try {
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

    return DateTime(now.year, now.month, 1);
  }

  /// 找到某一天所在周的第一天（星期日）
  DateTime _findFirstDayOfWeek(DateTime date) {
    int daysToSubtract = date.weekday % 7;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysToSubtract));
  }

  String _getWeekDayLabel(int index) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[index];
  }

  /// 生成月视图图表标签 - 只显示周开始日期
  String _getMonthChartLabel(DateTime weekStart) {
    return '${weekStart.month}/${weekStart.day}';
  }

  void _updateExerciseProgress() {
    final totalMinutes = totalExerciseMinutes;
    final goal = weeklyExerciseGoal;

    exerciseProgress.value = (totalMinutes / goal).clamp(0.0, 1.0);

    if (totalMinutes >= goal) {
      remainingMinutes.value = 0;
    } else {
      remainingMinutes.value = goal - totalMinutes;
    }

    print('Progress: $totalMinutes / $goal = ${exerciseProgress.value}');
    print('Remaining: ${remainingMinutes.value} minutes');
  }

  // ==================== 公共方法 ====================

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

  /// Get filtered data based on current filters (for HealthDataListScreen)
  List<HealthDataModel> getFilteredData() {
    return healthDataList;
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