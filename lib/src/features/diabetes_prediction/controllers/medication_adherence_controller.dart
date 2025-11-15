import 'package:flutter/material.dart' hide NavigationMode;
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../../../services/diabetes_hive_storage_manager.dart';
import '../views/diabetes_input/diabetes_prediction_overview_screen.dart';
import '../views/diabetes_input/meal_photos_upload_screen.dart';
import '../views/diabetes_input/widgets/diabetes_prediction_input_screen.dart';

/// Controller for managing medication adherence input
class MedicationAdherenceController extends GetxController {
  static MedicationAdherenceController get instance => Get.find();

  // Whether user takes diabetes medication
  final takesMedication = Rxn<bool>();

  // Adherence percentage (0-100) - represents how often user takes medication as prescribed
  final adherencePercentage = 90.obs;

  // Reasons for missing medication
  final missedReasons = <String>[].obs;

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
      final cachedData = _storageManager.getStepData(7);
      if (cachedData != null) {
        if (cachedData['takesMedication'] != null) {
          takesMedication.value = cachedData['takesMedication'];
        }
        if (cachedData['adherencePercentage'] != null) {
          adherencePercentage.value = cachedData['adherencePercentage'];
        }
        if (cachedData['missedReasons'] != null) {
          missedReasons.value = List<String>.from(cachedData['missedReasons']);
        }
      }

    } catch (e) {
      print('Error loading existing medication data: $e');
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
      canGoBack.value = lastStep >= 6;
    }
  }

  /// Set whether user takes medication
  void setTakesMedication(bool takes) {
    takesMedication.value = takes;

    // Clear medication-related data if user doesn't take medication
    if (!takes) {
      missedReasons.clear();
      adherencePercentage.value = 0; // Set to 0 if no medication
    } else {
      adherencePercentage.value = 90; // Reset to default if taking medication
    }
  }

  /// Set adherence percentage
  void setAdherencePercentage(int percentage) {
    adherencePercentage.value = percentage;

    // Clear missed reasons if adherence is 100%
    if (percentage == 100) {
      missedReasons.clear();
    }
  }

  /// Toggle missed reason
  void toggleMissedReason(String reason) {
    if (missedReasons.contains(reason)) {
      missedReasons.remove(reason);
    } else {
      missedReasons.add(reason);
    }
  }

  /// Check if can proceed
  bool get canProceed => takesMedication.value != null;

  /// Get medication adherence category for analysis
  String getMedicationAdherenceCategory() {
    if (takesMedication.value != true) {
      return 'No Medication'; // User doesn't take diabetes medication
    }

    final percentage = adherencePercentage.value;

    if (percentage >= 80) {
      return 'Good';
    } else if (percentage >= 50) {
      return 'Fair';
    } else {
      return 'Poor';
    }
  }

  /// Get adherence color
  Color getAdherenceColor() {
    if (takesMedication.value != true) {
      return Colors.grey; // No medication
    }

    final percentage = adherencePercentage.value;

    if (percentage >= 80) {
      return Colors.green; // Good adherence
    } else if (percentage >= 50) {
      return Colors.orange; // Moderate adherence
    } else {
      return Colors.red; // Poor adherence
    }
  }

  /// Get adherence icon
  IconData getAdherenceIcon() {
    if (takesMedication.value != true) {
      return Icons.medication_liquid;
    }

    final percentage = adherencePercentage.value;

    if (percentage >= 80) {
      return Icons.check_circle;
    } else if (percentage >= 50) {
      return Icons.warning;
    } else {
      return Icons.error;
    }
  }

  /// Get adherence description
  String getAdherenceDescription() {
    if (takesMedication.value != true) {
      return 'No Medication Required';
    }

    final percentage = adherencePercentage.value;

    if (percentage == 100) {
      return 'Perfect Adherence';
    } else if (percentage >= 90) {
      return 'Excellent Adherence';
    } else if (percentage >= 80) {
      return 'Good Adherence';
    } else if (percentage >= 70) {
      return 'Fair Adherence';
    } else if (percentage >= 50) {
      return 'Poor Adherence';
    } else {
      return 'Very Poor Adherence';
    }
  }

  /// Returns 0 or 1 for model submission
  int get medicationAdherentBinary {
    if (takesMedication.value != true) {
      return 0; // No medication → 0
    }

    // If user takes medication, check adherence
    return adherencePercentage.value >= 80 ? 1 : 0;
  }

  /// Calculate medication adherence score (0-100)
  // int getMedicationAdherenceScore() {
  //   if (takesMedication.value != true) {
  //     return 100; // Perfect score if no medication needed
  //   }
  //
  //   int score = adherencePercentage.value;
  //
  //   // Deduct points for common problematic reasons
  //   final problematicReasons = [
  //     'Forgetfulness',
  //     'Side effects',
  //     'Cost concerns'
  //   ];
  //   final problematicCount = missedReasons
  //       .where((reason) => problematicReasons.contains(reason))
  //       .length;
  //   score = (score - (problematicCount * 5)).clamp(0, 100);
  //
  //   return score;
  // }

  /// Get risk assessment based on adherence
  // String getRiskAssessment() {
  //   if (takesMedication.value != true) {
  //     return 'Low Risk'; // No medication means no adherence issues
  //   }
  //
  //   final percentage = adherencePercentage.value;
  //
  //   if (percentage >= 80) {
  //     return 'Low Risk';
  //   } else if (percentage >= 50) {
  //     return 'Moderate Risk';
  //   } else {
  //     return 'High Risk';
  //   }
  // }

  /// Handle close button - always go to overview with slide down
  Future<void> handleClose(BuildContext context) async {
    if (navigationMode.value == NavigationMode.flow) {
      // Save to cache before closing
      await _storageManager.updateStepData(7, {
        'takesMedication': takesMedication.value,
        'adherencePercentage': adherencePercentage.value,
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
      if (!canProceed) return;

      isLoading.value = true;

      // Save to Hive cache
      await _storageManager.updateStepData(7, {
        'takesMedication': takesMedication.value,
        'adherencePercentage': adherencePercentage.value,
      });

      // Navigate based on mode
      if (navigationMode.value == NavigationMode.edit) {
        // Edit mode: return to overview with slide down
        TLoaders.successSnackBar(
          title: 'Saved',
          message: 'Medication adherence updated in cache',
        );

        Get.off(
              () => DiabetesPredictionOverviewScreen(),
          transition: Transition.downToUp,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        // Flow mode: continue to next step
        Get.to(() => const MealPhotosUploadScreen());
      }
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to save medication adherence data. Please try again.',
      );
      print('Error saving medication adherence: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset all values to default
  void reset() {
    takesMedication.value = null;
    adherencePercentage.value = 90;
    missedReasons.clear();
    isLoading.value = false;
  }

  /// Get data for API submission
  // Map<String, dynamic> toJson() {
  //   return {
  //     'takesMedication': takesMedication.value,
  //     'adherencePercentage':
  //     takesMedication.value == true ? adherencePercentage.value : 0,
  //     'adherenceCategory': getMedicationAdherenceCategory(),
  //     'riskAssessment': getRiskAssessment(),
  //     'timestamp': DateTime.now().toIso8601String(),
  //   };
  // }
}