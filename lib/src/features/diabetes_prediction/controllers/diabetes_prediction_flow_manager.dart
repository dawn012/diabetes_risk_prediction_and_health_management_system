import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/repositories/user/user_repository.dart';
import '../views/diabetes_input/diabetes_assessment_start_screen.dart';
import '../views/diabetes_input/height_weight_input_screen.dart';
import '../views/diabetes_input/diabetes_prediction_overview_screen.dart';
import '../../../services/diabetes_hive_storage_manager.dart';

/// Manages the diabetes prediction flow and navigation
class DiabetesPredictionFlowManager extends GetxController {
  static DiabetesPredictionFlowManager get instance => Get.find();

  final DiabetesHiveStorageManager _storageManager = DiabetesHiveStorageManager.instance;
  final UserRepository _userRepository = Get.put(UserRepository());

  /// Entry point for diabetes prediction
  /// Checks state and routes to appropriate screen
  Future<void> enterPredictionFlow() async {
    try {
      final hasCache = _storageManager.hasCachedAssessment();
      final isFirstTime = _storageManager.isFirstTime();
      final completedCount = _storageManager.getCompletedStepsCount();
      final isComplete = _storageManager.isAllStepsCompleted();

      if (isFirstTime && !hasCache) {
        // First time and no cache - prefill and go to start screen
        await _prefillFromProfile();

        Get.to(
              () => DiabetesAssessmentStartScreen(),
          transition: Transition.downToUp,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else if (!isFirstTime && hasCache && !isComplete && completedCount > 0) {
        // Has incomplete progress - go to start screen (will show continue and start new buttons)
        Get.to(
              () => DiabetesAssessmentStartScreen(),
          transition: Transition.downToUp,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else if (isComplete) {
        // All completed - go to overview
        Get.to(
              () => DiabetesPredictionOverviewScreen(),
          transition: Transition.downToUp,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else if (!isFirstTime && hasCache && completedCount == 0) {
        // Has started but nothing completed - go to first step
        Get.to(
              () => HeightWeightInputScreen(),
          transition: Transition.downToUp,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        // Default case - go to start screen
        await _prefillFromProfile();
        Get.to(
              () => DiabetesAssessmentStartScreen(),
          transition: Transition.downToUp,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      print('Error entering prediction flow: $e');
      // Default to start screen on error
      Get.to(
            () => DiabetesAssessmentStartScreen(),
        transition: Transition.downToUp,
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Prefill cache from user profile (only height & weight)
  Future<void> _prefillFromProfile() async {
    try {
      final userData = await _userRepository.fetchUserDetails();
      final profile = userData.profile;

      await _storageManager.prefillFromProfile({
        'height': profile.height,
        'weight': profile.weight,
      });
    } catch (e) {
      print('Error prefilling from profile: $e');
    }
  }

  /// Get the next step to navigate to based on current progress
  int getNextIncompleteStep() {
    return _storageManager.getNextIncompleteStep();
  }

  /// Mark assessment as complete
  Future<void> completeAssessment() async {
    await _storageManager.markAssessmentComplete();
  }

  /// Reset entire flow (Start New)
  Future<void> resetFlow() async {
    await _storageManager.clearCache();
    await _prefillFromProfile();
  }

  /// Export to Firestore when prediction is complete
  Future<Map<String, dynamic>?> exportAssessmentData() async {
    return _storageManager.exportToFirestore();
  }
}