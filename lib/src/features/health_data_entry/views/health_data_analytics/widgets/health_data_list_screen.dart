import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../common/widgets/dialogs/common_confirmation_dialog.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/enums.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/blood_glucose_controller.dart';
import '../../../controllers/blood_pressure_controller.dart';
import '../../../controllers/weight_controller.dart';
import '../../../controllers/exercise_controller.dart';
import '../../../models/health_data_model.dart';
import '../../health_data_entry/health_data_entry_screen.dart';

class HealthDataListScreen extends StatelessWidget {
  final String title;
  final List<HealthDataModel> healthDataList;
  final HealthDataType healthDataType;

  const HealthDataListScreen({
    super.key,
    required this.title,
    required this.healthDataList,
    required this.healthDataType,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: darkMode ? TColors.dark : TColors.light,
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
      body: healthDataList.isEmpty
          ? _buildEmptyState(context, darkMode)
          : _buildDataList(context, darkMode),
    );
  }

  /// Empty State Widget
  Widget _buildEmptyState(BuildContext context, bool darkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_chart_outlined,
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
            'Start tracking your health data to see insights here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: darkMode ? Colors.grey.shade600 : Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Data List Widget
  Widget _buildDataList(BuildContext context, bool darkMode) {
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
            color: darkMode ? TColors.darkerGrey : Colors.white,
            borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
            border: Border.all(
              color: darkMode ? Colors.grey.shade700 : Colors.grey.shade200,
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
                          Text(
                            _getHealthDataValue(data, healthDataType),
                            style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: levelColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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

  /// Show Delete Confirmation Dialog
  void _showDeleteDialog(BuildContext context, HealthDataModel data) {
    ConfirmationDialog.show(
      title: 'Delete Record',
      message:
      'Are you sure you want to delete this health record? This action cannot be undone.',
      confirmButtonText: 'Delete',
      customIcon: Iconsax.trash_bold,
      iconColor: TColors.error,
      confirmButtonColor: TColors.error,
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
          // Exercise controller doesn't have delete method yet
          // TODO: Add delete method to ExerciseController
        }
        break;
    }
  }

  /// Get health data color based on type and values
  Color _getHealthDataColor(HealthDataModel data, HealthDataType type) {
    switch (type) {
      case HealthDataType.bloodGlucose:
        final glucose = data.bloodGlucose.glucoseLevel;
        if (glucose < 4.0) return TColors.glucoseLow;
        if (glucose > 10.0) return TColors.glucoseHigh;
        return TColors.glucoseGood;

      case HealthDataType.bloodPressure:
        final systolic = data.bloodPressure.systolic;
        final diastolic = data.bloodPressure.diastolic;
        if (systolic < 90 || diastolic < 60) return TColors.bpLow;
        if (systolic < 120 && diastolic < 80) return TColors.bpNormal;
        if (systolic < 130 && diastolic < 80) return TColors.bpElevated;
        return TColors.bpHigh;

      case HealthDataType.bodyComposition:
      // Simple BMI-based color coding
        final weight = data.bodyComposition.weight;
        final height = data.bodyComposition.bodyFat / 100; // Convert cm to m
        if (weight > 0 && height > 0) {
          final bmi = weight / (height * height);
          if (bmi < 18.5) return TColors.weightUnderweight;
          if (bmi < 25) return TColors.weightNormal;
          if (bmi < 30) return TColors.weightOverweight;
          return TColors.weightObese;
        }
        return TColors.weightNormal;

      case HealthDataType.physicalActivity:
        return TColors.success; // Default color for exercise
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
        return Icons.fitness_center;
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
    }
  }
}