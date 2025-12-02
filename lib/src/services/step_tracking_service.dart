import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../common/loaders/loaders.dart';
import '../data/repositories/authentication/authentication_repository.dart';
import '../data/repositories/health_log/health_log_repository.dart';
import '../features/health_data_entry/models/health_data_model.dart';
import '../features/personalization/controllers/user_controller.dart';

class StepTrackingService extends GetxController {
  static StepTrackingService get instance => Get.find();

  final _authRepo = AuthenticationRepository.instance;
  final _healthLogRepo = Get.put(HealthLogRepository());
  final _storage = GetStorage();

  // Storage base keys
  static const String _isConnectedKey = 'step_tracking_connected';
  static const String _lastSavedStepsKey = 'last_saved_steps';
  static const String _lastSaveDateKey = 'last_save_date';
  static const String _systemOffsetKey = 'system_step_offset';

  // Observables
  final isTracking = false.obs;
  final isConnected = false.obs;
  final currentSteps = 0.obs;
  final todaySteps = 0.obs;
  final isInitialized = false.obs;

  // Private variables
  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;
  int _systemStepOffset = 0;
  DateTime _lastResetDate = DateTime.now();
  int _lastSavedSteps = 0;
  DateTime? _lastSaveTime;
  final int _saveThreshold = 100;

  String? get _currentUserId => UserController.instance.user.value.userId;

  String _userKey(String baseKey) {
    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) return baseKey;
    return '${uid}_$baseKey';
  }

  @override
  void onInit() {
    super.onInit();
    _loadConnectionStatus();
    _loadSavedState();
    _setupAppLifecycle();
    _initializeStepTracking();
  }

  @override
  void onClose() {
    _saveBeforeClose();
    stopTracking();
    super.onClose();
  }

  DateTime _getNormalizedDate(DateTime date) {
    return DateTime(date.year, date.month, date.day, 12, 0, 0);
  }

  Future<void> _initializeStepTracking() async {
    if (isInitialized.value) {
      print('⏭️ Step tracking already initialized');
      return;
    }

    try {
      print('🔄 Initializing step tracking...');

      await _loadTodaySteps();

      if (isConnected.value) {
        await _checkAndStartTracking();
      }

      isInitialized.value = true;
      print('✅ Step tracking initialized successfully');
    } catch (e) {
      print('❌ Error initializing step tracking: $e');
      isInitialized.value = true;
    }
  }

  void _loadSavedState() {
    _lastSavedSteps = _storage.read(_userKey(_lastSavedStepsKey)) ?? 0;
    _systemStepOffset = _storage.read(_userKey(_systemOffsetKey)) ?? 0;

    final lastSaveMillis = _storage.read(_userKey(_lastSaveDateKey));
    if (lastSaveMillis != null) {
      _lastSaveTime = DateTime.fromMillisecondsSinceEpoch(lastSaveMillis);
    }

    print('📂 Loaded state: lastSaved=$_lastSavedSteps, offset=$_systemStepOffset');
  }

  void _saveState() {
    _storage.write(_userKey(_lastSavedStepsKey), _lastSavedSteps);
    _storage.write(_userKey(_lastSaveDateKey), DateTime.now().millisecondsSinceEpoch);
    _storage.write(_userKey(_systemOffsetKey), _systemStepOffset);
    print('💾 State saved: lastSaved=$_lastSavedSteps, offset=$_systemStepOffset');
  }

  void _setupAppLifecycle() {
    WidgetsBinding.instance.addObserver(
      LifecycleEventHandler(
        resumeCallBack: () => _onAppResumed(),
        suspendCallBack: () => _onAppPaused(),
      ),
    );
  }

  Future<void> _onAppPaused() async {
    print('App going to background, saving steps...');
    await _forceSaveCurrentSteps();
  }

  Future<void> _onAppResumed() async {
    print('App resumed, checking day change...');
    _checkDayChange();
  }

  void _checkDayChange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastReset = DateTime(_lastResetDate.year, _lastResetDate.month, _lastResetDate.day);

    if (!today.isAtSameMomentAs(lastReset)) {
      print('New day detected, resetting steps...');
      _resetForNewDay();
    }
  }

  Future<void> _resetForNewDay() async {
    if (todaySteps.value > 0) {
      await _saveStepsToFirebase(todaySteps.value, forceSave: true);
    }

    todaySteps.value = 0;
    currentSteps.value = 0;
    _lastSavedSteps = 0;
    _lastResetDate = DateTime.now();

    if (isTracking.value) {
      try {
        final currentSystemSteps = await Pedometer.stepCountStream.first;
        _systemStepOffset = currentSystemSteps.steps;
        print('🔄 New day: Reset offset to $_systemStepOffset');
      } catch (e) {
        print('❌ Error resetting offset: $e');
        _systemStepOffset = 0;
      }
    } else {
      _systemStepOffset = 0;
    }

    _saveState();
    print('✅ Steps reset for new day');
  }

  void _loadConnectionStatus() {
    isConnected.value = _storage.read(_userKey(_isConnectedKey)) ?? false;

    if (isConnected.value) {
      _checkAndStartTracking();
    }
  }

  void _saveConnectionStatus(bool connected) {
    _storage.write(_userKey(_isConnectedKey), connected);
    isConnected.value = connected;
    update();
    print('Step tracking connection status saved: $connected');
  }

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

  Future<void> _loadTodaySteps() async {
    try {
      final userId = _authRepo.authUser?.uid;
      if (userId == null) {
        print('❌ No user ID available');
        return;
      }

      final today = DateTime.now();
      final todayNoon = _getNormalizedDate(today);

      print('🔍 Loading steps for: ${todayNoon.toString()}');

      final stepRecord = await _healthLogRepo.findStepRecordForDate(
        userId: userId,
        date: todayNoon,
      );

      if (stepRecord != null && stepRecord.steps != null) {
        final savedSteps = stepRecord.steps!;
        todaySteps.value = savedSteps;
        currentSteps.value = savedSteps;
        _lastSavedSteps = savedSteps;

        print('✅ Loaded steps from Firebase: $savedSteps (log ID: ${stepRecord.logId})');
      } else {
        print('📭 No steps found in Firebase for today');
        todaySteps.value = 0;
        currentSteps.value = 0;
        _lastSavedSteps = 0;
      }
    } catch (e) {
      print('❌ Error loading today steps: $e');
      todaySteps.value = 0;
      currentSteps.value = 0;
      _lastSavedSteps = 0;
    }
  }

  Future<void> startTracking({bool silent = false}) async {
    if (isTracking.value) {
      _saveConnectionStatus(true);
      return;
    }

    try {
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

      await _setupSystemOffset();

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

      print('✅ Step tracking started');
    } catch (e) {
      if (!silent) {
        TLoaders.errorSnackBar(
          title: 'Error',
          message: 'Failed to start step tracking: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _setupSystemOffset() async {
    try {
      final initialStepCount = await Pedometer.stepCountStream.first;
      final systemSteps = initialStepCount.steps;
      final savedSteps = todaySteps.value;

      _systemStepOffset = systemSteps - savedSteps;

      print('📊 System offset setup: system=$systemSteps, saved=$savedSteps, offset=$_systemStepOffset');

      _saveState();
    } catch (e) {
      print('❌ Error setting up system offset: $e');
      _systemStepOffset = 0;
    }
  }

  void stopTracking() {
    _stepCountSubscription?.cancel();
    _pedestrianStatusSubscription?.cancel();
    _stepCountSubscription = null;
    _pedestrianStatusSubscription = null;
    isTracking.value = false;
    _saveConnectionStatus(false);
    _saveBeforeClose();
    update();
  }

  Future<void> _saveBeforeClose() async {
    if (todaySteps.value > 0 && todaySteps.value != _lastSavedSteps) {
      await _saveStepsToFirebase(todaySteps.value, forceSave: true);
      print('Final steps saved before close: ${todaySteps.value}');
    }
  }

  void _onStepCount(StepCount event) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastReset = DateTime(_lastResetDate.year, _lastResetDate.month, _lastResetDate.day);

    if (!today.isAtSameMomentAs(lastReset)) {
      print('🔄 New day detected in step count, resetting...');
      _resetForNewDay();
      return;
    }

    final actualSteps = event.steps - _systemStepOffset;

    if (actualSteps < 0) {
      print('⚠️ Negative steps detected, resetting offset');
      _systemStepOffset = event.steps - todaySteps.value;
      _saveState();
      return;
    }

    if (actualSteps != todaySteps.value) {
      todaySteps.value = actualSteps;
      currentSteps.value = actualSteps;

      print('📈 Steps updated: $actualSteps (system: ${event.steps}, offset: $_systemStepOffset)');

      _checkAndSaveSteps(actualSteps);
    }
  }

  void _checkAndSaveSteps(int currentSteps) {
    final stepsDiff = (currentSteps - _lastSavedSteps).abs();

    final bool thresholdReached = stepsDiff >= _saveThreshold && stepsDiff > 0;

    final bool timeThresholdReached = _lastSaveTime != null &&
        DateTime.now().difference(_lastSaveTime!).inMinutes >= 10;

    final bool shouldForceSave = stepsDiff == 0 &&
        currentSteps > 0 &&
        _lastSaveTime != null &&
        DateTime.now().difference(_lastSaveTime!).inMinutes >= 5;

    if (thresholdReached || timeThresholdReached || shouldForceSave) {
      _saveStepsToFirebase(currentSteps);
    }
  }

  void _onStepCountError(error) {
    print('Step Count Error: $error');
    stopTracking();
  }

  void _onPedestrianStatusChanged(PedestrianStatus event) {
    print('Pedestrian Status: ${event.status}');
  }

  void _onPedestrianStatusError(error) {
    print('Pedestrian Status Error: $error');
  }

  Future<void> _saveStepsToFirebase(int steps, {bool forceSave = false}) async {
    if (!forceSave && steps == _lastSavedSteps) {
      print('⏭️ Skipping save - steps unchanged: $steps');
      return;
    }

    try {
      final userId = _authRepo.authUser?.uid;
      if (userId == null) {
        print('❌ No user ID available');
        return;
      }

      final now = DateTime.now();
      final logDate = _getNormalizedDate(now);
      final logId =
          'steps_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

      print('💾 Saving steps: $steps for date: ${logDate.toString()}');

      final healthData = HealthDataModel.stepsOnly(
        logId: logId,
        date: logDate,
        steps: steps,
      );

      await _healthLogRepo.saveHealthLog(userId, healthData);

      _lastSavedSteps = steps;
      _lastSaveTime = DateTime.now();
      _saveState();

      print('✅ Steps saved to Firebase: $steps (logId: $logId)');
    } catch (e) {
      print('❌ Error saving steps: $e');
    }
  }

  Future<void> _forceSaveCurrentSteps() async {
    if (todaySteps.value > 0) {
      await _saveStepsToFirebase(todaySteps.value, forceSave: true);
    }
  }

  Future<void> saveCurrentSteps() async {
    await _forceSaveCurrentSteps();
  }

  void resetDailySteps() {
    _systemStepOffset = 0;
    todaySteps.value = 0;
    currentSteps.value = 0;
    _lastSavedSteps = 0;
    _lastResetDate = DateTime.now();
    _saveState();
  }

  Future<void> clearAllLocalData() async {
    print('🧹 Clearing all local step data...');

    await _storage.remove(_userKey(_isConnectedKey));
    await _storage.remove(_userKey(_lastSavedStepsKey));
    await _storage.remove(_userKey(_lastSaveDateKey));
    await _storage.remove(_userKey(_systemOffsetKey));

    _systemStepOffset = 0;
    _lastSavedSteps = 0;
    _lastSaveTime = null;
    _lastResetDate = DateTime.now();

    todaySteps.value = 0;
    currentSteps.value = 0;
    isTracking.value = false;
    isConnected.value = false;
    isInitialized.value = false;

    stopTracking();

    print('✅ All local step data cleared');
  }
}

class LifecycleEventHandler extends WidgetsBindingObserver {
  final AsyncCallback resumeCallBack;
  final AsyncCallback suspendCallBack;

  LifecycleEventHandler({
    required this.resumeCallBack,
    required this.suspendCallBack,
  });

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        await resumeCallBack();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        await suspendCallBack();
        break;
    }
  }
}