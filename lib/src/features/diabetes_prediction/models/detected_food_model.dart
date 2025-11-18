import 'package:hive/hive.dart';

part 'detected_food_model.g.dart';

@HiveType(typeId: 4)
class DetectedFood {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double calories;

  @HiveField(2)
  final double carbs;

  @HiveField(3)
  final double protein;

  @HiveField(4)
  final double fat;

  @HiveField(5)
  final double fiber;

  @HiveField(6)
  final double sugar;

  @HiveField(7)
  final double sodium;

  @HiveField(8)
  final double saturatedFat;

  @HiveField(9)
  final int? giValue;

  @HiveField(10)
  final double? glycemicLoad;

  @HiveField(11)
  final String glCategory;

  const DetectedFood({
    required this.name,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
    required this.saturatedFat,
    this.giValue,
    this.glycemicLoad,
    this.glCategory = 'unknown',
  });

  factory DetectedFood.fromJson(Map<String, dynamic> json) {
    try {
      return DetectedFood(
        name: _safeString(json['name']),
        calories: _safeDouble(json['calories']),
        carbs: _safeDouble(json['carbs']),
        protein: _safeDouble(json['protein']),
        fat: _safeDouble(json['fat']),
        fiber: _safeDouble(json['fiber']),
        sugar: _safeDouble(json['sugar']),
        sodium: _safeDouble(json['sodium']),
        saturatedFat: _safeDouble(json['saturatedFat']),
        giValue: json['giValue'] != null ? _safeInt(json['giValue']) : null,
        glycemicLoad: json['glycemicLoad'] != null ? _safeDouble(json['glycemicLoad']) : null,
        glCategory: _safeString(json['glCategory']),
      );
    } catch (e) {
      print('❌ Error parsing DetectedFood: $e');
      print('Problematic food JSON: $json');
      return DetectedFood(
        name: 'Unknown Food',
        calories: 0,
        carbs: 0,
        protein: 0,
        fat: 0,
        fiber: 0,
        sugar: 0,
        sodium: 0,
        saturatedFat: 0,
        glCategory: 'unknown',
      );
    }
  }

  // 安全类型转换辅助函数
  static String _safeString(dynamic value) {
    if (value == null) return 'Unknown Food';
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
    'name': name,
    'calories': calories,
    'carbs': carbs,
    'protein': protein,
    'fat': fat,
    'fiber': fiber,
    'sugar': sugar,
    'sodium': sodium,
    'saturatedFat': saturatedFat,
    'giValue': giValue,
    'glycemicLoad': glycemicLoad,
    'glCategory': glCategory,
  };

  /// Get net carbs (total carbs - fiber)
  double get netCarbs => (carbs - fiber).clamp(0.0, double.infinity);

  /// Check if GI data is available
  bool get hasGIData => giValue != null && glycemicLoad != null;

  /// Get formatted GL string
  String get glFormatted => glycemicLoad != null
      ? '${glycemicLoad!.toStringAsFixed(1)}'
      : 'N/A';

  @override
  String toString() {
    return 'DetectedFood(name: $name, calories: $calories, carbs: $carbs, GL: $glycemicLoad)';
  }
}