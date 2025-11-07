/// Defines physiological reasonable ranges for all health metrics.
/// These are NOT medical diagnosis limits, but safe validation ranges
/// covering all age groups (infants to elderly).

class HealthDataRanges {
  HealthDataRanges._();

  // ===== Blood Pressure =====
  static const int minSystolic = 40; // mmHg
  static const int maxSystolic = 250;

  static const int minDiastolic = 20; // mmHg
  static const int maxDiastolic = 150;

  static const int minPulse = 20; // bpm
  static const int maxPulse = 250;

  // ===== Blood Glucose =====
  static const double minGlucoseMmolL = 1.5; // mmol/L
  static const double maxGlucoseMmolL = 35.0;

  // ===== Body Composition =====
  static const double minWeightKg = 0.0; // kg
  static const double maxWeightKg = 300.0;

  // ===== Height (cm) =====
  static const double minHeight = 30.0;
  static const double maxHeight = 250.0;

  static const double minBodyFatPercent = 1.0; // %
  static const double maxBodyFatPercent = 90.0;

  // ===== Physical Activity =====
  static const int minActivityDurationMin = 1; // minutes
  static const int maxActivityDurationMin = 180; // 3 hours


  // ===== Stress Level =====
  // App scale: 1 (lowest) – 10 (highest)
  static const int minStressLevel = 1;
  static const int maxStressLevel = 10;

  // ===== Sleep Duration =====
  // Recommended adult sleep: 7–9 hours
  static const double minSleepHours = 3.0; // can validate very short sleep
  static const double maxSleepHours = 12.0; // maximum possible in a day

  // ===== Water Intake =====
  // General safe daily intake: 0–10 liters (extreme upper limit)
  // Recommended adult intake ~2–3 liters/day
  static const double minWaterLiters = 0.5;
  static const double maxWaterLiters = 5.0;

  // ===== Unit labels (for easier message formatting) =====
  static const String unitBloodPressure = 'mmHg';
  static const String unitPulse = 'bpm';
  static const String unitGlucose = 'mmol/L';
  static const String unitWeight = 'kg';
  static const String unitBodyFat = '%';
  static const String unitDuration = 'minutes';
  static const String unitStressLevel = 'score';
  static const String unitSleep = 'hours';
  static const String unitWater = 'liters';
}
