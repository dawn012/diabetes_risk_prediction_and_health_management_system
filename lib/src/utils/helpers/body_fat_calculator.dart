import '../constants/enums.dart';

class BodyFatCalculator {
  // 女性体脂率标准 (AFAB)
  static final Map<String, List<List<double>>> _femaleStandards = {
    '20-29': [
      [0, 14.0],           // low (under 14%)
      [14.0, 22.7],        // normal (excellent 14-16.5% + good 16.6-19.4% + fair 19.5-22.7%)
      [22.8, 27.1],        // elevated (poor 22.8-27.1%)
      [27.2, double.infinity], // high (dangerously high over 27.2%)
    ],
    '30-39': [
      [0, 14.0],           // low (under 14%)
      [14.0, 24.6],        // normal (excellent 14-17.4% + good 17.5-20.8% + fair 20.9-24.6%)
      [24.7, 29.1],        // elevated (poor 24.7-29.1%)
      [29.2, double.infinity], // high (dangerously high over 29.2%)
    ],
    '40-49': [
      [0, 14.0],           // low (under 14%)
      [14.0, 27.6],        // normal (excellent 14-19.8% + good 19.9-23.8% + fair 23.9-27.6%)
      [27.7, 31.9],        // elevated (poor 27.7-31.9%)
      [32.0, double.infinity], // high (dangerously high over 31.9%)
    ],
    '50-59': [
      [0, 14.0],           // low (under 14%)
      [14.0, 30.4],        // normal (excellent 14-22.5% + good 22.6-27% + fair 27.1-30.4%)
      [30.5, 34.5],        // elevated (poor 30.5-34.5%)
      [34.6, double.infinity], // high (dangerously high over 34.6%)
    ],
    '60-69': [
      [0, 14.0],           // low (under 14%)
      [14.0, 31.3],        // normal (excellent 14-23.2% + good 23.3-27.9% + fair 28-31.3%)
      [31.4, 35.4],        // elevated (poor 31.4-35.4%)
      [35.5, double.infinity], // high (dangerously high over 35.5%)
    ],
  };

  // 男性体脂率标准 (AMAB)
  static final Map<String, List<List<double>>> _maleStandards = {
    '20-29': [
      [0, 8.0],            // low (under 8%)
      [8.0, 18.6],         // normal (excellent 8-10.5% + good 10.6-14.8% + fair 14.9-18.6%)
      [18.7, 23.1],        // elevated (poor 18.7-23.1%)
      [23.2, double.infinity], // high (dangerously high over 23.2%)
    ],
    '30-39': [
      [0, 8.0],            // low (under 8%)
      [8.0, 21.3],         // normal (excellent 8-14.5% + good 14.6-18.2% + fair 18.3-21.3%)
      [21.4, 24.9],        // elevated (poor 21.4-24.9%)
      [25.0, double.infinity], // high (dangerously high over 25%)
    ],
    '40-49': [
      [0, 8.0],            // low (under 8%)
      [8.0, 23.4],         // normal (excellent 8-17.4% + good 17.5-20.6% + fair 20.7-23.4%)
      [23.5, 26.6],        // elevated (poor 23.5-26.6%)
      [26.7, double.infinity], // high (dangerously high over 26.7%)
    ],
    '50-59': [
      [0, 8.0],            // low (under 8%)
      [8.0, 24.6],         // normal (excellent 8-19.1% + good 19.2-22.1% + fair 22.2-24.6%)
      [24.7, 27.8],        // elevated (poor 24.7-27.8%)
      [27.9, double.infinity], // high (dangerously high over 27.9%)
    ],
    '60-69': [
      [0, 8.0],            // low (under 8%)
      [8.0, 25.2],         // normal (excellent 8-19.7% + good 19.8-22.6% + fair 22.7-25.2%)
      [25.3, 28.4],        // elevated (poor 25.3-28.4%)
      [28.5, double.infinity], // high (dangerously high over 28.5%)
    ],
  };

  /// 获取年龄组别
  static String _getAgeGroup(int age) {
    // 年龄小于13或大于120视为无效
    if (age < 13 || age > 120) {
      return 'invalid';
    }

    // 小于20的按20-29处理
    if (age < 20) return '20-29';

    // 正常年龄分组
    if (age >= 20 && age <= 29) return '20-29';
    if (age >= 30 && age <= 39) return '30-39';
    if (age >= 40 && age <= 49) return '40-49';
    if (age >= 50 && age <= 59) return '50-59';
    if (age >= 60 && age <= 69) return '60-69';

    // 大于69的按60-69处理
    if (age > 69) return '60-69';

    return 'invalid';
  }

  /// 获取体脂率健康等级
  static HealthLevel getBodyFatLevel({
    required double bodyFatPercentage,
    required String gender,
    required int age,
  }) {
    // 验证输入
    if (bodyFatPercentage < 0 || bodyFatPercentage > 100) {
      return HealthLevel.invalid;
    }

    final ageGroup = _getAgeGroup(age);
    if (ageGroup == 'invalid') {
      return HealthLevel.invalid;
    }

    List<List<double>> standards;

    if (gender.toLowerCase() == 'female' || gender.toLowerCase() == 'f') {
      standards = _femaleStandards[ageGroup]!;
    } else if (gender.toLowerCase() == 'male' || gender.toLowerCase() == 'm') {
      standards = _maleStandards[ageGroup]!;
    } else {
      return HealthLevel.invalid;
    }

    // 检查体脂率属于哪个等级
    if (bodyFatPercentage < standards[0][1]) {
      return HealthLevel.low;
    } else if (bodyFatPercentage < standards[1][1]) {
      return HealthLevel.normal;
    } else if (bodyFatPercentage < standards[2][1]) {
      return HealthLevel.elevated;
    } else {
      return HealthLevel.high;
    }
  }

  // /// 获取健康等级的颜色（用于UI显示）
  // static Color getHealthLevelColor(HealthLevel level) {
  //   switch (level) {
  //     case HealthLevel.low:
  //       return Colors.orange;
  //     case HealthLevel.normal:
  //       return Colors.green;
  //     case HealthLevel.elevated:
  //       return Colors.orange;
  //     case HealthLevel.high:
  //       return Colors.red;
  //     case HealthLevel.invalid:
  //       return Colors.grey;
  //   }
  // }

  /// 获取详细的健康建议
  static String getHealthAdvice(HealthLevel level, String gender) {
    switch (level) {
      case HealthLevel.low:
        return 'Your body fat percentage is below the recommended range. '
            'Consider consulting a healthcare professional for guidance on healthy weight gain.';
      case HealthLevel.normal:
        return 'Your body fat percentage is within the healthy range. '
            'Maintain your current lifestyle with balanced nutrition and regular exercise.';
      case HealthLevel.elevated:
        return 'Your body fat percentage is slightly above the recommended range. '
            'Consider increasing physical activity and adjusting your diet.';
      case HealthLevel.high:
        return 'Your body fat percentage is significantly above the healthy range. '
            'Consult a healthcare professional for personalized advice on weight management.';
      case HealthLevel.invalid:
        return 'Unable to calculate body fat level. Please check your input data.';
    }
  }
}