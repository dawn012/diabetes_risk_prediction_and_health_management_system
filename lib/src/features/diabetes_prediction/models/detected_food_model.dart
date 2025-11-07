/// Model for individual food item detected in a meal
class DetectedFood {
  final String name;
  final double calories;
  final double carbs;
  final double protein;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium;
  final double saturatedFat;
  final int? giValue;
  final double? glycemicLoad;
  final String glCategory; // "low", "medium", "high", "unknown"

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

  factory DetectedFood.fromJson(Map<String, dynamic> json) => DetectedFood(
    name: json['name'] ?? 'Unknown Food',
    calories: (json['calories'] ?? 0).toDouble(),
    carbs: (json['carbs'] ?? 0).toDouble(),
    protein: (json['protein'] ?? 0).toDouble(),
    fat: (json['fat'] ?? 0).toDouble(),
    fiber: (json['fiber'] ?? 0).toDouble(),
    sugar: (json['sugar'] ?? 0).toDouble(),
    sodium: (json['sodium'] ?? 0).toDouble(),
    saturatedFat: (json['saturatedFat'] ?? 0).toDouble(),
    giValue: json['giValue'],
    glycemicLoad: json['glycemicLoad']?.toDouble(),
    glCategory: json['glCategory'] ?? 'unknown',
  );

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
}