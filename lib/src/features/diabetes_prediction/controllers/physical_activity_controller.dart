import 'package:diabetes_risk_prediction_and_health_management_system/src/common/loaders/loaders.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/repositories/user/user_repository.dart';
import '../../../utils/constants/colors.dart';
import '../views/diabetes_input/stress_level_input_screen.dart';

class PhysicalActivityController extends GetxController {
  static PhysicalActivityController get instance => Get.find();

  // Page Controller for navigation
  final PageController pageController = PageController();

  // Observable variables
  final RxInt currentStep = 0.obs;
  final RxInt frequency = 0.obs; // Days per week (0-7)
  final RxInt duration = 0.obs; // Minutes per session
  final RxString intensity = ''.obs; // light, moderate, high
  final RxBool isLoading = false.obs;

  // User repository for data operations
  final UserRepository _userRepository = Get.put(UserRepository());

  @override
  void onInit() {
    super.onInit();
    _loadExistingData();
  }

  /// Check if user can proceed to next step
  RxBool get canProceed {
    switch (currentStep.value) {
      case 0: // Frequency step
        return (frequency.value >= 0).obs;
      case 1: // Duration step
        return (duration.value >= 0).obs;
      case 2: // Intensity step
        return intensity.value.isNotEmpty.obs;
      // case 3: // Summary step
      //   return (frequency.value >= 0 &&
      //       duration.value >= 0 &&
      //       intensity.value.isNotEmpty).obs;
      default:
        return false.obs;
    }
  }

  /// Load existing user data if available
  void _loadExistingData() async {
    try {
      isLoading.value = true;

      // Get current user data
      // You might need to extend UserProfileModel to include physical activity data
      final userData = await _userRepository.fetchUserDetails();

      // Load existing data if available
      // frequency.value = userData.profile.exerciseFrequency ?? 0;
      // duration.value = userData.profile.exerciseDuration ?? 0;
      // intensity.value = userData.profile.exerciseIntensity ?? '';

    } catch (e) {
      print('Error loading existing data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Set exercise frequency (days per week)
  void setFrequency(int days) {
    frequency.value = days;
    update();
  }

  /// Set exercise duration (minutes per session)
  void setDuration(int minutes) {
    duration.value = minutes;
    update();
  }

  /// Set exercise intensity
  void setIntensity(String level) {
    intensity.value = level;
    update();
  }

  /// Navigate to next step
  void nextStep() {
    if (!canProceed.value) return;

    // if (currentStep.value < 2) {
    //   currentStep.value++;
    //   pageController.nextPage(
    //     duration: const Duration(milliseconds: 300),
    //     curve: Curves.easeInOut,
    //   );
    // } else {
      // Complete and save
      saveAndContinue();
    // }
  }

  /// Navigate to previous step
  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Calculate total weekly minutes
  int get weeklyMinutes => frequency.value * duration.value;

  /// Calculate activity level based on WHO recommendations
  String getActivityLevel() {
    final totalMinutes = weeklyMinutes;

    if (totalMinutes == 0) return 'Sedentary';

    // WHO recommends at least 150 minutes of moderate-intensity
    // or 75 minutes of vigorous-intensity physical activity per week
    if (intensity.value == 'high') {
      if (totalMinutes >= 75) return 'Very Active';
      if (totalMinutes >= 37) return 'Active';
      return 'Lightly Active';
    } else if (intensity.value == 'moderate') {
      if (totalMinutes >= 150) return 'Very Active';
      if (totalMinutes >= 75) return 'Active';
      return 'Lightly Active';
    } else { // light intensity
      if (totalMinutes >= 300) return 'Active';
      if (totalMinutes >= 150) return 'Lightly Active';
      return 'Minimally Active';
    }
  }

  /// Get activity level color
  Color getActivityLevelColor() {
    switch (getActivityLevel()) {
      case 'Sedentary':
        return Colors.red;
      case 'Minimally Active':
        return Colors.deepOrange;
      case 'Lightly Active':
        return Colors.orange;
      case 'Active':
        return Colors.green;
      case 'Very Active':
        return TColors.primary;
      default:
        return TColors.darkGrey;
    }
  }

  /// Get activity level icon
  IconData getActivityLevelIcon() {
    switch (getActivityLevel()) {
      case 'Sedentary':
        return Icons.event_seat;
      case 'Minimally Active':
        return Icons.directions_walk;
      case 'Lightly Active':
        return Icons.directions_bike;
      case 'Active':
        return Icons.directions_run;
      case 'Very Active':
        return Icons.fitness_center;
      default:
        return Icons.help_outline;
    }
  }

  /// Get activity level description
  String getActivityLevelDescription() {
    switch (getActivityLevel()) {
      case 'Sedentary':
        return 'No Regular Physical Activity';
      case 'Minimally Active':
        return 'Some Light Physical Activity';
      case 'Lightly Active':
        return 'Regular Light to Moderate Activity';
      case 'Active':
        return 'Meets Physical Activity Guidelines';
      case 'Very Active':
        return 'Exceeds Physical Activity Guidelines';
      default:
        return 'Activity Level Unknown';
    }
  }

  /// Get activity recommendation
  String getActivityRecommendation() {
    switch (getActivityLevel()) {
      case 'Sedentary':
        return 'Consider starting with light activities like walking 10-15 minutes daily. Gradually increase duration and intensity.';
      case 'Minimally Active':
        return 'Good start! Try to increase your activity to 150 minutes of moderate exercise per week for better health benefits.';
      case 'Lightly Active':
        return 'You\'re on the right track! Consider adding some vigorous activities or increasing duration for optimal health.';
      case 'Active':
        return 'Excellent! You meet the recommended guidelines. Maintain this level and consider strength training 2x per week.';
      case 'Very Active':
        return 'Outstanding! You exceed recommendations. Ensure adequate rest and recovery between intense sessions.';
      default:
        return 'Please complete all questions to get personalized recommendations.';
    }
  }

  /// Calculate MET (Metabolic Equivalent of Task) score
  double calculateMETScore() {
    double intensityMET;

    switch (intensity.value) {
      case 'light':
        intensityMET = 3.0; // Light intensity activities
        break;
      case 'moderate':
        intensityMET = 5.0; // Moderate intensity activities
        break;
      case 'high':
        intensityMET = 8.0; // High intensity activities
        break;
      default:
        intensityMET = 0.0;
    }

    // MET-minutes per week = MET value × minutes per session × sessions per week
    return intensityMET * duration.value * frequency.value;
  }

  /// Get MET category
  String getMETCategory() {
    final metScore = calculateMETScore();

    if (metScore == 0) return 'Inactive';
    if (metScore < 500) return 'Low';
    if (metScore < 1000) return 'Moderate';
    return 'High';
  }

  /// Get diabetes risk assessment based on physical activity
  Map<String, dynamic> getDiabetesRiskAssessment() {
    final activityLevel = getActivityLevel();
    final metScore = calculateMETScore();

    String riskLevel = 'Unknown';
    String riskDescription = '';
    Color riskColor = TColors.darkGrey;

    if (activityLevel == 'Sedentary') {
      riskLevel = 'High Risk';
      riskDescription = 'Sedentary lifestyle significantly increases diabetes risk';
      riskColor = Colors.red;
    } else if (activityLevel == 'Minimally Active') {
      riskLevel = 'Moderate-High Risk';
      riskDescription = 'Some activity helps, but more is needed for optimal protection';
      riskColor = Colors.deepOrange;
    } else if (activityLevel == 'Lightly Active') {
      riskLevel = 'Moderate Risk';
      riskDescription = 'Regular activity provides some protection against diabetes';
      riskColor = Colors.orange;
    } else if (activityLevel == 'Active') {
      riskLevel = 'Low Risk';
      riskDescription = 'Good activity level significantly reduces diabetes risk';
      riskColor = Colors.green;
    } else if (activityLevel == 'Very Active') {
      riskLevel = 'Very Low Risk';
      riskDescription = 'Excellent activity level provides strong protection';
      riskColor = TColors.primary;
    }

    return {
      'riskLevel': riskLevel,
      'riskDescription': riskDescription,
      'riskColor': riskColor,
      'metScore': metScore,
      'weeklyMinutes': weeklyMinutes,
      'activityLevel': activityLevel,
    };
  }

  /// Save data and continue to next screen
  void saveAndContinue() async {
    try {
      isLoading.value = true;

      // Get current user data
      final currentUser = await _userRepository.fetchUserDetails();

      // You'll need to extend UserProfileModel to include physical activity fields
      // or create a separate PhysicalActivityModel
      /*
      final updatedProfile = UserProfileModel(
        // ... existing fields
        exerciseFrequency: frequency.value,
        exerciseDuration: duration.value,
        exerciseIntensity: intensity.value,
        weeklyExerciseMinutes: weeklyMinutes,
        activityLevel: getActivityLevel(),
        metScore: calculateMETScore(),
        updatedAt: DateTime.now(),
      );

      await _userRepository.updateUserProfile(updatedProfile);
      */

      // For now, save as separate data
      final activityData = {
        'frequency': frequency.value,
        'duration': duration.value,
        'intensity': intensity.value,
        'weeklyMinutes': weeklyMinutes,
        'activityLevel': getActivityLevel(),
        'metScore': calculateMETScore(),
        'riskAssessment': getDiabetesRiskAssessment(),
        'timestamp': DateTime.now(),
      };

      // Save to repository (you'll need to implement this method)
      // await _userRepository.savePhysicalActivityData(activityData);

      // Show success message
      // Get.snackbar(
      //   'Success',
      //   'Physical activity data saved successfully!',
      //   snackPosition: SnackPosition.BOTTOM,
      //   backgroundColor: TColors.primary,
      //   colorText: Colors.white,
      // );

      // Navigate to next screen
      Get.to(() => StressLevelInputScreen());

    } catch (e) {
      // Handle error
      TLoaders.errorSnackBar(title: 'Error', message: 'Failed to save data. Please try again.');
      print('Error saving physical activity: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset all values
  void reset() {
    frequency.value = 0;
    duration.value = 0;
    intensity.value = '';
    currentStep.value = 0;
    pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    update();
  }

  /// Validate inputs
  bool validateInputs() {
    if (frequency.value < 0 || frequency.value > 7) {
      Get.snackbar(
        'Invalid Frequency',
        'Exercise frequency must be between 0-7 days per week',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (duration.value < 0 || duration.value > 300) {
      Get.snackbar(
        'Invalid Duration',
        'Exercise duration must be between 0-300 minutes',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (intensity.value.isNotEmpty &&
        !['light', 'moderate', 'high'].contains(intensity.value)) {
      Get.snackbar(
        'Invalid Intensity',
        'Please select a valid exercise intensity',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    return true;
  }

  /// Show detailed analysis dialog
  void showDetailedAnalysis() {
    final assessment = getDiabetesRiskAssessment();

    Get.dialog(
      AlertDialog(
        backgroundColor: Get.theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              getActivityLevelIcon(),
              color: assessment['riskColor'],
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Activity Analysis',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: assessment['riskColor'],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAnalysisItem('Activity Level', assessment['activityLevel']),
              _buildAnalysisItem('Weekly Minutes', '${assessment['weeklyMinutes']} min'),
              _buildAnalysisItem('MET Score', '${assessment['metScore'].toStringAsFixed(1)}'),
              _buildAnalysisItem('Diabetes Risk', assessment['riskLevel']),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: assessment['riskColor'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  assessment['riskDescription'],
                  style: TextStyle(
                    fontSize: 14,
                    color: assessment['riskColor'],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}