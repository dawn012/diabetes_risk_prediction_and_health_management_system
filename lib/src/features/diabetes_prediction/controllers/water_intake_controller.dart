import 'package:flutter/material.dart' hide NavigationMode;
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../../../services/diabetes_hive_storage_manager.dart';
import '../../personalization/controllers/user_controller.dart';
import '../utils/diabetes_category_helper.dart';
import '../views/diabetes_input/diabetes_prediction_overview_screen.dart';
import '../views/diabetes_input/medication_adherence_input_screen.dart';
import '../views/diabetes_input/widgets/diabetes_prediction_input_screen.dart';

/// Controller for managing water intake input
class WaterIntakeController extends GetxController {
  static WaterIntakeController get instance => Get.find();

  // Water intake in liters per day (0.5 to 5.0)
  final Rx<double> waterIntake = 2.0.obs;

  // Preferred unit for display (liters, cups, bottles)
  final preferredUnit = 'liters'.obs;

  // Loading state
  final isLoading = false.obs;
  final RxBool canGoBack = false.obs;
  final Rx<NavigationMode> navigationMode = NavigationMode.flow.obs;

  // Repositories
  final UserRepository _userRepository = Get.put(UserRepository());
  final DiabetesHiveStorageManager _storageManager = DiabetesHiveStorageManager.instance;

  String userId = '';
  final currentUser = UserController.instance.user.value;

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
      final cachedData = _storageManager.getStepData(6);
      if (cachedData != null) {
        if (cachedData['waterIntake'] != null &&
            cachedData['waterIntake'] >= 0.5 &&
            cachedData['waterIntake'] <= 5.0) {
          waterIntake.value = cachedData['waterIntake'];
        }
        if (cachedData['preferredUnit'] != null) {
          preferredUnit.value = cachedData['preferredUnit'];
        }
      }

    } catch (e) {
      print('Error loading existing water intake data: $e');
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
      canGoBack.value = lastStep >= 5;
    }
  }

  /// Hydration classification (Severely / Under / Optimal / Over)
  String getHydrationStatusLabel() {
    final intake = waterIntake.value;
    final levels = DiabetesCategoryHelper.getWaterIntakeLevels(gender: currentUser.profile.gender, age: currentUser.profile.age);

    if (intake < levels[0]) return 'Severely Dehydrated';
    if (intake < levels[2]) return 'Under Hydrated'; // below optimal
    if (intake <= levels[3]) return 'Optimal Hydration';
    return 'Over Hydrated';
  }

  /// Color indicator for hydration level
  Color getHydrationStatusColor() {
    switch (getHydrationStatusLabel()) {
      case 'Severely Dehydrated':
        return Colors.red;
      case 'Under Hydrated':
        return Colors.orange;
      case 'Optimal Hydration':
        return Colors.green;
      case 'Over Hydrated':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Description for user feedback
  String getHydrationStatusDescription() {
    return getHydrationStatusLabel();
  }

  /// Binary hydration status (1 = adequately hydrated, 0 = not hydrated)
  int get hydrationStatusBinary {
    final label = getHydrationStatusLabel();
    if (label == 'Optimal Hydration') {
      return 1; // Yes
    } else {
      return 0; // No
    }
  }

  /// Set water intake amount
  void setWaterIntake(double intake) {
    if (intake >= 0.5 && intake <= 5.0) {
      waterIntake.value = double.parse(intake.toStringAsFixed(1));
    } else {
      // 如果超出范围，限制到边界值
      waterIntake.value = intake < 0.5 ? 0.5 : 5.0;
    }
  }

  /// Set preferred unit
  void setPreferredUnit(String unit) {
    preferredUnit.value = unit;
  }

  /// Check if can proceed (always true since water intake is always valid)
  bool get canProceed => true;

  /// Convert liters to cups (1 liter ≈ 4.2 cups)
  int getCupsEquivalent() {
    return (waterIntake.value * 4.2).round();
  }

  /// Convert liters to bottles (assuming 500ml bottles)
  int getBottlesEquivalent() {
    return (waterIntake.value * 2).round();
  }

  /// Get the water intake in preferred unit
  String getFormattedIntake() {
    switch (preferredUnit.value) {
      case 'cups':
        return '${getCupsEquivalent()} cups';
      case 'bottles':
        return '${getBottlesEquivalent()} bottles';
      default:
        return '${waterIntake.value.toStringAsFixed(1)} liters';
    }
  }

  /// Handle close button - always go to overview with slide down
  Future<void> handleClose(BuildContext context) async {
    if (navigationMode.value == NavigationMode.flow) {
      // Save to cache before closing
      await _storageManager.updateStepData(6, {
        'waterIntake': waterIntake.value,
        'preferredUnit': preferredUnit.value,
        'hydrationStatusBinary': hydrationStatusBinary
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
      await _storageManager.updateStepData(6, {
        'waterIntake': waterIntake.value,
        'preferredUnit': preferredUnit.value,
        'hydrationStatusBinary': hydrationStatusBinary
      });

      // Navigate based on mode
      if (navigationMode.value == NavigationMode.edit) {
        // Edit mode: return to overview with slide down
        TLoaders.successSnackBar(
          title: 'Saved',
          message: 'Water intake updated in cache',
        );

        Get.off(
              () => DiabetesPredictionOverviewScreen(),
          transition: Transition.downToUp,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        // Flow mode: continue to next step
        Get.off(() => const MedicationAdherenceInputScreen());
      }

    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to save water intake data. Please try again.',
      );
      print('Error saving water intake: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset all values to default
  void reset() {
    waterIntake.value = 2.0;
    preferredUnit.value = 'liters';
    isLoading.value = false;
  }

  /// Get data for API submission
  // Map<String, dynamic> toJson() {
  //   return {
  //     'waterIntake': waterIntake.value,
  //     'preferredUnit': preferredUnit.value,
  //     'hydrationStatus': getHydrationStatusCategory(),
  //     'hydrationScore': getHydrationScore(),
  //     'timestamp': DateTime.now().toIso8601String(),
  //   };
  // }
}