import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/meal_recommendation/models/meal_model.dart';
import '../features/meal_recommendation/models/meal_plan_meal_model.dart';
import '../features/meal_recommendation/models/meal_plan_model.dart';
import '../features/meal_recommendation/models/meal_preference_model.dart';
import '../features/meal_recommendation/models/nutrient_model.dart';
import '../features/personalization/controllers/user_controller.dart';
import '../utils/constants/enums.dart';

class MealHiveStorageManager extends GetxService {
  static MealHiveStorageManager get instance => Get.find();

  // Box names
  static const String _mealPreferencesBox = 'meal_preferences';
  static const String _tempMealPlanBox = 'temp_meal_plan';
  static const String _mealPlansBox = 'meal_plans';
  static const String _mealPlanMealsBox = 'meal_plan_meals';
  static const String _replacedRecipesBox = 'replaced_recipes';

  // 基础 Keys
  static const String _currentPreferencesKey = 'current_preferences';
  static const String _tempMealPlanKey = 'temp_meal_plan';
  static const String _activeMealPlanKey = 'active_meal_plan';

  late Box<MealPreferenceModel> _preferencesBox;
  late Box<MealPlanModel> _tempMealPlanBoxInstance;
  late Box<MealPlanModel> _mealPlansBoxInstance;
  late Box<MealPlanMealModel> _mealPlanMealsBoxInstance;
  late Box<String> _replacedRecipesBoxInstance;

  // ========= 用户相关 key 辅助 =========

  String _userKey(String baseKey) {
    final uid = UserController.instance.user.value.userId;
    if (uid.isEmpty) return baseKey; // 未登录时退回到原来的全局 key
    return '${uid}_$baseKey';
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeHive();
  }

  /// Initialize Hive for meal-related data
  Future<void> _initializeHive() async {
    try {
      // Register all meal-related adapters
      _registerAdapters();

      // Open boxes
      _preferencesBox = await Hive.openBox<MealPreferenceModel>(_mealPreferencesBox);
      _tempMealPlanBoxInstance = await Hive.openBox<MealPlanModel>(_tempMealPlanBox);
      _mealPlansBoxInstance = await Hive.openBox<MealPlanModel>(_mealPlansBox);
      _mealPlanMealsBoxInstance = await Hive.openBox<MealPlanMealModel>(_mealPlanMealsBox);
      _replacedRecipesBoxInstance = await Hive.openBox<String>(_replacedRecipesBox);

      print('✅ Meal Hive Storage initialized successfully');
    } catch (e) {
      print('❌ Error initializing Meal Hive: $e');
      rethrow;
    }
  }

  /// Register all meal-related Hive adapters
  void _registerAdapters() {
    // Only register if not already registered
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(MealPreferenceModelAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(MealPlanModelAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(MealPlanMealModelAdapter());
    }
    // Register enum adapters
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(DietPreferenceAdapter());
    }
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(AllergenAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(CookingMethodAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(MealPlanTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(MealPlanStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(MealTimeSlotAdapter());
    }
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(MealConsumptionStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(15)) {
      Hive.registerAdapter(MealModelAdapter());
    }
    if (!Hive.isAdapterRegistered(16)) {
      Hive.registerAdapter(NutrientModelAdapter());
    }
  }

  // ========== Meal Preferences Management ==========

  /// Get current meal preferences（按用户分）
  MealPreferenceModel getCurrentPreferences() {
    final pref = _preferencesBox.get(_userKey(_currentPreferencesKey));
    if (pref == null) {
      return MealPreferenceModel.empty();
    }
    return pref;
  }

  /// Check if preferences exist（按用户分）
  bool hasPreferences() {
    final pref = _preferencesBox.get(_userKey(_currentPreferencesKey));
    if (pref == null) return false;

    // Check if it has any meaningful data
    return pref.dietPreference != null ||
        pref.allergens.isNotEmpty ||
        pref.preferredCookingMethods.isNotEmpty ||
        pref.maxPreparationTime > 0;
  }

  /// Save meal preferences（按用户分）
  Future<void> savePreferences(MealPreferenceModel preferences) async {
    try {
      await _preferencesBox.put(_userKey(_currentPreferencesKey), preferences);
      print('✅ Meal preferences saved to Hive');
    } catch (e) {
      print('❌ Error saving preferences: $e');
      rethrow;
    }
  }

  /// Update specific preference fields
  Future<void> updatePreferences({
    DietPreference? dietPreference,
    List<Allergen>? allergens,
    List<CookingMethod>? cookingMethods,
    int? maxPreparationTime,
    MealPlanType? planType,
  }) async {
    final current = getCurrentPreferences();
    final updated = current.copyWith(
      dietPreference: dietPreference,
      allergens: allergens,
      preferredCookingMethods: cookingMethods,
      maxPreparationTime: maxPreparationTime,
      planType: planType,
      updatedAt: DateTime.now(),
    );
    await savePreferences(updated);
  }

  /// Clear all preferences（仅清当前用户的）
  Future<void> clearPreferences() async {
    try {
      await _preferencesBox.delete(_userKey(_currentPreferencesKey));
      print('✅ Meal preferences cleared');
    } catch (e) {
      print('❌ Error clearing preferences: $e');
    }
  }

  // ========== Temporary Meal Plan Management (Before Confirmation) ==========

  /// Get temporary meal plan (unconfirmed)（按用户分）
  MealPlanModel? getTempMealPlan() {
    return _tempMealPlanBoxInstance.get(_userKey(_tempMealPlanKey));
  }

  /// Check if temp meal plan exists（按用户分）
  bool hasTempMealPlan() {
    final plan = _tempMealPlanBoxInstance.get(_userKey(_tempMealPlanKey));
    return plan != null && plan.scheduledMeals.isNotEmpty;
  }

  /// Save temporary meal plan (before confirmation)（按用户分）
  Future<void> saveTempMealPlan(MealPlanModel mealPlan) async {
    try {
      await _tempMealPlanBoxInstance.put(_userKey(_tempMealPlanKey), mealPlan);
      print('✅ Temporary meal plan saved to Hive');
    } catch (e) {
      print('❌ Error saving temp meal plan: $e');
      rethrow;
    }
  }

  /// Clear temporary meal plan（按用户分）
  Future<void> clearTempMealPlan() async {
    try {
      await _tempMealPlanBoxInstance.delete(_userKey(_tempMealPlanKey));
      print('✅ Temporary meal plan cleared');
    } catch (e) {
      print('❌ Error clearing temp meal plan: $e');
    }
  }

  // ========== Active Meal Plans Management ==========

  /// Get active meal plan (confirmed)（按用户分）
  MealPlanModel? getActiveMealPlan() {
    return _mealPlansBoxInstance.get(_userKey(_activeMealPlanKey));
  }

  /// Check if active meal plan exists（按用户分）
  bool hasActiveMealPlan() {
    final plan = getActiveMealPlan();
    return plan != null && plan.scheduledMeals.isNotEmpty;
  }

  /// Save active meal plan (confirmed)（按用户分）
  Future<void> saveActiveMealPlan(MealPlanModel mealPlan) async {
    try {
      await _mealPlansBoxInstance.put(_userKey(_activeMealPlanKey), mealPlan);
      print('✅ Active meal plan saved to Hive');
    } catch (e) {
      print('❌ Error saving active meal plan: $e');
      rethrow;
    }
  }

  /// Get all meal plans (for history)
  /// 注意：这里仍然返回 box 里所有数据，如果你想按用户筛选，可以根据 key 过滤
  List<MealPlanModel> getAllMealPlans() {
    return _mealPlansBoxInstance.values.toList();
  }

  /// Save meal plan with custom key（建议外部传入的 key 也带上 uid 或在这里包一层）
  Future<void> saveMealPlan(String key, MealPlanModel mealPlan) async {
    try {
      await _mealPlansBoxInstance.put(_userKey(key), mealPlan);
      print('✅ Meal plan saved with key: ${_userKey(key)}');
    } catch (e) {
      print('❌ Error saving meal plan: $e');
      rethrow;
    }
  }

  /// Get meal plan by key
  MealPlanModel? getMealPlan(String key) {
    return _mealPlansBoxInstance.get(_userKey(key));
  }

  /// Delete meal plan
  Future<void> deleteMealPlan(String key) async {
    try {
      await _mealPlansBoxInstance.delete(_userKey(key));
      print('✅ Meal plan deleted: ${_userKey(key)}');
    } catch (e) {
      print('❌ Error deleting meal plan: $e');
    }
  }

  /// Clear all meal plans（清整个 box。若只清当前用户的，可遍历 keys 过滤 uid 前缀）
  Future<void> clearAllMealPlans() async {
    try {
      await _mealPlansBoxInstance.clear();
      print('✅ All meal plans cleared');
    } catch (e) {
      print('❌ Error clearing meal plans: $e');
    }
  }

  // ========== Meal Plan Meals Management ==========

  /// Get all meals for a specific date
  /// 注意：当前实现是整个 box 的 meals，不区分用户。
  /// 如果你希望按用户区分，可以在 MealPlanMealModel 里加 userId 字段并过滤。
  List<MealPlanMealModel> getMealsForDate(DateTime date) {
    return _mealPlanMealsBoxInstance.values
        .where((meal) => meal.isScheduledForDate(date))
        .toList();
  }

  /// Get meals for specific date and time slot
  List<MealPlanMealModel> getMealsForDateTime(DateTime date, MealTimeSlot timeSlot) {
    return _mealPlanMealsBoxInstance.values
        .where((meal) => meal.isScheduledForDate(date) && meal.mealTimeSlot == timeSlot)
        .toList();
  }

  /// Save meal plan meal
  Future<void> saveMealPlanMeal(MealPlanMealModel meal) async {
    try {
      await _mealPlanMealsBoxInstance.put(meal.mealPlanMealId, meal);
      print('✅ Meal plan meal saved');
    } catch (e) {
      print('❌ Error saving meal plan meal: $e');
      rethrow;
    }
  }

  /// Save multiple meal plan meals
  Future<void> saveMealPlanMeals(List<MealPlanMealModel> meals) async {
    try {
      final Map<String, MealPlanMealModel> mealMap = {
        for (var meal in meals) meal.mealPlanMealId: meal
      };
      await _mealPlanMealsBoxInstance.putAll(mealMap);
      print('✅ ${meals.length} meal plan meals saved');
    } catch (e) {
      print('❌ Error saving meal plan meals: $e');
      rethrow;
    }
  }

  /// Update meal consumption status
  Future<void> updateMealStatus(String mealPlanMealId, MealConsumptionStatus status) async {
    try {
      final meal = _mealPlanMealsBoxInstance.get(mealPlanMealId);
      if (meal != null) {
        final updated = meal.copyWith(status: status);
        await saveMealPlanMeal(updated);
        print('✅ Meal status updated: $status');
      }
    } catch (e) {
      print('❌ Error updating meal status: $e');
    }
  }

  /// Delete meal plan meal
  Future<void> deleteMealPlanMeal(String mealPlanMealId) async {
    try {
      await _mealPlanMealsBoxInstance.delete(mealPlanMealId);
      print('✅ Meal plan meal deleted');
    } catch (e) {
      print('❌ Error deleting meal plan meal: $e');
    }
  }

  /// Clear all meal plan meals（全局）
  Future<void> clearAllMealPlanMeals() async {
    try {
      await _mealPlanMealsBoxInstance.clear();
      print('✅ All meal plan meals cleared');
    } catch (e) {
      print('❌ Error clearing meal plan meals: $e');
    }
  }

  // ========== Helper Methods ==========

  /// Get today's meals
  List<MealPlanMealModel> getTodaysMeals() {
    return getMealsForDate(DateTime.now());
  }

  /// Get upcoming meals (today and future)
  List<MealPlanMealModel> getUpcomingMeals() {
    final now = DateTime.now();
    return _mealPlanMealsBoxInstance.values
        .where((meal) => meal.scheduledDate.isAfter(now) ||
        meal.isScheduledForDate(now))
        .toList();
  }

  /// Get pending meals for today
  List<MealPlanMealModel> getTodaysPendingMeals() {
    return getTodaysMeals().where((meal) => meal.isPending).toList();
  }

  /// Check if meal exists for specific date and time slot
  bool hasMealForSlot(DateTime date, MealTimeSlot timeSlot) {
    return getMealsForDateTime(date, timeSlot).isNotEmpty;
  }

  /// Get meal plan progress for today
  Map<String, dynamic> getTodaysProgress() {
    final todaysMeals = getTodaysMeals();
    final total = todaysMeals.length;
    final consumed = todaysMeals.where((meal) => meal.isConsumed).length;
    final skipped = todaysMeals.where((meal) => meal.isSkipped).length;
    final pending = todaysMeals.where((meal) => meal.isPending).length;

    return {
      'total': total,
      'consumed': consumed,
      'skipped': skipped,
      'pending': pending,
      'completionRate': total > 0 ? consumed / total : 0.0,
    };
  }

  // ========== Watch/Stream Methods ==========

  /// Watch for preferences changes（按当前用户 key）
  Stream<BoxEvent> watchPreferences() {
    return _preferencesBox.watch(key: _userKey(_currentPreferencesKey));
  }

  /// Watch for temp meal plan changes
  Stream<BoxEvent> watchTempMealPlan() {
    return _tempMealPlanBoxInstance.watch(key: _userKey(_tempMealPlanKey));
  }

  /// Watch for active meal plan changes
  Stream<BoxEvent> watchActiveMealPlan() {
    return _mealPlansBoxInstance.watch(key: _userKey(_activeMealPlanKey));
  }

  /// Watch for today's meals changes（仍是全局）
  Stream<List<MealPlanMealModel>> watchTodaysMeals() {
    return _mealPlanMealsBoxInstance.watch().map((event) {
      return getTodaysMeals();
    });
  }

  /// Watch for specific date's meals
  Stream<List<MealPlanMealModel>> watchMealsForDate(DateTime date) {
    return _mealPlanMealsBoxInstance.watch().map((event) {
      return getMealsForDate(date);
    });
  }

  // 添加被替换食谱的管理方法（给 key 加上 uid 前缀）

  String _recipeKey(String recipeId) => _userKey(recipeId);

  /// 添加被替换的食谱ID
  Future<void> addReplacedRecipe(String recipeId) async {
    try {
      await _replacedRecipesBoxInstance.put(_recipeKey(recipeId), recipeId);
      print('✅ Replaced recipe added to Hive: $recipeId');
    } catch (e) {
      print('❌ Error adding replaced recipe: $e');
      rethrow;
    }
  }

  /// 获取所有被替换的食谱ID（当前实现仍然返回 box 里所有值，如要严格区分用户，可在值中也存 uid 再过滤）
  List<String> getReplacedRecipes() {
    return _replacedRecipesBoxInstance.values.toList();
  }

  /// 检查食谱是否被替换过
  bool isRecipeReplaced(String recipeId) {
    return _replacedRecipesBoxInstance.containsKey(_recipeKey(recipeId));
  }

  /// 清空所有被替换的食谱记录（全局）
  Future<void> clearReplacedRecipes() async {
    try {
      await _replacedRecipesBoxInstance.clear();
      print('✅ All replaced recipes cleared from Hive');
    } catch (e) {
      print('❌ Error clearing replaced recipes: $e');
    }
  }

  /// 移除特定的被替换食谱记录
  Future<void> removeReplacedRecipe(String recipeId) async {
    try {
      await _replacedRecipesBoxInstance.delete(_recipeKey(recipeId));
      print('✅ Replaced recipe removed: $recipeId');
    } catch (e) {
      print('❌ Error removing replaced recipe: $e');
    }
  }

  // ========== Cleanup Methods ==========

  /// Clear all meal-related data（整个 box 清空）
  Future<void> clearAllData() async {
    try {
      await clearPreferences();
      await clearTempMealPlan();
      await clearAllMealPlans();
      await clearAllMealPlanMeals();
      await clearReplacedRecipes();
      print('✅ All meal data cleared');
    } catch (e) {
      print('❌ Error clearing all data: $e');
    }
  }

  /// Clear expired meal plan meals (older than 30 days)
  Future<void> clearExpiredMeals() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      final expiredMeals = _mealPlanMealsBoxInstance.values
          .where((meal) => meal.scheduledDate.isBefore(cutoffDate))
          .toList();

      for (final meal in expiredMeals) {
        await deleteMealPlanMeal(meal.mealPlanMealId);
      }

      if (expiredMeals.isNotEmpty) {
        print('✅ ${expiredMeals.length} expired meals cleared');
      }
    } catch (e) {
      print('❌ Error clearing expired meals: $e');
    }
  }

  /// Clear only temporary data (preferences and temp plan remain)
  Future<void> clearTemporaryData() async {
    try {
      await clearTempMealPlan();
      print('✅ Temporary data cleared');
    } catch (e) {
      print('❌ Error clearing temporary data: $e');
    }
  }

  @override
  void onClose() {
    _preferencesBox.close();
    _tempMealPlanBoxInstance.close();
    _mealPlansBoxInstance.close();
    _mealPlanMealsBoxInstance.close();
    _replacedRecipesBoxInstance.close();
    super.onClose();
  }
}
