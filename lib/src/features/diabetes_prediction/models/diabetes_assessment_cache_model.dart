import 'package:hive/hive.dart';

import 'diet_assessment_report_model.dart';
import 'meal_photo_record_model.dart';

part 'diabetes_assessment_cache_model.g.dart';

@HiveType(typeId: 0)
class DiabetesAssessmentCache extends HiveObject {
  @HiveField(0)
  double? height;

  @HiveField(1)
  double? weight;

  @HiveField(2)
  double? bloodGlucose;

  @HiveField(3)
  String? glucoseUnit; // 'mmol/L' or 'mg/dL'

  @HiveField(4)
  int? physicalActivityDuration;

  @HiveField(5)
  int? stressLevel;

  @HiveField(6)
  double? sleepDuration;

  @HiveField(7)
  double? waterIntake;

  @HiveField(8)
  bool? takesMedication;

  @HiveField(9)
  int? medicationAdherence;

  @HiveField(10)
  List<MealPhotoRecord>? mealPhotos; // Store full meal photo records with analysis

  @HiveField(11)
  bool? mealPhotosProcessed; // Whether photos have been analyzed

  @HiveField(12)
  DietAssessmentReport? dietAssessment; // Analysis results

  @HiveField(13)
  int currentStep;

  @HiveField(14)
  DateTime lastUpdated;

  @HiveField(15)
  Map<int, bool> completedSteps;

  @HiveField(16)
  bool isComplete;

  @HiveField(17)
  bool isFirstTime; // Track first time status

  DiabetesAssessmentCache({
    this.height,
    this.weight,
    this.bloodGlucose,
    this.glucoseUnit = 'mmol/L',
    this.physicalActivityDuration,
    this.stressLevel,
    this.sleepDuration,
    this.waterIntake,
    this.takesMedication,
    this.medicationAdherence,
    this.mealPhotos,
    this.mealPhotosProcessed,
    this.dietAssessment,
    this.currentStep = 1,
    required this.lastUpdated,
    Map<int, bool>? completedSteps,
    this.isComplete = false,
    this.isFirstTime = true,
  }) : completedSteps = completedSteps ?? {};

  /// Create empty cache
  factory DiabetesAssessmentCache.empty() {
    return DiabetesAssessmentCache(
      height: null,
      weight: null,
      bloodGlucose: null,
      glucoseUnit: 'mmol/L',
      physicalActivityDuration: null,
      stressLevel: null,
      sleepDuration: null,
      waterIntake: null,
      takesMedication: null,
      medicationAdherence: null,
      mealPhotos: null,
      mealPhotosProcessed: null,
      dietAssessment: null,
      currentStep: 1,
      lastUpdated: DateTime.now(),
      completedSteps: {},
      isComplete: false,
      isFirstTime: true,
    );
  }

  /// Copy with method - 修复参数
  DiabetesAssessmentCache copyWith({
    double? height,
    double? weight,
    double? bloodGlucose,
    String? glucoseUnit,
    int? physicalActivityDuration,
    int? stressLevel,
    double? sleepDuration,
    double? waterIntake,
    bool? takesMedication,
    int? medicationAdherence,
    List<MealPhotoRecord>? mealPhotos,
    bool? mealPhotosProcessed,
    DietAssessmentReport? dietAssessment,
    int? currentStep,
    DateTime? lastUpdated,
    Map<int, bool>? completedSteps,
    bool? isComplete,
    bool? isFirstTime,
  }) {
    return DiabetesAssessmentCache(
      height: height ?? this.height,
      weight: weight ?? this.weight,
      bloodGlucose: bloodGlucose ?? this.bloodGlucose,
      glucoseUnit: glucoseUnit ?? this.glucoseUnit ?? 'mmol/L',
      physicalActivityDuration: physicalActivityDuration ?? this.physicalActivityDuration,
      stressLevel: stressLevel ?? this.stressLevel,
      sleepDuration: sleepDuration ?? this.sleepDuration,
      waterIntake: waterIntake ?? this.waterIntake,
      takesMedication: takesMedication ?? this.takesMedication,
      medicationAdherence: medicationAdherence ?? this.medicationAdherence,
      mealPhotos: mealPhotos ?? this.mealPhotos,
      mealPhotosProcessed: mealPhotosProcessed ?? this.mealPhotosProcessed,
      dietAssessment: dietAssessment ?? this.dietAssessment,
      currentStep: currentStep ?? this.currentStep,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      completedSteps: completedSteps ?? this.completedSteps,
      isComplete: isComplete ?? this.isComplete,
      isFirstTime: isFirstTime ?? this.isFirstTime,
    );
  }

  /// 获取照片路径的便捷方法
  List<String> get mealPhotosPaths {
    return mealPhotos?.map((photo) => photo.imagePath).toList() ?? [];
  }

  /// Get completed steps count
  int get completedStepsCount {
    return completedSteps.values.where((v) => v == true).length;
  }

  /// Check if a step is completed
  bool isStepCompleted(int step) {
    return completedSteps[step] ?? false;
  }

  /// Mark step as completed
  void markStepCompleted(int step, bool completed) {
    completedSteps[step] = completed;
    lastUpdated = DateTime.now();
  }

  /// Get progress percentage
  double get progressPercentage {
    return completedStepsCount / 8.0;
  }

  /// Check if cache has any data
  bool get hasData {
    return height != null ||
        weight != null ||
        bloodGlucose != null ||
        physicalActivityDuration != null ||
        stressLevel != null ||
        sleepDuration != null ||
        waterIntake != null ||
        takesMedication != null ||
        (mealPhotos?.isNotEmpty ?? false);
  }

  /// Reset all data but keep the object structure
  void clearData() {
    height = null;
    weight = null;
    bloodGlucose = null;
    glucoseUnit = 'mmol/L';
    physicalActivityDuration = null;
    stressLevel = null;
    sleepDuration = null;
    waterIntake = null;
    takesMedication = null;
    medicationAdherence = null;
    mealPhotos = null;
    mealPhotosProcessed = null;
    dietAssessment = null;
    currentStep = 1;
    lastUpdated = DateTime.now();
    completedSteps.clear();
    isComplete = false;
    isFirstTime = true;
  }

  @override
  String toString() {
    return 'DiabetesAssessmentCache(step: $currentStep, completed: $completedStepsCount/8, hasData: $hasData)';
  }
}
