// meal_recommendation_model.dart
class MealRecommendationPreferences {
  String? dietPreference;
  List<String> allergens;
  int preparationTime; // in minutes
  String? cookingDifficulty;

  MealRecommendationPreferences({
    this.dietPreference,
    this.allergens = const [],
    this.preparationTime = 30,
    this.cookingDifficulty,
  });

  Map<String, dynamic> toJson() {
    return {
      'dietPreference': dietPreference,
      'allergens': allergens,
      'preparationTime': preparationTime,
      'cookingDifficulty': cookingDifficulty,
    };
  }

  factory MealRecommendationPreferences.fromJson(Map<String, dynamic> json) {
    return MealRecommendationPreferences(
      dietPreference: json['dietPreference'],
      allergens: List<String>.from(json['allergens'] ?? []),
      preparationTime: json['preparationTime'] ?? 30,
      cookingDifficulty: json['cookingDifficulty'],
    );
  }
}