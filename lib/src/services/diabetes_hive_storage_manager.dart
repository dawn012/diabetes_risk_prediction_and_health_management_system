import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

  late Box<DiabetesAssessmentCache> _assessmentBox;
  late Box _prefsBox; // 用于存储简单偏好设置

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeHive();
  }

  /// Initialize Hive
  Future<void> _initializeHive() async {
    try {
      // Register adapters
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

      // Open boxes
      _assessmentBox = await Hive.openBox<DiabetesAssessmentCache>(_boxName);
      _prefsBox = await Hive.openBox('diabetes_preferences');
    } catch (e) {
      print('Error initializing Hive: $e');
      rethrow;
    }
  }

  // ========== 原有 SharedPreferences 功能迁移 ==========

  /// Check if this is user's first time doing prediction
  bool isFirstTime() {
    return _prefsBox.get(_firstTimeKey, defaultValue: true);
  }

  /// Mark that user has started prediction flow
  Future<void> setFirstTimeComplete() async {
    await _prefsBox.put(_firstTimeKey, false);
  }

  /// Mark prediction as incomplete (user exited mid-flow)
  Future<void> markIncomplete(bool incomplete) async {
    await _prefsBox.put('is_incomplete', incomplete);
  }

  /// Check if there's incomplete prediction
  bool hasIncompletePrediction() {
    return _prefsBox.get('is_incomplete', defaultValue: false);
  }

  /// Clear all prediction progress
  Future<void> clearPredictionProgress() async {
    await _assessmentBox.delete(_cacheKey);
    await _prefsBox.put('is_incomplete', false);
  }

  /// Reset to first time state
  Future<void> resetToFirstTime() async {
    await clearPredictionProgress();
    await _prefsBox.put(_firstTimeKey, true);
  }

  // ========== 缓存管理功能 ==========

  /// Get current cached assessment
  DiabetesAssessmentCache? getCachedAssessment() {
    return _assessmentBox.get(_cacheKey);
  }

  /// Check if cache exists
  bool hasCachedAssessment() {
    final cache = _assessmentBox.get(_cacheKey);
    return cache != null && cache.hasData;
  }

  /// Save assessment cache
  Future<void> saveAssessment(DiabetesAssessmentCache cache) async {
    await _assessmentBox.put(_cacheKey, cache);
  }

  /// Update specific step data
  Future<void> updateStepData(int step, Map<String, dynamic> data, {bool markComplete = false}) async {
    var cache = getCachedAssessment() ?? DiabetesAssessmentCache.empty();

    switch (step) {
      case 1: // Height & Weight
        cache = cache.copyWith(
          height: data['height'],
          weight: data['weight'],
          currentStep: step,
        );
        cache.markStepCompleted(1, true);
        break;

      case 2: // Blood Glucose
        cache = cache.copyWith(
          bloodGlucose: data['glucose'],
          glucoseUnit: data['unit'],
          currentStep: step,
        );
        cache.markStepCompleted(2, true);
        break;

      case 3: // Physical Activity
        cache = cache.copyWith(
          physicalActivityDuration: data['duration'],
          currentStep: step,
        );
        cache.markStepCompleted(3, true);
        break;

      case 4: // Stress Level
        cache = cache.copyWith(
          stressLevel: data['stressLevel'],
          currentStep: step,
        );
        cache.markStepCompleted(4, true);
        break;

      case 5: // Sleep Duration
        cache = cache.copyWith(
          sleepDuration: data['sleepDuration'],
          currentStep: step,
        );
        cache.markStepCompleted(5, true);
        break;

      case 6: // Water Intake
        cache = cache.copyWith(
          waterIntake: data['waterIntake'],
          currentStep: step,
        );
        cache.markStepCompleted(6, true);
        break;

      case 7: // Medication
        cache = cache.copyWith(
          takesMedication: data['takesMedication'],
          medicationAdherence: data['adherencePercentage'],
          currentStep: step,
        );
        cache.markStepCompleted(7, true);
        break;

      case 8: // Diet/Meal Photos
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
    await markIncomplete(true); // 标记为有未完成进度
  }

  /// Mark step as completed
  Future<void> markStepCompleted(int step, bool completed) async {
    var cache = getCachedAssessment() ?? DiabetesAssessmentCache.empty();
    cache.markStepCompleted(step, completed);
    await saveAssessment(cache);

    if (completed && step == 8) {
      await markIncomplete(false); // 完成所有步骤，标记为完成
    } else {
      await markIncomplete(true); // 有步骤完成但不是全部，标记为未完成
    }
  }

  /// Get current step
  int getCurrentStep() {
    final cache = getCachedAssessment();
    return cache?.currentStep ?? 1;
  }

  /// Get last completed step
  int getLastCompletedStep() {
    final cache = getCachedAssessment();
    if (cache == null) return 0;

    for (int i = 8; i >= 1; i--) {
      if (cache.isStepCompleted(i)) return i;
    }
    return 0;
  }

  /// Get next incomplete step
  int getNextIncompleteStep() {
    final cache = getCachedAssessment();
    if (cache == null) return 1;

    for (int i = 1; i <= 8; i++) {
      if (!cache.isStepCompleted(i)) return i;
    }
    return 1; // All completed, return first
  }

  /// Get completed steps count
  int getCompletedStepsCount() {
    final cache = getCachedAssessment();
    return cache?.completedStepsCount ?? 0;
  }

  /// Check if step is completed
  bool isStepCompleted(int step) {
    final cache = getCachedAssessment();
    return cache?.isStepCompleted(step) ?? false;
  }

  /// Get progress percentage
  double getProgressPercentage() {
    final cache = getCachedAssessment();
    return cache?.progressPercentage ?? 0.0;
  }

  /// Check if all steps completed
  bool isAllStepsCompleted() {
    return getCompletedStepsCount() == 8;
  }

  /// Mark assessment as complete
  Future<void> markAssessmentComplete() async {
    var cache = getCachedAssessment();
    if (cache != null) {
      cache = cache.copyWith(isComplete: true);
      await saveAssessment(cache);
      await markIncomplete(false);
      await setFirstTimeComplete();
    }
  }

  /// Clear cached assessment (Start New)
  Future<void> clearCache() async {
    await _assessmentBox.delete(_cacheKey);
    await markIncomplete(false);
  }

  /// Get step-specific data
  Map<String, dynamic>? getStepData(int step) {
    final cache = getCachedAssessment();
    if (cache == null) return null;

    switch (step) {
      case 1:
        return {
          'height': cache.height,
          'weight': cache.weight,
        };
      case 2:
        return {
          'glucose': cache.bloodGlucose,
          'unit': cache.glucoseUnit,
        };
      case 3:
        return {
          'duration': cache.physicalActivityDuration,
        };
      case 4:
        return {
          'level': cache.stressLevel,
        };
      case 5:
        return {
          'duration': cache.sleepDuration,
        };
      case 6:
        return {
          'intake': cache.waterIntake,
        };
      case 7:
        return {
          'takesMedication': cache.takesMedication,
          'adherence': cache.medicationAdherence,
        };
      case 8:
        return {
          'mealPhotos': cache.mealPhotos,
        };
      default:
        return null;
    }
  }

  /// Pre-fill from user profile
  Future<void> prefillFromProfile(Map<String, dynamic> profileData) async {
    var cache = getCachedAssessment();

    // Only prefill if no cache exists or cache is empty
    if (cache == null || !cache.hasData) {
      cache = DiabetesAssessmentCache.empty();

      // Only prefill height and weight from profile
      if (profileData['height'] != null && profileData['height'] > 0) {
        cache = cache.copyWith(height: profileData['height']);
      }
      if (profileData['weight'] != null && profileData['weight'] > 0) {
        cache = cache.copyWith(weight: profileData['weight']);
      }

      await saveAssessment(cache);
    }
  }

  /// Get summary for display
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

  /// Get all steps status summary
  Map<String, dynamic> getProgressSummary() {
    final cache = getCachedAssessment();
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

  /// Check if user can navigate back to a step
  bool canNavigateBackTo(int targetStep) {
    final lastStep = getLastCompletedStep();
    return targetStep <= lastStep;
  }

  // ========== Hive 监听功能 ==========

  /// Watch for changes in the assessment cache
  Stream<BoxEvent> watchChanges() {
    return _assessmentBox.watch(key: _cacheKey);
  }

  /// Watch for specific step changes
  Stream<BoxEvent> watchStepChanges(int step) {
    return _assessmentBox.watch().where((event) {
      // 检查是否是当前缓存的改变
      if (event.key == _cacheKey && event.value is DiabetesAssessmentCache) {
        final cache = event.value as DiabetesAssessmentCache;
        // 检查指定步骤的数据是否改变
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
            return cache.takesMedication != null || cache.medicationAdherence != null;
          case 8:
            return cache.mealPhotos != null || cache.dietAssessment != null;
          default:
            return false;
        }
      }
      return false;
    });
  }

  /// Watch for completion status changes
  Stream<bool> watchStepCompletion(int step) {
    return _assessmentBox.watch(key: _cacheKey).map((event) {
      if (event.value is DiabetesAssessmentCache) {
        final cache = event.value as DiabetesAssessmentCache;
        return cache.isStepCompleted(step);
      }
      return false;
    });
  }

  /// Watch for overall progress changes
  Stream<int> watchProgressChanges() {
    return _assessmentBox.watch(key: _cacheKey).map((event) {
      if (event.value is DiabetesAssessmentCache) {
        final cache = event.value as DiabetesAssessmentCache;
        return cache.completedStepsCount;
      }
      return 0;
    });
  }

  /// Force refresh the cache (useful for manual updates)
  Future<void> refreshCache() async {
    // 这个方法主要是为了触发监听器
    final current = getCachedAssessment();
    if (current != null) {
      await saveAssessment(current); // 重新保存以触发监听
    }
  }

  /// Export cache to Firestore format (when user completes prediction)
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

    // 获取 stress category (0, 1, 2)
    final stressCategory = DiabetesCategoryHelper.getStressCategory(cache.stressLevel!);

    // 获取 water intake category
    final waterIntakeCategory = DiabetesCategoryHelper.getHydrationStatusBinary(cache.waterIntake!, gender: user.profile.gender, age: user.profile.age);

    // 获取 medication category
    final medicationCategory = DiabetesCategoryHelper.getMedicationAdherentBinary(
        cache.takesMedication!,
        cache.medicationAdherence
    );

    // 获取 diet health (0 or 1)
    final dietHealthy = DiabetesCategoryHelper.getDietHealthyBinary(cache.dietAssessment!.isHealthy);

    return {
      // 直接使用输入值
      'height': cache.height,
      'weight': cache.weight,
      'bloodGlucose': cache.bloodGlucose,
      'physicalActivityDuration': cache.physicalActivityDuration,
      'sleepDuration': cache.sleepDuration,

      // 使用分类值
      'stressLevel': stressCategory, // 0, 1, 2
      'waterIntake': waterIntakeCategory, // 分类值
      'medicationAdherence': medicationCategory, // 分类值
      'dietHealthy': dietHealthy, // 0 or 1

      // 'mealPhotos': _convertMealPhotosForExport(cache.mealPhotos!),

      // 元数据
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