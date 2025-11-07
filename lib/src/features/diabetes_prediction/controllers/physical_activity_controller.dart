import 'package:flutter/material.dart' hide NavigationMode;
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/health_log/health_log_repository.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../../../services/diabetes_hive_storage_manager.dart';
import '../views/diabetes_input/diabetes_prediction_overview_screen.dart';
import '../views/diabetes_input/stress_level_input_screen.dart';
import '../views/diabetes_input/widgets/diabetes_prediction_input_screen.dart';

class PhysicalActivityController extends GetxController {
  static PhysicalActivityController get instance => Get.find();

  // Observable variables
  final RxInt duration = 0.obs; // Minutes per day
  final RxBool isLoading = false.obs;
  final RxBool canGoBack = false.obs;
  final RxBool shouldShowSyncButton = false.obs;
  final Rx<NavigationMode> navigationMode = NavigationMode.flow.obs;

  // Repositories
  final UserRepository _userRepository = Get.put(UserRepository());
  final HealthLogRepository _healthLogRepository = Get.put(HealthLogRepository());
  final DiabetesHiveStorageManager _storageManager = DiabetesHiveStorageManager.instance;

  String userId = '';
  int? syncableDuration;
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

  /// Check if user can proceed to next step
  RxBool get canProceed => (duration.value >= 0).obs;

  /// Load existing user data if available
  Future<void> _loadExistingData() async {
    try {
      isLoading.value = true;

      // Get current user data
      final userData = await _userRepository.fetchUserDetails();
      userId = userData.userId;

      // Check cache first (priority)
      final cachedData = _storageManager.getStepData(3);
      if (cachedData != null) {
        if (cachedData['duration'] != null && cachedData['duration'] >= 0) {
          duration.value = cachedData['duration'];
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
  /// Special: Calculate 7-day average and compare with user input
  Future<void> _checkSyncAvailability() async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));
      final activityLogs = await _healthLogRepository
          .getPhysicalActivityLogsStream(
          userId,
          sevenDaysAgo,
          DateTime.now()
      )
          .first;

      if (activityLogs.isNotEmpty) {
        // Calculate average daily duration
        final totalDuration = activityLogs.fold<int>(
            0,
                (sum, log) => sum + log.physicalActivity.duration
        );
        final averageDuration = (totalDuration / activityLogs.length).round();

        if (hasUserInput) {
          // User has input, compare with 7-day average
          if (averageDuration > 0 && averageDuration != duration.value) {
            syncableDuration = averageDuration;
            shouldShowSyncButton.value = true;
          }
        } else {
          // User hasn't input, show sync if logs exist
          if (averageDuration > 0) {
            syncableDuration = averageDuration;
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
      canGoBack.value = lastStep >= 2;
    }
  }

  /// Sync from health logs (7-day average)
  Future<void> syncFromHealthLogs() async {
    if (syncableDuration != null) {
      duration.value = syncableDuration!;
      hasUserInput = true;
      shouldShowSyncButton.value = false;

      TLoaders.successSnackBar(
        title: 'Synced',
        message: 'Activity duration synced from health logs (7-day average: ${syncableDuration} min/day)',
      );
    }
  }

  /// Set exercise duration (minutes per day)
  void setDuration(int minutes) {
    duration.value = minutes;
    hasUserInput = true;
    update();
  }

  /// Handle close button - always go to overview with slide down
  Future<void> handleClose(BuildContext context) async {
    if (navigationMode.value == NavigationMode.flow) {
      // Save to cache before closing
      await _storageManager.updateStepData(3, {
        'duration': duration.value,
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
      await _storageManager.updateStepData(3, {
        'duration': duration.value,
      });

      // Navigate based on mode
      if (navigationMode.value == NavigationMode.edit) {
        // Edit mode: return to overview with slide down
        TLoaders.successSnackBar(
          title: 'Saved',
          message: 'Physical activity updated in cache',
        );

        Get.off(
              () => DiabetesPredictionOverviewScreen(),
          transition: Transition.downToUp,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        // Flow mode: continue to next step
        Get.to(() => StressLevelInputScreen());
      }

    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to save data. Please try again.',
      );
      print('Error saving physical activity: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Calculate activity level category
  String getActivityLevel() {
    if (duration.value == 0) return 'Sedentary';
    if (duration.value < 15) return 'Minimal';
    if (duration.value < 30) return 'Light';
    if (duration.value < 60) return 'Moderate';
    return 'Active';
  }

  /// Get activity level color
  Color getActivityLevelColor() {
    if (duration.value == 0) return Colors.grey;
    if (duration.value < 15) return Colors.orange;
    if (duration.value < 30) return Colors.amber;
    if (duration.value < 60) return Colors.lightGreen;
    return Colors.green;
  }

  /// Get activity level description
  String getActivityLevelDescription() {
    switch (getActivityLevel()) {
      case 'Sedentary':
        return 'No regular physical activity';
      case 'Minimal':
        return 'Some light physical activity';
      case 'Light':
        return 'Regular light activity';
      case 'Moderate':
        return 'Regular moderate activity';
      case 'Active':
        return 'Very active lifestyle';
      default:
        return '';
    }
  }

  /// Get WHO recommendation message
  String getWHORecommendation() {
    final weeklyMinutes = duration.value * 7;

    if (weeklyMinutes < 150) {
      final remaining = 150 - weeklyMinutes;
      return 'Add $remaining more minutes per week to meet WHO guidelines (150 min/week)';
    } else {
      return 'Great! You meet WHO recommendations for physical activity';
    }
  }

  /// Check if meets WHO guidelines
  bool meetsWHOGuidelines() {
    return (duration.value * 7) >= 150;
  }

  /// Reset all values
  void reset() {
    duration.value = 0;
    hasUserInput = false;
    update();
  }

  @override
  void onClose() {
    super.onClose();
  }
}