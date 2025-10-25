import '../../features/health_data_entry/models/health_data_model.dart';

class HealthDataValidator {
  HealthDataValidator._();

  /// Validate health data form
  static Map<String, String> validateHealthDataForm(HealthDataModel data) {
    final errors = <String, String>{};

    // Check if at least one health metric is recorded
    if (!_hasAtLeastOneMetric(data)) {
      errors['general'] = 'At least one health metric must be recorded';
      return errors;
    }

    // Validate Blood Pressure if provided
    if (_hasBloodPressureData(data)) {
      final bpErrors = _validateBloodPressure(data);
      if (bpErrors.isNotEmpty) {
        errors['bloodPressure'] = bpErrors.join(', ');
      }
    }

    // Validate Blood Glucose if provided
    if (_hasBloodGlucoseData(data)) {
      final bgErrors = _validateBloodGlucose(data);
      if (bgErrors.isNotEmpty) {
        errors['bloodGlucose'] = bgErrors.join(', ');
      }
    }

    // Validate Body Composition if provided
    if (_hasBodyCompositionData(data)) {
      final bcErrors = _validateBodyComposition(data);
      if (bcErrors.isNotEmpty) {
        errors['bodyComposition'] = bcErrors.join(', ');
      }
    }

    // Validate Physical Activity if provided
    if (_hasPhysicalActivityData(data)) {
      final paErrors = _validatePhysicalActivity(data);
      if (paErrors.isNotEmpty) {
        errors['physicalActivity'] = paErrors.join(', ');
      }
    }

    return errors;
  }

  /// Validate systolic blood pressure
  static String? validateSystolic(int? value) {
    if (value == null || value <= 0) {
      return 'Please enter systolic blood pressure';
    }
    if (value < 1 || value > 500) {
      return 'Systolic blood pressure must be between 1 and 500 mmHg';
    }
    return null;
  }

  /// Validate diastolic blood pressure
  static String? validateDiastolic(int? value) {
    if (value == null || value <= 0) {
      return 'Please enter diastolic blood pressure';
    }
    if (value < 1 || value > 500) {
      return 'Diastolic blood pressure must be between 1 and 500 mmHg';
    }
    return null;
  }

  /// Validate pulse
  static String? validatePulse(int? value) {
    if (value == null || value <= 0) {
      return 'Please enter pulse';
    }
    if (value < 1 || value > 500) {
      return 'Pulse must be between 1 and 500 bpm';
    }
    return null;
  }

  /// Validate blood glucose level
  static String? validateGlucoseLevel(double? value) {
    if (value == null || value <= 0) {
      return 'Please enter blood glucose level';
    }
    if (value < 0.0 || value > 50.0) {
      return 'Blood glucose level must be between 0.0 and 50.0 mmol/L';
    }
    return null;
  }

  /// Validate weight
  static String? validateWeight(double? value) {
    if (value != null && value > 0) {
      if (value < 0.0 || value > 500.0) {
        return 'Weight must be between 0.0 and 500.0 kg';
      }
    }
    return null;
  }

  /// Validate body fat percentage
  static String? validateBodyFat(double? value) {
    if (value != null && value > 0) {
      if (value < 0.0 || value > 99.0) {
        return 'Body fat percentage must be between 0.0 and 99.0%';
      }
    }
    return null;
  }

  /// Validate activity type
  static String? validateActivityType(String? value, int duration) {
    if (duration > 0 && (value == null || value.trim().isEmpty)) {
      return 'Please enter activity type when duration is provided';
    }
    return null;
  }

  /// Validate activity duration
  static String? validateActivityDuration(int? value, String activityType) {
    if (activityType.isNotEmpty && (value == null || value <= 0)) {
      return 'Please enter duration when activity type is provided';
    }
    if (value != null && value < 0) {
      return 'Duration must be greater than or equal to 0';
    }
    return null;
  }

  // Private helper methods
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

    final activityTypeError = validateActivityType(pa.activityType, pa.duration);
    if (activityTypeError != null) errors.add(activityTypeError);

    final durationError = validateActivityDuration(pa.duration, pa.activityType);
    if (durationError != null) errors.add(durationError);

    return errors;
  }
}
