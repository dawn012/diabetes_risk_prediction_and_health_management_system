class BMICalculator {
  // Adult BMI classification standards
  static final Map<String, List<double>> _adultCategories = {
    'Underweight': [0, 18.4],
    'Normal weight': [18.5, 24.9],
    'Overweight': [25.0, 29.9],
    'Obese': [30.0, double.infinity],
  };

  // Female children and adolescents BMI percentile standards (13-19 years, based on months)
  static final Map<String, List<double>> _femaleChildCategories = {
    // 13 years (156-167 months)
    '156': [0, 15.5, 20.7, 24.4, double.infinity],
    '157': [0, 15.5, 20.8, 24.5, double.infinity],
    '158': [0, 15.6, 20.9, 24.6, double.infinity],
    '159': [0, 15.6, 20.9, 24.7, double.infinity],
    '160': [0, 15.7, 21.0, 24.8, double.infinity],
    '161': [0, 15.7, 21.1, 24.9, double.infinity],
    '162': [0, 15.8, 21.2, 25.0, double.infinity],
    '163': [0, 15.8, 21.2, 25.1, double.infinity],
    '164': [0, 15.9, 21.3, 25.1, double.infinity],
    '165': [0, 15.9, 21.4, 25.2, double.infinity],
    '166': [0, 15.9, 21.4, 25.3, double.infinity],
    '167': [0, 16.0, 21.5, 25.4, double.infinity],

    // 14 years (168-179 months)
    '168': [0, 16.0, 21.6, 25.5, double.infinity],
    '169': [0, 16.1, 21.6, 25.6, double.infinity],
    '170': [0, 16.1, 21.7, 25.6, double.infinity],
    '171': [0, 16.2, 21.8, 25.7, double.infinity],
    '172': [0, 16.2, 21.8, 25.8, double.infinity],
    '173': [0, 16.2, 21.9, 25.9, double.infinity],
    '174': [0, 16.3, 22.0, 25.9, double.infinity],
    '175': [0, 16.3, 22.0, 26.0, double.infinity],
    '176': [0, 16.4, 22.1, 26.1, double.infinity],
    '177': [0, 16.4, 22.2, 26.1, double.infinity],
    '178': [0, 16.4, 22.2, 26.2, double.infinity],
    '179': [0, 16.5, 22.3, 26.3, double.infinity],

    // 15 years (180-191 months)
    '180': [0, 16.5, 22.3, 26.3, double.infinity],
    '181': [0, 16.5, 22.4, 26.4, double.infinity],
    '182': [0, 16.6, 22.4, 26.5, double.infinity],
    '183': [0, 16.6, 22.5, 26.5, double.infinity],
    '184': [0, 16.6, 22.5, 26.6, double.infinity],
    '185': [0, 16.6, 22.6, 26.6, double.infinity],
    '186': [0, 16.7, 22.6, 26.7, double.infinity],
    '187': [0, 16.7, 22.7, 26.7, double.infinity],
    '188': [0, 16.7, 22.7, 26.8, double.infinity],
    '189': [0, 16.8, 22.8, 26.8, double.infinity],
    '190': [0, 16.8, 22.8, 26.9, double.infinity],
    '191': [0, 16.8, 22.8, 26.9, double.infinity],

    // 16 years (192-203 months)
    '192': [0, 16.8, 22.9, 27.0, double.infinity],
    '193': [0, 16.8, 22.9, 27.0, double.infinity],
    '194': [0, 16.9, 23.0, 27.1, double.infinity],
    '195': [0, 16.9, 23.0, 27.1, double.infinity],
    '196': [0, 16.9, 23.0, 27.1, double.infinity],
    '197': [0, 16.9, 23.1, 27.2, double.infinity],
    '198': [0, 16.9, 23.1, 27.2, double.infinity],
    '199': [0, 17.0, 23.1, 27.2, double.infinity],
    '200': [0, 17.0, 23.1, 27.3, double.infinity],
    '201': [0, 17.0, 23.2, 27.3, double.infinity],
    '202': [0, 17.0, 23.2, 27.3, double.infinity],
    '203': [0, 17.0, 23.2, 27.4, double.infinity],

    // 17 years (204-215 months)
    '204': [0, 17.0, 23.3, 27.4, double.infinity],
    '205': [0, 17.0, 23.3, 27.4, double.infinity],
    '206': [0, 17.1, 23.3, 27.4, double.infinity],
    '207': [0, 17.1, 23.3, 27.5, double.infinity],
    '208': [0, 17.1, 23.4, 27.5, double.infinity],
    '209': [0, 17.1, 23.4, 27.5, double.infinity],
    '210': [0, 17.1, 23.4, 27.5, double.infinity],
    '211': [0, 17.1, 23.4, 27.6, double.infinity],
    '212': [0, 17.1, 23.4, 27.6, double.infinity],
    '213': [0, 17.1, 23.5, 27.6, double.infinity],
    '214': [0, 17.1, 23.5, 27.6, double.infinity],
    '215': [0, 17.1, 23.5, 27.6, double.infinity],

    // 18 years (216-227 months)
    '216': [0, 17.1, 23.5, 27.7, double.infinity],
    '217': [0, 17.2, 23.5, 27.7, double.infinity],
    '218': [0, 17.2, 23.6, 27.7, double.infinity],
    '219': [0, 17.2, 23.6, 27.7, double.infinity],
    '220': [0, 17.2, 23.6, 27.7, double.infinity],
    '221': [0, 17.2, 23.6, 27.7, double.infinity],
    '222': [0, 17.2, 23.6, 27.7, double.infinity],
    '223': [0, 17.2, 23.6, 27.8, double.infinity],
    '224': [0, 17.2, 23.6, 27.8, double.infinity],
    '225': [0, 17.2, 23.7, 27.8, double.infinity],
    '226': [0, 17.2, 23.7, 27.8, double.infinity],
    '227': [0, 17.2, 23.7, 27.8, double.infinity],

    // 19 years (228 months)
    '228': [0, 17.2, 23.7, 27.8, double.infinity],
  };

  // Male children and adolescents BMI percentile standards (13-19 years, based on months)
  static final Map<String, List<double>> _maleChildCategories = {
    // 13 years (156-167 months)
    '156': [0, 15.4, 19.9, 23.1, double.infinity],
    '157': [0, 15.4, 19.9, 23.2, double.infinity],
    '158': [0, 15.5, 20.0, 23.3, double.infinity],
    '159': [0, 15.5, 20.1, 23.4, double.infinity],
    '160': [0, 15.6, 20.2, 23.5, double.infinity],
    '161': [0, 15.6, 20.2, 23.6, double.infinity],
    '162': [0, 15.7, 20.3, 23.7, double.infinity],
    '163': [0, 15.7, 20.4, 23.8, double.infinity],
    '164': [0, 15.8, 20.5, 23.9, double.infinity],
    '165': [0, 15.8, 20.5, 24.0, double.infinity],
    '166': [0, 15.9, 20.6, 24.0, double.infinity],
    '167': [0, 15.9, 20.7, 24.1, double.infinity],

    // 14 years (168-179 months)
    '168': [0, 16.0, 20.8, 24.2, double.infinity],
    '169': [0, 16.0, 20.8, 24.3, double.infinity],
    '170': [0, 16.1, 20.9, 24.4, double.infinity],
    '171': [0, 16.1, 21.0, 24.5, double.infinity],
    '172': [0, 16.2, 21.1, 24.6, double.infinity],
    '173': [0, 16.2, 21.1, 24.7, double.infinity],
    '174': [0, 16.3, 21.2, 24.7, double.infinity],
    '175': [0, 16.3, 21.3, 24.8, double.infinity],
    '176': [0, 16.4, 21.3, 24.9, double.infinity],
    '177': [0, 16.4, 21.4, 25.0, double.infinity],
    '178': [0, 16.5, 21.5, 25.1, double.infinity],
    '179': [0, 16.5, 21.6, 25.1, double.infinity],

    // 15 years (180-191 months)
    '180': [0, 16.5, 21.6, 25.2, double.infinity],
    '181': [0, 16.6, 21.7, 25.3, double.infinity],
    '182': [0, 16.6, 21.8, 25.4, double.infinity],
    '183': [0, 16.7, 21.8, 25.5, double.infinity],
    '184': [0, 16.7, 21.9, 25.5, double.infinity],
    '185': [0, 16.8, 22.0, 25.6, double.infinity],
    '186': [0, 16.8, 22.0, 25.7, double.infinity],
    '187': [0, 16.9, 22.1, 25.8, double.infinity],
    '188': [0, 16.9, 22.2, 25.8, double.infinity],
    '189': [0, 17.0, 22.2, 25.9, double.infinity],
    '190': [0, 17.0, 22.3, 26.0, double.infinity],
    '191': [0, 17.0, 22.4, 26.1, double.infinity],

    // 16 years (192-203 months)
    '192': [0, 17.1, 22.4, 26.1, double.infinity],
    '193': [0, 17.1, 22.5, 26.2, double.infinity],
    '194': [0, 17.2, 22.6, 26.3, double.infinity],
    '195': [0, 17.2, 22.6, 26.3, double.infinity],
    '196': [0, 17.2, 22.7, 26.4, double.infinity],
    '197': [0, 17.3, 22.7, 26.5, double.infinity],
    '198': [0, 17.3, 22.8, 26.5, double.infinity],
    '199': [0, 17.4, 22.9, 26.6, double.infinity],
    '200': [0, 17.4, 22.9, 26.7, double.infinity],
    '201': [0, 17.4, 23.0, 26.7, double.infinity],
    '202': [0, 17.5, 23.0, 26.8, double.infinity],
    '203': [0, 17.5, 23.1, 26.8, double.infinity],

    // 17 years (204-215 months)
    '204': [0, 17.5, 23.1, 26.9, double.infinity],
    '205': [0, 17.6, 23.2, 27.0, double.infinity],
    '206': [0, 17.6, 23.2, 27.0, double.infinity],
    '207': [0, 17.6, 23.3, 27.1, double.infinity],
    '208': [0, 17.7, 23.3, 27.1, double.infinity],
    '209': [0, 17.7, 23.4, 27.2, double.infinity],
    '210': [0, 17.7, 23.4, 27.2, double.infinity],
    '211': [0, 17.8, 23.5, 27.3, double.infinity],
    '212': [0, 17.8, 23.5, 27.3, double.infinity],
    '213': [0, 17.8, 23.6, 27.4, double.infinity],
    '214': [0, 17.9, 23.6, 27.4, double.infinity],
    '215': [0, 17.9, 23.7, 27.5, double.infinity],

    // 18 years (216-227 months)
    '216': [0, 17.9, 23.7, 27.5, double.infinity],
    '217': [0, 18.0, 23.8, 27.6, double.infinity],
    '218': [0, 18.0, 23.8, 27.6, double.infinity],
    '219': [0, 18.0, 23.9, 27.7, double.infinity],
    '220': [0, 18.0, 23.9, 27.7, double.infinity],
    '221': [0, 18.1, 24.0, 27.8, double.infinity],
    '222': [0, 18.1, 24.0, 27.8, double.infinity],
    '223': [0, 18.1, 24.1, 27.9, double.infinity],
    '224': [0, 18.2, 24.1, 27.9, double.infinity],
    '225': [0, 18.2, 24.2, 27.9, double.infinity],
    '226': [0, 18.2, 24.2, 28.0, double.infinity],
    '227': [0, 18.2, 24.3, 28.0, double.infinity],

    // 19 years (228 months)
    '228': [0, 18.2, 24.3, 28.1, double.infinity],
  };

  /// Calculate BMI
  static double calculateBMI(double weight, double height) {
    if (height <= 0) throw ArgumentError('Height must be greater than 0');
    return weight / ((height / 100) * (height / 100));
  }

  /// Get BMI category
  static BMICategory getBMICategory({
    required double weight,
    required double height,
    int? ageInMonths,
    String? gender,
  }) {
    final double bmi = calculateBMI(weight, height);

    // Use adult standards if no age provided, age >= 228 months, or no gender provided
    if (ageInMonths == null || ageInMonths >= 228 || gender == null) {
      return _getAdultCategory(bmi);
    }

    // For children and adolescents (5-18 years, i.e., 60-227 months)
    if (ageInMonths >= 60 && ageInMonths <= 227) {
      return _getChildCategory(bmi, ageInMonths, gender.toLowerCase());
    }

    // Age less than 5 years not supported
    throw ArgumentError('BMI calculation is not supported for children under 5 years old (60 months)');
  }

  /// Get adult BMI category
  static BMICategory _getAdultCategory(double bmi) {
    if (bmi < 18.5) {
      return BMICategory('Underweight', 1);
    } else if (bmi >= 18.5 && bmi <= 24.9) {
      return BMICategory('Normal weight', 2);
    } else if (bmi >= 25.0 && bmi <= 29.9) {
      return BMICategory('Overweight', 3);
    } else {
      return BMICategory('Obese', 4);
    }
  }

  /// Get children and adolescents BMI category
  static BMICategory _getChildCategory(double bmi, int ageInMonths, String gender) {
    String monthKey = ageInMonths.toString();

    Map<String, List<double>> categoryData;

    if (gender == 'female') {
      categoryData = _femaleChildCategories;
    } else if (gender == 'male') {
      categoryData = _maleChildCategories;
    } else {
      throw ArgumentError('Gender must be either "male" or "female"');
    }

    if (!categoryData.containsKey(monthKey)) {
      throw ArgumentError('No BMI data available for $gender at $ageInMonths months');
    }

    final thresholds = categoryData[monthKey]!;

    if (bmi < thresholds[1]) { // < 5th percentile
      return BMICategory('Underweight', 1);
    } else if (bmi >= thresholds[1] && bmi < thresholds[2]) { // 5th - 84th percentile
      return BMICategory('Healthy weight', 2);
    } else if (bmi >= thresholds[2] && bmi < thresholds[3]) { // 85th - 94th percentile
      return BMICategory('Overweight', 3);
    } else { // ≥ 95th percentile
      return BMICategory('Obese', 4);
    }
  }

  /// Get detailed BMI information
  static BMIResult getBMIInfo({
    required double weight,
    required double height,
    int? ageInMonths,
    String? gender,
  }) {
    final bmi = calculateBMI(weight, height);
    final category = getBMICategory(
      weight: weight,
      height: height,
      ageInMonths: ageInMonths,
      gender: gender,
    );

    return BMIResult(bmi, category);
  }

  /// Get BMI percentile values for specific age and gender
  static List<double>? getBMIThresholds(int ageInMonths, String gender) {
    if (ageInMonths >= 228) return null;

    String monthKey = ageInMonths.toString();

    if (gender.toLowerCase() == 'female') {
      return _femaleChildCategories[monthKey];
    } else if (gender.toLowerCase() == 'male') {
      return _maleChildCategories[monthKey];
    }
    return null;
  }
}

/// BMI category result
class BMICategory {
  final String name;
  final int level;

  BMICategory(this.name, this.level);

  @override
  String toString() {
    return '$name - Level $level';
  }
}

/// BMI calculation result
class BMIResult {
  final double bmi;
  final BMICategory category;

  BMIResult(this.bmi, this.category);

  @override
  String toString() {
    return 'BMI: ${bmi.toStringAsFixed(1)} - ${category.name}';
  }
}