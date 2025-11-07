import 'package:flutter/material.dart' hide NavigationMode;
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../../../services/diabetes_hive_storage_manager.dart';
import '../views/diabetes_input/diabetes_prediction_overview_screen.dart';
import '../views/diabetes_input/water_intake_input_screen.dart';
import '../views/diabetes_input/widgets/diabetes_prediction_input_screen.dart';

/// Controller for managing sleep duration input
class SleepDurationController extends GetxController {
  static SleepDurationController get instance => Get.find();

  // Sleep duration in hours (3.0 to 12.0)
  final sleepDuration = 7.5.obs;

  // Loading state
  final isLoading = false.obs;
  final RxBool canGoBack = false.obs;
  final Rx<NavigationMode> navigationMode = NavigationMode.flow.obs;

  // Repositories
  final UserRepository _userRepository = Get.put(UserRepository());
  final DiabetesHiveStorageManager _storageManager = DiabetesHiveStorageManager.instance;

  String userId = '';

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
    await _checkNavigationState();
  }

  /// Load existing user data if available
  Future<void> _loadExistingData() async {
    try {
      isLoading.value = true;

      // Get current user data
      final userData = await _userRepository.fetchUserDetails();
      userId = userData.userId;

      // Check cache first (priority)
      final cachedData = _storageManager.getStepData(5);
      if (cachedData != null) {
        if (cachedData['sleepDuration'] != null &&
            cachedData['sleepDuration'] >= 3.0 &&
            cachedData['sleepDuration'] <= 12.0) {
          sleepDuration.value = cachedData['sleepDuration'];
        }
      }

    } catch (e) {
      print('Error loading existing sleep data: $e');
    } finally {
      isLoading.value = false;
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
      canGoBack.value = lastStep >= 4;
    }
  }

  /// Set sleep duration
  void setSleepDuration(double duration) {
    if (duration >= 3 && duration <= 12) sleepDuration.value = duration;
  }

  /// Check if can proceed (always true since sleep duration is always valid)
  bool get canProceed => true;

  /// Get formatted duration string
  String getFormattedDuration() {
    final hours = sleepDuration.value.floor();
    final minutes = ((sleepDuration.value - hours) * 60).round();

    if (minutes == 0) {
      return '${hours}h';
    } else {
      return '${hours}h ${minutes}m';
    }
  }

  /// Get sleep quality color based on duration
  Color getSleepQualityColor() {
    final duration = sleepDuration.value;

    if (duration >= 7.0 && duration <= 9.0) {
      return Colors.green; // Optimal sleep
    } else if ((duration >= 6.0 && duration < 7.0) || (duration > 9.0 && duration <= 10.0)) {
      return Colors.orange; // Suboptimal but acceptable
    } else {
      return Colors.red; // Poor sleep duration
    }
  }

  /// Get sleep icon based on duration
  IconData getSleepIcon() {
    final duration = sleepDuration.value;

    if (duration >= 7.0 && duration <= 9.0) {
      return Icons.bedtime; // Good sleep
    } else if (duration < 6.0) {
      return Icons.alarm; // Too little sleep
    } else {
      return Icons.snooze; // Too much sleep
    }
  }

  /// Get sleep quality description
  String getSleepQualityDescription() {
    final duration = sleepDuration.value;

    if (duration < 5.0) {
      return 'Severely Insufficient Sleep';
    } else if (duration < 7.0) {
      return 'Insufficient Sleep';
    } else if (duration <= 9.0) {
      return 'Optimal Sleep Duration';
    } else {
      return 'Excessive Sleep Duration';
    }
  }

  /// Get sleep quality category for data analysis
  String getSleepQualityCategory() {
    final duration = sleepDuration.value;

    if (duration < 6.0) {
      return 'Insufficient';
    } else if (duration <= 9.0) {
      return 'Optimal';
    } else {
      return 'Excessive';
    }
  }

  /// Calculate sleep score (0-100)
  int getSleepScore() {
    final duration = sleepDuration.value;
    int score = 0;

    // Base score from duration
    if (duration >= 7.0 && duration <= 9.0) {
      score = 100;
    } else if ((duration >= 6.5 && duration < 7.0) || (duration > 9.0 && duration <= 9.5)) {
      score = 85;
    } else if ((duration >= 6.0 && duration < 6.5) || (duration > 9.5 && duration <= 10.0)) {
      score = 70;
    } else if ((duration >= 5.5 && duration < 6.0) || (duration > 10.0 && duration <= 10.5)) {
      score = 55;
    } else {
      score = 40;
    }

    return score;
  }

  /// Handle close button - always go to overview with slide down
  Future<void> handleClose(BuildContext context) async {
    if (navigationMode.value == NavigationMode.flow) {
      // Save to cache before closing
      await _storageManager.updateStepData(5, {
        'sleepDuration': sleepDuration.value,
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
    try {
      isLoading.value = true;

      // Save to Hive cache
      await _storageManager.updateStepData(5, {
        'sleepDuration': sleepDuration.value,
      });

      // Navigate based on mode
      if (navigationMode.value == NavigationMode.edit) {
        // Edit mode: return to overview with slide down
        TLoaders.successSnackBar(
          title: 'Saved',
          message: 'Sleep duration updated in cache',
        );

        Get.off(
              () => DiabetesPredictionOverviewScreen(),
          transition: Transition.downToUp,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        // Flow mode: continue to next step
        Get.to(() => const WaterIntakeInputScreen());
      }

    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to save sleep duration data. Please try again.',
      );
      print('Error saving sleep duration: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset all values to default
  void reset() {
    sleepDuration.value = 7.5;
    isLoading.value = false;
  }

  /// Get data for API submission
  Map<String, dynamic> toJson() {
    return {
      'sleepDuration': sleepDuration.value,
      'sleepScore': getSleepScore(),
      'sleepQuality': getSleepQualityCategory(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}