import 'dart:async';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
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
  final _healthLogRepo = Get.put(HealthLogRepository());
  final _storage = GetStorage();

  // Storage key
  static const String _isConnectedKey = 'step_tracking_connected';

  // Observables
  final isTracking = false.obs;
  final isConnected = false.obs;
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
    _loadConnectionStatus();
    _loadTodaySteps();
  }

  @override
  void onClose() {
    stopTracking();
    super.onClose();
  }

  /// Load connection status from storage
  void _loadConnectionStatus() {
    isConnected.value = _storage.read(_isConnectedKey) ?? false;

    // If connected, start tracking automatically
    if (isConnected.value) {
      _checkAndStartTracking();
    }
  }

  /// Save connection status to storage
  void _saveConnectionStatus(bool connected) {
    _storage.write(_isConnectedKey, connected);
    isConnected.value = connected;

    // 强制触发更新
    update();

    print('Step tracking connection status saved: $connected');
  }

  /// Check and start tracking if permission is granted
  Future<void> _checkAndStartTracking() async {
    try {
      final status = await Permission.activityRecognition.status;
      if (status.isGranted) {
        await startTracking(silent: true);
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
  Future<void> startTracking({bool silent = false}) async {
    if (isTracking.value) {
      // 如果已经在追踪，只需要更新连接状态
      _saveConnectionStatus(true);
      return;
    }

    try {
      // Request permission
      final status = await Permission.activityRecognition.request();

      if (status.isDenied || status.isPermanentlyDenied) {
        if (!silent) {
          TLoaders.errorSnackBar(
            title: 'Permission Required',
            message: 'Please enable activity recognition permission to track steps.',
          );
        }
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
      _saveConnectionStatus(true);

      if (!silent) {
        TLoaders.successSnackBar(
          title: 'Tracking Started',
          message: 'Step tracking is now active.',
        );
      }
    } catch (e) {
      if (!silent) {
        TLoaders.errorSnackBar(
          title: 'Error',
          message: 'Failed to start step tracking: ${e.toString()}',
        );
      }
    }
  }

  /// Stop tracking steps
  void stopTracking() {
    _stepCountSubscription?.cancel();
    _pedestrianStatusSubscription?.cancel();
    _stepCountSubscription = null;
    _pedestrianStatusSubscription = null;
    isTracking.value = false;
    _saveConnectionStatus(false);

    // 立即通知所有监听者状态已改变
    update();
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