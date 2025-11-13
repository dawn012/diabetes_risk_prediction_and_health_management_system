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
            if (prediction.inputs.mealPhotos?.isNotEmpty ?? false)
              _buildMealPhotosSection(context, darkMode),

            const SizedBox(height: TSizes.defaultSpace),

            /// Diet Assessment Summary
            if (prediction.inputs.dietAssessment != null)
              _buildDietAssessmentSummary(context, darkMode),

            const SizedBox(height: TSizes.defaultSpace),
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
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
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
        color: darkMode ? TColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        border: Border.all(
          color: darkMode ? TColors.dark : Colors.grey.shade200,
        ),
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
                child: Icon(
                  Icons.lightbulb_outline,
                  color: TColors.info,
                  size: 20,
                ),
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
                Icon(
                  Icons.check_circle_outline,
                  color: TColors.success,
                  size: 20,
                ),
                const SizedBox(width: TSizes.sm),
                Expanded(
                  child: Text(
                    rec,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: darkMode ? TColors.grey : TColors.darkGrey,
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

  /// Basic Health Data
  Widget _buildBasicHealthData(BuildContext context, bool darkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: darkMode ? TColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        border: Border.all(
          color: darkMode ? TColors.dark : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          _buildDataRow(
            context,
            darkMode,
            'Height',
            prediction.inputs.height != null
                ? '${prediction.inputs.height!.toStringAsFixed(1)} cm'
                : 'Not recorded',
          ),
          const Divider(),
          _buildDataRow(
            context,
            darkMode,
            'Weight',
            prediction.inputs.weight != null
                ? '${prediction.inputs.weight!.toStringAsFixed(1)} kg'
                : 'Not recorded',
          ),
          const Divider(),
          _buildDataRow(
            context,
            darkMode,
            'Blood Glucose',
            prediction.inputs.bloodGlucose != null
                ? '${prediction.inputs.bloodGlucose!.toStringAsFixed(1)} ${prediction.inputs.glucoseUnit ?? 'mmol/L'}'
                : 'Not recorded',
          ),
        ],
      ),
    );
  }

  /// Lifestyle Data
  Widget _buildLifestyleData(BuildContext context, bool darkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: darkMode ? TColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        border: Border.all(
          color: darkMode ? TColors.dark : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          _buildDataRow(
            context,
            darkMode,
            'Physical Activity',
            prediction.inputs.physicalActivityDuration != null
                ? '${prediction.inputs.physicalActivityDuration} min/day'
                : 'Not recorded',
          ),
          const Divider(),
          _buildDataRow(
            context,
            darkMode,
            'Stress Level',
            prediction.inputs.stressLevel != null
                ? '${prediction.inputs.stressLevel}/10'
                : 'Not recorded',
          ),
          const Divider(),
          _buildDataRow(
            context,
            darkMode,
            'Sleep Duration',
            prediction.inputs.sleepDuration != null
                ? '${prediction.inputs.sleepDuration!.toStringAsFixed(1)} hours'
                : 'Not recorded',
          ),
          const Divider(),
          _buildDataRow(
            context,
            darkMode,
            'Water Intake',
            prediction.inputs.waterIntake != null
                ? '${prediction.inputs.waterIntake!.toStringAsFixed(1)} L'
                : 'Not recorded',
          ),
        ],
      ),
    );
  }

  /// Medication Data
  Widget _buildMedicationData(BuildContext context, bool darkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: darkMode ? TColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        border: Border.all(
          color: darkMode ? TColors.dark : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          _buildDataRow(
            context,
            darkMode,
            'Takes Medication',
            'Yes',
          ),
          if (prediction.inputs.medicationAdherence != null) ...[
            const Divider(),
            _buildDataRow(
              context,
              darkMode,
              'Medication Adherence',
              '${prediction.inputs.medicationAdherence}%',
            ),
          ],
        ],
      ),
    );
  }

  /// Data Row
  Widget _buildDataRow(
      BuildContext context, bool darkMode, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TSizes.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: darkMode ? TColors.grey : TColors.darkGrey,
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
      ),
    );
  }

  /// Meal Photos Section
  Widget _buildMealPhotosSection(BuildContext context, bool darkMode) {
    final mealPhotos = prediction.inputs.mealPhotos!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, darkMode, 'Meal Analysis'),
        const SizedBox(height: TSizes.md),
        ...mealPhotos.asMap().entries.map((entry) {
          final index = entry.key;
          final photo = entry.value;
          return _buildMealPhotoItem(context, darkMode, index + 1, photo);
        }),
      ],
    );
  }

  /// Meal Photo Item
  Widget _buildMealPhotoItem(
      BuildContext context, bool darkMode, int mealNumber, photo) {
    final hasAnalysis = photo.analysisResult != null;
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

    return Container(
      margin: const EdgeInsets.only(
        left: TSizes.defaultSpace,
        right: TSizes.defaultSpace,
        bottom: TSizes.md,
      ),
      decoration: BoxDecoration(
        color: darkMode ? TColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        border: Border.all(
          color: darkMode ? TColors.dark : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Meal Header
          Padding(
            padding: const EdgeInsets.all(TSizes.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: TColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.restaurant,
                    color: TColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: TSizes.sm),
                Expanded(
                  child: Text(
                    'Meal $mealNumber',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: darkMode ? TColors.white : TColors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (hasAnalysis)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: getGLColor(glCategory).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'GL: ${totalGL.toStringAsFixed(1)}',
                      style: TextStyle(
                        color: getGLColor(glCategory),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          /// Meal Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(TSizes.cardRadiusMd),
              bottomRight: Radius.circular(TSizes.cardRadiusMd),
            ),
            child: photo.isLocalPath
                ? Image.file(
              File(photo.imagePath),
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            )
                : photo.isNetworkUrl
                ? Image.network(
              photo.imagePath,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  color: darkMode
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: darkMode
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
                  child: Center(
                    child: Icon(
                      Icons.error_outline,
                      size: 48,
                      color: darkMode
                          ? Colors.grey.shade600
                          : Colors.grey.shade400,
                    ),
                  ),
                );
              },
            )
                : Container(
              height: 200,
              color: darkMode
                  ? Colors.grey.shade800
                  : Colors.grey.shade200,
              child: Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 48,
                  color: darkMode
                      ? Colors.grey.shade600
                      : Colors.grey.shade400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Diet Assessment Summary
  Widget _buildDietAssessmentSummary(BuildContext context, bool darkMode) {
    final assessment = prediction.inputs.dietAssessment!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: darkMode ? TColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        border: Border.all(
          color: darkMode ? TColors.dark : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Diet Assessment Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: darkMode ? TColors.white : TColors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: TSizes.md),

          /// Summary Table
          Table(
            border: TableBorder.all(
              color: darkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              width: 1,
            ),
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
            },
            children: [
              _buildTableRow(
                context,
                darkMode,
                'Average GL per Meal',
                assessment.avgGLPerMeal.toStringAsFixed(1),
                isHeader: true,
              ),
              _buildTableRow(
                context,
                darkMode,
                'Total Meals',
                assessment.mealCount.toString(),
              ),
              _buildTableRow(
                context,
                darkMode,
                'Low GL Meals',
                assessment.lowGLMealsCount.toString(),
              ),
              _buildTableRow(
                context,
                darkMode,
                'Medium GL Meals',
                assessment.mediumGLMealsCount.toString(),
              ),
              _buildTableRow(
                context,
                darkMode,
                'High GL Meals',
                assessment.highGLMealsCount.toString(),
              ),
              _buildTableRow(
                context,
                darkMode,
                'Diet Status',
                assessment.isHealthy ? 'Healthy' : 'Needs Improvement',
                valueColor:
                assessment.isHealthy ? TColors.success : TColors.warning,
              ),
            ],
          ),

          /// Warnings
          if (assessment.warnings.isNotEmpty) ...[
            const SizedBox(height: TSizes.md),
            Container(
              padding: const EdgeInsets.all(TSizes.sm),
              decoration: BoxDecoration(
                color: TColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: TColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: TSizes.xs),
                      Text(
                        'Warnings',
                        style: TextStyle(
                          color: TColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TSizes.xs),
                  ...assessment.warnings.map((warning) => Padding(
                    padding: const EdgeInsets.only(top: TSizes.xs),
                    child: Text(
                      '• $warning',
                      style:
                      Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: darkMode
                            ? TColors.grey
                            : TColors.darkGrey,
                      ),
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

  /// Table Row
  TableRow _buildTableRow(
      BuildContext context,
      bool darkMode,
      String label,
      String value, {
        bool isHeader = false,
        Color? valueColor,
      }) {
    return TableRow(
      decoration: isHeader
          ? BoxDecoration(
        color: darkMode
            ? Colors.grey.shade800.withOpacity(0.3)
            : Colors.grey.shade100,
      )
          : null,
      children: [
        Padding(
          padding: const EdgeInsets.all(TSizes.sm),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: darkMode ? TColors.grey : TColors.darkGrey,
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(TSizes.sm),
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: valueColor ??
                  (darkMode ? TColors.white : TColors.black),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}