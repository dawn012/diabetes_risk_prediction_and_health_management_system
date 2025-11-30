import '../../features/health_data_entry/models/health_data_model.dart';
import '../constants/health_data_range.dart';

class HealthDataValidator {
  HealthDataValidator._();

  /// Validate health data form
  static Map<String, String> validateHealthDataForm(HealthDataModel data) {
    final errors = <String, String>{};

    if (!_hasAtLeastOneMetric(data)) {
      errors['general'] = 'At least one health metric must be recorded';
      return errors;
    }

    if (_hasBloodPressureData(data)) {
      final bpErrors = _validateBloodPressure(data);
      if (bpErrors.isNotEmpty) errors['bloodPressure'] = bpErrors.join(', ');
    }

    if (_hasBloodGlucoseData(data)) {
      final bgErrors = _validateBloodGlucose(data);
      if (bgErrors.isNotEmpty) errors['bloodGlucose'] = bgErrors.join(', ');
    }

    if (_hasBodyCompositionData(data)) {
      final bcErrors = _validateBodyComposition(data);
      if (bcErrors.isNotEmpty) errors['bodyComposition'] = bcErrors.join(', ');
    }

    if (_hasPhysicalActivityData(data)) {
      final paErrors = _validatePhysicalActivity(data);
      if (paErrors.isNotEmpty) errors['physicalActivity'] = paErrors.join(', ');
    }

    return errors;
  }

  /// Validate systolic blood pressure
  static String? validateSystolic(int? value) {
    if (value == null) {
      return 'Please enter systolic blood pressure';
    }
    if (value < HealthDataRanges.minSystolic ||
        value > HealthDataRanges.maxSystolic) {
      return 'Systolic blood pressure must be between '
          '${HealthDataRanges.minSystolic} and ${HealthDataRanges.maxSystolic} ${HealthDataRanges.unitBloodPressure}';
    }
    return null;
  }

  /// Validate diastolic blood pressure
  static String? validateDiastolic(int? value) {
    if (value == null) {
      return 'Please enter diastolic blood pressure';
    }
    if (value < HealthDataRanges.minDiastolic ||
        value > HealthDataRanges.maxDiastolic) {
      return 'Diastolic blood pressure must be between '
          '${HealthDataRanges.minDiastolic} and ${HealthDataRanges.maxDiastolic} ${HealthDataRanges.unitBloodPressure}';
    }
    return null;
  }

  /// Validate pulse
  static String? validatePulse(int? value) {
    if (value == null) {
      return 'Please enter pulse';
    }
    if (value < HealthDataRanges.minPulse ||
        value > HealthDataRanges.maxPulse) {
      return 'Pulse must be between '
          '${HealthDataRanges.minPulse} and ${HealthDataRanges.maxPulse} ${HealthDataRanges.unitPulse}';
    }
    return null;
  }

  /// Validate blood glucose level
  static String? validateGlucoseLevel(double? value) {
    if (value == null) {
      return 'Please enter blood glucose level';
    }
    if (value < HealthDataRanges.minGlucoseMmolL ||
        value > HealthDataRanges.maxGlucoseMmolL) {
      return 'Blood glucose level must be between '
          '${HealthDataRanges.minGlucoseMmolL} and ${HealthDataRanges.maxGlucoseMmolL} ${HealthDataRanges.unitGlucose}';
    }
    return null;
  }

  /// Validate weight
  static String? validateWeight(double? value) {
    if (value == null) {
      return 'Please enter weight';
    }

    if (value < HealthDataRanges.minWeightKg ||
        value > HealthDataRanges.maxWeightKg) {
      return 'Weight must be between '
          '${HealthDataRanges.minWeightKg} and ${HealthDataRanges.maxWeightKg} ${HealthDataRanges.unitWeight}';
    }

    return null;
  }

  /// Validate body fat percentage
  static String? validateBodyFat(double? value) {
    if (value == null) {
      return 'Please enter body fat';
    }

    if (value < HealthDataRanges.minBodyFatPercent ||
        value > HealthDataRanges.maxBodyFatPercent) {
      return 'Body fat percentage must be between '
          '${HealthDataRanges.minBodyFatPercent} and ${HealthDataRanges.maxBodyFatPercent}${HealthDataRanges.unitBodyFat}';
    }

    return null;
  }

  /// Validate activity type
  static String? validateActivityType(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter activity type';
    }
    return null;
  }

  /// Validate activity duration
  static String? validateActivityDuration(int? value) {
    if (value == null) {
      return 'Please enter activity duration';
    }
    if ((value < HealthDataRanges.minActivityDurationMin || value > HealthDataRanges.maxActivityDurationMin)) {
      return 'Duration must be between ${HealthDataRanges.minActivityDurationMin} and '
          '${HealthDataRanges.maxActivityDurationMin} ${HealthDataRanges.unitDuration}';
    }
    return null;
  }

  // ===== Helper Methods =====
  static bool _hasAtLeastOneMetric(HealthDataModel data) {
    return _hasBloodPressureData(data) ||
        _hasBloodGlucoseData(data) ||
        _hasBodyCompositionData(data) ||
        _hasPhysicalActivityData(data);
  }

  static bool _hasBloodPressureData(HealthDataModel data) {
    return data.bloodPressure.systolic > 0 ||
        data.bloodPressure.diastolic > 0 ||
        data.bloodPressure.pulse > 0;
  }

  static bool _hasBloodGlucoseData(HealthDataModel data) {
    return data.bloodGlucose.glucoseLevel > 0;
  }

  static bool _hasBodyCompositionData(HealthDataModel data) {
    return data.bodyComposition.weight > 0 || data.bodyComposition.bodyFat > 0;
  }

  static bool _hasPhysicalActivityData(HealthDataModel data) {
    return data.physicalActivity.activityType.isNotEmpty ||
        data.physicalActivity.duration > 0;
  }

  static List<String> _validateBloodPressure(HealthDataModel data) {
    final errors = <String>[];
    final bp = data.bloodPressure;

    final systolicError = validateSystolic(bp.systolic);
    if (systolicError != null) errors.add(systolicError);

    final diastolicError = validateDiastolic(bp.diastolic);
    if (diastolicError != null) errors.add(diastolicError);

    final pulseError = validatePulse(bp.pulse);
    if (pulseError != null) errors.add(pulseError);

    return errors;
  }

  static List<String> _validateBloodGlucose(HealthDataModel data) {
    final errors = <String>[];
    final bg = data.bloodGlucose;

    final glucoseError = validateGlucoseLevel(bg.glucoseLevel);
    if (glucoseError != null) errors.add(glucoseError);

    return errors;
  }

  static List<String> _validateBodyComposition(HealthDataModel data) {
    final errors = <String>[];
    final bc = data.bodyComposition;

    final weightError = validateWeight(bc.weight);
    if (weightError != null) errors.add(weightError);

    final bodyFatError = validateBodyFat(bc.bodyFat);
    if (bodyFatError != null) errors.add(bodyFatError);

    return errors;
  }

  static List<String> _validatePhysicalActivity(HealthDataModel data) {
    final errors = <String>[];
    final pa = data.physicalActivity;

    final activityTypeError =
        validateActivityType(pa.activityType);
    if (activityTypeError != null) errors.add(activityTypeError);

    final durationError =
        validateActivityDuration(pa.duration);
    if (durationError != null) errors.add(durationError);

    return errors;
  }
}
