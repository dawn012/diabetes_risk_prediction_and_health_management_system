import 'package:hive/hive.dart';
import 'detected_food_model.dart';

part 'meal_analysis_result_model.g.dart';

@HiveType(typeId: 3)
class MealAnalysisResult {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int mealNumber;

  @HiveField(2)
  final List<DetectedFood> foods;

  @HiveField(3)
  final double totalGL;

  @HiveField(4)
  final String glCategory;

  @HiveField(5)
  final String? error;

  const MealAnalysisResult({
    required this.id,
    required this.mealNumber,
    required this.foods,
    required this.totalGL,
    required this.glCategory,
    this.error,
  });

  factory MealAnalysisResult.fromJson(Map<String, dynamic> json) => MealAnalysisResult(
    id: json['id'],
    mealNumber: json['mealNumber'],
    foods: (json['foods'] as List?)
        ?.map((f) => DetectedFood.fromJson(f))
        .toList() ?? [],
    totalGL: (json['totalGL'] ?? 0).toDouble(),
    glCategory: json['glCategory'] ?? 'unknown',
    error: json['error'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'mealNumber': mealNumber,
    'foods': foods.map((f) => f.toJson()).toList(),
    'totalGL': totalGL,
    'glCategory': glCategory,
    if (error != null) 'error': error,
  };

  /// Check if this meal has errors
  bool get hasError => error != null;

  /// Check if this meal has valid analysis data
  bool get hasValidData => foods.isNotEmpty && !hasError;

  /// Get total calories from all foods
  double get totalCalories => foods.fold(0.0, (sum, f) => sum + f.calories);

  /// Get total carbs from all foods
  double get totalCarbs => foods.fold(0.0, (sum, f) => sum + f.carbs);

  /// Get total sugar from all foods
  double get totalSugar => foods.fold(0.0, (sum, f) => sum + f.sugar);

  /// Get total fiber from all foods
  double get totalFiber => foods.fold(0.0, (sum, f) => sum + f.fiber);

  /// Get formatted GL with category
  String get glDescription => '$totalGL ($glCategory)';
}