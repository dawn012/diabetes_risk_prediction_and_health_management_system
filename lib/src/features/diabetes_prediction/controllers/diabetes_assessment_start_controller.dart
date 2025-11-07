
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/widgets/dialogs/dialog.dart';
import '../../../services/diabetes_hive_storage_manager.dart';
import '../views/diabetes_input/height_weight_input_screen.dart';
import '../views/diabetes_input/diabetes_prediction_overview_screen.dart';

class DiabetesAssessmentStartController extends GetxController {
  static DiabetesAssessmentStartController get instance => Get.find();

  final DiabetesHiveStorageManager _storageManager = DiabetesHiveStorageManager.instance;

  final RxBool isLoading = false.obs;
  final RxBool hasIncomplete = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkIncomplete();
  }

  /// Check if there's incomplete assessment
  Future<void> _checkIncomplete() async {
    try {
      isLoading.value = true;

      final incomplete = await _storageManager.hasIncompletePrediction();
      final completedCount = await _storageManager.getCompletedStepsCount();

      // Has incomplete if marked incomplete and has some progress
      hasIncomplete.value = incomplete && completedCount > 0;
    } catch (e) {
      print('Error checking incomplete: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Start new assessment from beginning
  Future<void> startAssessment() async {
    try {
      isLoading.value = true;

      // Mark as in progress
      await _storageManager.markIncomplete(true);

      // Navigate to first step
      Get.to(() => HeightWeightInputScreen());
    } catch (e) {
      print('Error starting assessment: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Continue incomplete assessment
  Future<void> continueAssessment() async {
    try {
      isLoading.value = true;

      final lastStep = await _storageManager.getLastCompletedStep();
      final completedCount = await _storageManager.getCompletedStepsCount();

      if (completedCount > 0) {
        // Go to overview to see progress
        Get.off(() => DiabetesPredictionOverviewScreen(),
          transition: Transition.downToUp,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,);
      } else {
        // Start from beginning
        Get.off(() => HeightWeightInputScreen());
      }
    } catch (e) {
      print('Error continuing assessment: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Start completely new assessment (clear old data)
  Future<void> startNewAssessment() async {
    try {
      isLoading.value = true;

      TDialog.deleteDialog(
        title: 'Start New Assessment?',
        message: 'This will clear your current progress. Are you sure?',
        buttonTitle: 'Start New',
        onConfirm: () async {
          // Clear all progress
          await _storageManager.clearPredictionProgress();
          await _storageManager.markIncomplete(true);

          // Navigate to first step
          Get.off(() => HeightWeightInputScreen());
        },
      );
    } catch (e) {
      print('Error starting new assessment: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset and go back
  void goBack() {
    Get.back();
  }
}