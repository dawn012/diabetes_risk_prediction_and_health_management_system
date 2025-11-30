import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import '../../../utils/constants/enums.dart';
import '../../../utils/constants/firebase_field_names.dart';
import 'nutrient_model.dart';

part 'meal_model.g.dart';

@HiveType(typeId: 15)
class MealModel {
  @HiveField(0)
  final String mealId;

  @HiveField(1)
  final String mealName;

  @HiveField(2)
  final String mealDescription;

  @HiveField(3)
  final String imageUrl;

  @HiveField(4)
  final List<String> ingredients;

  @HiveField(5)
  final int preparationTime;

  @HiveField(6)
  final int cookingTime;

  @HiveField(7)
  final NutrientModel nutrient;

  @HiveField(8)
  final List<String> instructions;

  @HiveField(9)
  final int serves;

  @HiveField(10)
  final List<String> dishType;

  @HiveField(11)
  final List<String> dietaryRestrictions;

  @HiveField(12)
  final List<String> dietType;

  @HiveField(13)
  final List<CookingMethod> cookingMethod;

  @HiveField(14)
  final String authorName;

  @HiveField(15)
  final List<String>? notes;

  @HiveField(16)
  final String sourceUrl;

  const MealModel({
    required this.mealId,
    required this.mealName,
    required this.mealDescription,
    required this.imageUrl,
    required this.ingredients,
    required this.preparationTime,
    required this.cookingTime,
    required this.nutrient,
    required this.instructions,
    required this.serves,
    required this.dishType,
    required this.dietaryRestrictions,
    required this.dietType,
    required this.cookingMethod,
    required this.authorName,
    this.notes,
    required this.sourceUrl,
  });

  static MealModel empty() {
    return MealModel(
      mealId: '',
      mealName: '',
      mealDescription: '',
      imageUrl: '',
      ingredients: [],
      preparationTime: 0,
      cookingTime: 0,
      nutrient: NutrientModel.empty(),
      instructions: [],
      serves: 1,
      dishType: [],
      dietaryRestrictions: [],
      dietType: [],
      cookingMethod: [],
      authorName: '',
      notes: null,
      sourceUrl: '',
    );
  }

  MealModel copyWith({
    String? mealId,
    String? mealName,
    String? mealDescription,
    String? imageUrl,
    List<String>? ingredients,
    int? preparationTime,
    int? cookingTime,
    NutrientModel? nutrient,
    List<String>? instructions,
    int? serves,
    List<String>? dishType,
    List<String>? dietaryRestrictions,
    List<String>? dietType,
    List<CookingMethod>? cookingMethod,
    String? authorName,
    List<String>? notes,
    String? sourceUrl,
  }) {
    return MealModel(
      mealId: mealId ?? this.mealId,
      mealName: mealName ?? this.mealName,
      mealDescription: mealDescription ?? this.mealDescription,
      imageUrl: imageUrl ?? this.imageUrl,
      ingredients: ingredients ?? this.ingredients,
      preparationTime: preparationTime ?? this.preparationTime,
      cookingTime: cookingTime ?? this.cookingTime,
      nutrient: nutrient ?? this.nutrient,
      instructions: instructions ?? this.instructions,
      serves: serves ?? this.serves,
      dishType: dishType ?? this.dishType,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      dietType: dietType ?? this.dietType,
      cookingMethod: cookingMethod ?? this.cookingMethod,
      authorName: authorName ?? this.authorName,
      notes: notes ?? this.notes,
      sourceUrl: sourceUrl ?? this.sourceUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.mealId: mealId,
      FirebaseFieldNames.mealName: mealName,
      FirebaseFieldNames.mealDescription: mealDescription,
      FirebaseFieldNames.imageUrl: imageUrl,
      FirebaseFieldNames.ingredients: ingredients,
      FirebaseFieldNames.preparationTime: preparationTime,
      FirebaseFieldNames.cookingTime: cookingTime,
      FirebaseFieldNames.nutrient: nutrient.toJson(),
      FirebaseFieldNames.instructions: instructions,
      FirebaseFieldNames.serves: serves,
      FirebaseFieldNames.dishType: dishType,
      FirebaseFieldNames.dietaryRestrictions: dietaryRestrictions,
      FirebaseFieldNames.dietType: dietType,
      FirebaseFieldNames.cookingMethod: cookingMethod.map((e) => e.value).toList(),
      FirebaseFieldNames.authorName: authorName,
      FirebaseFieldNames.notes: notes,
      FirebaseFieldNames.sourceUrl: sourceUrl,
    };
  }

  factory MealModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return MealModel.empty();

    return MealModel(
      mealId: data[FirebaseFieldNames.mealId] ?? '',
      mealName: data[FirebaseFieldNames.mealName] ?? '',
      mealDescription: data[FirebaseFieldNames.mealDescription] ?? '',
      imageUrl: data[FirebaseFieldNames.imageUrl] ?? '',
      ingredients: List<String>.from(data[FirebaseFieldNames.ingredients] ?? []),
      preparationTime: data[FirebaseFieldNames.preparationTime] ?? 0,
      cookingTime: data[FirebaseFieldNames.cookingTime] ?? 0,
      nutrient: data[FirebaseFieldNames.nutrient] != null
          ? NutrientModel.fromMap(data[FirebaseFieldNames.nutrient])
          : NutrientModel.empty(),
      instructions: List<String>.from(data[FirebaseFieldNames.instructions] ?? []),
      serves: data[FirebaseFieldNames.serves] ?? 1,
      dishType: List<String>.from(data[FirebaseFieldNames.dishType] ?? []),
      dietaryRestrictions: List<String>.from(data[FirebaseFieldNames.dietaryRestrictions] ?? []),
      dietType: List<String>.from(data[FirebaseFieldNames.dietType] ?? []),
      cookingMethod: (data[FirebaseFieldNames.cookingMethod] as List<dynamic>?)
          ?.map((e) => CookingMethod.fromString(e.toString()))
          .toList() ?? [],
      authorName: data[FirebaseFieldNames.authorName] ?? '',
      notes: data[FirebaseFieldNames.notes] != null
          ? List<String>.from(data[FirebaseFieldNames.notes]!)
          : null,
      sourceUrl: data[FirebaseFieldNames.sourceUrl] ?? '',
    );
  }
}