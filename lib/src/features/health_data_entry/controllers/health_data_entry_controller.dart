import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/health_log/health_log_repository.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/validators/health_data_validator.dart';
import '../models/blood_glucose_model.dart';
import '../models/blood_pressure_model.dart';
import '../models/body_composition_model.dart';
import '../models/health_data_model.dart';
import '../models/physical_activity_model.dart';
import 'blood_glucose_controller.dart';

class HealthDataEntryController extends GetxController {
  final HealthDataModel? editData;
  final List<String>? initialSections;

  HealthDataEntryController({this.editData, this.initialSections});

  // Repositories
  final _healthLogRepo = HealthLogRepository.instance;
  final _authRepo = AuthenticationRepository.instance;

  // Observable states
  final selectedDate = DateTime.now().toLocal().obs;
  final selectedTime = TimeOfDay.now().obs;
  final selectedPeriod = PhysiologicalTimePeriod.beforeBreakfast.obs;
  final activeSections = <String>{}.obs;
  final isLoading = false.obs;

  // Text Controllers
  final glucoseController = TextEditingController();
  final systolicController = TextEditingController();
  final diastolicController = TextEditingController();
  final pulseController = TextEditingController();
  final weightController = TextEditingController();
  final bodyFatController = TextEditingController();
  final exerciseNameController = TextEditingController();
  final durationController = TextEditingController();
  final noteController = TextEditingController();

  // Intensity level
  final selectedIntensityLevel = IntensityLevel.moderate.obs;

  // Validation errors
  final fieldErrors = <String, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    if (editData != null) {
      _populateEditData();
    } else if (initialSections != null) {
      _populateInitialSections();
    }
  }

  /// 填充初始sections
  void _populateInitialSections() {
    if (initialSections != null && initialSections!.isNotEmpty) {
      for (final section in initialSections!) {
        if (!activeSections.contains(section)) {
          activeSections.add(section);
        }
      }
    }
  }

  /// Populate form with existing data for editing
  void _populateEditData() {
    final data = editData!;

    // Set date and time
    selectedDate.value = data.logDateTime;
    selectedTime.value = TimeOfDay.fromDateTime(data.logDateTime);
    selectedPeriod.value = data.physiologicalTimePeriod;

    // Populate form fields based on available data
    activeSections.clear();

    // Blood Glucose
    if (data.bloodGlucose.glucoseLevel > 0) {
      activeSections.add('Blood Glucose');
      glucoseController.text = data.bloodGlucose.glucoseLevel.toString();
    }

    // Blood Pressure
    if (data.bloodPressure.systolic > 0 ||
        data.bloodPressure.diastolic > 0 ||
        data.bloodPressure.pulse > 0) {
      activeSections.add('Blood Pressure & Pulse');
      systolicController.text = data.bloodPressure.systolic.toString();
      diastolicController.text = data.bloodPressure.diastolic.toString();
      pulseController.text = data.bloodPressure.pulse.toString();
    }

    // Body Composition
    if (data.bodyComposition.weight > 0 || data.bodyComposition.bodyFat > 0) {
      activeSections.add('Weight & Body Fat');
      weightController.text = data.bodyComposition.weight.toString();
      bodyFatController.text = data.bodyComposition.bodyFat.toString();
    }

    // Physical Activity
    if (data.physicalActivity.activityType.isNotEmpty ||
        data.physicalActivity.duration > 0) {
      activeSections.add('Exercise');
      exerciseNameController.text = data.physicalActivity.activityType;
      durationController.text = data.physicalActivity.duration.toString();
      selectedIntensityLevel.value = data.physicalActivity.intensityLevel;
    }
  }

  /// Update period
  void updatePeriod(PhysiologicalTimePeriod period) {
    selectedPeriod.value = period;
  }

  /// Update intensity level
  void updateIntensityLevel(IntensityLevel level) {
    selectedIntensityLevel.value = level;
  }

  /// Add section
  void addSection(String section) {
    if (!activeSections.contains(section)) {
      activeSections.add(section);
    }
  }

  /// Remove section
  void removeSection(String section) {
    activeSections.remove(section);
    _clearSectionControllers(section);
    _clearSectionFieldErrors(section);
  }

  /// Clear controllers for removed section
  void _clearSectionControllers(String section) {
    switch (section) {
      case 'Blood Glucose':
        glucoseController.clear();
        break;
      case 'Blood Pressure & Pulse':
        systolicController.clear();
        diastolicController.clear();
        pulseController.clear();
        break;
      case 'Weight & Body Fat':
        weightController.clear();
        bodyFatController.clear();
        break;
      case 'Exercise':
        exerciseNameController.clear();
        durationController.clear();
        selectedIntensityLevel.value = IntensityLevel.moderate;
        break;
      case 'Note':
        noteController.clear();
        break;
    }
  }

  /// Clear field errors for removed section
  void _clearSectionFieldErrors(String section) {
    switch (section) {
      case 'Blood Glucose':
        fieldErrors.remove('glucose');
        break;
      case 'Blood Pressure & Pulse':
        fieldErrors.remove('systolic');
        fieldErrors.remove('diastolic');
        fieldErrors.remove('pulse');
        break;
      case 'Weight & Body Fat':
        fieldErrors.remove('weight');
        fieldErrors.remove('bodyFat');
        break;
      case 'Exercise':
        fieldErrors.remove('activityType');
        fieldErrors.remove('duration');
        break;
    }
  }

  /// Get available sections to add
  List<String> getAvailableSections() {
    const allSections = [
      'Blood Glucose',
      'Blood Pressure & Pulse',
      'Weight & Body Fat',
      'Exercise',
      'Note',
    ];

    return allSections
        .where((section) => !activeSections.contains(section))
        .toList();
  }

  /// Clear all field errors
  void clearFieldErrors() {
    fieldErrors.clear();
  }

  /// Get error message for a specific field
  String? getFieldError(String fieldName) {
    return fieldErrors[fieldName];
  }

  /// 获取当前正在编辑的数据类型
  List<String> _getCurrentDataTypes() {
    final types = <String>[];

    if (activeSections.contains('Blood Glucose')) {
      types.add('bloodGlucose');
    }
    if (activeSections.contains('Blood Pressure & Pulse')) {
      types.add('bloodPressure');
    }
    if (activeSections.contains('Weight & Body Fat')) {
      types.add('bodyComposition');
    }
    if (activeSections.contains('Exercise')) {
      types.add('physicalActivity');
    }

    return types;
  }

  // /// 检查时间间隔是否太近（业务逻辑）
  // Future<bool> _checkTimeIntervalTooClose({
  //   required String userId,
  //   required DateTime logDateTime,
  // }) async {
  //   // 业务规则：至少10分钟间隔
  //   const minInterval = Duration(minutes: 10);
  //   final startTime = logDateTime.subtract(minInterval);
  //   final endTime = logDateTime.add(minInterval);
  //
  //   final nearbyLogs = await _healthLogRepo.findLogsInTimeRange(
  //     userId: userId,
  //     startTime: startTime,
  //     endTime: endTime,
  //     physiologicalTimePeriod: selectedPeriod.value,
  //   );
  //
  //   return nearbyLogs.isNotEmpty;
  // }

  /// 检查重复数据类型并返回需要覆盖的数据类型列表
  Future<Map<String, dynamic>?> _checkDuplicateDataType({
    required String userId,
    required DateTime logDateTime,
  }) async {
    final existingLog = await _healthLogRepo.findLogAtExactTime(
      userId: userId,
      logDateTime: logDateTime,
      physiologicalTimePeriod: selectedPeriod.value,
    );

    if (existingLog != null) {
      final dataTypes = _getCurrentDataTypes();
      final conflictingTypes = <String>[];

      for (final dataType in dataTypes) {
        if (_healthLogRepo.hasDataType(existingLog, dataType)) {
          conflictingTypes.add(dataType);
        }
      }

      if (conflictingTypes.isNotEmpty) {
        return {
          'log': existingLog,
          'conflictingTypes': conflictingTypes,
        };
      }
    }

    return null;
  }

  /// Validate form before saving
  bool _validateForm(HealthDataModel healthData) {
    clearFieldErrors();

    // Check if at least one metric is provided
    if (activeSections.isEmpty) {
      TLoaders.warningSnackBar(
        title: 'No Data',
        message: 'Please add at least one health metric to record',
      );
      return false;
    }

    bool isValid = true;

    // Validate each active section
    if (activeSections.contains('Blood Glucose')) {
      final error = HealthDataValidator.validateGlucoseLevel(
          healthData.bloodGlucose.glucoseLevel);
      if (error != null) {
        fieldErrors['glucose'] = error;
        isValid = false;
      }
    }

    if (activeSections.contains('Blood Pressure & Pulse')) {
      final systolicError = HealthDataValidator.validateSystolic(
          healthData.bloodPressure.systolic);
      if (systolicError != null) {
        fieldErrors['systolic'] = systolicError;
        isValid = false;
      }

      final diastolicError = HealthDataValidator.validateDiastolic(
          healthData.bloodPressure.diastolic);
      if (diastolicError != null) {
        fieldErrors['diastolic'] = diastolicError;
        isValid = false;
      }

      final pulseError = HealthDataValidator.validatePulse(
          healthData.bloodPressure.pulse);
      if (pulseError != null) {
        fieldErrors['pulse'] = pulseError;
        isValid = false;
      }
    }

    if (activeSections.contains('Weight & Body Fat')) {
      if (healthData.bodyComposition.weight > 0) {
        final weightError = HealthDataValidator.validateWeight(
            healthData.bodyComposition.weight);
        if (weightError != null) {
          fieldErrors['weight'] = weightError;
          isValid = false;
        }
      }

      if (healthData.bodyComposition.bodyFat > 0) {
        final bodyFatError = HealthDataValidator.validateBodyFat(
            healthData.bodyComposition.bodyFat);
        if (bodyFatError != null) {
          fieldErrors['bodyFat'] = bodyFatError;
          isValid = false;
        }
      }

      // At least one field must be filled
      if (healthData.bodyComposition.weight <= 0 &&
          healthData.bodyComposition.bodyFat <= 0) {
        fieldErrors['weight'] = 'Please enter at least weight or body fat';
        isValid = false;
      }
    }

    if (activeSections.contains('Exercise')) {
      final activityError = HealthDataValidator.validateActivityType(
          healthData.physicalActivity.activityType,
          healthData.physicalActivity.duration);
      if (activityError != null) {
        fieldErrors['activityType'] = activityError;
        isValid = false;
      }

      final durationError = HealthDataValidator.validateActivityDuration(
          healthData.physicalActivity.duration,
          healthData.physicalActivity.activityType);
      if (durationError != null) {
        fieldErrors['duration'] = durationError;
        isValid = false;
      }
    }

    if (!isValid) {
      fieldErrors.refresh();
    }

    return isValid;
  }

  /// Save health data (for new records)
  Future<void> saveHealthData() async {
    try {
      isLoading.value = true;

      final userId = _authRepo.authUser?.uid;
      if (userId == null) {
        TLoaders.errorSnackBar(
          title: 'Error',
          message: 'User not authenticated',
        );
        return;
      }

      final healthData = _createHealthDataModel();

      // Validate the data
      if (!_validateForm(healthData)) {
        return;
      }

      // // 检查时间间隔是否太近（10分钟内）
      // final isTimeTooClose = await _checkTimeIntervalTooClose(
      //   userId: userId,
      //   logDateTime: healthData.logDateTime,
      // );
      //
      // if (isTimeTooClose) {
      //   TLoaders.warningSnackBar(
      //     title: 'Time Interval Too Close',
      //     message: 'Please wait at least 10 minutes between records for the same time period',
      //   );
      //   return;
      // }

      // 检查重复数据类型
      final duplicateResult = await _checkDuplicateDataType(
        userId: userId,
        logDateTime: healthData.logDateTime,
      );

      if (duplicateResult != null) {
        final existingLog = duplicateResult['log'] as HealthDataModel;
        final conflictingTypes = duplicateResult['conflictingTypes'] as List<String>;

        // 询问用户是否覆盖冲突的数据类型
        final shouldOverride = await _showOverrideDialog(conflictingTypes);
        if (!shouldOverride) {
          return;
        }

        // 只覆盖冲突的数据类型，保留其他数据
        final mergedData = _createMergedHealthData(existingLog, healthData, conflictingTypes);
        await _healthLogRepo.updateHealthLog(userId, mergedData);

        TLoaders.successSnackBar(
          title: 'Success',
          message: '${conflictingTypes.length} data type(s) updated successfully',
        );
      } else {
        // 没有重复：创建新记录（会自动合并相同时间的记录）
        await _healthLogRepo.saveHealthLog(userId, healthData);
        TLoaders.successSnackBar(
            title: 'Success',
            message: 'Health data saved successfully'
        );
      }

      // Refresh the data controllers
      _refreshDataControllers();

      if (Get.context != null) {
        Navigator.of(Get.context!, rootNavigator: true).pop(true);
      }

    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to save health data: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Update health data (for existing records)
  Future<void> updateHealthData() async {
    try {
      isLoading.value = true;

      final userId = _authRepo.authUser?.uid;
      if (userId == null) {
        TLoaders.errorSnackBar(
          title: 'Error',
          message: 'User not authenticated',
        );
        return;
      }

      final healthData = _createHealthDataModel();

      // Validate the data
      if (!_validateForm(healthData)) {
        return;
      }

      await _healthLogRepo.updateHealthLog(userId, healthData);

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Health data updated successfully',
      );

      _refreshDataControllers();

      if (Get.context != null) {
        Navigator.of(Get.context!, rootNavigator: true).pop(true);
      }

    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to update health data: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete health data
  Future<void> deleteHealthData() async {
    if (editData == null) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'No data to delete',
      );
      return;
    }

    try {
      isLoading.value = true;

      final userId = _authRepo.authUser?.uid;
      if (userId == null) {
        TLoaders.errorSnackBar(
          title: 'Error',
          message: 'User not authenticated',
        );
        return;
      }

      await _healthLogRepo.deleteHealthLog(userId, editData!.logId);

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Health data deleted successfully',
      );

      _refreshDataControllers();

    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to delete health data: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 创建合并后的健康数据（只覆盖冲突的数据类型）
  HealthDataModel _createMergedHealthData(HealthDataModel existing, HealthDataModel newData, List<String> conflictingTypes) {
    return HealthDataModel(
      logId: existing.logId,
      logDateTime: existing.logDateTime,
      physiologicalTimePeriod: existing.physiologicalTimePeriod,

      // 血压数据：只有冲突时才覆盖，否则保留原有数据
      bloodPressure: BloodPressureModel(
        systolic: conflictingTypes.contains('bloodPressure') && newData.bloodPressure.systolic > 0
            ? newData.bloodPressure.systolic
            : existing.bloodPressure.systolic,
        diastolic: conflictingTypes.contains('bloodPressure') && newData.bloodPressure.diastolic > 0
            ? newData.bloodPressure.diastolic
            : existing.bloodPressure.diastolic,
        pulse: conflictingTypes.contains('bloodPressure') && newData.bloodPressure.pulse > 0
            ? newData.bloodPressure.pulse
            : existing.bloodPressure.pulse,
      ),

      // 血糖数据：只有冲突时才覆盖
      bloodGlucose: BloodGlucoseModel(
        glucoseLevel: conflictingTypes.contains('bloodGlucose') && newData.bloodGlucose.glucoseLevel > 0
            ? newData.bloodGlucose.glucoseLevel
            : existing.bloodGlucose.glucoseLevel,
      ),

      // 身体成分数据：只有冲突时才覆盖
      bodyComposition: BodyCompositionModel(
        weight: conflictingTypes.contains('bodyComposition') && newData.bodyComposition.weight > 0
            ? newData.bodyComposition.weight
            : existing.bodyComposition.weight,
        bodyFat: conflictingTypes.contains('bodyComposition') && newData.bodyComposition.bodyFat > 0
            ? newData.bodyComposition.bodyFat
            : existing.bodyComposition.bodyFat,
      ),

      // 运动数据：只有冲突时才覆盖
      physicalActivity: PhysicalActivityModel(
        activityType: conflictingTypes.contains('physicalActivity') && newData.physicalActivity.activityType.isNotEmpty
            ? newData.physicalActivity.activityType
            : existing.physicalActivity.activityType,
        duration: conflictingTypes.contains('physicalActivity') && newData.physicalActivity.duration > 0
            ? newData.physicalActivity.duration
            : existing.physicalActivity.duration,
        intensityLevel: conflictingTypes.contains('physicalActivity') && newData.physicalActivity.activityType.isNotEmpty
            ? newData.physicalActivity.intensityLevel
            : existing.physicalActivity.intensityLevel,
      ),
    );
  }

  /// 显示覆盖确认对话框（明确显示哪些数据类型会被覆盖）
  Future<bool> _showOverrideDialog(List<String> conflictingTypes) async {
    String dataTypesText = conflictingTypes.map((type) {
      switch (type) {
        case 'bloodGlucose': return 'blood glucose';
        case 'bloodPressure': return 'blood pressure';
        case 'bodyComposition': return 'weight & body fat';
        case 'physicalActivity': return 'exercise';
        default: return type;
      }
    }).join(', ');

    return await Get.dialog<bool>(
      AlertDialog(
        title: Text('Duplicate Data Found'),
        content: Text(
          'The following data types already exist at this time: $dataTypesText. '
              'Do you want to override these specific data types? '
              '\n\nOther existing data in this record will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              'Override Selected Data',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Create HealthDataModel from form input
  HealthDataModel _createHealthDataModel() {
    final logDateTime = DateTime(
      selectedDate.value.year,
      selectedDate.value.month,
      selectedDate.value.day,
      selectedTime.value.hour,
      selectedTime.value.minute,
    );

    return HealthDataModel(
      logId: editData?.logId ?? _generateLogId(),
      logDateTime: logDateTime,
      physiologicalTimePeriod: selectedPeriod.value,
      bloodGlucose: BloodGlucoseModel(
        glucoseLevel: activeSections.contains('Blood Glucose') &&
            glucoseController.text.isNotEmpty
            ? double.tryParse(glucoseController.text) ?? 0.0
            : editData?.bloodGlucose.glucoseLevel ?? 0.0,
      ),
      bloodPressure: BloodPressureModel(
        systolic: activeSections.contains('Blood Pressure & Pulse') &&
            systolicController.text.isNotEmpty
            ? int.tryParse(systolicController.text) ?? 0
            : editData?.bloodPressure.systolic ?? 0,
        diastolic: activeSections.contains('Blood Pressure & Pulse') &&
            diastolicController.text.isNotEmpty
            ? int.tryParse(diastolicController.text) ?? 0
            : editData?.bloodPressure.diastolic ?? 0,
        pulse: activeSections.contains('Blood Pressure & Pulse') &&
            pulseController.text.isNotEmpty
            ? int.tryParse(pulseController.text) ?? 0
            : editData?.bloodPressure.pulse ?? 0,
      ),
      bodyComposition: BodyCompositionModel(
        weight: activeSections.contains('Weight & Body Fat') &&
            weightController.text.isNotEmpty
            ? double.tryParse(weightController.text) ?? 0.0
            : editData?.bodyComposition.weight ?? 0.0,
        bodyFat: activeSections.contains('Weight & Body Fat') &&
            bodyFatController.text.isNotEmpty
            ? double.tryParse(bodyFatController.text) ?? 0.0
            : editData?.bodyComposition.bodyFat ?? 0.0,
      ),
      physicalActivity: PhysicalActivityModel(
        activityType: activeSections.contains('Exercise') &&
            exerciseNameController.text.isNotEmpty
            ? exerciseNameController.text
            : editData?.physicalActivity.activityType ?? '',
        duration: activeSections.contains('Exercise') &&
            durationController.text.isNotEmpty
            ? int.tryParse(durationController.text) ?? 0
            : editData?.physicalActivity.duration ?? 0,
        intensityLevel: activeSections.contains('Exercise')
            ? selectedIntensityLevel.value
            : editData?.physicalActivity.intensityLevel ?? IntensityLevel.moderate,
      ),
    );
  }

  /// Generate unique log ID
  String _generateLogId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Refresh data controllers
  void _refreshDataControllers() {
    if (Get.isRegistered<BloodGlucoseController>()) {
      Get.find<BloodGlucoseController>().refreshData();
    }
  }

  @override
  void onClose() {
    glucoseController.dispose();
    systolicController.dispose();
    diastolicController.dispose();
    pulseController.dispose();
    weightController.dispose();
    bodyFatController.dispose();
    exerciseNameController.dispose();
    durationController.dispose();
    noteController.dispose();
    super.onClose();
  }
}