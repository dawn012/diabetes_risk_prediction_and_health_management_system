import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../views/diabetes_input/water_intake_input_screen.dart';

/// Controller for managing sleep duration input
class SleepDurationController extends GetxController {
  static SleepDurationController get instance => Get.find();

  // Sleep duration in hours (3.0 to 12.0)
  final sleepDuration = 7.5.obs;

  // // Sleep factors that affect sleep quality
  // final sleepFactors = <String>[].obs;

  // Loading state
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Set default to recommended sleep duration
    sleepDuration.value = 7.5;
  }

  /// Set sleep duration
  void setSleepDuration(double duration) {
    sleepDuration.value = duration;
  }

  /// Check if can proceed (always true since sleep duration is always valid)
  bool get canProceed => true;

  /// Get formatted duration string
  String getFormattedDuration() {
    final hours = sleepDuration.value.floor();
    final minutes = ((sleepDuration.value - hours) * 60).round();

    if (minutes == 0) {
      return '${hours}h';
    } else {
      return '${hours}h ${minutes}m';
    }
  }

  /// Get sleep quality color based on duration
  Color getSleepQualityColor() {
    final duration = sleepDuration.value;

    if (duration >= 7.0 && duration <= 9.0) {
      return Colors.green; // Optimal sleep
    } else if ((duration >= 6.0 && duration < 7.0) || (duration > 9.0 && duration <= 10.0)) {
      return Colors.orange; // Suboptimal but acceptable
    } else {
      return Colors.red; // Poor sleep duration
    }
  }

  /// Get sleep icon based on duration
  IconData getSleepIcon() {
    final duration = sleepDuration.value;

    if (duration >= 7.0 && duration <= 9.0) {
      return Icons.bedtime; // Good sleep
    } else if (duration < 6.0) {
      return Icons.alarm; // Too little sleep
    } else {
      return Icons.snooze; // Too much sleep
    }
  }

  /// Get sleep quality description
  String getSleepQualityDescription() {
    final duration = sleepDuration.value;

    if (duration < 5.0) {
      return 'Severely Insufficient Sleep';
    } else if (duration < 6.0) {
      return 'Insufficient Sleep';
    } else if (duration < 7.0) {
      return 'Below Recommended';
    } else if (duration <= 9.0) {
      return 'Optimal Sleep Duration';
    } else if (duration <= 10.0) {
      return 'Above Recommended';
    } else {
      return 'Excessive Sleep Duration';
    }
  }

  /// Get sleep quality category for data analysis
  String getSleepQualityCategory() {
    final duration = sleepDuration.value;

    if (duration < 6.0) {
      return 'Insufficient';
    } else if (duration <= 9.0) {
      return 'Optimal';
    } else {
      return 'Excessive';
    }
  }

  // /// Get health recommendations based on sleep duration
  // List<String> getHealthRecommendations() {
  //   final duration = sleepDuration.value;
  //   final recommendations = <String>[];
  //
  //   if (duration < 6.0) {
  //     recommendations.addAll([
  //       'Try to increase sleep duration to 7-9 hours',
  //       'Maintain consistent bedtime and wake-up times',
  //       'Create a relaxing bedtime routine',
  //       'Limit caffeine and screen time before bed',
  //     ]);
  //   } else if (duration > 9.5) {
  //     recommendations.addAll([
  //       'Consider if you might be oversleeping',
  //       'Evaluate sleep quality rather than just quantity',
  //       'Check for underlying sleep disorders',
  //       'Maintain regular sleep schedule',
  //     ]);
  //   } else {
  //     recommendations.addAll([
  //       'Great job maintaining healthy sleep duration!',
  //       'Continue your current sleep routine',
  //       'Focus on sleep quality and consistency',
  //     ]);
  //   }
  //
  //   // Add factor-specific recommendations
  //   if (sleepFactors.contains('Stress')) {
  //     recommendations.add('Practice relaxation techniques before bed');
  //   }
  //   if (sleepFactors.contains('Screen Time')) {
  //     recommendations.add('Avoid screens 1 hour before bedtime');
  //   }
  //   if (sleepFactors.contains('Caffeine')) {
  //     recommendations.add('Limit caffeine intake after 2 PM');
  //   }
  //   if (sleepFactors.contains('Noise')) {
  //     recommendations.add('Consider using earplugs or white noise machine');
  //   }
  //   if (sleepFactors.contains('Temperature')) {
  //     recommendations.add('Keep bedroom cool (65-68°F/18-20°C)');
  //   }
  //   if (sleepFactors.contains('Work Schedule')) {
  //     recommendations.add('Try to maintain consistent sleep schedule even with irregular work hours');
  //   }
  //
  //   return recommendations;
  // }

  /// Calculate sleep score (0-100)
  int getSleepScore() {
    final duration = sleepDuration.value;
    int score = 0;

    // Base score from duration
    if (duration >= 7.0 && duration <= 9.0) {
      score = 100;
    } else if ((duration >= 6.5 && duration < 7.0) || (duration > 9.0 && duration <= 9.5)) {
      score = 85;
    } else if ((duration >= 6.0 && duration < 6.5) || (duration > 9.5 && duration <= 10.0)) {
      score = 70;
    } else if ((duration >= 5.5 && duration < 6.0) || (duration > 10.0 && duration <= 10.5)) {
      score = 55;
    } else {
      score = 40;
    }

    return score;
  }

  /// Save data and continue to next step
  Future<void> saveAndContinue() async {
    try {
      isLoading.value = true;

      // Simulate API call or data processing
      await Future.delayed(const Duration(milliseconds: 800));

      // Here you would typically:
      // 1. Validate the data
      // 2. Save to local storage or send to API
      // 3. Navigate to next screen

      final sleepData = {
        'duration': sleepDuration.value,
        'formattedDuration': getFormattedDuration(),
        'qualityCategory': getSleepQualityCategory(),
        'qualityScore': getSleepScore(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('Sleep Duration Data: $sleepData'); // For debugging

      // Navigate to next screen
      Get.to(() => WaterIntakeInputScreen());

      // Get.snackbar(
      //   'Success',
      //   'Sleep duration data saved successfully!',
      //   snackPosition: SnackPosition.TOP,
      //   backgroundColor: Colors.green,
      //   colorText: Colors.white,
      //   duration: const Duration(seconds: 2),
      // );

    } catch (e) {
      TLoaders.errorSnackBar(title: 'Error', message: 'Failed to save data. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset all values to default
  void reset() {
    sleepDuration.value = 7.5;
    isLoading.value = false;
  }

  /// Get data for API submission
  Map<String, dynamic> toJson() {
    return {
      'sleepDuration': sleepDuration.value,
      'sleepScore': getSleepScore(),
      'sleepQuality': getSleepQualityCategory(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}