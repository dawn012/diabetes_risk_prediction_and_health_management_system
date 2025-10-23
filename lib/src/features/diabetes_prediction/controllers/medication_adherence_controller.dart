import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../views/diabetes_input/meal_photos_upload_screen.dart';

/// Controller for managing medication adherence input
class MedicationAdherenceController extends GetxController {
  static MedicationAdherenceController get instance => Get.find();

  // Whether user takes diabetes medication
  final takesMedication = Rxn<bool>();

  // Types of medication taken
  final medicationTypes = <String>[].obs;

  // Adherence percentage (0-100)
  final adherencePercentage = 90.obs;

  // Reasons for missing medication
  final missedReasons = <String>[].obs;

  // Loading state
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Set default adherence to 90%
    adherencePercentage.value = 90;
  }

  /// Set whether user takes medication
  void setTakesMedication(bool takes) {
    takesMedication.value = takes;

    // Clear medication-related data if user doesn't take medication
    if (!takes) {
      medicationTypes.clear();
      missedReasons.clear();
      adherencePercentage.value = 0; // Set to 0 if no medication
    } else {
      adherencePercentage.value = 90; // Reset to default if taking medication
    }
  }

  /// Toggle medication type
  void toggleMedicationType(String type) {
    if (medicationTypes.contains(type)) {
      medicationTypes.remove(type);
    } else {
      medicationTypes.add(type);
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

  /// Calculate medication adherence score (0-100)
  int getMedicationAdherenceScore() {
    if (takesMedication.value != true) {
      return 100; // Perfect score if no medication needed
    }

    int score = adherencePercentage.value;

    // Deduct points for common problematic reasons
    final problematicReasons = ['Forgetfulness', 'Side effects', 'Cost concerns'];
    final problematicCount = missedReasons.where((reason) => problematicReasons.contains(reason)).length;
    score = (score - (problematicCount * 5)).clamp(0, 100);

    return score;
  }

  /// Get risk assessment based on adherence
  String getRiskAssessment() {
    if (takesMedication.value != true) {
      return 'Low Risk'; // No medication means no adherence issues
    }

    final percentage = adherencePercentage.value;

    if (percentage >= 80) {
      return 'Low Risk';
    } else if (percentage >= 50) {
      return 'Moderate Risk';
    } else {
      return 'High Risk';
    }
  }

  /// Get primary medication type (for analysis)
  String getPrimaryMedicationType() {
    if (medicationTypes.isEmpty) {
      return 'None';
    }

    // Priority order for diabetes medications
    final priorityOrder = [
      'Insulin',
      'Metformin',
      'Sulfonylureas',
      'GLP-1 agonists',
      'DPP-4 inhibitors',
      'Other'
    ];

    for (String type in priorityOrder) {
      if (medicationTypes.contains(type)) {
        return type;
      }
    }

    return medicationTypes.first;
  }

  /// Save data and continue to next step
  Future<void> saveAndContinue() async {
    try {
      isLoading.value = true;

      // Simulate API call or data processing
      await Future.delayed(const Duration(milliseconds: 800));

      final medicationAdherenceData = {
        'takesMedication': takesMedication.value,
        'medicationTypes': medicationTypes.toList(),
        'primaryMedicationType': getPrimaryMedicationType(),
        'adherencePercentage': adherencePercentage.value,
        'adherenceCategory': getMedicationAdherenceCategory(),
        'adherenceScore': getMedicationAdherenceScore(),
        'riskAssessment': getRiskAssessment(),
        'missedReasons': missedReasons.toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('Medication Adherence Data: $medicationAdherenceData'); // For debugging

      // Navigate to next screen
      // Get.snackbar(
      //   'Success',
      //   'Medication adherence data saved successfully!',
      //   snackPosition: SnackPosition.TOP,
      //   backgroundColor: Colors.green,
      //   colorText: Colors.white,
      //   duration: const Duration(seconds: 2),
      // );
      Get.to(() => MealPhotosUploadScreen());

    } catch (e) {
      TLoaders.errorSnackBar(title: 'Error', message: 'Failed to save data. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset all values to default
  void reset() {
    takesMedication.value = null;
    medicationTypes.clear();
    adherencePercentage.value = 90;
    missedReasons.clear();
    isLoading.value = false;
  }

  /// Get data for API submission
  Map<String, dynamic> toJson() {
    return {
      'takesMedication': takesMedication.value,
      'medicationTypes': medicationTypes.toList(),
      'adherencePercentage': takesMedication.value == true ? adherencePercentage.value : 0,
      'adherenceCategory': getMedicationAdherenceCategory(),
      'riskAssessment': getRiskAssessment(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}