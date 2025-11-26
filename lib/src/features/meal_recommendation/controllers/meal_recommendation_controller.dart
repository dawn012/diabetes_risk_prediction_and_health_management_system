import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/diabetes_prediction/diabetes_prediction_repository.dart';
import '../../../data/repositories/meal_recommendation/meal_repository.dart';
import '../../../data/repositories/subscription/subscription_repository.dart';
import '../../../services/meal_hive_storage_manager.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/meal_time_constants.dart';
import '../../diabetes_prediction/controllers/diabetes_prediction_flow_manager.dart';
import '../../personalization/controllers/user_controller.dart';
import '../../subscription/views/subscription_plan_selection_screen.dart';
import '../models/meal_model.dart';
import '../models/meal_plan_meal_model.dart';
import '../models/meal_plan_model.dart';
import '../models/meal_preference_model.dart';
import '../views/meal_plan_preview_screen.dart';

class MealRecommendationController extends GetxController {
  static MealRecommendationController get instance => Get.find();

  final mealRepo = Get.put(MealRepository());
  final subscriptionRepo = Get.put(SubscriptionRepository());
  final mealHiveStorage = Get.put(MealHiveStorageManager());

  // Form fields
  final selectedDietPreference = Rxn<DietPreference>();
  final selectedAllergens = <Allergen>[].obs;
  final selectedCookingMethods = <CookingMethod>[].obs;
  final preparationTime = 30.obs;
  final selectedPlanType = Rx<MealPlanType>(MealPlanType.daily);

  // Form validation
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Loading states
  final isLoading = false.obs;
  final isGenerating = false.obs;
  final isReplacingMeal = false.obs;

  // Subscription and prediction checks
  final hasActiveSubscription = false.obs;
  final hasDiabetesPrediction = false.obs;
  final daysSinceLastPrediction = 0.obs;

  StreamSubscription? _activeSubscriptionStream;

  // Current User
  final currentUser = UserController.instance.user.value;

  // Diet preference options (matching DietPreference enum)
  final dietPreferences = [
    'No Preference',
    ...DietPreference.values.map((e) => e.displayName).toList(),
  ];

  // Common allergens (matching Allergen enum)
  final commonAllergens = Allergen.values.map((e) => e.displayName).toList();

  // Cooking methods (matching CookingMethod enum)
  final cookingMethods =
  CookingMethod.values.map((e) => e.displayName).toList();

  // Generated meal plan (before confirmation)
  final Rx<MealPlanModel?> generatedMealPlan = Rx<MealPlanModel?>(null);

  // API endpoint
  static const String mealRecommendationApiUrl =
      'YOUR_MEAL_RECOMMENDATION_API_URL';

  @override
  void onInit() {
    super.onInit();
    _initializeData();
    _setupActiveSubscriptionListener();
  }

  @override
  void onClose() {
    _activeSubscriptionStream?.cancel();
    super.onClose();
  }

  Future<void> _initializeData() async {
    await _checkDiabetesPredictionStatus();
    await _loadMealPreferenceFromLocal();
    await _loadTempMealPlanFromLocal();
  }

  /// Setup active subscription status listener
  void _setupActiveSubscriptionListener() {
    _activeSubscriptionStream?.cancel();

    _activeSubscriptionStream = subscriptionRepo
        .streamHasActiveSubscription(currentUser.userId)
        .listen((hasActive) {
      print('Active subscription status changed: $hasActive');
      hasActiveSubscription.value = hasActive;
    }, onError: (error) {
      print('Error in active subscription stream: $error');
      hasActiveSubscription.value = false;
    });
  }

  /// Check diabetes prediction status
  Future<void> _checkDiabetesPredictionStatus() async {
    try {
      final user = AuthenticationRepository.instance.authUser;
      if (user == null) {
        hasDiabetesPrediction.value = false;
        daysSinceLastPrediction.value = 0;
        return;
      }

      final predictionRepository = DiabetesPredictionRepository.instance;
      final latestPrediction =
      await predictionRepository.getLatestPrediction(user.uid);

      if (latestPrediction != null) {
        hasDiabetesPrediction.value = true;
        final daysSince =
            DateTime.now().difference(latestPrediction.predictionDateTime).inDays;
        daysSinceLastPrediction.value = daysSince;
      } else {
        hasDiabetesPrediction.value = false;
        daysSinceLastPrediction.value = 0;
      }
    } catch (e) {
      print('Error checking diabetes prediction: $e');
      hasDiabetesPrediction.value = false;
      daysSinceLastPrediction.value = 0;
    }
  }

  /// Load meal preference from Hive (local storage)
  Future<void> _loadMealPreferenceFromLocal() async {
    try {
      // Check if preference exists in Hive
      if (mealHiveStorage.hasPreferences()) {
        final preference = mealHiveStorage.getCurrentPreferences();
        if (preference.dietPreference != null ||
            preference.allergens.isNotEmpty ||
            preference.preferredCookingMethods.isNotEmpty) {
          _populateFormWithPreference(preference);
          print('✅ Loaded meal preference from Hive');
          return;
        }
      }

      // If not in Hive, try to fetch from Firestore
      final preference = await mealRepo.getMealPreference();
      if (preference != null) {
        _populateFormWithPreference(preference);
        // Save to Hive for next time
        await mealHiveStorage.savePreferences(preference);
        print('✅ Loaded meal preference from Firestore and saved to Hive');
      }
    } catch (e) {
      print('Error loading meal preference: $e');
    }
  }

  /// Load temporary meal plan from Hive (local storage)
  Future<void> _loadTempMealPlanFromLocal() async {
    try {
      // Check if temp plan exists in Hive
      if (mealHiveStorage.hasActiveMealPlan()) {
        final tempPlan = mealHiveStorage.getActiveMealPlan();
        if (tempPlan != null && tempPlan.scheduledMeals.isNotEmpty) {
          generatedMealPlan.value = tempPlan;
          print('✅ Loaded temp meal plan from Hive');

          // Navigate to preview screen if plan exists
          Future.delayed(const Duration(milliseconds: 500), () {
            Get.to(() => const MealPlanPreviewScreen());
          });
        }
      }
    } catch (e) {
      print('Error loading temp meal plan: $e');
    }
  }

  /// Populate form with existing preference
  void _populateFormWithPreference(MealPreferenceModel preference) {
    selectedDietPreference.value = preference.dietPreference;
    selectedAllergens.assignAll(preference.allergens);
    selectedCookingMethods.assignAll(preference.preferredCookingMethods);
    preparationTime.value = preference.maxPreparationTime;
    selectedPlanType.value = preference.planType;
  }

  /// Toggle allergen selection
  void toggleAllergen(String allergenName) {
    final allergen =
    Allergen.values.firstWhere((a) => a.displayName == allergenName);

    if (selectedAllergens.contains(allergen)) {
      selectedAllergens.remove(allergen);
    } else {
      selectedAllergens.add(allergen);
    }
  }

  /// Toggle cooking method selection
  void toggleCookingMethod(String methodName) {
    final method =
    CookingMethod.values.firstWhere((m) => m.displayName == methodName);

    if (selectedCookingMethods.contains(method)) {
      selectedCookingMethods.remove(method);
    } else {
      selectedCookingMethods.add(method);
    }
  }

  /// Check if allergen is selected
  bool isAllergenSelected(String allergenName) {
    final allergen =
    Allergen.values.firstWhere((a) => a.displayName == allergenName);
    return selectedAllergens.contains(allergen);
  }

  /// Check if cooking method is selected
  bool isCookingMethodSelected(String methodName) {
    final method =
    CookingMethod.values.firstWhere((m) => m.displayName == methodName);
    return selectedCookingMethods.contains(method);
  }

  /// Update preparation time
  void updatePreparationTime(double value) {
    preparationTime.value = value.round();
  }

  /// Check if form is valid (diet preference is optional now)
  bool get isFormValid {
    return true; // Always valid since all fields are optional
  }

  /// Check if can generate meal recommendation
  bool get canGenerateRecommendation {
    return hasActiveSubscription.value && hasDiabetesPrediction.value;
  }

  /// Get warning message for prediction age
  String? get predictionWarningMessage {
    if (!hasDiabetesPrediction.value) {
      return 'Please complete a diabetes risk prediction first';
    }

    if (daysSinceLastPrediction.value > 7) {
      return 'Your last prediction was ${daysSinceLastPrediction.value} days ago. Consider updating for better recommendations.';
    }

    return null;
  }

  /// Submit meal preferences and generate meal plan
  Future<void> submitMealPreferences() async {
    if (!canGenerateRecommendation) {
      if (!hasActiveSubscription.value) {
        TLoaders.warningSnackBar(
          title: 'Subscription Required',
          message: 'Please subscribe to access meal recommendations',
        );
      } else if (!hasDiabetesPrediction.value) {
        TLoaders.warningSnackBar(
          title: 'Prediction Required',
          message: 'Please complete a diabetes risk prediction first',
        );
      }
      return;
    }

    try {
      isGenerating.value = true;

      // Create preference model
      final preference = MealPreferenceModel(
        dietPreference: selectedDietPreference.value,
        allergens: selectedAllergens.toList(),
        preferredCookingMethods: selectedCookingMethods.toList(),
        maxPreparationTime: preparationTime.value,
        planType: selectedPlanType.value,
        updatedAt: DateTime.now(),
      );

      // Save preference to Hive (local) first
      await mealHiveStorage.savePreferences(preference);
      print('✅ Saved preference to Hive');

      // Save preference to Firestore
      await mealRepo.saveMealPreference(preference);
      print('✅ Saved preference to Firestore');

      // Calculate remaining meals for today
      final remainingSlots =
      MealTimeConstants.getRemainingMealSlots(DateTime.now());

      if (remainingSlots.isEmpty &&
          selectedPlanType.value == MealPlanType.daily) {
        TLoaders.warningSnackBar(
          title: 'No Meals Remaining',
          message:
          'All meal slots for today have passed. Try generating a weekly plan instead.',
        );
        isGenerating.value = false;
        return;
      }

      // Generate meal plan via API
      final mealPlan = await _generateMealPlan(preference, remainingSlots);

      if (mealPlan != null) {
        generatedMealPlan.value = mealPlan;

        // Save to Hive (temporary storage until confirmed)
        await mealHiveStorage.saveActiveMealPlan(mealPlan);
        print('✅ Saved temp meal plan to Hive');

        TLoaders.successSnackBar(
          title: 'Success',
          message: 'Meal plan generated successfully!',
        );

        // Navigate to meal plan preview screen
        Get.to(() => const MealPlanPreviewScreen());
      }
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to generate meal plan: ${e.toString()}',
      );
    } finally {
      isGenerating.value = false;
    }
  }

  /// Generate meal plan via API
  Future<MealPlanModel?> _generateMealPlan(
      MealPreferenceModel preference,
      List<MealTimeSlot> remainingSlots,
      ) async {
    try {
      // TODO: Replace with your actual API call
      // This is a placeholder showing the expected structure

      /*
      final response = await http.post(
        Uri.parse(mealRecommendationApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': mealRepo.userId,
          'dietPreference': preference.dietPreference?.value,
          'allergens': preference.allergens.map((e) => e.value).toList(),
          'maxPreparationTime': preference.maxPreparationTime,
          'planType': preference.planType.value,
          'remainingSlots': remainingSlots.map((e) => e.value).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final mealIds = List<String>.from(data['mealIds']);

        // Fetch meals and create plan
        return await _createMealPlanFromMealIds(mealIds, remainingSlots);
      }
      */

      throw 'API integration pending';
    } catch (e) {
      print('Error generating meal plan: $e');
      rethrow;
    }
  }

  /// Create meal plan from meal IDs
  Future<MealPlanModel> _createMealPlanFromMealIds(
      List<String> mealIds,
      List<MealTimeSlot> slots,
      ) async {
    try {
      // Fetch meals
      final meals = await mealRepo.getMealsByIds(mealIds);

      if (meals.length != mealIds.length) {
        throw 'Some meals could not be found';
      }

      // Create scheduled meals
      final scheduledMeals = <MealPlanMealModel>[];
      final now = DateTime.now();

      for (int i = 0; i < meals.length; i++) {
        final slot = slots[i % slots.length];
        final scheduledDate = now.add(Duration(days: i ~/ slots.length));

        scheduledMeals.add(MealPlanMealModel(
          mealPlanMealId: const Uuid().v4(),
          meal: meals[i],
          scheduledDate: scheduledDate,
          mealTimeSlot: slot,
          status: MealConsumptionStatus.pending,
        ));
      }

      // Create meal plan
      return MealPlanModel(
        mealPlanId: const Uuid().v4(),
        userId: mealRepo.userId!,
        scheduledMeals: scheduledMeals,
        planType: selectedPlanType.value,
        startDateTime: now,
        endDateTime: selectedPlanType.value == MealPlanType.daily
            ? now
            : now.add(const Duration(days: 7)),
        adherence: 0,
        status: MealPlanStatus.confirmed,
      );
    } catch (e) {
      print('Error creating meal plan: $e');
      rethrow;
    }
  }

  /// Replace a specific meal in the plan
  Future<void> replaceMeal(String mealPlanMealId) async {
    if (generatedMealPlan.value == null) return;

    try {
      isReplacingMeal.value = true;

      // TODO: Call API to get replacement meal
      // For now, this is a placeholder

      /*
      final response = await http.post(
        Uri.parse('$mealRecommendationApiUrl/replace'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'mealPlanMealId': mealPlanMealId,
          'preferences': {
            'dietPreference': selectedDietPreference.value?.value,
            'allergens': selectedAllergens.map((e) => e.value).toList(),
            'preferredCookingMethods': selectedCookingMethods.map((e) => e.value).toList(),
            'maxPreparationTime': preparationTime.value,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newMealId = data['mealId'];

        // Fetch new meal and update plan
        final newMeal = await mealRepo.getMealById(newMealId);
        if (newMeal != null) {
          _updateMealInPlan(mealPlanMealId, newMeal);
        }
      }
      */

      throw 'API integration pending';
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to replace meal: ${e.toString()}',
      );
    } finally {
      isReplacingMeal.value = false;
    }
  }

  /// Update meal in the generated plan
  void _updateMealInPlan(String mealPlanMealId, MealModel newMeal) {
    final currentPlan = generatedMealPlan.value;
    if (currentPlan == null) return;

    final updatedMeals = currentPlan.scheduledMeals.map((scheduledMeal) {
      if (scheduledMeal.mealPlanMealId == mealPlanMealId) {
        return scheduledMeal.copyWith(meal: newMeal);
      }
      return scheduledMeal;
    }).toList();

    generatedMealPlan.value = currentPlan.copyWith(scheduledMeals: updatedMeals);

    // Update Hive storage
    mealHiveStorage.saveActiveMealPlan(generatedMealPlan.value!);
  }

  /// Regenerate entire meal plan
  Future<void> regenerateMealPlan() async {
    await submitMealPreferences();
  }

  /// Confirm meal plan and save to Firestore
  Future<void> confirmMealPlan() async {
    if (generatedMealPlan.value == null) return;

    try {
      isLoading.value = true;

      await mealRepo.saveMealPlan(generatedMealPlan.value!);

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Meal plan confirmed and saved!',
      );

      // Clear generated plan and temp storage
      generatedMealPlan.value = null;
      await mealHiveStorage.deleteMealPlan('active_meal_plan');

      // Navigate back
      Get.back();
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to save meal plan: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Discard generated meal plan
  Future<void> discardMealPlan() async {
    generatedMealPlan.value = null;
    await mealHiveStorage.deleteMealPlan('active_meal_plan');
  }

  /// Reset form
  void resetForm() {
    selectedDietPreference.value = null;
    selectedAllergens.clear();
    selectedCookingMethods.clear();
    preparationTime.value = 30;
    selectedPlanType.value = MealPlanType.daily;
  }

  Future<void> refreshData() async {
    await _initializeData();
  }

  /// Navigate to subscription page
  void navigateToSubscription() {
    Get.to(() => SubscriptionPlanScreen());
  }

  /// Navigate to diabetes prediction
  void navigateToDiabetesPrediction() {
    final flowManager = Get.put(DiabetesPredictionFlowManager());
    flowManager.enterPredictionFlow();
  }
}