import 'package:flutter/material.dart' hide NavigationMode;
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../../../services/diabetes_hive_storage_manager.dart';
import '../views/diabetes_input/diabetes_prediction_overview_screen.dart';
import '../views/diabetes_input/sleep_duration_input_screen.dart';
import '../views/diabetes_input/widgets/diabetes_prediction_input_screen.dart';

class StressLevelController extends GetxController {
  static StressLevelController get instance => Get.find();

  // Observable variables
  final RxInt stressLevel = 5.obs; // Scale 1-10, default to middle
  final RxList<String> stressSources = <String>[].obs; // Selected stress sources (optional)
  final RxBool isLoading = false.obs;
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

  /// Check if user can proceed
  RxBool get canProceed {
    // User can proceed as long as they have selected a stress level (1-10)
    // Stress sources are optional
    return (stressLevel.value >= 1 && stressLevel.value <= 10).obs;
  }

  /// Load existing user data if available
  Future<void> _loadExistingData() async {
    try {
      isLoading.value = true;

      // Get current user data
      final userData = await _userRepository.fetchUserDetails();
      userId = userData.userId;

      // Check cache first (priority)
      final cachedData = _storageManager.getStepData(4);
      if (cachedData != null) {
        if (cachedData['stressLevel'] != null &&
            cachedData['stressLevel'] >= 1 &&
            cachedData['stressLevel'] <= 10) {
          stressLevel.value = cachedData['stressLevel'];
        }
      }

    } catch (e) {
      print('Error loading existing stress data: $e');
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
      canGoBack.value = lastStep >= 3;
    }
  }

  /// Set stress level (1-10)
  void setStressLevel(int level) {
    if (level >= 1 && level <= 10) {
      stressLevel.value = level;
      update();
    }
  }

  /// Toggle stress source selection
  void toggleStressSource(String source) {
    if (stressSources.contains(source)) {
      stressSources.remove(source);
    } else {
      stressSources.add(source);
    }
    update();
  }
  /// Get stress level color based on severity
  Color getStressLevelColor() {
    if (stressLevel.value <= 3) {
      return Colors.green; // Low stress
    } else if (stressLevel.value <= 6) {
      return Colors.orange; // Moderate stress
    } else {
      return Colors.red; // High stress
    }
  }

  /// Get stress level emoji
  String getStressEmoji() {
    if (stressLevel.value <= 3) {
      return '😌'; // Relaxed
    } else if (stressLevel.value <= 6) {
      return '😐'; // Moderately stressed
    } else {
      return '😰'; // Stressed
    }
  }

  /// Get stress level description
  String getStressLevelDescription() {
    if (stressLevel.value <= 3) {
      return 'Low Stress - Feeling calm and relaxed';
    } else if (stressLevel.value <= 6) {
      return 'Moderate Stress - Noticeable stress but manageable';
    } else {
      return 'High Stress - Significant stress affecting daily life';
    }
  }

  /// Get stress category as numeric value (0 = Low, 1 = Moderate, 2 = High)
  int getStressCategory() {
    if (stressLevel.value <= 3) {
      return 0; // Low
    } else if (stressLevel.value <= 6) {
      return 1; // Moderate
    } else {
      return 2; // High
    }
  }

  /// Handle close button - always go to overview with slide down
  Future<void> handleClose(BuildContext context) async {
    if (navigationMode.value == NavigationMode.flow) {
      // Save to cache before closing
      await _storageManager.updateStepData(4, {
        'stressLevel': stressLevel.value,
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
      if (!validateInputs()) return;

      isLoading.value = true;

      // Save to Hive cache
      await _storageManager.updateStepData(4, {
        'stressLevel': stressLevel.value,
      });

      // Navigate based on mode
      if (navigationMode.value == NavigationMode.edit) {
        // Edit mode: return to overview with slide down
        TLoaders.successSnackBar(
          title: 'Saved',
          message: 'Stress level updated in cache',
        );

        Get.off(
              () => DiabetesPredictionOverviewScreen(),
          transition: Transition.downToUp,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        // Flow mode: continue to next step
        Get.to(() => const SleepDurationInputScreen());
      }

    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to save stress level data. Please try again.',
      );
      print('Error saving stress level: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset all values
  void reset() {
    stressLevel.value = 5;
    stressSources.clear();
    update();
  }

  /// Validate inputs
  bool validateInputs() {
    if (stressLevel.value < 1 || stressLevel.value > 10) {
      TLoaders.warningSnackBar(
        title: 'Invalid Stress Level',
        message: 'Stress level must be between 1-10',
      );
      return false;
    }

    return true;
  }

  @override
  void onClose() {
    super.onClose();
  }
}