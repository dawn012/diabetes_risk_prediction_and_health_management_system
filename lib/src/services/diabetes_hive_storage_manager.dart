import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/diabetes_prediction/models/detected_food_model.dart';
import '../features/diabetes_prediction/models/diabetes_assessment_cache_model.dart';
import '../features/diabetes_prediction/models/diet_assessment_report_model.dart';
import '../features/diabetes_prediction/models/meal_analysis_result_model.dart';
import '../features/diabetes_prediction/models/meal_photo_record_model.dart';
import '../features/diabetes_prediction/utils/diabetes_category_helper.dart';
import '../features/personalization/controllers/user_controller.dart';

class DiabetesHiveStorageManager extends GetxService {
  static DiabetesHiveStorageManager get instance => Get.find();

  static const String _boxName = 'diabetes_assessment';
  static const String _cacheKey = 'current_assessment';
  static const String _firstTimeKey = 'is_first_time';
  static const String _incompleteKey = 'is_incomplete';

  late Box<DiabetesAssessmentCache> _assessmentBox;
  late Box _prefsBox;

  String _userKey(String baseKey) {
    final uid = UserController.instance.user.value.userId;
    if (uid.isEmpty) return baseKey;
    return '${uid}_$baseKey';
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeHive();
  }

  Future<void> _initializeHive() async {
    try {
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(DiabetesAssessmentCacheAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(MealPhotoRecordAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(DietAssessmentReportAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(MealAnalysisResultAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(DetectedFoodAdapter());
      }

      _assessmentBox = await Hive.openBox<DiabetesAssessmentCache>(_boxName);
      _prefsBox = await Hive.openBox('diabetes_preferences');
    } catch (e) {
      print('Error initializing Hive: $e');
      rethrow;
    }
  }

  // ========== 原有 SharedPreferences 功能迁移 ==========

  bool isFirstTime() {
    return _prefsBox.get(_userKey(_firstTimeKey), defaultValue: true);
  }

  Future<void> setFirstTimeComplete() async {
    await _prefsBox.put(_userKey(_firstTimeKey), false);
  }

  Future<void> markIncomplete(bool incomplete) async {
    await _prefsBox.put(_userKey(_incompleteKey), incomplete);
  }

  bool hasIncompletePrediction() {
    return _prefsBox.get(_userKey(_incompleteKey), defaultValue: false);
  }

  Future<void> clearPredictionProgress() async {
    await _assessmentBox.delete(_userKey(_cacheKey));
    await _prefsBox.put(_userKey(_incompleteKey), false);
  }

  Future<void> resetToFirstTime() async {
    await clearPredictionProgress();
    await _prefsBox.put(_userKey(_firstTimeKey), true);
  }

  // ========== 缓存管理功能 ==========

  DiabetesAssessmentCache? getCachedAssessment() {
    return _assessmentBox.get(_userKey(_cacheKey));
  }

  bool hasCachedAssessment() {
    final cache = _assessmentBox.get(_userKey(_cacheKey));
    return cache != null && cache.hasData;
  }

  Future<void> saveAssessment(DiabetesAssessmentCache cache) async {
    await _assessmentBox.put(_userKey(_cacheKey), cache);
  }

  Future<void> updateStepData(
      int step,
      Map<String, dynamic> data, {
        bool markComplete = false,
      }) async {
    var cache = getCachedAssessment() ?? DiabetesAssessmentCache.empty();

    switch (step) {
      case 1:
        cache = cache.copyWith(
          height: data['height'],
          weight: data['weight'],
          currentStep: step,
        );
        cache.markStepCompleted(1, true);
        break;
      case 2:
        cache = cache.copyWith(
          bloodGlucose: data['glucose'],
          glucoseUnit: data['unit'],
          currentStep: step,
        );
        cache.markStepCompleted(2, true);
        break;
      case 3:
        cache = cache.copyWith(
          physicalActivityDuration: data['duration'],
          currentStep: step,
        );
        cache.markStepCompleted(3, true);
        break;
      case 4:
        cache = cache.copyWith(
          stressLevel: data['stressLevel'],
          currentStep: step,
        );
        cache.markStepCompleted(4, true);
        break;
      case 5:
        cache = cache.copyWith(
          sleepDuration: data['sleepDuration'],
          currentStep: step,
        );
        cache.markStepCompleted(5, true);
        break;
      case 6:
        cache = cache.copyWith(
          waterIntake: data['waterIntake'],
          currentStep: step,
        );
        cache.markStepCompleted(6, true);
        break;
      case 7:
        cache = cache.copyWith(
          takesMedication: data['takesMedication'],
          medicationAdherence: data['adherencePercentage'],
          currentStep: step,
        );
        cache.markStepCompleted(7, true);
        break;
      case 8:
        cache = cache.copyWith(
          mealPhotos: data['mealPhotos'],
          mealPhotosProcessed: data['mealPhotosProcessed'] ?? false,
          dietAssessment: data['dietAssessment'],
          currentStep: step,
        );
        cache.markStepCompleted(8, markComplete);
        break;
    }

    await saveAssessment(cache);
    await markIncomplete(true);
  }

  Future<void> markStepCompleted(int step, bool completed) async {
    var cache = getCachedAssessment() ?? DiabetesAssessmentCache.empty();
    cache.markStepCompleted(step, completed);
    await saveAssessment(cache);

    if (completed && step == 8) {
      await markIncomplete(false);
    } else {
      await markIncomplete(true);
    }
  }

  int getCurrentStep() {
    final cache = getCachedAssessment();
    return cache?.currentStep ?? 1;
  }

  int getLastCompletedStep() {
    final cache = getCachedAssessment();
    if (cache == null) return 0;

    for (int i = 8; i >= 1; i--) {
      if (cache.isStepCompleted(i)) return i;
    }
    return 0;
  }

  int getNextIncompleteStep() {
    final cache = getCachedAssessment();
    if (cache == null) return 1;

    for (int i = 1; i <= 8; i++) {
      if (!cache.isStepCompleted(i)) return i;
    }
    return 1;
  }

  int getCompletedStepsCount() {
    final cache = getCachedAssessment();
    return cache?.completedStepsCount ?? 0;
  }

  bool isStepCompleted(int step) {
    final cache = getCachedAssessment();
    return cache?.isStepCompleted(step) ?? false;
  }

  double getProgressPercentage() {
    final cache = getCachedAssessment();
    return cache?.progressPercentage ?? 0.0;
  }

  bool isAllStepsCompleted() {
    return getCompletedStepsCount() == 8;
  }

  Future<void> markAssessmentComplete() async {
    var cache = getCachedAssessment();
    if (cache != null) {
      cache = cache.copyWith(isComplete: true);
      await saveAssessment(cache);
      await markIncomplete(false);
      await setFirstTimeComplete();
    }
  }

  Future<void> clearCache() async {
    await _assessmentBox.delete(_userKey(_cacheKey));
    await markIncomplete(false);
  }

  Map<String, dynamic>? getStepData(int step) {
    final cache = getCachedAssessment();
    if (cache == null) return null;

    switch (step) {
      case 1:
        return {'height': cache.height, 'weight': cache.weight};
      case 2:
        return {'glucose': cache.bloodGlucose, 'unit': cache.glucoseUnit};
      case 3:
        return {'duration': cache.physicalActivityDuration};
      case 4:
        return {'level': cache.stressLevel};
      case 5:
        return {'duration': cache.sleepDuration};
      case 6:
        return {'intake': cache.waterIntake};
      case 7:
        return {
          'takesMedication': cache.takesMedication,
          'adherence': cache.medicationAdherence,
        };
      case 8:
        return {'mealPhotos': cache.mealPhotos};
      default:
        return null;
    }
  }

  Future<void> prefillFromProfile(Map<String, dynamic> profileData) async {
    var cache = getCachedAssessment();

    if (cache == null || !cache.hasData) {
      cache = DiabetesAssessmentCache.empty();

      if (profileData['height'] != null && profileData['height'] > 0) {
        cache = cache.copyWith(height: profileData['height']);
      }
      if (profileData['weight'] != null && profileData['weight'] > 0) {
        cache = cache.copyWith(weight: profileData['weight']);
      }

      await saveAssessment(cache);
    }
  }

  Map<String, dynamic> getSummary() {
    final cache = getCachedAssessment();
    if (cache == null) {
      return {
        'hasCache': false,
        'currentStep': 1,
        'completedCount': 0,
        'progressPercentage': 0.0,
        'lastUpdated': null,
        'isFirstTime': isFirstTime(),
        'isIncomplete': hasIncompletePrediction(),
      };
    }

    return {
      'hasCache': true,
      'currentStep': cache.currentStep,
      'completedCount': cache.completedStepsCount,
      'progressPercentage': cache.progressPercentage,
      'lastUpdated': cache.lastUpdated,
      'isComplete': cache.isComplete,
      'isFirstTime': isFirstTime(),
      'isIncomplete': hasIncompletePrediction(),
    };
  }

  Map<String, dynamic> getProgressSummary() {
    final completedCount = getCompletedStepsCount();

    Map<String, bool> progress = {};
    for (int i = 1; i <= 8; i++) {
      progress['step$i'] = isStepCompleted(i);
    }

    return {
      'progress': progress,
      'lastStep': getLastCompletedStep(),
      'completedCount': completedCount,
      'isIncomplete': hasIncompletePrediction(),
      'isFirstTime': isFirstTime(),
      'progressPercentage': getProgressPercentage(),
    };
  }

  bool canNavigateBackTo(int targetStep) {
    final lastStep = getLastCompletedStep();
    return targetStep <= lastStep;
  }

  // ========== Hive 监听功能 ==========

  Stream<BoxEvent> watchChanges() {
    return _assessmentBox.watch(key: _userKey(_cacheKey));
  }

  Stream<BoxEvent> watchStepChanges(int step) {
    return _assessmentBox.watch().where((event) {
      if (event.key == _userKey(_cacheKey) &&
          event.value is DiabetesAssessmentCache) {
        final cache = event.value as DiabetesAssessmentCache;
        switch (step) {
          case 1:
            return cache.height != null || cache.weight != null;
          case 2:
            return cache.bloodGlucose != null;
          case 3:
            return cache.physicalActivityDuration != null;
          case 4:
            return cache.stressLevel != null;
          case 5:
            return cache.sleepDuration != null;
          case 6:
            return cache.waterIntake != null;
          case 7:
            return cache.takesMedication != null ||
                cache.medicationAdherence != null;
          case 8:
            return cache.mealPhotos != null || cache.dietAssessment != null;
          default:
            return false;
        }
      }
      return false;
    });
  }

  Stream<bool> watchStepCompletion(int step) {
    return _assessmentBox
        .watch(key: _userKey(_cacheKey))
        .map((event) {
      if (event.value is DiabetesAssessmentCache) {
        final cache = event.value as DiabetesAssessmentCache;
        return cache.isStepCompleted(step);
      }
      return false;
    });
  }

  Stream<int> watchProgressChanges() {
    return _assessmentBox
        .watch(key: _userKey(_cacheKey))
        .map((event) {
      if (event.value is DiabetesAssessmentCache) {
        final cache = event.value as DiabetesAssessmentCache;
        return cache.completedStepsCount;
      }
      return 0;
    });
  }

  Future<void> refreshCache() async {
    final current = getCachedAssessment();
    if (current != null) {
      await saveAssessment(current);
    }
  }

  Map<String, dynamic>? exportToFirestore() {
    final cache = getCachedAssessment();
    if (cache == null) return null;

    final user = UserController.instance.user.value;

    final hasRequiredData =
        cache.height != null &&
            cache.weight != null &&
            cache.bloodGlucose != null &&
            cache.physicalActivityDuration != null &&
            cache.stressLevel != null &&
            cache.sleepDuration != null &&
            cache.waterIntake != null &&
            cache.takesMedication != null &&
            cache.mealPhotos != null &&
            cache.mealPhotos!.isNotEmpty &&
            cache.dietAssessment != null;

    if (!hasRequiredData) {
      print('Missing required data for export:');
      print('   height: ${cache.height}');
      print('   weight: ${cache.weight}');
      print('   bloodGlucose: ${cache.bloodGlucose}');
      print('   physicalActivityDuration: ${cache.physicalActivityDuration}');
      print('   stressLevel: ${cache.stressLevel}');
      print('   sleepDuration: ${cache.sleepDuration}');
      print('   waterIntake: ${cache.waterIntake}');
      print('   takesMedication: ${cache.takesMedication}');
      print('   mealPhotos: ${cache.mealPhotos?.length}');
      print('   dietAssessment: ${cache.dietAssessment}');
      return null;
    }

    final stressCategory =
    DiabetesCategoryHelper.getStressCategory(cache.stressLevel!);

    final waterIntakeCategory =
    DiabetesCategoryHelper.getHydrationStatusBinary(
      cache.waterIntake!,
      gender: user.profile.gender,
      age: user.profile.age,
    );

    final medicationCategory =
    DiabetesCategoryHelper.getMedicationAdherentBinary(
      cache.takesMedication!,
      cache.medicationAdherence,
    );

    final dietHealthy =
    DiabetesCategoryHelper.getDietHealthyBinary(cache.dietAssessment!.isHealthy);

    return {
      'height': cache.height,
      'weight': cache.weight,
      'bloodGlucose': cache.bloodGlucose,
      'physicalActivityDuration': cache.physicalActivityDuration,
      'sleepDuration': cache.sleepDuration,
      'stressLevel': stressCategory,
      'waterIntake': waterIntakeCategory,
      'medicationAdherence': medicationCategory,
      'dietHealthy': dietHealthy,
      'glucoseUnit': cache.glucoseUnit,
      'assessmentDate': cache.lastUpdated.toIso8601String(),
      'completedSteps': cache.completedSteps,
    };
  }

  @override
  void onClose() {
    _assessmentBox.close();
    _prefsBox.close();
    super.onClose();
  }
}