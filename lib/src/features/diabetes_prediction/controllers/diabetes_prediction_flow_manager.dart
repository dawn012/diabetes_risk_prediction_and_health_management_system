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
        // Has incomplete progress - show resume dialog
        _showResumeDialog(completedCount);
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

  /// Show resume dialog
  void _showResumeDialog(int completedCount) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Get.theme.primaryColor),
            SizedBox(width: 12),
            Text('Continue Assessment?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have completed $completedCount out of 8 steps.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'Would you like to continue where you left off or start from the beginning?',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _startFromBeginning();
            },
            child: Text('Start Over'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _continueFromLastStep(completedCount);
            },
            child: Text('Continue'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Continue from last completed step
  Future<void> _continueFromLastStep(int completedCount) async {
    if (completedCount > 0) {
      // Go to overview to see progress and choose where to continue
      Get.to(
            () => DiabetesPredictionOverviewScreen(),
        transition: Transition.downToUp,
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // Start from step 1
      Get.to(() => HeightWeightInputScreen());
    }
  }

  /// Start from beginning (clear cache)
  Future<void> _startFromBeginning() async {
    await _storageManager.clearCache();
    await _prefillFromProfile(); // Re-prefill after clearing
    Get.to(() => HeightWeightInputScreen());
  }

  /// Navigate to specific step by number
  void navigateToStep(int stepNumber) {
    switch (stepNumber) {
      case 1:
        Get.to(() => HeightWeightInputScreen());
        break;
    // Add other steps as you implement them
      default:
        Get.snackbar(
          'Coming Soon',
          'This step is not yet available',
          snackPosition: SnackPosition.BOTTOM,
        );
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