import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../health_data_entry/controllers/diabetes_risk_controller.dart';
import '../../models/diabetes_risk_prediction_model.dart';
import '../../models/meal_analysis_result_model.dart';
import '../../models/detected_food_model.dart';

class DiabetesRiskDetailScreen extends StatelessWidget {
  final DiabetesRiskPredictionModel prediction;

  const DiabetesRiskDetailScreen({
    super.key,
    required this.prediction,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);
    final controller = Get.find<DiabetesRiskController>();
    final riskColor = controller.getRiskLevelColor(prediction.riskScore);
    final riskLevel = controller.getRiskLevel(prediction.riskScore);

    return Scaffold(
      backgroundColor: darkMode ? const Color(0xFF0A0A0B) : TColors.light,
      appBar: TAppBar(
        backgroundColor: TColors.primary,
        title: const Text(
          'Risk Assessment Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: TColors.white),
        ),
        showBackArrow: true,
        iconTheme: const IconThemeData(color: TColors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// Header - Risk Score
            _buildRiskScoreHeader(context, darkMode, riskColor, riskLevel),

            const SizedBox(height: TSizes.defaultSpace),

            /// Recommendations
            if (prediction.recommendations.isNotEmpty)
              _buildRecommendations(context, darkMode),

            const SizedBox(height: TSizes.defaultSpace),

            /// Input Data Section
            _buildSectionHeader(context, darkMode, 'Assessment Data'),
            const SizedBox(height: TSizes.md),

            /// Basic Health Data
            _buildBasicHealthData(context, darkMode),

            const SizedBox(height: TSizes.md),

            /// Lifestyle Data
            _buildLifestyleData(context, darkMode),

            const SizedBox(height: TSizes.md),

            /// Medication Data
            if (prediction.inputs.takesMedication == true)
              _buildMedicationData(context, darkMode),

            const SizedBox(height: TSizes.defaultSpace),

            /// Meal Photos Section
            if (prediction.inputs.mealPhotos?.isNotEmpty ?? false) ...[
              _buildSectionHeader(context, darkMode, 'Meal Analysis'),
              const SizedBox(height: TSizes.md),
              _buildMealPhotosGrid(context, darkMode),
            ],

            const SizedBox(height: TSizes.defaultSpace),

            /// Diet Assessment Summary
            if (prediction.inputs.dietAssessment != null) ...[
              _buildSectionHeader(context, darkMode, 'Diet Summary'),
              const SizedBox(height: TSizes.md),
              _buildDietAssessmentSummary(context, darkMode),
            ],

            const SizedBox(height: TSizes.defaultSpace * 2),
          ],
        ),
      ),
    );
  }

  /// Risk Score Header
  Widget _buildRiskScoreHeader(
      BuildContext context, bool darkMode, Color riskColor, String riskLevel) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(TSizes.defaultSpace),
      padding: const EdgeInsets.all(TSizes.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [riskColor, riskColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: riskColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Risk Score',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: TSizes.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                prediction.riskScore.toStringAsFixed(1),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 56,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'pts',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: TSizes.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${riskLevel.toUpperCase()} RISK',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: TSizes.md),
          Text(
            'Assessed on ${DateFormat('MMM dd, yyyy \'at\' hh:mm a').format(prediction.predictionDateTime)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Recommendations
  Widget _buildRecommendations(BuildContext context, bool darkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: darkMode ? TColors.darkerGrey.withOpacity(0.3) : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.lightbulb_outline, color: TColors.info, size: 20),
              ),
              const SizedBox(width: TSizes.sm),
              Text(
                'Recommendations',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: darkMode ? TColors.white : TColors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: TSizes.md),
          ...prediction.recommendations.map((rec) => Padding(
            padding: const EdgeInsets.only(bottom: TSizes.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline, color: TColors.success, size: 20),
                const SizedBox(width: TSizes.sm),
                Expanded(
                  child: Text(
                    rec,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: darkMode ? TColors.grey : TColors.darkerGrey,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  /// Section Header
  Widget _buildSectionHeader(BuildContext context, bool darkMode, String title) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: darkMode ? TColors.white : TColors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Basic Health Data - No dividers, with icons
  Widget _buildBasicHealthData(BuildContext context, bool darkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: darkMode ? TColors.darkerGrey.withOpacity(0.3) : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
      ),
      child: Column(
        children: [
          _buildDataRowWithIcon(
            context,
            darkMode,
            Icons.height,
            'Height',
            prediction.inputs.height != null
                ? '${prediction.inputs.height!.toStringAsFixed(1)} cm'
                : 'Not recorded',
            TColors.primary,
          ),
          const SizedBox(height: TSizes.md),
          _buildDataRowWithIcon(
            context,
            darkMode,
            Icons.monitor_weight_outlined,
            'Weight',
            prediction.inputs.weight != null
                ? '${prediction.inputs.weight!.toStringAsFixed(1)} kg'
                : 'Not recorded',
            TColors.secondary,
          ),
          const SizedBox(height: TSizes.md),
          _buildDataRowWithIcon(
            context,
            darkMode,
            Icons.bloodtype,
            'Blood Glucose',
            prediction.inputs.bloodGlucose != null
                ? '${prediction.inputs.bloodGlucose!.toStringAsFixed(1)} ${prediction.inputs.glucoseUnit ?? 'mmol/L'}'
                : 'Not recorded',
            TColors.error,
          ),
        ],
      ),
    );
  }

  /// Lifestyle Data - No dividers, with icons
  Widget _buildLifestyleData(BuildContext context, bool darkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: darkMode ? TColors.darkerGrey.withOpacity(0.3) : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
      ),
      child: Column(
        children: [
          _buildDataRowWithIcon(
            context,
            darkMode,
            Icons.directions_run,
            'Physical Activity',
            prediction.inputs.physicalActivityDuration != null
                ? '${prediction.inputs.physicalActivityDuration} min/day'
                : 'Not recorded',
            Colors.green,
          ),
          const SizedBox(height: TSizes.md),
          _buildDataRowWithIcon(
            context,
            darkMode,
            Icons.psychology,
            'Stress Level',
            prediction.inputs.stressLevel != null
                ? '${prediction.inputs.stressLevel}/10'
                : 'Not recorded',
            TColors.warning,
          ),
          const SizedBox(height: TSizes.md),
          _buildDataRowWithIcon(
            context,
            darkMode,
            Icons.bedtime,
            'Sleep Duration',
            prediction.inputs.sleepDuration != null
                ? '${prediction.inputs.sleepDuration!.toStringAsFixed(1)} hours'
                : 'Not recorded',
            TColors.info,
          ),
          const SizedBox(height: TSizes.md),
          _buildDataRowWithIcon(
            context,
            darkMode,
            Icons.water_drop,
            'Water Intake',
            prediction.inputs.waterIntake != null
                ? '${prediction.inputs.waterIntake!.toStringAsFixed(1)} L'
                : 'Not recorded',
            Colors.blue,
          ),
        ],
      ),
    );
  }

  /// Medication Data - No dividers, with icons
  Widget _buildMedicationData(BuildContext context, bool darkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: darkMode ? TColors.darkerGrey.withOpacity(0.3) : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
      ),
      child: Column(
        children: [
          _buildDataRowWithIcon(
            context,
            darkMode,
            Icons.medication,
            'Takes Medication',
            'Yes',
            Colors.purple,
          ),
          if (prediction.inputs.medicationAdherence != null) ...[
            const SizedBox(height: TSizes.md),
            _buildDataRowWithIcon(
              context,
              darkMode,
              Icons.check_circle_outline,
              'Medication Adherence',
              '${prediction.inputs.medicationAdherence}%',
              TColors.success,
            ),
          ],
        ],
      ),
    );
  }

  /// Data Row With Icon - No divider line
  Widget _buildDataRowWithIcon(
      BuildContext context, bool darkMode, IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: TSizes.md),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: darkMode ? TColors.grey : TColors.darkerGrey,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: darkMode ? TColors.white : TColors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Meal Photos Grid
  Widget _buildMealPhotosGrid(BuildContext context, bool darkMode) {
    final mealPhotos = prediction.inputs.mealPhotos!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: mealPhotos.length,
        itemBuilder: (context, index) {
          final photo = mealPhotos[index];
          return _buildMealPhotoCard(context, darkMode, index + 1, photo);
        },
      ),
    );
  }

  /// Meal Photo Card
  Widget _buildMealPhotoCard(
      BuildContext context, bool darkMode, int mealNumber, photo) {
    final hasAnalysis = photo.analysisResult != null;
    final hasError = photo.analysisResult?.hasError ?? false;
    final totalGL = photo.analysisResult?.totalGL ?? 0.0;
    final glCategory = photo.analysisResult?.glCategory ?? 'unknown';

    Color getGLColor(String category) {
      switch (category.toLowerCase()) {
        case 'low':
          return TColors.success;
        case 'medium':
          return TColors.warning;
        case 'high':
          return TColors.error;
        default:
          return TColors.darkGrey;
      }
    }

    return GestureDetector(
      onTap: hasAnalysis && !hasError
          ? () => _showMealDetails(photo.analysisResult!, darkMode)
          : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: darkMode ? TColors.darkerGrey.withOpacity(0.3) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Image with GL Badge
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: photo.isLocalPath
                        ? Image.file(
                      File(photo.imagePath),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    )
                        : photo.isNetworkUrl
                        ? Image.network(
                      photo.imagePath,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: darkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                          child: const Center(
                            child: Icon(Icons.error_outline, size: 32),
                          ),
                        );
                      },
                    )
                        : Container(
                      color: darkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 32),
                      ),
                    ),
                  ),
                  if (hasAnalysis && !hasError)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: getGLColor(glCategory),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'GL ${totalGL.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            /// Meal Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.restaurant, size: 16, color: TColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Meal $mealNumber',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: darkMode ? TColors.white : TColors.black,
                        ),
                      ),
                    ],
                  ),
                  if (hasAnalysis && !hasError) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${photo.analysisResult!.foods.length} food(s)',
                      style: TextStyle(
                        fontSize: 12,
                        color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                      ),
                    ),
                    Text(
                      glCategory.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: getGLColor(glCategory),
                      ),
                    ),
                  ] else if (hasError)
                    Text(
                      'Not a food item',
                      style: TextStyle(
                        fontSize: 11,
                        color: TColors.error,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show Meal Details Dialog - Following meal screen design
  void _showMealDetails(MealAnalysisResult meal, bool darkMode) {
    Get.dialog(
      Dialog(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Meal ${meal.mealNumber} Details',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getGLColor(meal.glCategory).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getGLColor(meal.glCategory).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total GL:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${meal.totalGL.toStringAsFixed(1)} (${meal.glCategory.toUpperCase()})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getGLColor(meal.glCategory),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: meal.foods.length,
                  itemBuilder: (context, index) {
                    final food = meal.foods[index];
                    final hasGIData = food.giValue != null && food.glycemicLoad != null;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              food.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Show GI data if available
                            if (hasGIData) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'GL:',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getGLColor(food.glCategory)
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${food.glycemicLoad!.toStringAsFixed(1)} (${food.glCategory})',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _getGLColor(food.glCategory),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'GI:',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    '${food.giValue}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                            ] else ...[
                              // Show warning if no GI data
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 12,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Cannot find GI value',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Calories:',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '${food.calories.toStringAsFixed(2)} kcal',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Carbs:',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '${food.carbs.toStringAsFixed(2)} g',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Fiber:',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '${food.fiber.toStringAsFixed(2)} g',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Diet Assessment Summary - Following meal screen table design
  Widget _buildDietAssessmentSummary(BuildContext context, bool darkMode) {
    final assessment = prediction.inputs.dietAssessment!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: darkMode ? TColors.darkerGrey.withOpacity(0.3) : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Health Status Badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (assessment.isHealthy ? TColors.success : TColors.warning).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (assessment.isHealthy ? TColors.success : TColors.warning).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  assessment.isHealthy ? Icons.check_circle : Icons.warning_amber,
                  color: assessment.isHealthy ? TColors.success : TColors.warning,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assessment.isHealthy ? 'Healthy Diet' : 'Needs Improvement',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: assessment.isHealthy ? TColors.success : TColors.warning,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Average GL: ${assessment.avgGLPerMeal.toStringAsFixed(1)} per meal',
                        style: TextStyle(
                          fontSize: 12,
                          color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          /// GL Distribution
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: darkMode ? TColors.black.withOpacity(0.2) : TColors.light,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GL Distribution',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: darkMode ? TColors.white : TColors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildGLDistributionItem(
                        'Low',
                        assessment.lowGLMealsCount,
                        TColors.success,
                        darkMode,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildGLDistributionItem(
                        'Medium',
                        assessment.mediumGLMealsCount,
                        TColors.warning,
                        darkMode,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildGLDistributionItem(
                        'High',
                        assessment.highGLMealsCount,
                        TColors.error,
                        darkMode,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          /// Nutritional Summary Table
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: darkMode ? TColors.black.withOpacity(0.2) : TColors.light,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nutritional Summary',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: darkMode ? TColors.white : TColors.black,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  darkMode,
                  Icons.local_fire_department,
                  'Total Calories',
                  '${assessment.totalCalories.toStringAsFixed(2)} kcal',
                  TColors.primary,
                ),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  darkMode,
                  Icons.grain,
                  'Total Carbs',
                  '${assessment.totalCarbs.toStringAsFixed(2)} g',
                  Colors.orange,
                ),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  darkMode,
                  Icons.cake,
                  'Total Sugar',
                  '${assessment.totalSugar.toStringAsFixed(2)} g',
                  TColors.error,
                ),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  darkMode,
                  Icons.spa,
                  'Total Fiber',
                  '${assessment.totalFiber.toStringAsFixed(2)} g',
                  TColors.success,
                ),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  darkMode,
                  Icons.restaurant,
                  'Total Meals',
                  '${assessment.mealCount}',
                  TColors.secondary,
                ),
              ],
            ),
          ),

          /// Warnings
          if (assessment.warnings.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: TColors.error.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: TColors.error, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Health Concerns',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: TColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...assessment.warnings.map((warning) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: TextStyle(
                            fontSize: 12,
                            color: TColors.error,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            warning,
                            style: TextStyle(
                              fontSize: 12,
                              color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build GL Distribution Item
  Widget _buildGLDistributionItem(String label, int count, Color color, bool darkMode) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: darkMode ? TColors.darkGrey : TColors.darkerGrey,
            ),
          ),
        ],
      ),
    );
  }

  /// Build Summary Row
  Widget _buildSummaryRow(
      bool darkMode, IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: darkMode ? TColors.grey : TColors.darkerGrey,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: darkMode ? TColors.white : TColors.black,
          ),
        ),
      ],
    );
  }

  /// Get GL Color Helper
  Color _getGLColor(String category) {
    switch (category.toLowerCase()) {
      case 'low':
        return TColors.success;
      case 'medium':
        return TColors.warning;
      case 'high':
        return TColors.error;
      default:
        return TColors.darkGrey;
    }
  }
}