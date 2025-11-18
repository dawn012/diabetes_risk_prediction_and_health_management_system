import 'package:hive/hive.dart';
import 'meal_analysis_result_model.dart';

part 'diet_assessment_report_model.g.dart';

@HiveType(typeId: 2)
class DietAssessmentReport {
  @HiveField(0)
  final List<MealAnalysisResult> meals;

  @HiveField(1)
  final double avgGLPerMeal;

  @HiveField(2)
  final bool isHealthy;

  @HiveField(3)
  final List<String> warnings;

  @HiveField(4)
  final int mealCount;

  @HiveField(5)
  final Map<String, int> glThresholds;

  @HiveField(6)
  final DateTime assessmentDate;

  const DietAssessmentReport({
    required this.meals,
    required this.avgGLPerMeal,
    required this.isHealthy,
    required this.warnings,
    required this.mealCount,
    required this.glThresholds,
    required this.assessmentDate,
  });

  factory DietAssessmentReport.fromJson(Map<String, dynamic> json) {
    try {
      print('🔧 Parsing DietAssessmentReport from JSON');

      // 安全处理 meals 数组
      List<MealAnalysisResult> meals = [];
      final mealsData = json['meals'];
      if (mealsData is List) {
        print('📊 Processing ${mealsData.length} meals');
        for (int i = 0; i < mealsData.length; i++) {
          try {
            final mealItem = mealsData[i];
            if (mealItem is Map<String, dynamic>) {
              meals.add(MealAnalysisResult.fromJson(mealItem));
            } else if (mealItem is Map) {
              final convertedMeal = _convertMealMap(mealItem);
              meals.add(MealAnalysisResult.fromJson(convertedMeal));
            } else {
              print('⚠️ Meal item $i has invalid type: ${mealItem.runtimeType}');
            }
          } catch (e) {
            print('❌ Error parsing meal item $i: $e');
          }
        }
      } else {
        print('⚠️ Meals data is not a List: ${mealsData?.runtimeType}');
      }

      // 安全处理其他字段
      final avgGLPerMeal = _safeDouble(json['avgGLPerMeal']);
      final isHealthy = json['isHealthy'] == true;
      final mealCount = _safeInt(json['mealCount']);

      // 处理 warnings 数组
      List<String> warnings = [];
      final warningsData = json['warnings'];
      if (warningsData is List) {
        warnings = warningsData.map((w) => w?.toString() ?? '').where((w) => w.isNotEmpty).toList();
      }

      // 处理 glThresholds
      Map<String, int> glThresholds = {
        'low': 10,
        'medium': 20,
        'high': 20,
      };
      final thresholdsData = json['glThresholds'];
      if (thresholdsData is Map) {
        glThresholds = thresholdsData.map<String, int>((key, value) {
          final stringKey = key?.toString() ?? '';
          final intValue = (value is num) ? value.toInt() : 0;
          return MapEntry(stringKey, intValue);
        });
      }

      // 处理日期
      DateTime assessmentDate;
      try {
        final processedAt = json['processedAt']?.toString();
        assessmentDate = processedAt != null ? DateTime.parse(processedAt) : DateTime.now();
      } catch (e) {
        print('⚠️ Error parsing date, using current time: $e');
        assessmentDate = DateTime.now();
      }

      print('✅ Successfully parsed DietAssessmentReport with ${meals.length} meals');

      return DietAssessmentReport(
        meals: meals,
        avgGLPerMeal: avgGLPerMeal,
        isHealthy: isHealthy,
        warnings: warnings,
        mealCount: mealCount,
        glThresholds: glThresholds,
        assessmentDate: assessmentDate,
      );
    } catch (e) {
      print('💥 Critical error in DietAssessmentReport.fromJson: $e');
      print('📄 Problematic JSON: $json');

      // 返回一个默认的评估报告而不是抛出异常
      return DietAssessmentReport(
        meals: [],
        avgGLPerMeal: 0.0,
        isHealthy: false,
        warnings: ['Error parsing assessment data'],
        mealCount: 0,
        glThresholds: {'low': 10, 'medium': 20, 'high': 20},
        assessmentDate: DateTime.now(),
      );
    }
  }

  static Map<String, dynamic> _convertMealMap(Map<dynamic, dynamic> rawMap) {
    return rawMap.map<String, dynamic>((key, value) {
      final stringKey = key?.toString() ?? '';
      return MapEntry(stringKey, value);
    });
  }

  static String _safeString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  static int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() => {
    'meals': meals.map((m) => m.toJson()).toList(),
    'avgGLPerMeal': avgGLPerMeal,
    'isHealthy': isHealthy,
    'warnings': warnings,
    'mealCount': mealCount,
    'glThresholds': glThresholds,
    'processedAt': assessmentDate.toIso8601String(),
  };

  /// Total number of foods detected across all meals (excluding error meals)
  int get totalFoodsDetected => meals
      .where((m) => !m.hasError)
      .fold(0, (sum, m) => sum + m.foods.length);

  /// Number of low GL meals
  int get lowGLMealsCount => meals
      .where((m) => !m.hasError && m.glCategory == 'low')
      .length;

  /// Number of medium GL meals
  int get mediumGLMealsCount => meals
      .where((m) => !m.hasError && m.glCategory == 'medium')
      .length;

  /// Number of high GL meals
  int get highGLMealsCount => meals
      .where((m) => !m.hasError && m.glCategory == 'high')
      .length;

  /// Total calories across all meals (excluding error meals)
  double get totalCalories => meals
      .where((m) => !m.hasError)
      .fold(0.0, (sum, m) =>
  sum + m.foods.fold(0.0, (s, f) => s + f.calories));

  /// Total carbs across all meals (excluding error meals)
  double get totalCarbs => meals
      .where((m) => !m.hasError)
      .fold(0.0, (sum, m) =>
  sum + m.foods.fold(0.0, (s, f) => s + f.carbs));

  /// Total sugar across all meals (excluding error meals)
  double get totalSugar => meals
      .where((m) => !m.hasError)
      .fold(0.0, (sum, m) =>
  sum + m.foods.fold(0.0, (s, f) => s + f.sugar));

  /// Total fiber across all meals (excluding error meals)
  double get totalFiber => meals
      .where((m) => !m.hasError)
      .fold(0.0, (sum, m) =>
  sum + m.foods.fold(0.0, (s, f) => s + f.fiber));

  /// Total protein across all meals (excluding error meals)
  double get totalProtein => meals
      .where((m) => !m.hasError)
      .fold(0.0, (sum, m) =>
  sum + m.foods.fold(0.0, (s, f) => s + f.protein));

  /// Total fat across all meals (excluding error meals)
  double get totalFat => meals
      .where((m) => !m.hasError)
      .fold(0.0, (sum, m) =>
  sum + m.foods.fold(0.0, (s, f) => s + f.fat));

  /// Percentage of high GL meals (only from valid meals)
  double get highGLPercentage => mealCount > 0
      ? (highGLMealsCount / mealCount * 100)
      : 0.0;

  /// Get GL category for average GL
  String get avgGLCategory {
    if (avgGLPerMeal < glThresholds['low']!) return 'low';
    if (avgGLPerMeal < glThresholds['medium']!) return 'medium';
    return 'high';
  }

  /// Get health status emoji
  String get healthStatusEmoji => isHealthy ? '✅' : '⚠️';

  /// Get health status text
  String get healthStatusText => isHealthy
      ? 'Healthy Diet Detected'
      : 'Diet Needs Improvement';

  /// Get GL distribution as percentages (only from valid meals)
  Map<String, double> get glDistributionPercentage => {
    'low': mealCount > 0 ? (lowGLMealsCount / mealCount * 100) : 0.0,
    'medium': mealCount > 0 ? (mediumGLMealsCount / mealCount * 100) : 0.0,
    'high': mealCount > 0 ? (highGLMealsCount / mealCount * 100) : 0.0,
  };

  /// Check if there are any warnings
  bool get hasWarnings => warnings.isNotEmpty;

  /// Get number of meals with valid data (no errors)
  int get validMealsCount => meals.where((m) => m.hasValidData).length;

  /// Get number of meals with errors
  int get errorMealsCount => meals.where((m) => m.hasError).length;

  @override
  String toString() {
    return 'DietAssessmentReport(meals: ${meals.length}, validMeals: $validMealsCount, avgGL: $avgGLPerMeal, isHealthy: $isHealthy)';
  }
}