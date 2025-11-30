import 'package:hive/hive.dart';

import '../../../utils/constants/firebase_field_names.dart';

part 'nutrient_model.g.dart';

@HiveType(typeId: 16)
class NutrientModel {
  @HiveField(0)
  final double calories;

  @HiveField(1)
  final double protein;

  @HiveField(2)
  final double fat;

  @HiveField(3)
  final double saturatedFat;

  @HiveField(4)
  final double carbohydrates;

  @HiveField(5)
  final double fiber;

  @HiveField(6)
  final double sugar;

  @HiveField(7)
  final double sodium;

  @HiveField(8)
  final double cholesterol;

  const NutrientModel({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.saturatedFat,
    required this.carbohydrates,
    required this.fiber,
    required this.sugar,
    required this.sodium,
    required this.cholesterol,
  });

  static NutrientModel empty() {
    return NutrientModel(
      calories: 0,
      protein: 0,
      fat: 0,
      saturatedFat: 0,
      carbohydrates: 0,
      fiber: 0,
      sugar: 0,
      sodium: 0,
      cholesterol: 0,
    );
  }

  NutrientModel copyWith({
    double? calories,
    double? protein,
    double? fat,
    double? saturatedFat,
    double? carbohydrates,
    double? fiber,
    double? sugar,
    double? sodium,
    double? cholesterol,
  }) {
    return NutrientModel(
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      saturatedFat: saturatedFat ?? this.saturatedFat,
      carbohydrates: carbohydrates ?? this.carbohydrates,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      sodium: sodium ?? this.sodium,
      cholesterol: cholesterol ?? this.cholesterol,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.calories: calories,
      FirebaseFieldNames.protein: protein,
      FirebaseFieldNames.fat: fat,
      FirebaseFieldNames.saturatedFat: saturatedFat,
      FirebaseFieldNames.carbohydrates: carbohydrates,
      FirebaseFieldNames.fiber: fiber,
      FirebaseFieldNames.sugar: sugar,
      FirebaseFieldNames.sodium: sodium,
      FirebaseFieldNames.cholesterol: cholesterol,
    };
  }

  factory NutrientModel.fromMap(Map<String, dynamic> data) {
    return NutrientModel(
      calories: (data[FirebaseFieldNames.calories] ?? 0).toDouble(),
      protein: (data[FirebaseFieldNames.protein] ?? 0).toDouble(),
      fat: (data[FirebaseFieldNames.fat] ?? 0).toDouble(),
      saturatedFat: (data[FirebaseFieldNames.saturatedFat] ?? 0).toDouble(),
      carbohydrates: (data[FirebaseFieldNames.carbohydrates] ?? 0).toDouble(),
      fiber: (data[FirebaseFieldNames.fiber] ?? 0).toDouble(),
      sugar: (data[FirebaseFieldNames.sugar] ?? 0).toDouble(),
      sodium: (data[FirebaseFieldNames.sodium] ?? 0).toDouble(),
      cholesterol: (data[FirebaseFieldNames.cholesterol] ?? 0).toDouble(),
    );
  }
}