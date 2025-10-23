import 'dart:async';
import 'package:get/get.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../common/loaders/loaders.dart';
import '../data/repositories/authentication/authentication_repository.dart';
import '../data/repositories/health_log/health_log_repository.dart';
import '../features/health_data_entry/models/health_data_model.dart';
import '../utils/constants/enums.dart';

class StepTrackingService extends GetxController {
  static StepTrackingService get instance => Get.find();

  final _authRepo = AuthenticationRepository.instance;
  final _healthLogRepo = HealthLogRepository.instance;

  // Observables
  final isTracking = false.obs;
  final currentSteps = 0.obs;
  final todaySteps = 0.obs;

  // Private
  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;
  int _initialSteps = 0;
  DateTime _lastResetDate = DateTime.now();

  @override
  void onInit() {
    super.onInit();
    _loadTodaySteps();
    _checkAndStartTracking(); // 自动检查并启动追踪
  }

  @override
  void onClose() {
    stopTracking();
    super.onClose();
  }

  /// 检查是否应该启动追踪（如果之前已连接）
  Future<void> _checkAndStartTracking() async {
    try {
      final userId = _authRepo.authUser?.uid;
      if (userId == null) return;

      // 检查权限状态
      final status = await Permission.activityRecognition.status;
      if (status.isGranted) {
        // 如果权限已授予，自动启动追踪
        await startTracking();
      }
    } catch (e) {
      print('Error checking tracking status: $e');
    }
  }

  /// Load today's steps from Firebase
  Future<void> _loadTodaySteps() async {
    try {
      final userId = _authRepo.authUser?.uid;
      if (userId == null) return;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final logs = await _healthLogRepo.findLogsInTimeRange(
        userId: userId,
        startTime: startOfDay,
        endTime: endOfDay,
        physiologicalTimePeriod: PhysiologicalTimePeriod.wakeUp,
      );

      if (logs.isNotEmpty && logs.first.steps != null) {
        todaySteps.value = logs.first.steps!;
        currentSteps.value = logs.first.steps!;
      }
    } catch (e) {
      print('Error loading today steps: $e');
    }
  }

  /// Start tracking steps
  Future<void> startTracking() async {
    if (isTracking.value) return;

    try {
      // Request permission
      final status = await Permission.activityRecognition.request();

      if (status.isDenied || status.isPermanentlyDenied) {
        TLoaders.errorSnackBar(
          title: 'Permission Required',
          message: 'Please enable activity recognition permission to track steps.',
        );
        return;
      }

      // Initialize step count
      _stepCountSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
      );

      _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
        _onPedestrianStatusChanged,
        onError: _onPedestrianStatusError,
      );

      isTracking.value = true;

      TLoaders.successSnackBar(
        title: 'Tracking Started',
        message: 'Step tracking is now active.',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to start step tracking: ${e.toString()}',
      );
    }
  }

  /// Stop tracking steps
  void stopTracking() {
    _stepCountSubscription?.cancel();
    _pedestrianStatusSubscription?.cancel();
    _stepCountSubscription = null;
    _pedestrianStatusSubscription = null;
    isTracking.value = false;
  }

  /// Handle step count updates
  void _onStepCount(StepCount event) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastReset = DateTime(_lastResetDate.year, _lastResetDate.month, _lastResetDate.day);

    // Reset if it's a new day
    if (!today.isAtSameMomentAs(lastReset)) {
      _initialSteps = event.steps;
      _lastResetDate = now;
      todaySteps.value = 0;
    }

    // Calculate today's steps
    if (_initialSteps == 0) {
      _initialSteps = event.steps;
    }

    final stepsToday = event.steps - _initialSteps;
    todaySteps.value = stepsToday;
    currentSteps.value = stepsToday;

    // Save to Firebase every 100 steps
    if (stepsToday % 100 == 0) {
      _saveStepsToFirebase(stepsToday);
    }
  }

  /// Handle step count errors
  void _onStepCountError(error) {
    print('Step Count Error: $error');
    stopTracking();
  }

  /// Handle pedestrian status changes
  void _onPedestrianStatusChanged(PedestrianStatus event) {
    // Optional: You can use this to show walking/stopped status
    print('Pedestrian Status: ${event.status}');
  }

  /// Handle pedestrian status errors
  void _onPedestrianStatusError(error) {
    print('Pedestrian Status Error: $error');
  }

  /// Save steps to Firebase
  Future<void> _saveStepsToFirebase(int steps) async {
    try {
      final userId = _authRepo.authUser?.uid;
      if (userId == null) return;

      final today = DateTime.now();
      final logDate = DateTime(today.year, today.month, today.day);

      final healthData = HealthDataModel.stepsOnly(
        date: logDate,
        steps: steps,
      );

      await _healthLogRepo.saveHealthLog(userId, healthData);
    } catch (e) {
      print('Error saving steps: $e');
    }
  }

  /// Manually save current steps (called when app goes to background)
  Future<void> saveCurrentSteps() async {
    if (todaySteps.value > 0) {
      await _saveStepsToFirebase(todaySteps.value);
    }
  }

  /// Reset daily steps (for testing)
  void resetDailySteps() {
    _initialSteps = 0;
    todaySteps.value = 0;
    currentSteps.value = 0;
    _lastResetDate = DateTime.now();
  }
}