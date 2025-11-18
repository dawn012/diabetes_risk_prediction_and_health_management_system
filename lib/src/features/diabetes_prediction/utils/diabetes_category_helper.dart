class DiabetesCategoryHelper {
  DiabetesCategoryHelper._();

  // ========== Water Intake Levels Definition ==========
  static const Map<String, Map<String, List<double>>> _waterIntakeLevels = {
    'male': {
      '9-13': [1.0, 1.3, 1.6, 2.0],    // Level 1-4 for boys 9-13
      '14-18': [1.2, 1.5, 1.9, 2.3],   // Level 1-4 for boys 14-18
      '19+': [1.5, 2.0, 2.6, 3.2],     // Level 1-4 for men 19+
    },
    'female': {
      '9-13': [0.8, 1.1, 1.4, 1.8],    // Level 1-4 for girls 9-13
      '14-18': [1.0, 1.3, 1.6, 2.0],   // Level 1-4 for girls 14-18
      '19+': [1.2, 1.6, 2.1, 2.7],     // Level 1-4 for women 19+
    },
    'default': {
      'default': [1.5, 2.0, 2.5, 3.5], // Fallback levels
    }
  };

  // ========== Stress Level Categories ==========
  /// Get stress category as numeric value (0 = Low, 1 = Moderate, 2 = High)
  static int getStressCategory(int stressLevel) {
    if (stressLevel <= 3) {
      return 0; // Low
    } else if (stressLevel <= 6) {
      return 1; // Moderate
    } else {
      return 2; // High
    }
  }

  // ========== Water Intake Categories ==========
  /// Get age category for water intake recommendations
  static String? getAgeCategory(int? age) {
    if (age == null) return null;
    if (age >= 9 && age <= 13) return '9-13';
    if (age >= 14 && age <= 18) return '14-18';
    if (age >= 19) return '19+';
    return null;
  }

  /// Get water intake levels based on user's age and gender
  static List<double> getWaterIntakeLevels({required String gender, required int? age}) {
    final ageCategory = getAgeCategory(age);
    final normalizedGender = gender.toLowerCase();

    // Check if we have both gender and age category
    if (normalizedGender.isNotEmpty && ageCategory != null) {
      final isMale = normalizedGender.contains('male') || normalizedGender.contains('boy') || normalizedGender.contains('man');
      final isFemale = normalizedGender.contains('female') || normalizedGender.contains('girl') || normalizedGender.contains('woman');

      final genderKey = isMale ? 'male' : (isFemale ? 'female' : null);

      if (genderKey != null && _waterIntakeLevels[genderKey]?.containsKey(ageCategory) == true) {
        return _waterIntakeLevels[genderKey]![ageCategory]!;
      }
    }

    // Fallback to default levels if any parameter is missing
    return _waterIntakeLevels['default']!['default']!;
  }

  /// Binary hydration status (1 = adequately hydrated, 0 = not hydrated)
  static int getHydrationStatusBinary(double waterIntake, {required String gender, required int? age}) {
    final levels = getWaterIntakeLevels(gender: gender, age: age);

    // 直接根据 levels 判断
    if (waterIntake < levels[0]) return 0; // Severely Dehydrated
    if (waterIntake < levels[2]) return 0; // Under Hydrated (below optimal)
    if (waterIntake <= levels[3]) return 1; // Optimal Hydration
    return 0; // Over Hydrated
  }

  // ========== Medication Adherence Categories ==========
  /// Returns 0 or 1 for model submission (1 = adherent, 0 = not adherent)
  static int getMedicationAdherentBinary(bool takesMedication, int? adherencePercentage) {
    if (takesMedication != true) {
      return 0; // No medication → 0
    }
    // If user takes medication, check adherence
    return (adherencePercentage ?? 0) >= 80 ? 1 : 0;
  }

  // ========== Diet Assessment Categories ==========
  /// Get diet health binary (1 = healthy, 0 = unhealthy)
  static int getDietHealthyBinary(bool isHealthy) {
    return isHealthy ? 1 : 0;
  }

  // ========== Convenience Methods ==========
  /// Get all binary values for model submission in one call
  static Map<String, int> getAllBinaryValues({
    required int stressLevel,
    required double waterIntake,
    required String gender,
    required int? age,
    required bool takesMedication,
    required int? medicationAdherence,
    required bool dietHealthy,
  }) {
    return {
      'stress_binary': getStressCategory(stressLevel),
      'hydration_binary': getHydrationStatusBinary(
          waterIntake,
          gender: gender,
          age: age
      ),
      'medication_binary': getMedicationAdherentBinary(
          takesMedication,
          medicationAdherence
      ),
      'diet_binary': getDietHealthyBinary(dietHealthy),
    };
  }
}