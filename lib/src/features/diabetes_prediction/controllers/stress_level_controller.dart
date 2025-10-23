import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../../../utils/constants/colors.dart';
import '../views/diabetes_input/sleep_duration_input_screen.dart';

class StressLevelController extends GetxController {
  static StressLevelController get instance => Get.find();

  // Observable variables
  final RxInt stressLevel = 5.obs; // Scale 1-10, default to middle
  final RxList<String> stressSources = <String>[].obs; // Selected stress sources
  final RxBool isLoading = false.obs;

  // User repository for data operations
  final UserRepository _userRepository = Get.put(UserRepository());

  @override
  void onInit() {
    super.onInit();
    _loadExistingData();
  }

  /// Check if user can proceed
  RxBool get canProceed {
    // User can proceed as long as they have selected a stress level (1-10)
    // Stress sources are optional
    return (stressLevel.value >= 1 && stressLevel.value <= 10).obs;
  }

  /// Load existing user data if available
  void _loadExistingData() async {
    try {
      isLoading.value = true;

      // Get current user data
      final userData = await _userRepository.fetchUserDetails();

      // Load existing data if available
      // You might need to extend UserProfileModel to include stress data
      // stressLevel.value = userData.profile.stressLevel ?? 5;
      // stressSources.value = userData.profile.stressSources ?? [];

    } catch (e) {
      print('Error loading existing stress data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Set stress level (1-10)
  void setStressLevel(int level) {
    if (level >= 1 && level <= 10) {
      stressLevel.value = level;
      update();
    }
  }

  /// Toggle stress source selection
  void toggleStressSource(String source) {
    if (stressSources.contains(source)) {
      stressSources.remove(source);
    } else {
      stressSources.add(source);
    }
    update();
  }

  /// Get stress level color based on severity
  Color getStressLevelColor() {
    if (stressLevel.value <= 2) {
      return Colors.green; // Low stress
    } else if (stressLevel.value <= 4) {
      return Colors.lightGreen; // Mild stress
    } else if (stressLevel.value <= 6) {
      return Colors.orange; // Moderate stress
    } else if (stressLevel.value <= 8) {
      return Colors.deepOrange; // High stress
    } else {
      return Colors.red; // Very high stress
    }
  }

  /// Get stress level emoji
  String getStressEmoji() {
    if (stressLevel.value <= 2) {
      return '😌'; // Relaxed
    } else if (stressLevel.value <= 4) {
      return '🙂'; // Slightly stressed
    } else if (stressLevel.value <= 6) {
      return '😐'; // Moderately stressed
    } else if (stressLevel.value <= 8) {
      return '😰'; // Stressed
    } else {
      return '😫'; // Very stressed
    }
  }

  /// Get stress level description
  String getStressLevelDescription() {
    if (stressLevel.value <= 2) {
      return 'Very Low Stress - Feeling calm and relaxed';
    } else if (stressLevel.value <= 4) {
      return 'Low Stress - Generally comfortable with minor worries';
    } else if (stressLevel.value <= 6) {
      return 'Moderate Stress - Noticeable stress but manageable';
    } else if (stressLevel.value <= 8) {
      return 'High Stress - Significant stress affecting daily life';
    } else {
      return 'Very High Stress - Overwhelming stress levels';
    }
  }

  /// Get stress category for analysis
  String getStressCategory() {
    if (stressLevel.value <= 3) {
      return 'Low';
    } else if (stressLevel.value <= 6) {
      return 'Moderate';
    } else {
      return 'High';
    }
  }

  /// Calculate stress impact on health
  Map<String, dynamic> getStressHealthImpact() {
    String impactLevel;
    String description;
    Color impactColor;
    List<String> healthRisks = [];

    if (stressLevel.value <= 3) {
      impactLevel = 'Minimal Impact';
      description = 'Low stress levels typically have minimal negative health effects';
      impactColor = Colors.green;
      healthRisks = ['Generally positive for health'];
    } else if (stressLevel.value <= 6) {
      impactLevel = 'Moderate Impact';
      description = 'Moderate stress may affect sleep, mood, and daily functioning';
      impactColor = Colors.orange;
      healthRisks = [
        'May affect sleep quality',
        'Possible mood fluctuations',
        'Reduced immune function',
        'Digestive issues',
      ];
    } else {
      impactLevel = 'High Impact';
      description = 'High stress levels can significantly impact physical and mental health';
      impactColor = Colors.red;
      healthRisks = [
        'Increased diabetes risk',
        'Cardiovascular problems',
        'Compromised immune system',
        'Sleep disorders',
        'Anxiety and depression risk',
        'Digestive problems',
        'Chronic fatigue',
      ];
    }

    return {
      'impactLevel': impactLevel,
      'description': description,
      'impactColor': impactColor,
      'healthRisks': healthRisks,
      'stressLevel': stressLevel.value,
      'stressCategory': getStressCategory(),
    };
  }

  /// Get diabetes risk assessment based on stress level
  Map<String, dynamic> getDiabetesRiskAssessment() {
    String riskLevel;
    String riskDescription;
    Color riskColor;

    if (stressLevel.value <= 3) {
      riskLevel = 'Low Additional Risk';
      riskDescription = 'Low stress levels do not significantly increase diabetes risk';
      riskColor = Colors.green;
    } else if (stressLevel.value <= 6) {
      riskLevel = 'Moderate Additional Risk';
      riskDescription = 'Moderate stress may contribute to insulin resistance and glucose metabolism issues';
      riskColor = Colors.orange;
    } else {
      riskLevel = 'High Additional Risk';
      riskDescription = 'High chronic stress significantly increases diabetes risk through cortisol elevation and lifestyle impacts';
      riskColor = Colors.red;
    }

    return {
      'riskLevel': riskLevel,
      'riskDescription': riskDescription,
      'riskColor': riskColor,
      'stressLevel': stressLevel.value,
      'stressSources': stressSources.toList(),
    };
  }

  /// Get stress management recommendations
  List<String> getStressManagementRecommendations() {
    List<String> recommendations = [];

    if (stressLevel.value <= 3) {
      recommendations = [
        'Continue current stress management practices',
        'Maintain regular exercise and healthy lifestyle',
        'Practice mindfulness or meditation',
        'Ensure adequate sleep (7-9 hours)',
      ];
    } else if (stressLevel.value <= 6) {
      recommendations = [
        'Practice deep breathing exercises',
        'Regular physical activity (30 minutes daily)',
        'Consider meditation or yoga',
        'Maintain social connections',
        'Prioritize sleep hygiene',
        'Limit caffeine and alcohol',
        'Time management techniques',
      ];
    } else {
      recommendations = [
        'Consider professional counseling or therapy',
        'Practice daily stress-reduction techniques',
        'Regular exercise (proven stress reducer)',
        'Mindfulness meditation (10-20 minutes daily)',
        'Establish boundaries in work/personal life',
        'Seek social support from friends and family',
        'Consider stress management courses',
        'Evaluate and address major stressors',
        'Prioritize self-care activities',
        'Consult healthcare provider if needed',
      ];
    }

    // Add specific recommendations based on stress sources
    if (stressSources.contains('Work/Career')) {
      recommendations.add('Consider workplace stress management programs');
      recommendations.add('Discuss workload with supervisor if appropriate');
    }

    if (stressSources.contains('Finances')) {
      recommendations.add('Consider financial counseling or budgeting assistance');
      recommendations.add('Explore stress-reduction techniques for financial anxiety');
    }

    if (stressSources.contains('Health')) {
      recommendations.add('Discuss health concerns with healthcare provider');
      recommendations.add('Address health anxiety through appropriate channels');
    }

    return recommendations;
  }

  /// Calculate stress score for overall health assessment
  double calculateStressScore() {
    // Normalize stress level to 0-1 scale
    double normalizedStress = (stressLevel.value - 1) / 9.0;

    // Additional weight based on number of stress sources
    double sourceWeight = stressSources.length * 0.05; // Each source adds 5%

    return (normalizedStress + sourceWeight).clamp(0.0, 1.0);
  }

  /// Get overall stress assessment
  Map<String, dynamic> getOverallAssessment() {
    final healthImpact = getStressHealthImpact();
    final diabetesRisk = getDiabetesRiskAssessment();
    final recommendations = getStressManagementRecommendations();
    final stressScore = calculateStressScore();

    return {
      'stressLevel': stressLevel.value,
      'stressCategory': getStressCategory(),
      'stressSources': stressSources.toList(),
      'stressScore': stressScore,
      'healthImpact': healthImpact,
      'diabetesRisk': diabetesRisk,
      'recommendations': recommendations,
      'timestamp': DateTime.now(),
    };
  }

  /// Save data and continue to next screen
  void saveAndContinue() async {
    try {
      isLoading.value = true;

      // Get current user data
      final currentUser = await _userRepository.fetchUserDetails();

      // You'll need to extend UserProfileModel to include stress fields
      // or create a separate StressAssessmentModel
      /*
      final updatedProfile = UserProfileModel(
        // ... existing fields
        stressLevel: stressLevel.value,
        stressSources: stressSources.toList(),
        stressCategory: getStressCategory(),
        stressScore: calculateStressScore(),
        updatedAt: DateTime.now(),
      );

      await _userRepository.updateUserProfile(updatedProfile);
      */

      // For now, save as separate data
      final stressData = getOverallAssessment();

      // Save to repository (you'll need to implement this method)
      // await _userRepository.saveStressLevelData(stressData);

      // Show success message
      // Get.snackbar(
      //   'Success',
      //   'Stress assessment saved successfully!',
      //   snackPosition: SnackPosition.BOTTOM,
      //   backgroundColor: TColors.primary,
      //   colorText: Colors.white,
      // );

      // Navigate to next screen
      Get.to(() => SleepDurationInputScreen());

    } catch (e) {
      // Handle error
      TLoaders.errorSnackBar(title: 'Error', message: 'Failed to save data. Please try again.');
      print('Error saving stress assessment: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset all values
  void reset() {
    stressLevel.value = 5;
    stressSources.clear();
    update();
  }

  /// Validate inputs
  bool validateInputs() {
    if (stressLevel.value < 1 || stressLevel.value > 10) {
      Get.snackbar(
        'Invalid Stress Level',
        'Stress level must be between 1-10',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    return true;
  }

  /// Show detailed stress analysis dialog
  void showDetailedAnalysis() {
    final assessment = getOverallAssessment();

    Get.dialog(
      AlertDialog(
        backgroundColor: Get.theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.psychology,
              color: getStressLevelColor(),
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Stress Analysis',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: getStressLevelColor(),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAnalysisItem('Stress Level', '${assessment['stressLevel']}/10'),
              _buildAnalysisItem('Category', assessment['stressCategory']),
              _buildAnalysisItem('Stress Score', '${(assessment['stressScore'] * 100).toStringAsFixed(1)}%'),
              _buildAnalysisItem('Health Impact', assessment['healthImpact']['impactLevel']),
              _buildAnalysisItem('Diabetes Risk', assessment['diabetesRisk']['riskLevel']),

              if (stressSources.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Stress Sources:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(stressSources.join(', ')),
              ],

              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: getStressLevelColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  assessment['diabetesRisk']['riskDescription'],
                  style: TextStyle(
                    fontSize: 14,
                    color: getStressLevelColor(),
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
          TextButton(
            onPressed: () {
              Get.back();
              _showRecommendations(assessment['recommendations']);
            },
            child: Text('View Recommendations'),
          ),
        ],
      ),
    );
  }

  /// Show stress management recommendations dialog
  void _showRecommendations(List<String> recommendations) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Get.theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Stress Management Tips',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: TColors.primary,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: TColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rec,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )).toList(),
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
    super.onClose();
  }
}