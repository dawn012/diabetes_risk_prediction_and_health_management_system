import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../views/diabetes_input/blood_glucose_input_screen.dart';
import '../views/diabetes_input/height_weight_input_screen.dart';
import '../views/diabetes_input/physical_activity_input_screen.dart';
import '../views/diabetes_input/stress_level_input_screen.dart';
import 'diabetes_blood_glucose_controller.dart';
import 'height_weight_controller.dart';
import 'physical_activity_controller.dart';
import 'sleep_duration_controller.dart';
import 'stress_level_controller.dart';

/// Main controller for managing the diabetes prediction input flow
class DiabetesPredictionController extends GetxController {
  static DiabetesPredictionController get instance => Get.find();

  // Current step tracking
  final currentStep = 0.obs;
  final totalSteps = 4;

  // Controllers for each step
  late final heightWeightController = Get.put(HeightWeightController());
  late final bloodGlucoseController = Get.put(DiabetesBloodGlucoseController());
  late final physicalActivityController = Get.put(PhysicalActivityController());
  late final stressLevelController = Get.put(StressLevelController());
  late final sleepDurationController = Get.put(SleepDurationController());

  // Overall loading state
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize the flow
    currentStep.value = 0;
  }

  /// Navigate to the next step in the flow
  void nextStep() {
    if (currentStep.value < totalSteps - 1) {
      currentStep.value++;
      _navigateToCurrentStep();
    } else {
      // Complete the assessment
      completeAssessment();
    }
  }

  /// Navigate to the previous step in the flow
  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
      _navigateToCurrentStep();
    }
  }

  /// Navigate to specific step
  void goToStep(int step) {
    if (step >= 0 && step < totalSteps) {
      currentStep.value = step;
      _navigateToCurrentStep();
    }
  }

  /// Get current progress value (0.0 to 1.0)
  double get currentProgress => (currentStep.value + 1) / totalSteps;

  /// Check if current step can proceed
  bool get canProceed {
    switch (currentStep.value) {
      case 0:
        return heightWeightController.canProceed.value;
      case 1:
        return bloodGlucoseController.canProceed.value;
      case 2:
        return physicalActivityController.canProceed.value;
      case 3:
        return stressLevelController.canProceed.value;
      default:
        return false;
    }
  }

  /// Navigate to the screen for current step
  void _navigateToCurrentStep() {
    switch (currentStep.value) {
      case 0:
        Get.to(() => HeightWeightInputScreen());
        break;
      case 1:
        Get.to(() => BloodGlucoseInputScreen());
        break;
      case 2:
        Get.to(() => PhysicalActivityInputScreen());
        break;
      case 3:
        Get.to(() => StressLevelInputScreen());
        break;
    }
  }

  /// Complete the entire assessment
  Future<void> completeAssessment() async {
    try {
      isLoading.value = true;

      // Collect all data
      final assessmentData = {
        'height': heightWeightController.height.value,
        'weight': heightWeightController.weight.value,
        'bloodGlucose': {
          'value': bloodGlucoseController.currentValue.value,
          'unit': bloodGlucoseController.measurementType.value,
        },
        'physicalActivity': {
          'frequency': physicalActivityController.frequency.value,
          'duration': physicalActivityController.duration.value,
          'intensity': physicalActivityController.intensity.value,
        },
        'stress': {
          'level': stressLevelController.stressLevel.value,
          'sources': stressLevelController.stressSources.toList(),
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Send data to API or process locally
      await _processAssessmentData(assessmentData);

      // Navigate to results screen
      Get.toNamed('/prediction-results', arguments: assessmentData);

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to process assessment. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Process the assessment data (API call or local processing)
  Future<void> _processAssessmentData(Map<String, dynamic> data) async {
    // Simulate API processing
    await Future.delayed(const Duration(seconds: 2));

    // Here you would:
    // 1. Send data to your diabetes prediction API
    // 2. Calculate BMI and other derived metrics
    // 3. Apply machine learning model for prediction
    // 4. Generate personalized recommendations

    // Example local calculations:
    final height = data['height'] as double;
    final weight = data['weight'] as double;
    final bmi = weight / ((height / 100) * (height / 100));

    // Add calculated values back to data
    data['calculatedValues'] = {
      'bmi': bmi,
      'bmiCategory': _getBMICategory(bmi),
      'riskScore': _calculateRiskScore(data),
    };
  }

  /// Get BMI category
  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal weight';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  /// Calculate basic risk score (simplified example)
  double _calculateRiskScore(Map<String, dynamic> data) {
    double score = 0.0;

    // BMI factor
    final bmi = data['calculatedValues']['bmi'] as double;
    if (bmi >= 30) score += 0.3;
    else if (bmi >= 25) score += 0.2;

    // Blood glucose factor
    final glucose = data['bloodGlucose'];
    if (glucose['unit'] == 'mg/dL') {
      if (glucose['value'] >= 126) score += 0.4;
      else if (glucose['value'] >= 100) score += 0.2;
    } else {
      if (glucose['value'] >= 7.0) score += 0.4;
      else if (glucose['value'] >= 5.6) score += 0.2;
    }

    // Physical activity factor
    final activity = data['physicalActivity'];
    if (activity['frequency'] == 0) score += 0.2;
    else if (activity['frequency'] < 3) score += 0.1;

    // Stress factor
    final stressLevel = data['stress']['level'] as int;
    if (stressLevel >= 8) score += 0.1;
    else if (stressLevel >= 6) score += 0.05;

    return score.clamp(0.0, 1.0);
  }

  /// Reset the entire flow
  void resetFlow() {
    currentStep.value = 0;
    heightWeightController.reset();
    bloodGlucoseController.reset();
    physicalActivityController.reset();
    stressLevelController.reset();
    sleepDurationController.reset();
  }

  /// Get step title
  String getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Health Metrics';
      case 1:
        return 'Blood Glucose';
      case 2:
        return 'Physical Activity';
      case 3:
        return 'Stress Level';
      case 4:
        return 'Sleep Duration';
      default:
        return 'Assessment';
    }
  }

  /// Get step description
  String getStepDescription(int step) {
    switch (step) {
      case 0:
        return 'Height and weight measurements';
      case 1:
        return 'Blood glucose level input';
      case 2:
        return 'Exercise and activity habits';
      case 3:
        return 'Stress assessment';
      default:
        return '';
    }
  }
}