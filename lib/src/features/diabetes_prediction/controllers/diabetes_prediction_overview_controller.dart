import 'dart:async';
import 'package:flutter/animation.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/health_log/health_log_repository.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../../../features/personalization/models/user_profile_model.dart';
import '../../authentication/models/user_model.dart';
import '../views/diabetes_input/blood_glucose_input_screen.dart';
import '../views/diabetes_input/height_weight_input_screen.dart';
import '../views/diabetes_input/meal_photos_upload_screen.dart';
import '../views/diabetes_input/medication_adherence_input_screen.dart';
import '../views/diabetes_input/physical_activity_input_screen.dart';
import '../views/diabetes_input/sleep_duration_input_screen.dart';
import '../views/diabetes_input/stress_level_input_screen.dart';
import '../views/diabetes_input/water_intake_input_screen.dart';
import '../views/diabetes_input/widgets/diabetes_prediction_input_screen.dart';
import '../../../services/diabetes_hive_storage_manager.dart';

class DiabetesPredictionOverviewController extends GetxController {
  static DiabetesPredictionOverviewController get instance => Get.find();

  final UserRepository _userRepository = Get.put(UserRepository());
  final HealthLogRepository _healthLogRepository = Get.put(HealthLogRepository());
  final DiabetesHiveStorageManager _storageManager = DiabetesHiveStorageManager.instance;

  // Observable variables
  final RxBool isLoading = false.obs;
  final RxInt completedSteps = 0.obs;
  final RxMap<int, String> stepValues = <int, String>{}.obs;
  final RxMap<int, bool> syncAvailable = <int, bool>{}.obs;

  // Current user data
  String userId = '';
  UserProfileModel? userProfile;

  // Stream subscription
  StreamSubscription<UserModel>? _userStreamSubscription;
  StreamSubscription<BoxEvent>? _hiveStreamSubscription;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    _userStreamSubscription?.cancel();
    _hiveStreamSubscription?.cancel();
    super.onClose();
  }

  /// Initialize the controller
  Future<void> _initialize() async {
    try {
      isLoading.value = true;

      // Get current user ID
      final userData = await _userRepository.fetchUserDetails();
      userId = userData.userId;
      userProfile = userData.profile;

      // Initial load from cache
      await _loadProgressFromCache();
      await _checkSyncAvailability();

      // Setup real-time listener for health logs updates
      _setupUserStream();
      _setupHiveListener();
    } catch (e) {
      print('Error initializing overview: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Setup real-time user data stream (for health logs)
  void _setupUserStream() {
    _userStreamSubscription = _userRepository.streamUserDetails().listen(
          (userData) async {
        userProfile = userData.profile;
        // Reload sync availability when user data changes
        await _checkSyncAvailability();
      },
      onError: (error) {
        print('Error in user stream: $error');
      },
    );
  }

  /// Setup Hive data change listener
  void _setupHiveListener() {
    // 监听 Hive box 的变化
    _hiveStreamSubscription = _storageManager.watchChanges().listen((_) {
      // 当 Hive 数据变化时，重新加载进度
      _loadProgressFromCache();
      _checkSyncAvailability();
    });
  }

  /// Load progress from Hive cache
  Future<void> _loadProgressFromCache() async {
    try {
      final cache = _storageManager.getCachedAssessment();
      if (cache == null) {
        completedSteps.value = 0;
        return;
      }

      // Step 1: Height & Weight
      if (cache.isStepCompleted(1)) {
        if (cache.height != null && cache.weight != null) {
          stepValues[1] = '${cache.height!.toInt()} cm, ${cache.weight!.toStringAsFixed(1)} kg';
        }
      }

      // Step 2: Blood Glucose
      if (cache.isStepCompleted(2)) {
        if (cache.bloodGlucose != null) {
          stepValues[2] = '${cache.bloodGlucose!.toInt()} ${cache.glucoseUnit}';
        }
      }

      // Step 3: Physical Activity
      if (cache.isStepCompleted(3)) {
        if (cache.physicalActivityDuration != null) {
          if (cache.physicalActivityDuration == 0) {
            stepValues[3] = 'No regular activity';
          } else {
            stepValues[3] = '${cache.physicalActivityDuration} min/day';
          }
        }
      }

      // Step 4: Stress Level
      if (cache.isStepCompleted(4)) {
        if (cache.stressLevel != null) {
          stepValues[4] = cache.stressLevel.toString();
        }
      }

      // Step 5: Sleep Duration
      if (cache.isStepCompleted(5)) {
        if (cache.sleepDuration != null) {
          stepValues[5] = '${cache.sleepDuration} hours';
        }
      }

      // Step 6: Water Intake
      if (cache.isStepCompleted(6)) {
        if (cache.waterIntake != null) {
          stepValues[6] = '${cache.waterIntake} ml/day';
        }
      }

      // Step 7: Medicine Prescribed
      if (cache.isStepCompleted(7)) {
        if (cache.takesMedication == true) {
          stepValues[7] = 'Yes, ${cache.medicationAdherence}x/day';
        } else {
          stepValues[7] = 'No medication';
        }
      }

      // Step 8: Meal Photos & Diet Assessment
      if (cache.isStepCompleted(8)) {
        if (cache.mealPhotosProcessed == true && cache.dietAssessment != null) {
          final assessment = cache.dietAssessment!;
          stepValues[8] = assessment.isHealthy
              ? 'Healthy (${cache.mealPhotos?.length ?? 0} photos)'
              : 'Needs Improvement (${cache.mealPhotos?.length ?? 0} photos)';
        } else if (cache.mealPhotos != null && cache.mealPhotos!.isNotEmpty) {
          stepValues[8] = '${cache.mealPhotos!.length} photos uploaded';
        }
      }

      // Update completed count
      completedSteps.value = cache.completedStepsCount;

    } catch (e) {
      print('Error loading progress from cache: $e');
    }
  }

  /// Check if sync is available for steps with health logs
  Future<void> _checkSyncAvailability() async {
    try {
      final threeDaysAgo = DateTime.now().subtract(Duration(days: 3));
      final sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));
      final now = DateTime.now();

      final cache = _storageManager.getCachedAssessment();

      // Step 1: Weight - Check if health logs differ from cache
      final weightLogs = await _healthLogRepository.getBodyCompositionLogsStream(
        userId,
        threeDaysAgo,
        now,
      ).first;

      if (weightLogs.isNotEmpty) {
        final latestWeight = weightLogs.first.bodyComposition.weight;
        final cachedWeight = cache?.weight;

        if (cachedWeight != null) {
          syncAvailable[1] = latestWeight != cachedWeight && latestWeight > 0;
        } else if (latestWeight > 0) {
          syncAvailable[1] = true;
        }
      }

      // Step 2: Blood Glucose
      final glucoseLogs = await _healthLogRepository.getBloodGlucoseLogsStream(
        userId,
        threeDaysAgo,
        now,
      ).first;

      if (glucoseLogs.isNotEmpty) {
        final latestGlucose = glucoseLogs.first.bloodGlucose.glucoseLevel;
        final glucoseMgDl = latestGlucose * 18;
        final cachedGlucose = cache?.bloodGlucose;

        if (cachedGlucose != null) {
          syncAvailable[2] = glucoseMgDl != cachedGlucose && glucoseMgDl > 0;
        } else if (glucoseMgDl > 0) {
          syncAvailable[2] = true;
        }
      }

      // Step 3: Physical Activity - Calculate 7-day average
      final activityLogs = await _healthLogRepository.getPhysicalActivityLogsStream(
        userId,
        sevenDaysAgo,
        now,
      ).first;

      if (activityLogs.isNotEmpty) {
        final totalDuration = activityLogs.fold<int>(
          0,
              (sum, log) => sum + log.physicalActivity.duration,
        );
        final averageDuration = (totalDuration / activityLogs.length).round();
        final cachedDuration = cache?.physicalActivityDuration;

        if (cachedDuration != null) {
          syncAvailable[3] = averageDuration != cachedDuration && averageDuration > 0;
        } else if (averageDuration > 0) {
          syncAvailable[3] = true;
        }
      }

    } catch (e) {
      print('Error checking sync availability: $e');
    }
  }

  /// Check if a step is completed
  bool isStepCompleted(int stepNumber) {
    return stepValues.containsKey(stepNumber) && stepValues[stepNumber]!.isNotEmpty;
  }

  /// Get step value display text
  String? getStepValue(int stepNumber) {
    return stepValues[stepNumber];
  }

  /// Check if sync button should be shown
  bool shouldShowSync(int stepNumber) {
    return syncAvailable[stepNumber] == true;
  }

  /// Sync step data from health logs to cache
  Future<void> syncStep(int stepNumber) async {
    try {
      isLoading.value = true;

      switch (stepNumber) {
        case 1: // Weight
          await _syncWeight();
          break;
        case 2: // Blood Glucose
          await _syncBloodGlucose();
          break;
        case 3: // Physical Activity
          await _syncPhysicalActivity();
          break;
      }

      // Refresh data
      await _loadProgressFromCache();
      await _checkSyncAvailability();

      TLoaders.successSnackBar(
        title: 'Synced',
        message: 'Data synced from health logs to cache',
      );

    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to sync data: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Sync weight from health logs to cache
  Future<void> _syncWeight() async {
    final threeDaysAgo = DateTime.now().subtract(Duration(days: 3));
    final weightLogs = await _healthLogRepository.getBodyCompositionLogsStream(
      userId,
      threeDaysAgo,
      DateTime.now(),
    ).first;

    if (weightLogs.isNotEmpty) {
      final latestWeight = weightLogs.first.bodyComposition.weight;
      if (latestWeight > 0) {
        final cache = _storageManager.getCachedAssessment();
        await _storageManager.updateStepData(1, {
          'height': cache?.height ?? 170.0, // Keep existing height
          'weight': latestWeight,
        });
      }
    }
  }

  /// Sync blood glucose from health logs to cache
  Future<void> _syncBloodGlucose() async {
    final threeDaysAgo = DateTime.now().subtract(Duration(days: 3));
    final glucoseLogs = await _healthLogRepository.getBloodGlucoseLogsStream(
      userId,
      threeDaysAgo,
      DateTime.now(),
    ).first;

    if (glucoseLogs.isNotEmpty) {
      final latestGlucose = glucoseLogs.first.bloodGlucose.glucoseLevel;
      final glucoseMgDl = latestGlucose * 18;

      if (glucoseMgDl > 0) {
        await _storageManager.updateStepData(2, {
          'glucose': glucoseMgDl,
          'unit': 'mg/dL',
        });
      }
    }
  }

  /// Sync physical activity from health logs to cache
  Future<void> _syncPhysicalActivity() async {
    final sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));
    final activityLogs = await _healthLogRepository.getPhysicalActivityLogsStream(
      userId,
      sevenDaysAgo,
      DateTime.now(),
    ).first;

    if (activityLogs.isNotEmpty) {
      final totalDuration = activityLogs.fold<int>(
        0,
            (sum, log) => sum + log.physicalActivity.duration,
      );
      final averageDuration = (totalDuration / activityLogs.length).round();

      if (averageDuration >= 0) {
        await _storageManager.updateStepData(3, {
          'duration': averageDuration,
        });
      }
    }
  }

  /// Navigate to specific step
  void navigateToStep(int stepNumber) {
    final cache = _storageManager.getCachedAssessment();

    switch (stepNumber) {
      case 1:
        Get.to(
              () => HeightWeightInputScreen(
            initialHeight: cache?.height,
            initialWeight: cache?.weight,
            mode: NavigationMode.edit,
          ),
          transition: Transition.downToUp,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        break;
      case 2:
        Get.to(
              () => BloodGlucoseInputScreen(
            initialGlucoseValue: cache?.bloodGlucose,
            mode: NavigationMode.edit,
          ),
          transition: Transition.downToUp,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        break;
      case 3:
        Get.to(
              () => PhysicalActivityInputScreen(
            initialDuration: cache?.physicalActivityDuration,
            mode: NavigationMode.edit,
          ),
          transition: Transition.downToUp,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        break;
      case 4:
        Get.to(
              () => StressLevelInputScreen(
            initialStressLevel: cache?.stressLevel,
            mode: NavigationMode.edit,
          ),
          transition: Transition.downToUp,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        break;
      case 5:
        Get.to(
              () => SleepDurationInputScreen(
            initialSleepDuration: cache?.sleepDuration,
            mode: NavigationMode.edit,
          ),
          transition: Transition.downToUp,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        break;
      case 6:
        Get.to(
              () => WaterIntakeInputScreen(
            initialWaterIntake: cache?.waterIntake,
            mode: NavigationMode.edit,
          ),
          transition: Transition.downToUp,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        break;
      case 7:
        Get.to(
              () => MedicationAdherenceInputScreen(
            initialTakesMedication: cache?.takesMedication,
            initialAdherencePercentage: cache?.medicationAdherence,
            mode: NavigationMode.edit,
          ),
          transition: Transition.downToUp,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        break;
      case 8:
        Get.to(
              () => MealPhotosUploadScreen(
            mode: NavigationMode.edit,
          ),
          transition: Transition.downToUp,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        break;
      default:
        TLoaders.warningSnackBar(
          title: 'Coming Soon',
          message: 'This step is not yet available',
        );
    }
  }

  /// Check if all steps are completed
  RxBool get allStepsCompleted => (completedSteps.value == 8).obs;

  /// Start prediction - Export to Firestore and navigate to results
  Future<void> startPrediction() async {
    try {
      isLoading.value = true;

      // Export assessment data for prediction
      final assessmentData = _storageManager.exportToFirestore();

      if (assessmentData == null) {
        TLoaders.errorSnackBar(
          title: 'Error',
          message: 'Assessment data is incomplete',
        );
        return;
      }

      // TODO: Call prediction API and save to Firestore history
      // await _predictionService.predict(assessmentData);

      TLoaders.successSnackBar(
        title: 'Ready',
        message: 'Starting diabetes risk prediction...',
      );

      // Navigate to results (implement later)
      // Get.toNamed('/prediction-results');

    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to start prediction: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset progress (Clear cache)
  Future<void> resetProgress() async {
    await _storageManager.clearCache();
    stepValues.clear();
    completedSteps.value = 0;
    syncAvailable.clear();
  }
}