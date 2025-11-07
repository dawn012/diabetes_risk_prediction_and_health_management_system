import 'package:flutter/material.dart' hide NavigationMode;
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/health_log/health_log_repository.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../views/diabetes_input/blood_glucose_input_screen.dart';
import '../views/diabetes_input/diabetes_prediction_overview_screen.dart';
import '../views/diabetes_input/widgets/diabetes_prediction_input_screen.dart';
import '../../../services/diabetes_hive_storage_manager.dart';

class HeightWeightController extends GetxController {
  static HeightWeightController get instance => Get.find();

  // Observable variables
  final Rx<double> height = 170.0.obs;
  final Rx<double> weight = 70.0.obs;
  final RxBool isLoading = false.obs;
  final RxBool canGoBack = false.obs;
  final RxBool shouldShowSyncButton = false.obs;
  final Rx<NavigationMode> navigationMode = NavigationMode.flow.obs;

  // Repositories
  final UserRepository _userRepository = Get.put(UserRepository());
  final HealthLogRepository _healthLogRepository = Get.put(HealthLogRepository());
  final DiabetesHiveStorageManager _storageManager = DiabetesHiveStorageManager.instance;

  String userId = '';
  double? syncableWeight;
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

  /// Check if user can proceed (both values should be reasonable)
  RxBool get canProceed => (height.value >= 100 &&
      height.value <= 273.9 &&
      weight.value >= 0.1 &&
      weight.value <= 500.0).obs;

  /// Load existing user data if available
  Future<void> _loadExistingData() async {
    try {
      isLoading.value = true;

      // Get current user data
      final userData = await _userRepository.fetchUserDetails();
      userId = userData.userId;

      // First check cache (priority)
      final cachedData = _storageManager.getStepData(1);
      if (cachedData != null) {
        if (cachedData['height'] != null && cachedData['height'] > 0) {
          height.value = cachedData['height'];
        }
        if (cachedData['weight'] != null && cachedData['weight'] > 0) {
          weight.value = cachedData['weight'];
          hasUserInput = true;
        }
      } else {
        // No cache, use profile data (already prefilled if available)
        if (userData.profile.height > 0) {
          height.value = userData.profile.height;
        }
        if (userData.profile.weight > 0) {
          weight.value = userData.profile.weight;
          hasUserInput = true;
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
      final weightLogs = await _healthLogRepository.getBodyCompositionLogsStream(
          userId,
          threeDaysAgo,
          DateTime.now()
      ).first;

      if (weightLogs.isNotEmpty) {
        final latestWeight = weightLogs.first.bodyComposition.weight;

        if (hasUserInput) {
          if (latestWeight > 0 && latestWeight != weight.value) {
            syncableWeight = latestWeight;
            shouldShowSyncButton.value = true;
          }
        } else {
          if (latestWeight > 0) {
            syncableWeight = latestWeight;
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

      // Can go back if has any completed steps
      canGoBack.value = lastStep >= 1;
    }
  }

  /// Sync from health logs
  Future<void> syncFromHealthLogs() async {
    if (syncableWeight != null) {
      weight.value = syncableWeight!;
      hasUserInput = true;
      shouldShowSyncButton.value = false;

      TLoaders.successSnackBar(
        title: 'Synced',
        message: 'Weight synced from health logs',
      );
    }
  }

  /// Update height value
  void updateHeight(double newHeight) {
    height.value = double.parse(newHeight.toStringAsFixed(1));
    hasUserInput = true;
    update();
  }

  /// Update weight value
  void updateWeight(double newWeight) {
    weight.value = double.parse(newWeight.toStringAsFixed(1));
    hasUserInput = true;
    update();
  }

  /// Increase weight by 0.5kg
  void increaseWeight() {
    if (weight.value < 500.0) {
      weight.value = double.parse((weight.value + 0.5).toStringAsFixed(1));
      hasUserInput = true;
      update();
    }
  }

  /// Decrease weight by 0.5kg
  void decreaseWeight() {
    if (weight.value > 0.1) {
      weight.value = double.parse((weight.value - 0.5).toStringAsFixed(1));
      hasUserInput = true;
      update();
    }
  }

  /// Calculate BMI
  double get bmi {
    final heightInMeters = height.value / 100;
    return weight.value / (heightInMeters * heightInMeters);
  }

  /// Get BMI category
  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }

  /// Handle close button - always go to overview with slide down
  Future<void> handleClose(BuildContext context) async {
    if (navigationMode.value == NavigationMode.flow) {
      // Save to cache before closing
      await _storageManager.updateStepData(1, {
        'height': height.value,
        'weight': weight.value,
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

  /// Save data and continue/return based on mode
  Future<void> saveAndContinue() async {
    if (!canProceed.value) return;

    try {
      isLoading.value = true;

      // Save to Hive cache
      await _storageManager.updateStepData(1, {
        'height': height.value,
        'weight': weight.value,
      });

      // Navigate based on mode
      if (navigationMode.value == NavigationMode.edit) {
        // Edit mode: return to overview with slide down
        TLoaders.successSnackBar(
          title: 'Saved',
          message: 'Height and weight updated in cache',
        );

        Get.off(
              () => DiabetesPredictionOverviewScreen(),
          transition: Transition.downToUp,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        // Flow mode: continue to next step
        Get.to(() => BloodGlucoseInputScreen());
      }

    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to save data. Please try again.',
      );
      print('Error saving height/weight: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset values to default
  void reset() {
    height.value = 170.0;
    weight.value = 70.0;
    hasUserInput = false;
    update();
  }

  @override
  void onClose() {
    super.onClose();
  }
}