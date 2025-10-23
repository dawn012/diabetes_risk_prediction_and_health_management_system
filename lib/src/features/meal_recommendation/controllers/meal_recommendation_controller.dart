import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/meal_recommendation_preferences.dart';

class MealRecommendationController extends GetxController {
  // Form fields
  final selectedDietPreference = Rxn<String>();
  final selectedAllergens = <String>[].obs;
  final preparationTime = 30.obs;
  final selectedCookingDifficulty = Rxn<String>();

  // Form validation
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Loading state
  final isLoading = false.obs;

  // Diet preference options
  final dietPreferences = [
    'No Preference',
    'Vegetarian',
    'Vegan',
    'Pescatarian',
    'Keto',
    'Mediterranean',
    'Low Carb',
    'High Protein',
    'Gluten Free',
    'Dairy Free',
  ];

  // Common allergens
  final commonAllergens = [
    'Peanuts',
    'Tree Nuts',
    'Milk',
    'Eggs',
    'Fish',
    'Shellfish',
    'Soy',
    'Wheat/Gluten',
    'Sesame',
    'Sulphites',
  ];

  // Cooking difficulty levels
  final cookingDifficulties = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Expert',
  ];

  void toggleAllergen(String allergen) {
    if (selectedAllergens.contains(allergen)) {
      selectedAllergens.remove(allergen);
    } else {
      selectedAllergens.add(allergen);
    }
  }

  bool isAllergenSelected(String allergen) {
    return selectedAllergens.contains(allergen);
  }

  void updatePreparationTime(double value) {
    preparationTime.value = value.round();
  }

  bool get isFormValid {
    return selectedDietPreference.value != null &&
        selectedCookingDifficulty.value != null;
  }

  Future<void> submitMealPreferences() async {
    if (!isFormValid) {
      Get.snackbar(
        'Incomplete Form',
        'Please fill in all required fields',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    try {
      final preferences = MealRecommendationPreferences(
        dietPreference: selectedDietPreference.value,
        allergens: selectedAllergens.toList(),
        preparationTime: preparationTime.value,
        cookingDifficulty: selectedCookingDifficulty.value,
      );

      // TODO: Save preferences to backend/local storage
      await Future.delayed(Duration(seconds: 2)); // Simulate API call

      Get.snackbar(
        'Success',
        'Meal preferences saved successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // TODO: Navigate to meal recommendations or close form
      Get.back();

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save preferences. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void resetForm() {
    selectedDietPreference.value = null;
    selectedAllergens.clear();
    preparationTime.value = 30;
    selectedCookingDifficulty.value = null;
  }
}