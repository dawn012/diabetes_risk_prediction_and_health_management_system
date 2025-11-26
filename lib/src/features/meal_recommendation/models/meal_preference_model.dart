import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../../utils/constants/enums.dart';
import '../../../utils/constants/firebase_field_names.dart';

part 'meal_preference_model.g.dart';

@HiveType(typeId: 5)
class MealPreferenceModel extends HiveObject {
  @HiveField(0)
  final DietPreference? dietPreference;

  @HiveField(1)
  final List<Allergen> allergens;

  @HiveField(2)
  final List<CookingMethod> preferredCookingMethods;

  @HiveField(3)
  final int maxPreparationTime;

  @HiveField(4)
  final MealPlanType planType;

  @HiveField(5)
  final DateTime updatedAt;

  MealPreferenceModel({
    this.dietPreference,
    required this.allergens,
    required this.preferredCookingMethods,
    required this.maxPreparationTime,
    required this.planType,
    required this.updatedAt,
  });

  factory MealPreferenceModel.empty() {
    return MealPreferenceModel(
      dietPreference: null,
      allergens: [],
      preferredCookingMethods: [],
      maxPreparationTime: 0,
      planType: MealPlanType.daily,
      updatedAt: DateTime.now(),
    );
  }

  MealPreferenceModel copyWith({
    DietPreference? dietPreference,
    List<Allergen>? allergens,
    List<CookingMethod>? preferredCookingMethods,
    int? maxPreparationTime,
    MealPlanType? planType,
    DateTime? updatedAt,
  }) {
    return MealPreferenceModel(
      dietPreference: dietPreference ?? this.dietPreference,
      allergens: allergens ?? this.allergens,
      preferredCookingMethods: preferredCookingMethods ?? this.preferredCookingMethods,
      maxPreparationTime: maxPreparationTime ?? this.maxPreparationTime,
      planType: planType ?? this.planType,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (dietPreference != null) FirebaseFieldNames.dietPreference: dietPreference!.value,
      FirebaseFieldNames.allergens: allergens.map((e) => e.value).toList(),
      FirebaseFieldNames.preferredCookingMethods: preferredCookingMethods.map((e) => e.value).toList(),
      FirebaseFieldNames.maxPreparationTime: maxPreparationTime,
      FirebaseFieldNames.planType: planType.value,
      FirebaseFieldNames.updatedAt: updatedAt.millisecondsSinceEpoch,
    };
  }

  factory MealPreferenceModel.fromMap(Map<String, dynamic> data) {
    return MealPreferenceModel(
      dietPreference: data[FirebaseFieldNames.dietPreference] != null
          ? DietPreference.fromString(data[FirebaseFieldNames.dietPreference])
          : null,
      allergens: (data[FirebaseFieldNames.allergens] as List<dynamic>?)
          ?.map((e) => Allergen.fromString(e.toString()))
          .toList() ?? [],
      preferredCookingMethods: (data[FirebaseFieldNames.preferredCookingMethods] as List<dynamic>?)
          ?.map((e) => CookingMethod.fromString(e.toString()))
          .toList() ?? [],
      maxPreparationTime: data[FirebaseFieldNames.maxPreparationTime] ?? 0,
      planType: MealPlanType.fromString(data[FirebaseFieldNames.planType] ?? 'daily'),
      updatedAt: data[FirebaseFieldNames.updatedAt] != null
          ? DateTime.fromMillisecondsSinceEpoch(data[FirebaseFieldNames.updatedAt])
          : DateTime.now(),
    );
  }

  // Helper methods
  bool get hasDietPreference => dietPreference != null;
  bool get hasAllergens => allergens.isNotEmpty;
  bool get hasPreferredCookingMethods => preferredCookingMethods.isNotEmpty;
  bool get hasMaxPreparationTime => maxPreparationTime > 0;

  bool avoidsAllergen(Allergen allergen) {
    return allergens.contains(allergen);
  }

  bool prefersCookingMethod(CookingMethod method) {
    return preferredCookingMethods.isEmpty || preferredCookingMethods.contains(method);
  }

  bool isPreparationTimeAcceptable(int preparationTime) {
    return maxPreparationTime == 0 || preparationTime <= maxPreparationTime;
  }

  String get allergensDisplay {
    if (allergens.isEmpty) return 'No allergies';
    return allergens.map((e) => e.displayName).join(', ');
  }

  String get cookingMethodsDisplay {
    if (preferredCookingMethods.isEmpty) return 'Any cooking method';
    return preferredCookingMethods.map((e) => e.displayName).join(', ');
  }

  String get dietPreferenceDisplay {
    return dietPreference?.displayName ?? 'No specific diet';
  }

  String get planTypeDisplay {
    return planType.value.capitalizeFirst!;
  }
}