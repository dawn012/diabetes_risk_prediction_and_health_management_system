import 'package:flutter/material.dart' hide NavigationMode;
import 'package:get/get.dart';
import 'dart:math' as math;

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/health_log/health_log_repository.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../../../services/diabetes_hive_storage_manager.dart';
import '../views/diabetes_input/diabetes_prediction_overview_screen.dart';
import '../views/diabetes_input/physical_activity_input_screen.dart';
import '../views/diabetes_input/widgets/diabetes_prediction_input_screen.dart';

class DiabetesBloodGlucoseController extends GetxController {
  static DiabetesBloodGlucoseController get instance => Get.find();

  // Observable variables
  final Rx<double> currentValue = 100.0.obs;
  final RxString measurementType = 'mg/dL'.obs;
  final RxBool isLoading = false.obs;
  final RxBool canGoBack = false.obs;
  final RxBool shouldShowSyncButton = false.obs;
  final Rx<NavigationMode> navigationMode = NavigationMode.flow.obs;

  // Repositories
  final UserRepository _userRepository = Get.put(UserRepository());
  final HealthLogRepository _healthLogRepository = Get.put(HealthLogRepository());
  final DiabetesHiveStorageManager _storageManager = DiabetesHiveStorageManager.instance;

  final List<double> mmolLabels = [2.8, 5.5, 11.0, 22.0];
  String userId = '';
  double? syncableGlucose;
  bool hasUserInput = false;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  /// Initialize controller
  Future<void> _initialize() async {
    // Get navigation mode from arguments if provided
    if (Get.arguments != null && Get.arguments['mode'] != null) {
      navigationMode.value = Get.arguments['mode'];
    }

    await _loadExistingData();
    await _checkSyncAvailability();
    await _checkNavigationState();
  }

  /// Check if user can proceed
  RxBool get canProceed => (currentValue.value > 0).obs;

  /// Load existing user data if available
  Future<void> _loadExistingData() async {
    try {
      isLoading.value = true;

      final userData = await _userRepository.fetchUserDetails();
      userId = userData.userId;

      // Check cache first (priority)
      final cachedData = _storageManager.getStepData(2);
      if (cachedData != null) {
        if (cachedData['glucose'] != null && cachedData['glucose'] > 0) {
          currentValue.value = cachedData['glucose'];
          hasUserInput = true;
        }
        if (cachedData['unit'] != null) {
          measurementType.value = cachedData['unit'];
        }
      }

    } catch (e) {
      print('Error loading existing data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Check if sync is available from health logs
  Future<void> _checkSyncAvailability() async {
    try {
      final threeDaysAgo = DateTime.now().subtract(Duration(days: 3));
      final glucoseLogs = await _healthLogRepository.getBloodGlucoseLogsStream(
          userId,
          threeDaysAgo,
          DateTime.now()
      ).first;

      if (glucoseLogs.isNotEmpty) {
        final latestGlucose = glucoseLogs.first.bloodGlucose.glucoseLevel;
        // Convert mmol/L to mg/dL
        final glucoseMgDl = latestGlucose * 18.0;

        // Get current value in mg/dL for comparison
        final currentMgDl = measurementType.value == 'mmol/L'
            ? mmolToMgdl(currentValue.value)
            : currentValue.value;

        if (hasUserInput) {
          // User has input, compare with latest log
          if (glucoseMgDl > 0 && glucoseMgDl != currentMgDl) {
            syncableGlucose = glucoseMgDl;
            shouldShowSyncButton.value = true;
          }
        } else {
          // User hasn't input, show sync if logs exist
          if (glucoseMgDl > 0) {
            syncableGlucose = glucoseMgDl;
            shouldShowSyncButton.value = true;
          }
        }
      }
    } catch (e) {
      print('Error checking sync: $e');
    }
  }

  /// Check navigation state
  Future<void> _checkNavigationState() async {
    if (navigationMode.value == NavigationMode.edit) {
      // Edit mode: no back button
      canGoBack.value = false;
    } else {
      // Flow mode: check progress
      final lastStep = _storageManager.getLastCompletedStep();

      // Can go back if previous steps are completed
      canGoBack.value = lastStep >= 1;
    }
  }

  /// Sync from health logs
  Future<void> syncFromHealthLogs() async {
    if (syncableGlucose != null) {
      // Convert to current unit if needed
      if (measurementType.value == 'mmol/L') {
        currentValue.value = mgdlToMmol(syncableGlucose!);
      } else {
        currentValue.value = syncableGlucose!;
      }
      hasUserInput = true;
      shouldShowSyncButton.value = false;

      TLoaders.successSnackBar(
        title: 'Synced',
        message: 'Blood glucose synced from health logs',
      );
    }
  }

  /// Set measurement type (mg/dL or mmol/L)
  void setMeasurementType(String type) {
    if (measurementType.value == type) return;

    // Convert current value to new unit
    if (type == 'mmol/L' && measurementType.value == 'mg/dL') {
      currentValue.value = mgdlToMmol(currentValue.value);
    } else if (type == 'mg/dL' && measurementType.value == 'mmol/L') {
      currentValue.value = mmolToMgdl(currentValue.value);
    }

    measurementType.value = type;
    update();
  }

  /// Update glucose value
  void updateGlucoseValue(double value) {
    currentValue.value = value;
    hasUserInput = true;
    update();
  }

  /// Convert mg/dL to mmol/L
  double mgdlToMmol(double mgdl) {
    return double.parse((mgdl / 18.0).toStringAsFixed(1));
  }

  /// Convert mmol/L to mg/dL
  double mmolToMgdl(double mmol) {
    return double.parse((mmol * 18.0).toStringAsFixed(0));
  }

  /// Get glucose color based on level
  Color getGlucoseColor() {
    if (measurementType.value == 'mg/dL') {
      if (currentValue.value < 70) return Colors.blue;
      if (currentValue.value <= 99) return Colors.green;
      if (currentValue.value <= 125) return Colors.orange;
      if (currentValue.value <= 199) return Colors.deepOrange;
      return Colors.red;
    } else {
      // mmol/L ranges
      if (currentValue.value < 3.9) return Colors.blue;
      if (currentValue.value <= 5.5) return Colors.green;
      if (currentValue.value <= 6.9) return Colors.orange;
      if (currentValue.value <= 11.0) return Colors.deepOrange;
      return Colors.red;
    }
  }

  /// Get glucose status text
  String getGlucoseStatus() {
    if (measurementType.value == 'mg/dL') {
      if (currentValue.value < 70) return 'Low';
      if (currentValue.value <= 99) return 'Normal';
      if (currentValue.value <= 125) return 'Elevated';
      if (currentValue.value <= 199) return 'High';
      return 'Very High';
    } else {
      // mmol/L ranges
      if (currentValue.value < 3.9) return 'Low';
      if (currentValue.value <= 5.5) return 'Normal';
      if (currentValue.value <= 6.9) return 'Elevated';
      if (currentValue.value <= 11.0) return 'High';
      return 'Very High';
    }
  }

  /// Get needle angle for gauge display
  double getNeedleAngle() {
    double percentage;

    if (measurementType.value == 'mg/dL') {
      // Map 50-400 to 0-270 degrees
      percentage = (currentValue.value - 50) / (400 - 50);
    } else {
      // Map 2.8-22.0 to 0-270 degrees
      percentage = (currentValue.value - 2.8) / (22.0 - 2.8);
    }

    percentage = percentage.clamp(0.0, 1.0);
    return (percentage * 270 - 135) * math.pi / 180; // -135 to 135 degrees
  }

  /// Handle close button
  Future<void> handleClose(BuildContext context) async {
    if (navigationMode.value == NavigationMode.flow) {
      // Save to cache before closing
      await _storageManager.updateStepData(2, {
        'glucose': currentValue.value,
        'unit': measurementType.value,
      });
    }

    // Navigate to overview with slide down transition
    Get.off(
          () => DiabetesPredictionOverviewScreen(),
      transition: Transition.downToUp,
      duration: Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  /// Save data and continue to next screen
  Future<void> saveAndContinue() async {
    if (!canProceed.value) return;

    try {
      isLoading.value = true;

      // Convert to mg/dL for consistent storage
      final glucoseInMgDl = measurementType.value == 'mmol/L'
          ? mmolToMgdl(currentValue.value)
          : currentValue.value;

      // Save to Hive cache
      await _storageManager.updateStepData(2, {
        'glucose': glucoseInMgDl,
        'unit': 'mg/dL', // Always store in mg/dL for consistency
      });

      // Navigate based on mode
      if (navigationMode.value == NavigationMode.edit) {
        // Edit mode: return to overview with slide down
        TLoaders.successSnackBar(
          title: 'Saved',
          message: 'Blood glucose updated in cache',
        );

        Get.off(
              () => DiabetesPredictionOverviewScreen(),
          transition: Transition.downToUp,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        // Flow mode: continue to next step
        Get.to(() => PhysicalActivityInputScreen());
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Error', message: 'Failed to save data. Please try again.');
      print('Error saving blood glucose: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset values to default
  void reset() {
    currentValue.value = measurementType.value == 'mg/dL' ? 100.0 : 5.5;
    hasUserInput = false;
    update();
  }

  @override
  void onClose() {
    super.onClose();
  }
}