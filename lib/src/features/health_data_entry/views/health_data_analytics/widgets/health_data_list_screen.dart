import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../../common/widgets/dialogs/dialog.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/enums.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../../diabetes_prediction/models/diabetes_risk_prediction_model.dart';
import '../../../../diabetes_prediction/views/diabetes_output/diabetes_risk_detail_screen.dart';
import '../../../controllers/blood_glucose_controller.dart';
import '../../../controllers/blood_pressure_controller.dart';
import '../../../controllers/weight_controller.dart';
import '../../../controllers/exercise_controller.dart';
import '../../../controllers/diabetes_risk_controller.dart';
import '../../../models/health_data_model.dart';
import '../../health_data_entry/health_data_entry_screen.dart';

class HealthDataListScreen extends StatelessWidget {
  final String title;
  final HealthDataType healthDataType;
  final String? filterType; // 'good', 'high', 'low', 'all', etc.

  const HealthDataListScreen({
    super.key,
    required this.title,
    required this.healthDataType,
    this.filterType,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: darkMode ? const Color(0xFF0A0A0B) : TColors.light,
      appBar: AppBar(
        backgroundColor: TColors.primary,
        foregroundColor: TColors.white,
        automaticallyImplyLeading: false,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: TColors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            color: TColors.white,
            onPressed: () => Get.back(),
          ),
        ],
      ),
      body: _buildBody(context, darkMode),
    );
  }

  Widget _buildBody(BuildContext context, bool darkMode) {
    // Get the appropriate controller based on health data type
    switch (healthDataType) {
      case HealthDataType.bloodGlucose:
        final controller = Get.find<BloodGlucoseController>();
        return Obx(() {
          final healthDataList = _getFilteredList(controller.getFilteredData());
          return healthDataList.isEmpty
              ? _buildEmptyState(context, darkMode)
              : _buildDataList(context, darkMode, healthDataList);
        });

      case HealthDataType.bloodPressure:
        final controller = Get.find<BloodPressureController>();
        return Obx(() {
          final healthDataList = _getFilteredList(controller.getFilteredData());
          return healthDataList.isEmpty
              ? _buildEmptyState(context, darkMode)
              : _buildDataList(context, darkMode, healthDataList);
        });

      case HealthDataType.bodyComposition:
        final controller = Get.find<WeightController>();
        return Obx(() {
          final healthDataList = _getFilteredList(controller.getFilteredData());
          return healthDataList.isEmpty
              ? _buildEmptyState(context, darkMode)
              : _buildDataList(context, darkMode, healthDataList);
        });

      case HealthDataType.physicalActivity:
        final controller = Get.find<ExerciseController>();
        return Obx(() {
          final healthDataList = _getFilteredList(controller.getFilteredData());
          return healthDataList.isEmpty
              ? _buildEmptyState(context, darkMode)
              : _buildDataList(context, darkMode, healthDataList);
        });

      case HealthDataType.diabetesRisk:
        final controller = Get.find<DiabetesRiskController>();
        return Obx(() {
          final predictionList = _getFilteredDiabetesRiskList(controller.getFilteredData());
          return predictionList.isEmpty
              ? _buildEmptyState(context, darkMode)
              : _buildDiabetesRiskList(context, darkMode, predictionList);
        });
    }
  }

  /// Apply additional filtering based on filterType for health data
  List<HealthDataModel> _getFilteredList(List<HealthDataModel> data) {
    if (filterType == null || filterType == 'all') {
      return data;
    }

    switch (healthDataType) {
      case HealthDataType.bloodGlucose:
        final controller = Get.find<BloodGlucoseController>();
        switch (filterType) {
          case 'normal':
            return data.where((d) =>
            controller.getGlucoseLevel(d.bloodGlucose.glucoseLevel) == HealthLevel.normal
            ).toList();
          case 'high':
            return data.where((d) =>
            controller.getGlucoseLevel(d.bloodGlucose.glucoseLevel) == HealthLevel.high
            ).toList();
          case 'low':
            return data.where((d) =>
            controller.getGlucoseLevel(d.bloodGlucose.glucoseLevel) == HealthLevel.low
            ).toList();
        }
        break;

      case HealthDataType.bloodPressure:
        final controller = Get.find<BloodPressureController>();
        switch (filterType) {
          case 'normal':
            return data.where((d) =>
            controller.getBPLevel(d.bloodPressure.systolic, d.bloodPressure.diastolic) == 'normal'
            ).toList();
          case 'elevated':
            return data.where((d) =>
            controller.getBPLevel(d.bloodPressure.systolic, d.bloodPressure.diastolic) == 'elevated'
            ).toList();
          case 'high':
            return data.where((d) =>
            controller.getBPLevel(d.bloodPressure.systolic, d.bloodPressure.diastolic) == 'high'
            ).toList();
          case 'low':
            return data.where((d) =>
            controller.getBPLevel(d.bloodPressure.systolic, d.bloodPressure.diastolic) == 'low'
            ).toList();
        }
        break;

      case HealthDataType.bodyComposition:
      // Add weight filtering logic if needed
        break;

      case HealthDataType.physicalActivity:
      // Add activity filtering logic if needed
        break;

      case HealthDataType.diabetesRisk:
      // Handled separately in _getFilteredDiabetesRiskList
        break;
    }

    return data;
  }

  /// Apply filtering for diabetes risk data
  List<DiabetesRiskPredictionModel> _getFilteredDiabetesRiskList(
      List<DiabetesRiskPredictionModel> data) {
    if (filterType == null || filterType == 'all') {
      return data;
    }

    final controller = Get.find<DiabetesRiskController>();
    switch (filterType) {
      case 'low':
        return data
            .where((d) => controller.getRiskLevel(d.riskScore) == 'low')
            .toList();
      case 'medium':
        return data
            .where((d) => controller.getRiskLevel(d.riskScore) == 'medium')
            .toList();
      case 'high':
        return data
            .where((d) => controller.getRiskLevel(d.riskScore) == 'high')
            .toList();
    }

    return data;
  }

  /// Empty State Widget
  Widget _buildEmptyState(BuildContext context, bool darkMode) {
    String emptyMessage = 'Start tracking your health data to see insights here';
    IconData emptyIcon = Icons.insert_chart_outlined;

    if (healthDataType == HealthDataType.diabetesRisk) {
      emptyMessage = 'Complete a diabetes risk assessment to see results here';
      emptyIcon = Icons.assessment_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            emptyIcon,
            size: 64,
            color: darkMode ? Colors.grey.shade600 : Colors.grey.shade300,
          ),
          const SizedBox(height: TSizes.md),
          Text(
            'No Records Found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: darkMode ? Colors.grey.shade500 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: TSizes.sm),
          Text(
            emptyMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: darkMode ? Colors.grey.shade600 : Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Data List Widget for Health Data
  Widget _buildDataList(BuildContext context, bool darkMode, List<HealthDataModel> healthDataList) {
    // Group data by date
    final groupedData = <String, List<HealthDataModel>>{};

    for (final data in healthDataList) {
      final dateKey = DateFormat('EEEE, M/d/yyyy').format(data.logDateTime);
      groupedData.putIfAbsent(dateKey, () => []).add(data);
    }

    // Sort groups by date (newest first)
    final sortedGroups = groupedData.entries.toList()
      ..sort((a, b) {
        final dateA = healthDataList
            .firstWhere((d) =>
        DateFormat('EEEE, M/d/yyyy').format(d.logDateTime) == a.key)
            .logDateTime;
        final dateB = healthDataList
            .firstWhere((d) =>
        DateFormat('EEEE, M/d/yyyy').format(d.logDateTime) == b.key)
            .logDateTime;
        return dateB.compareTo(dateA);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      itemCount: sortedGroups.length,
      itemBuilder: (context, groupIndex) {
        final group = sortedGroups[groupIndex];
        final dateLabel = group.key;
        final dayData = group.value;

        // Sort data within each day by time (newest first)
        dayData.sort((a, b) => b.logDateTime.compareTo(a.logDateTime));

        // Group by physiological time period
        final periodGroups = <PhysiologicalTimePeriod, List<HealthDataModel>>{};
        for (final data in dayData) {
          periodGroups
              .putIfAbsent(data.physiologicalTimePeriod, () => [])
              .add(data);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Date Header
            if (groupIndex == 0 ||
                sortedGroups[groupIndex - 1].key != dateLabel)
              Container(
                margin: const EdgeInsets.only(bottom: TSizes.md),
                child: Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: darkMode ? TColors.grey : TColors.darkGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            /// Period Groups
            ...periodGroups.entries.map((periodEntry) {
              final period = periodEntry.key;
              final periodData = periodEntry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Period Header
                  Container(
                    margin: const EdgeInsets.only(bottom: TSizes.sm),
                    child: Text(
                      period.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: TColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  /// Records in this period
                  ...periodData.map((data) =>
                      _buildHealthDataItem(context, data, darkMode)),

                  const SizedBox(height: TSizes.md),
                ],
              );
            }),

            const SizedBox(height: TSizes.md),
          ],
        );
      },
    );
  }

  /// Data List Widget for Diabetes Risk
  Widget _buildDiabetesRiskList(BuildContext context, bool darkMode,
      List<DiabetesRiskPredictionModel> predictionList) {
    // Group data by date
    final groupedData = <String, List<DiabetesRiskPredictionModel>>{};

    for (final data in predictionList) {
      final dateKey = DateFormat('EEEE, M/d/yyyy').format(data.predictionDateTime);
      groupedData.putIfAbsent(dateKey, () => []).add(data);
    }

    // Sort groups by date (newest first)
    final sortedGroups = groupedData.entries.toList()
      ..sort((a, b) {
        final dateA = predictionList
            .firstWhere((d) =>
        DateFormat('EEEE, M/d/yyyy').format(d.predictionDateTime) == a.key)
            .predictionDateTime;
        final dateB = predictionList
            .firstWhere((d) =>
        DateFormat('EEEE, M/d/yyyy').format(d.predictionDateTime) == b.key)
            .predictionDateTime;
        return dateB.compareTo(dateA);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      itemCount: sortedGroups.length,
      itemBuilder: (context, groupIndex) {
        final group = sortedGroups[groupIndex];
        final dateLabel = group.key;
        final dayData = group.value;

        // Sort data within each day by time (newest first)
        dayData.sort((a, b) => b.predictionDateTime.compareTo(a.predictionDateTime));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Date Header
            if (groupIndex == 0 ||
                sortedGroups[groupIndex - 1].key != dateLabel)
              Container(
                margin: const EdgeInsets.only(bottom: TSizes.md),
                child: Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: darkMode ? TColors.grey : TColors.darkGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            /// Records
            ...dayData.map((data) =>
                _buildDiabetesRiskItem(context, data, darkMode)),

            const SizedBox(height: TSizes.md),
          ],
        );
      },
    );
  }

  /// Health Data Item Widget
  Widget _buildHealthDataItem(
      BuildContext context, HealthDataModel data, bool darkMode) {
    final levelColor = _getHealthDataColor(data, healthDataType);

    return Container(
      margin: const EdgeInsets.only(bottom: TSizes.sm),
      child: GestureDetector(
        onTap: () => Get.to(() => HealthDataEntryScreen(editData: data)),
        onLongPress: () => _showDeleteDialog(context, data),
        child: Container(
          padding: const EdgeInsets.all(TSizes.md),
          decoration: BoxDecoration(
            color: darkMode ? TColors.dark : TColors.white,
            borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
            border: Border.all(
              color: darkMode ? TColors.dark : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              /// Time
              SizedBox(
                width: 50,
                child: Text(
                  DateFormat('HH:mm').format(data.logDateTime),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: darkMode ? TColors.grey : TColors.darkGrey,
                  ),
                ),
              ),

              const SizedBox(width: TSizes.md),

              /// Health Data Icon and Info
              Expanded(
                child: Row(
                  children: [
                    /// Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: levelColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getHealthDataIcon(healthDataType),
                        color: levelColor,
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: TSizes.sm),

                    /// Data Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getHealthDataTitle(healthDataType),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: darkMode ? TColors.white : TColors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          _buildHealthDataValue(context, data, healthDataType),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              /// Delete Button
              GestureDetector(
                onTap: () => _showDeleteDialog(context, data),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: darkMode
                        ? Colors.grey.shade700
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: darkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Diabetes Risk Item Widget
  Widget _buildDiabetesRiskItem(
      BuildContext context, DiabetesRiskPredictionModel prediction, bool darkMode) {
    final controller = Get.find<DiabetesRiskController>();
    final riskColor = controller.getRiskLevelColor(prediction.riskScore);
    final riskLevel = controller.getRiskLevel(prediction.riskScore);

    return Container(
      margin: const EdgeInsets.only(bottom: TSizes.sm),
      child: GestureDetector(
        onTap: () => Get.to(() => DiabetesRiskDetailScreen(prediction: prediction)),
        child: Container(
          padding: const EdgeInsets.all(TSizes.md),
          decoration: BoxDecoration(
            color: darkMode ? TColors.dark : TColors.white,
            borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
            border: Border.all(
              color: darkMode ? TColors.dark : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              /// Time
              SizedBox(
                width: 50,
                child: Text(
                  DateFormat('HH:mm').format(prediction.predictionDateTime),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: darkMode ? TColors.grey : TColors.darkGrey,
                  ),
                ),
              ),

              const SizedBox(width: TSizes.md),

              /// Risk Icon and Info
              Expanded(
                child: Row(
                  children: [
                    /// Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: riskColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.favorite_border,
                        color: riskColor,
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: TSizes.sm),

                    /// Data Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Diabetes Risk Score',
                            style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: darkMode
                                  ? TColors.white
                                  : TColors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                prediction.riskScore.toStringAsFixed(1),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                  color: riskColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'pts',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: riskColor),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: riskColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  riskLevel.toUpperCase(),
                                  style: TextStyle(
                                    color: riskColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              /// Arrow
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: darkMode ? Colors.grey.shade500 : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show Delete Confirmation Dialog
  void _showDeleteDialog(BuildContext context, HealthDataModel data) {
    TDialog.deleteDialog(
      title: 'Delete Record',
      message:
      'Are you sure you want to delete this health record? This action cannot be undone.',
      onConfirm: () => _deleteHealthRecord(data.logId),
    );
  }

  /// Delete health record based on type
  void _deleteHealthRecord(String logId) {
    switch (healthDataType) {
      case HealthDataType.bloodGlucose:
        if (Get.isRegistered<BloodGlucoseController>()) {
          Get.find<BloodGlucoseController>().deleteHealthRecord(logId);
        }
        break;
      case HealthDataType.bloodPressure:
        if (Get.isRegistered<BloodPressureController>()) {
          Get.find<BloodPressureController>().deleteHealthRecord(logId);
        }
        break;
      case HealthDataType.bodyComposition:
        if (Get.isRegistered<WeightController>()) {
          Get.find<WeightController>().deleteHealthRecord(logId);
        }
        break;
      case HealthDataType.physicalActivity:
        if (Get.isRegistered<ExerciseController>()) {
          Get.find<ExerciseController>().deleteHealthRecord(logId);
        }
        break;
      case HealthDataType.diabetesRisk:
      // Diabetes risk records are not deletable from this screen
        break;
    }
  }

  /// Get health data color based on type and values
  Color _getHealthDataColor(HealthDataModel data, HealthDataType type) {
    switch (type) {
      case HealthDataType.bloodGlucose:
        final controller = Get.find<BloodGlucoseController>();
        return controller.getGlucoseLevelColor(data.bloodGlucose.glucoseLevel);

      case HealthDataType.bloodPressure:
        final controller = Get.find<BloodPressureController>();
        return controller.getBPLevelColor(
            data.bloodPressure.systolic,
            data.bloodPressure.diastolic
        );

      case HealthDataType.bodyComposition:
        final controller = Get.find<WeightController>();
        final weight = data.bodyComposition.weight;
        if (weight > 0) {
          return controller.getWeightStatusColor(weight);
        }
        return TColors.grey;

      case HealthDataType.physicalActivity:
        final intensity = data.physicalActivity.intensityLevel;
        switch (intensity) {
          case IntensityLevel.low:
            return TColors.info;
          case IntensityLevel.moderate:
            return TColors.warning;
          case IntensityLevel.high:
            return TColors.error;
          default:
            return TColors.primary;
        }

      case HealthDataType.diabetesRisk:
      // This won't be called for diabetes risk items
        return TColors.primary;
    }
  }

  /// Get health data icon based on type
  IconData _getHealthDataIcon(HealthDataType type) {
    switch (type) {
      case HealthDataType.bloodGlucose:
        return Icons.opacity;
      case HealthDataType.bloodPressure:
        return Icons.favorite;
      case HealthDataType.bodyComposition:
        return Icons.monitor_weight;
      case HealthDataType.physicalActivity:
        return Icons.directions_run;
      case HealthDataType.diabetesRisk:
        return Icons.favorite_border;
    }
  }

  /// Get health data title based on type
  String _getHealthDataTitle(HealthDataType type) {
    switch (type) {
      case HealthDataType.bloodGlucose:
        return 'Blood Glucose';
      case HealthDataType.bloodPressure:
        return 'Blood Pressure';
      case HealthDataType.bodyComposition:
        return 'Weight';
      case HealthDataType.physicalActivity:
        return 'Exercise';
      case HealthDataType.diabetesRisk:
        return 'Diabetes Risk';
    }
  }

  /// Get health data value based on type
  String _getHealthDataValue(HealthDataModel data, HealthDataType type) {
    switch (type) {
      case HealthDataType.bloodGlucose:
        return '${data.bloodGlucose.glucoseLevel.toStringAsFixed(1)} mmol/L';

      case HealthDataType.bloodPressure:
        final systolic = data.bloodPressure.systolic;
        final diastolic = data.bloodPressure.diastolic;
        final pulse = data.bloodPressure.pulse;

        String bpString = '';
        if (systolic > 0 || diastolic > 0) {
          bpString = '${systolic}/${diastolic} mmHg';
        }
        if (pulse > 0) {
          bpString += bpString.isEmpty ? '${pulse} bpm' : ', ${pulse} bpm';
        }
        return bpString.isEmpty ? 'No data' : bpString;

      case HealthDataType.bodyComposition:
        final weight = data.bodyComposition.weight;
        final bodyFat = data.bodyComposition.bodyFat;
        if (weight > 0 && bodyFat > 0) {
          return '${weight.toStringAsFixed(1)} kg, ${bodyFat.toStringAsFixed(1)}%';
        } else if (weight > 0) {
          return '${weight.toStringAsFixed(1)} kg';
        } else if (bodyFat > 0) {
          return '${bodyFat.toStringAsFixed(1)}%';
        }
        return 'No data';

      case HealthDataType.physicalActivity:
        final activity = data.physicalActivity.activityType;
        final duration = data.physicalActivity.duration;
        final intensity = data.physicalActivity.intensityLevel;

        String activityString = '';
        if (activity.isNotEmpty) {
          activityString = activity;
        }
        if (duration > 0) {
          activityString +=
          activityString.isEmpty ? '${duration} min' : ', ${duration} min';
        }
        if (intensity != IntensityLevel.moderate) {
          activityString += activityString.isEmpty
              ? intensity.displayName
              : ', ${intensity.displayName}';
        }
        return activityString.isEmpty ? 'No data' : activityString;

      case HealthDataType.diabetesRisk:
      // This won't be called for diabetes risk items
        return '';
    }
  }

  /// Build health data value widget with individual colors for each metric
  Widget _buildHealthDataValue(BuildContext context, HealthDataModel data, HealthDataType type) {
    final headlineStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.bold,
    );

    switch (type) {
      case HealthDataType.bloodGlucose:
        final controller = Get.find<BloodGlucoseController>();
        final color = controller.getGlucoseLevelColor(data.bloodGlucose.glucoseLevel);
        return Text(
          '${data.bloodGlucose.glucoseLevel.toStringAsFixed(1)} mmol/L',
          style: headlineStyle?.copyWith(color: color),
        );

      case HealthDataType.bloodPressure:
        final controller = Get.find<BloodPressureController>();
        final systolic = data.bloodPressure.systolic;
        final diastolic = data.bloodPressure.diastolic;
        final pulse = data.bloodPressure.pulse;

        final bpColor = controller.getBPLevelColor(systolic, diastolic);
        final pulseColor = controller.getPulseLevelColor(pulse);

        List<TextSpan> spans = [];

        // Add blood pressure
        if (systolic > 0 || diastolic > 0) {
          spans.add(TextSpan(
            text: '$systolic/$diastolic mmHg',
            style: headlineStyle?.copyWith(color: bpColor),
          ));
        }

        // Add pulse
        if (pulse > 0) {
          if (spans.isNotEmpty) {
            spans.add(TextSpan(
              text: ', ',
              style: headlineStyle,
            ));
          }
          spans.add(TextSpan(
            text: '$pulse bpm',
            style: headlineStyle?.copyWith(color: pulseColor),
          ));
        }

        if (spans.isEmpty) {
          return Text(
            'No data',
            style: headlineStyle?.copyWith(color: TColors.darkGrey),
          );
        }

        return RichText(
          text: TextSpan(children: spans),
        );

      case HealthDataType.bodyComposition:
        final controller = Get.find<WeightController>();
        final weight = data.bodyComposition.weight;
        final bodyFat = data.bodyComposition.bodyFat;

        final weightColor = weight > 0
            ? controller.getWeightStatusColor(weight)
            : TColors.darkGrey;
        final bodyFatColor = bodyFat > 0
            ? controller.getBodyFatStatusColor(bodyFat)
            : TColors.darkGrey;

        List<TextSpan> spans = [];

        // Add weight
        if (weight > 0) {
          spans.add(TextSpan(
            text: '${weight.toStringAsFixed(1)} kg',
            style: headlineStyle?.copyWith(color: weightColor),
          ));
        }

        // Add body fat
        if (bodyFat > 0) {
          if (spans.isNotEmpty) {
            spans.add(TextSpan(
              text: ', ',
              style: headlineStyle,
            ));
          }
          spans.add(TextSpan(
            text: '${bodyFat.toStringAsFixed(1)}%',
            style: headlineStyle?.copyWith(color: bodyFatColor),
          ));
        }

        if (spans.isEmpty) {
          return Text(
            'No data',
            style: headlineStyle?.copyWith(color: TColors.darkGrey),
          );
        }

        return RichText(
          text: TextSpan(children: spans),
        );

      case HealthDataType.physicalActivity:
        final levelColor = _getHealthDataColor(data, healthDataType);
        return Text(
          _getHealthDataValue(data, healthDataType),
          style: headlineStyle?.copyWith(color: levelColor),
        );

      case HealthDataType.diabetesRisk:
      // This won't be called for diabetes risk items
        return const SizedBox.shrink();
    }
  }
}