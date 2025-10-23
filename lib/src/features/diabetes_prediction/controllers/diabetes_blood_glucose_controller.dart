import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../views/diabetes_input/physical_activity_input_screen.dart';

class DiabetesBloodGlucoseController extends GetxController {
  static DiabetesBloodGlucoseController get instance => Get.find();

  // Observable variables
  final Rx<double> currentValue = 100.0.obs;
  final RxString measurementType = 'mg/dL'.obs;
  final RxBool isLoading = false.obs;

  // User repository for data operations
  final UserRepository _userRepository = Get.put(UserRepository());

  @override
  void onInit() {
    super.onInit();
    _loadExistingData();
  }

  /// Check if user can proceed
  RxBool get canProceed => (currentValue.value > 0).obs;

  /// Load existing user data if available
  void _loadExistingData() async {
    try {
      isLoading.value = true;

      // Get current user data - you might need to extend UserProfileModel
      // to include blood glucose data, or create a separate model
      final userData = await _userRepository.fetchUserDetails();

      // If you have blood glucose data stored somewhere, load it here
      // currentValue.value = userData.profile.bloodGlucose ?? 100.0;

    } catch (e) {
      print('Error loading existing data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Set measurement type (mg/dL or mmol/L)
  void setMeasurementType(String type) {
    if (measurementType.value == type) return;

    // Convert current value to new unit
    if (type == 'mmol/L' && measurementType.value == 'mg/dL') {
      currentValue.value = mgdlToMmol(currentValue.value);
    } else if (type == 'mg/dL' && measurementType.value == 'mmol/L') {
      currentValue.value = mmolToMgdl(currentValue.value);
    }

    measurementType.value = type;
    update();
  }

  /// Update glucose value
  void updateGlucoseValue(double value) {
    currentValue.value = value;
    update();
  }

  /// Convert mg/dL to mmol/L
  double mgdlToMmol(double mgdl) {
    return double.parse((mgdl / 18.0).toStringAsFixed(1));
  }

  /// Convert mmol/L to mg/dL
  double mmolToMgdl(double mmol) {
    return double.parse((mmol * 18.0).toStringAsFixed(0));
  }

  /// Get glucose color based on level
  Color getGlucoseColor() {
    if (measurementType.value == 'mg/dL') {
      if (currentValue.value < 70) return Colors.blue;
      if (currentValue.value <= 99) return Colors.green;
      if (currentValue.value <= 125) return Colors.orange;
      if (currentValue.value <= 199) return Colors.deepOrange;
      return Colors.red;
    } else {
      // mmol/L ranges
      if (currentValue.value < 3.9) return Colors.blue;
      if (currentValue.value <= 5.5) return Colors.green;
      if (currentValue.value <= 6.9) return Colors.orange;
      if (currentValue.value <= 11.0) return Colors.deepOrange;
      return Colors.red;
    }
  }

  /// Get glucose status text
  String getGlucoseStatus() {
    if (measurementType.value == 'mg/dL') {
      if (currentValue.value < 70) return 'Low';
      if (currentValue.value <= 99) return 'Normal';
      if (currentValue.value <= 125) return 'Elevated';
      if (currentValue.value <= 199) return 'High';
      return 'Very High';
    } else {
      // mmol/L ranges
      if (currentValue.value < 3.9) return 'Low';
      if (currentValue.value <= 5.5) return 'Normal';
      if (currentValue.value <= 6.9) return 'Elevated';
      if (currentValue.value <= 11.0) return 'High';
      return 'Very High';
    }
  }

  /// Get needle angle for gauge display
  double getNeedleAngle() {
    double percentage;

    if (measurementType.value == 'mg/dL') {
      // Map 50-400 to 0-270 degrees
      percentage = (currentValue.value - 50) / (400 - 50);
    } else {
      // Map 3.0-22.0 to 0-270 degrees
      percentage = (currentValue.value - 3.0) / (22.0 - 3.0);
    }

    percentage = percentage.clamp(0.0, 1.0);
    return (percentage * 270 - 135) * math.pi / 180; // -135 to 135 degrees
  }

  /// Get detailed glucose analysis
  // Map<String, dynamic> getGlucoseAnalysis() {
  //   final status = getGlucoseStatus();
  //   final color = getGlucoseColor();
  //
  //   String recommendation = '';
  //   String riskLevel = '';
  //
  //   if (measurementType.value == 'mg/dL') {
  //     if (currentValue.value < 70) {
  //       recommendation = 'Consider eating something sweet immediately';
  //       riskLevel = 'Low Blood Sugar';
  //     } else if (currentValue.value <= 99) {
  //       recommendation = 'Maintain current lifestyle habits';
  //       riskLevel = 'Healthy Range';
  //     } else if (currentValue.value <= 125) {
  //       recommendation = 'Monitor diet and exercise regularly';
  //       riskLevel = 'Pre-diabetic Range';
  //     } else {
  //       recommendation = 'Consult healthcare provider';
  //       riskLevel = 'Diabetic Range';
  //     }
  //   } else {
  //     if (currentValue.value < 3.9) {
  //       recommendation = 'Consider eating something sweet immediately';
  //       riskLevel = 'Low Blood Sugar';
  //     } else if (currentValue.value <= 5.5) {
  //       recommendation = 'Maintain current lifestyle habits';
  //       riskLevel = 'Healthy Range';
  //     } else if (currentValue.value <= 6.9) {
  //       recommendation = 'Monitor diet and exercise regularly';
  //       riskLevel = 'Pre-diabetic Range';
  //     } else {
  //       recommendation = 'Consult healthcare provider';
  //       riskLevel = 'Diabetic Range';
  //     }
  //   }
  //
  //   return {
  //     'status': status,
  //     'color': color,
  //     'recommendation': recommendation,
  //     'riskLevel': riskLevel,
  //   };
  // }

  /// Save data and continue to next screen
  void saveAndContinue() async {
    if (!canProceed.value) return;

    try {
      isLoading.value = true;

      // Convert to mg/dL for consistent storage
      final glucoseInMgDl = measurementType.value == 'mmol/L'
          ? mmolToMgdl(currentValue.value)
          : currentValue.value;

      // You'll need to extend your UserProfileModel or create a separate model
      // to store blood glucose data. For now, I'll show how it could work:

      /*
      // Get current user data
      final currentUser = await _userRepository.fetchUserDetails();

      // Update the profile with blood glucose data
      // You might need to add bloodGlucose field to UserProfileModel
      final updatedProfile = UserProfileModel(
        // ... existing fields
        bloodGlucose: glucoseInMgDl,
        updatedAt: DateTime.now(),
      );

      // Save to repository
      await _userRepository.updateUserProfile(updatedProfile);
      */

      // For now, just save locally or to a separate collection
      // await _userRepository.saveBloodGlucoseReading({
      //   'value': glucoseInMgDl,
      //   'unit': 'mg/dL',
      //   'originalUnit': measurementType.value,
      //   'originalValue': currentValue.value,
      //   'timestamp': DateTime.now(),
      //   'status': getGlucoseStatus(),
      // });

      // Show success message
      // TLoaders.successSnackBar(title: 'Success', message: 'Blood glucose level saved successfully!');

      // Navigate to next screen
      Get.to(() => PhysicalActivityInputScreen());

    } catch (e) {
      // Handle error
      TLoaders.errorSnackBar(title: 'Error', message: 'Failed to save data. Please try again.');
      print('Error saving blood glucose: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Show detailed analysis
  // void showAnalysis() {
  //   final analysis = getGlucoseAnalysis();
  //
  //   Get.dialog(
  //     AlertDialog(
  //       backgroundColor: Get.theme.scaffoldBackgroundColor,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(16),
  //       ),
  //       title: Text(
  //         'Glucose Analysis',
  //         style: TextStyle(
  //           fontWeight: FontWeight.bold,
  //           color: analysis['color'],
  //         ),
  //       ),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text('Status: ${analysis['status']}'),
  //           const SizedBox(height: 8),
  //           Text('Risk Level: ${analysis['riskLevel']}'),
  //           const SizedBox(height: 8),
  //           Text('Recommendation: ${analysis['recommendation']}'),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Get.back(),
  //           child: Text('OK'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  /// Reset values to default
  void reset() {
    currentValue.value = measurementType.value == 'mg/dL' ? 100.0 : 5.5;
    update();
  }

  /// Validate input ranges
  bool validateInputs() {
    if (measurementType.value == 'mg/dL') {
      if (currentValue.value < 50 || currentValue.value > 400) {
        Get.snackbar(
          'Invalid Reading',
          'Blood glucose must be between 50-400 mg/dL',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } else {
      if (currentValue.value < 3.0 || currentValue.value > 22.0) {
        Get.snackbar(
          'Invalid Reading',
          'Blood glucose must be between 3.0-22.0 mmol/L',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    }
    return true;
  }

  @override
  void onClose() {
    super.onClose();
  }
}