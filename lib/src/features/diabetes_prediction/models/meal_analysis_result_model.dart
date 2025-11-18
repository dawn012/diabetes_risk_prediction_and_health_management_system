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

  factory MealAnalysisResult.fromJson(Map<String, dynamic> json) {
    try {
      print('🔧 Parsing MealAnalysisResult from JSON');
      print('📋 Raw JSON keys: ${json.keys.toList()}');

      // 安全类型转换
      final id = _safeString(json['id']);
      final mealNumber = _safeInt(json['mealNumber']);
      final totalGL = _safeDouble(json['totalGL']);
      final glCategory = _safeString(json['glCategory']);
      final error = json['error']?.toString();

      // 处理 foods 数组
      List<DetectedFood> foods = [];
      final foodsData = json['foods'];

      if (foodsData is List) {
        print('🍎 Processing ${foodsData.length} food items');
        for (int i = 0; i < foodsData.length; i++) {
          try {
            final foodItem = foodsData[i];
            if (foodItem is Map<String, dynamic>) {
              foods.add(DetectedFood.fromJson(foodItem));
            } else if (foodItem is Map) {
              // 转换 Map<Object?, Object?> 到 Map<String, dynamic>
              final convertedFood = _convertFoodMap(foodItem);
              foods.add(DetectedFood.fromJson(convertedFood));
            } else {
              print('⚠️ Food item $i has invalid type: ${foodItem.runtimeType}');
            }
          } catch (e) {
            print('❌ Error parsing food item $i: $e');
          }
        }
      } else {
        print('⚠️ Foods data is not a List: ${foodsData?.runtimeType}');
      }

      print('✅ Successfully parsed meal: $id, $mealNumber, GL: $totalGL, category: $glCategory, foods: ${foods.length}');

      return MealAnalysisResult(
        id: id,
        mealNumber: mealNumber,
        foods: foods,
        totalGL: totalGL,
        glCategory: glCategory,
        error: error,
      );
    } catch (e) {
      print('💥 Critical error in MealAnalysisResult.fromJson: $e');
      print('📄 Problematic JSON: $json');
      rethrow;
    }
  }

  // 辅助方法：转换食物 Map
  static Map<String, dynamic> _convertFoodMap(Map<dynamic, dynamic> rawMap) {
    return rawMap.map<String, dynamic>((key, value) {
      final stringKey = key?.toString() ?? '';
      return MapEntry(stringKey, value);
    });
  }

  // 安全类型转换辅助函数
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