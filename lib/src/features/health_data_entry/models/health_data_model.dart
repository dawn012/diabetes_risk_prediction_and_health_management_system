import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/firebase_field_names.dart';
import 'blood_glucose_model.dart';
import 'blood_pressure_model.dart';
import 'body_composition_model.dart';
import 'physical_activity_model.dart';

/// Updated HealthDataModel without userId (managed at user level)
class HealthDataModel {
  final String logId;
  final DateTime logDateTime;
  final PhysiologicalTimePeriod physiologicalTimePeriod;
  final BloodPressureModel bloodPressure;
  final BloodGlucoseModel bloodGlucose;
  final BodyCompositionModel bodyComposition;
  final PhysicalActivityModel physicalActivity;
  final int? steps;

  HealthDataModel({
    required this.logId,
    required this.logDateTime,
    required this.physiologicalTimePeriod,
    required this.bloodPressure,
    required this.bloodGlucose,
    required this.bodyComposition,
    required this.physicalActivity,
    this.steps,
  });

  /// Empty constructor
  static HealthDataModel empty() {
    return HealthDataModel(
      logId: '',
      logDateTime: DateTime.now(),
      physiologicalTimePeriod: PhysiologicalTimePeriod.beforeBreakfast,
      bloodPressure: BloodPressureModel.empty(),
      bloodGlucose: BloodGlucoseModel.empty(),
      bodyComposition: BodyCompositionModel.empty(),
      physicalActivity: PhysicalActivityModel.empty(),
      steps: null,
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.logId: logId,
      FirebaseFieldNames.logDateTime: logDateTime.millisecondsSinceEpoch,
      FirebaseFieldNames.physiologicalTimePeriod: physiologicalTimePeriod.value,
      FirebaseFieldNames.bloodPressure: bloodPressure.toJson(),
      FirebaseFieldNames.bloodGlucose: bloodGlucose.toJson(),
      FirebaseFieldNames.bodyComposition: bodyComposition.toJson(),
      FirebaseFieldNames.physicalActivity: physicalActivity.toJson(),
      if (steps != null) FirebaseFieldNames.steps: steps,
    };
  }

  /// 步数记录的工厂方法
  factory HealthDataModel.stepsOnly({
    String? logId,
    required DateTime date,
    required int steps,
  }) {
    return HealthDataModel(
      logId: logId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      logDateTime: DateTime(date.year, date.month, date.day), // 时间设为 00:00:00
      physiologicalTimePeriod: PhysiologicalTimePeriod.wakeUp,
      bloodPressure: BloodPressureModel.empty(),
      bloodGlucose: BloodGlucoseModel.empty(),
      bodyComposition: BodyCompositionModel.empty(),
      physicalActivity: PhysicalActivityModel.empty(),
      steps: steps,
    );
  }

  /// Create from Firestore document
  factory HealthDataModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    if (data == null) return HealthDataModel.empty();

    return HealthDataModel(
      logId: data[FirebaseFieldNames.logId] ?? document.id,
      logDateTime: data[FirebaseFieldNames.logDateTime] != null
          ? DateTime.fromMillisecondsSinceEpoch(
          data[FirebaseFieldNames.logDateTime])
          : DateTime.now(),
      physiologicalTimePeriod: PhysiologicalTimePeriod.fromString(
          data[FirebaseFieldNames.physiologicalTimePeriod] ?? 'before breakfast'),
      bloodPressure: data[FirebaseFieldNames.bloodPressure] != null
          ? BloodPressureModel.fromJson(data[FirebaseFieldNames.bloodPressure])
          : BloodPressureModel.empty(),
      bloodGlucose: data[FirebaseFieldNames.bloodGlucose] != null
          ? BloodGlucoseModel.fromJson(data[FirebaseFieldNames.bloodGlucose])
          : BloodGlucoseModel.empty(),
      bodyComposition: data[FirebaseFieldNames.bodyComposition] != null
          ? BodyCompositionModel.fromJson(
          data[FirebaseFieldNames.bodyComposition])
          : BodyCompositionModel.empty(),
      physicalActivity: data[FirebaseFieldNames.physicalActivity] != null
          ? PhysicalActivityModel.fromJson(
          data[FirebaseFieldNames.physicalActivity])
          : PhysicalActivityModel.empty(),
      steps: data[FirebaseFieldNames.steps],
    );
  }

  /// Copy with method
  HealthDataModel copyWith({
    String? logId,
    DateTime? logDateTime,
    PhysiologicalTimePeriod? physiologicalTimePeriod,
    BloodPressureModel? bloodPressure,
    BloodGlucoseModel? bloodGlucose,
    BodyCompositionModel? bodyComposition,
    PhysicalActivityModel? physicalActivity,
    int? steps
  }) {
    return HealthDataModel(
      logId: logId ?? this.logId,
      logDateTime: logDateTime ?? this.logDateTime,
      physiologicalTimePeriod:
      physiologicalTimePeriod ?? this.physiologicalTimePeriod,
      bloodPressure: bloodPressure ?? this.bloodPressure,
      bloodGlucose: bloodGlucose ?? this.bloodGlucose,
      bodyComposition: bodyComposition ?? this.bodyComposition,
      physicalActivity: physicalActivity ?? this.physicalActivity,
      steps: steps ?? this.steps,
    );
  }
}