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

  factory DietAssessmentReport.fromJson(Map<String, dynamic> json) => DietAssessmentReport(
    meals: (json['meals'] as List)
        .map((m) => MealAnalysisResult.fromJson(m))
        .toList(),
    avgGLPerMeal: (json['avgGLPerMeal'] ?? 0).toDouble(),
    isHealthy: json['isHealthy'] ?? false,
    warnings: List<String>.from(json['warnings'] ?? []),
    mealCount: json['mealCount'] ?? 0,
    glThresholds: Map<String, int>.from(json['glThresholds'] ?? {
      'low': 10,
      'medium': 20,
      'high': 20,
    }),
    assessmentDate: json['processedAt'] != null
        ? DateTime.parse(json['processedAt'])
        : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'meals': meals.map((m) => m.toJson()).toList(),
    'avgGLPerMeal': avgGLPerMeal,
    'isHealthy': isHealthy,
    'warnings': warnings,
    'mealCount': mealCount,
    'glThresholds': glThresholds,
    'processedAt': assessmentDate.toIso8601String(),
  };

  // Helper getters for summary statistics

  /// Total number of foods detected across all meals
  int get totalFoodsDetected => meals.fold(0, (sum, m) => sum + m.foods.length);

  /// Number of low GL meals
  int get lowGLMealsCount => meals.where((m) => m.glCategory == 'low').length;

  /// Number of medium GL meals
  int get mediumGLMealsCount => meals.where((m) => m.glCategory == 'medium').length;

  /// Number of high GL meals
  int get highGLMealsCount => meals.where((m) => m.glCategory == 'high').length;

  /// Total calories across all meals
  double get totalCalories => meals.fold(0.0, (sum, m) =>
  sum + m.foods.fold(0.0, (s, f) => s + f.calories));

  /// Total carbs across all meals
  double get totalCarbs => meals.fold(0.0, (sum, m) =>
  sum + m.foods.fold(0.0, (s, f) => s + f.carbs));

  /// Total sugar across all meals
  double get totalSugar => meals.fold(0.0, (sum, m) =>
  sum + m.foods.fold(0.0, (s, f) => s + f.sugar));

  /// Total fiber across all meals
  double get totalFiber => meals.fold(0.0, (sum, m) =>
  sum + m.foods.fold(0.0, (s, f) => s + f.fiber));

  /// Total protein across all meals
  double get totalProtein => meals.fold(0.0, (sum, m) =>
  sum + m.foods.fold(0.0, (s, f) => s + f.protein));

  /// Total fat across all meals
  double get totalFat => meals.fold(0.0, (sum, m) =>
  sum + m.foods.fold(0.0, (s, f) => s + f.fat));

  /// Percentage of high GL meals
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

  /// Get GL distribution as percentages
  Map<String, double> get glDistributionPercentage => {
    'low': mealCount > 0 ? (lowGLMealsCount / mealCount * 100) : 0.0,
    'medium': mealCount > 0 ? (mediumGLMealsCount / mealCount * 100) : 0.0,
    'high': mealCount > 0 ? (highGLMealsCount / mealCount * 100) : 0.0,
  };

  /// Check if there are any warnings
  bool get hasWarnings => warnings.isNotEmpty;

  /// Get number of meals with valid data
  int get validMealsCount => meals.where((m) => m.hasValidData).length;

  /// Get number of meals with errors
  int get errorMealsCount => meals.where((m) => m.hasError).length;
}
