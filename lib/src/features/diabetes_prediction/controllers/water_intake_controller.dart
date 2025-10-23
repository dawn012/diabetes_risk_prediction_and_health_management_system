import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../views/diabetes_input/medication_adherence_input_screen.dart';

/// Controller for managing water intake input
class WaterIntakeController extends GetxController {
  static WaterIntakeController get instance => Get.find();

  // Water intake in liters per day (0.5 to 5.0)
  final waterIntake = 2.0.obs;

  // Preferred unit for display (liters, cups, bottles)
  final preferredUnit = 'liters'.obs;

  // Loading state
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Set default to recommended water intake
    waterIntake.value = 2.0;
  }

  /// Set water intake amount
  void setWaterIntake(double intake) {
    waterIntake.value = intake;
  }

  /// Set preferred unit
  void setPreferredUnit(String unit) {
    preferredUnit.value = unit;
  }

  /// Check if can proceed (always true since water intake is always valid)
  bool get canProceed => true;

  /// Get hydration status based on water intake
  String getHydrationStatus() {
    final intake = waterIntake.value;

    if (intake < 1.5) {
      return 'Dehydrated';
    } else if (intake < 2.0) {
      return 'Mild Dehydration';
    } else if (intake <= 3.5) {
      return 'Well Hydrated';
    } else if (intake <= 4.0) {
      return 'Over Hydrated';
    } else {
      return 'Excessive Intake';
    }
  }

  /// Get hydration status color
  Color getHydrationStatusColor() {
    final intake = waterIntake.value;

    if (intake >= 2.0 && intake <= 3.5) {
      return Colors.green; // Well hydrated
    } else if ((intake >= 1.5 && intake < 2.0) || (intake > 3.5 && intake <= 4.0)) {
      return Colors.orange; // Mild dehydration or over hydration
    } else {
      return Colors.red; // Dehydrated or excessive
    }
  }

  /// Get hydration status description
  String getHydrationStatusDescription() {
    final intake = waterIntake.value;

    if (intake < 1.0) {
      return 'Severely Dehydrated';
    } else if (intake < 1.5) {
      return 'Dehydrated';
    } else if (intake < 2.0) {
      return 'Mild Dehydration';
    } else if (intake <= 3.0) {
      return 'Optimal Hydration';
    } else if (intake <= 3.5) {
      return 'Well Hydrated';
    } else if (intake <= 4.0) {
      return 'Over Hydrated';
    } else {
      return 'Excessive Water Intake';
    }
  }

  /// Convert liters to cups (1 liter ≈ 4.2 cups)
  int getCupsEquivalent() {
    return (waterIntake.value * 4.2).round();
  }

  /// Convert liters to bottles (assuming 500ml bottles)
  int getBottlesEquivalent() {
    return (waterIntake.value * 2).round();
  }

  /// Get hydration status for data analysis (simplified)
  String getHydrationStatusCategory() {
    final intake = waterIntake.value;

    if (intake < 1.5) {
      return 'Poor';
    } else if (intake >= 2.0 && intake <= 3.5) {
      return 'Good';
    } else {
      return 'Excessive';
    }
  }

  /// Calculate hydration score (0-100)
  int getHydrationScore() {
    final intake = waterIntake.value;

    if (intake >= 2.0 && intake <= 3.0) {
      return 100; // Optimal range
    } else if ((intake >= 1.8 && intake < 2.0) || (intake > 3.0 && intake <= 3.5)) {
      return 85; // Good range
    } else if ((intake >= 1.5 && intake < 1.8) || (intake > 3.5 && intake <= 4.0)) {
      return 65; // Acceptable range
    } else if ((intake >= 1.2 && intake < 1.5) || (intake > 4.0 && intake <= 4.5)) {
      return 45; // Poor range
    } else {
      return 25; // Very poor range
    }
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

  /// Save data and continue to next step
  Future<void> saveAndContinue() async {
    try {
      isLoading.value = true;

      // Simulate API call or data processing
      await Future.delayed(const Duration(milliseconds: 800));

      final waterIntakeData = {
        'dailyWaterIntake': waterIntake.value,
        'preferredUnit': preferredUnit.value,
        'hydrationStatus': getHydrationStatus(),
        'hydrationCategory': getHydrationStatusCategory(),
        'hydrationScore': getHydrationScore(),
        'cupsEquivalent': getCupsEquivalent(),
        'bottlesEquivalent': getBottlesEquivalent(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('Water Intake Data: $waterIntakeData'); // For debugging

      // Navigate to next screen
      // Get.snackbar(
      //   'Success',
      //   'Water intake data saved successfully!',
      //   snackPosition: SnackPosition.TOP,
      //   backgroundColor: Colors.green,
      //   colorText: Colors.white,
      //   duration: const Duration(seconds: 2),
      // );
      Get.to(() => MedicationAdherenceInputScreen());

    } catch (e) {
      TLoaders.errorSnackBar(title: 'Error', message: 'Failed to save data. Please try again.');
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
  Map<String, dynamic> toJson() {
    return {
      'waterIntake': waterIntake.value,
      'preferredUnit': preferredUnit.value,
      'hydrationStatus': getHydrationStatusCategory(),
      'hydrationScore': getHydrationScore(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}