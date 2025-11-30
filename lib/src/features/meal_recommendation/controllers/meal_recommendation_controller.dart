import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/diabetes_prediction/diabetes_prediction_repository.dart';
import '../../../data/repositories/meal_recommendation/meal_repository.dart';
import '../../../data/repositories/subscription/subscription_repository.dart';
import '../../../services/meal_hive_storage_manager.dart';
import '../../../services/meal_recommendation_api_service.dart';
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

  // 存储本地替换的食谱ID
  final _localReplacedRecipeIds = <String>[];

  // Diet preference options
  final dietPreferences = [
    'No Preference',
    ...DietPreference.values.map((e) => e.displayName).toList(),
  ];

  // Common allergens
  final commonAllergens = Allergen.values.map((e) => e.displayName).toList();

  // Cooking methods
  final cookingMethods =
      CookingMethod.values.map((e) => e.displayName).toList();

  // Generated meal plan (before confirmation)
  final Rx<MealPlanModel?> generatedMealPlan = Rx<MealPlanModel?>(null);

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

  void _setupActiveSubscriptionListener() {
    _activeSubscriptionStream?.cancel();

    _activeSubscriptionStream = subscriptionRepo
        .streamHasActiveSubscription(currentUser.userId)
        .listen((hasActive) {
      hasActiveSubscription.value = hasActive;
    }, onError: (error) {
      print('Error in active subscription stream: $error');
      hasActiveSubscription.value = false;
    });
  }

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
        final daysSince = DateTime.now()
            .difference(latestPrediction.predictionDateTime)
            .inDays;
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

  Future<void> _loadMealPreferenceFromLocal() async {
    try {
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

      final preference = await mealRepo.getMealPreference();
      if (preference != null) {
        _populateFormWithPreference(preference);
        await mealHiveStorage.savePreferences(preference);
        print('✅ Loaded meal preference from Firestore and saved to Hive');
      }
    } catch (e) {
      print('Error loading meal preference: $e');
    }
  }

  Future<void> _loadTempMealPlanFromLocal() async {
    try {
      if (mealHiveStorage.hasActiveMealPlan()) {
        final tempPlan = mealHiveStorage.getActiveMealPlan();
        if (tempPlan != null && tempPlan.scheduledMeals.isNotEmpty) {
          generatedMealPlan.value = tempPlan;
          print('✅ Loaded temp meal plan from Hive');

          Future.delayed(const Duration(milliseconds: 500), () {
            Get.to(() => const MealPlanPreviewScreen());
          });
        }
      }
    } catch (e) {
      print('Error loading temp meal plan: $e');
    }
  }

  void _populateFormWithPreference(MealPreferenceModel preference) {
    selectedDietPreference.value = preference.dietPreference;
    selectedAllergens.assignAll(preference.allergens);
    selectedCookingMethods.assignAll(preference.preferredCookingMethods);
    preparationTime.value = preference.maxPreparationTime;
    selectedPlanType.value = preference.planType;
  }

  void toggleAllergen(String allergenName) {
    final allergen =
        Allergen.values.firstWhere((a) => a.displayName == allergenName);

    if (selectedAllergens.contains(allergen)) {
      selectedAllergens.remove(allergen);
    } else {
      selectedAllergens.add(allergen);
    }
  }

  void toggleCookingMethod(String methodName) {
    final method =
        CookingMethod.values.firstWhere((m) => m.displayName == methodName);

    if (selectedCookingMethods.contains(method)) {
      selectedCookingMethods.remove(method);
    } else {
      selectedCookingMethods.add(method);
    }
  }

  bool isAllergenSelected(String allergenName) {
    final allergen =
        Allergen.values.firstWhere((a) => a.displayName == allergenName);
    return selectedAllergens.contains(allergen);
  }

  bool isCookingMethodSelected(String methodName) {
    final method =
        CookingMethod.values.firstWhere((m) => m.displayName == methodName);
    return selectedCookingMethods.contains(method);
  }

  void updatePreparationTime(double value) {
    preparationTime.value = value.round();
  }

  bool get isFormValid => true;

  bool get canGenerateRecommendation {
    return hasActiveSubscription.value && hasDiabetesPrediction.value;
  }

  String? get predictionWarningMessage {
    if (!hasDiabetesPrediction.value) {
      return 'Please complete a diabetes risk prediction first';
    }

    if (daysSinceLastPrediction.value > 7) {
      return 'Your last prediction was ${daysSinceLastPrediction.value} days ago. Consider updating for better recommendations.';
    }

    return null;
  }

  /// 构建用户偏好的 API 请求格式
  Future<Map<String, dynamic>> _buildUserPreferencesForApi() async {
    // 获取最新的 diabetes prediction
    final predictionRepo = DiabetesPredictionRepository.instance;
    final latestPrediction =
        await predictionRepo.getLatestPrediction(currentUser.userId);

    return {
      'age': currentUser.profile.age,
      'gender': currentUser.profile.gender.toLowerCase(),
      'diabetes_risk': latestPrediction?.riskLevel ?? 'medium',
      // 这里需要从实际的 prediction 获取
      'diet_preference': selectedDietPreference.value != null
          ? [selectedDietPreference.value!.value]
          : [],
      'allergens': selectedAllergens.map((e) => e.value).toList(),
      'cooking_methods': selectedCookingMethods.map((e) => e.value).toList(),
      'max_cooking_time': preparationTime.value,
    };
  }

  /// 获取过去计划的食谱ID（用于避免重复）
  /// 只获取最近30天内的计划，且最多返回40%的食谱ID
  Future<List<String>> _getPastRecipeIds() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));

      // 1. 从 Firestore 获取已保存的计划
      final pastPlans = await mealRepo.getPastMealPlans();

      // 过滤最近30天的计划
      final recentPlans = pastPlans
          .where((plan) => plan.endDateTime.isAfter(cutoffDate))
          .toList();

      // 获取所有食谱ID
      final Set<String> allRecipeIds = {};

      // 2. 添加已保存计划的食谱ID
      for (var plan in recentPlans) {
        for (var meal in plan.scheduledMeals) {
          allRecipeIds.add(meal.meal.mealId);
        }
      }

      // 3. 添加当前临时计划的食谱ID（如果存在）
      if (generatedMealPlan.value != null) {
        for (var meal in generatedMealPlan.value!.scheduledMeals) {
          allRecipeIds.add(meal.meal.mealId);
        }
        print(
            '✅ Added ${generatedMealPlan.value!.scheduledMeals.length} recipes from current temp plan');
      }

      // 4. 添加 Hive 中存储的临时计划的食谱ID
      final hiveTempPlan = mealHiveStorage.getTempMealPlan();
      if (hiveTempPlan != null && hiveTempPlan.scheduledMeals.isNotEmpty) {
        for (var meal in hiveTempPlan.scheduledMeals) {
          allRecipeIds.add(meal.meal.mealId);
        }
        print(
            '✅ Added ${hiveTempPlan.scheduledMeals.length} recipes from Hive temp plan');
      }

      // 5. 添加被替换的食谱ID（从 Hive 获取）
      final replacedRecipes = mealHiveStorage.getReplacedRecipes();
      allRecipeIds.addAll(replacedRecipes);

      if (allRecipeIds.isEmpty) return [];

      print('📊 Total unique recipes in history: ${allRecipeIds.length}');

      // 计算要避免重复的数量 (60%，因为我们允许40%重复)
      final avoidCount = (allRecipeIds.length * 0.6).round();
      final result = allRecipeIds.take(avoidCount).toList();

      return result;
    } catch (e) {
      print('Error getting past recipe IDs: $e');
      return [];
    }
  }

  /// 提交餐食偏好并生成餐食计划
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

      // 创建并保存偏好设置
      final preference = MealPreferenceModel(
        dietPreference: selectedDietPreference.value,
        allergens: selectedAllergens.toList(),
        preferredCookingMethods: selectedCookingMethods.toList(),
        maxPreparationTime: preparationTime.value,
        planType: selectedPlanType.value,
        updatedAt: DateTime.now(),
      );

      await mealHiveStorage.savePreferences(preference);
      await mealRepo.saveMealPreference(preference);

      // 获取过去的食谱ID
      final pastRecipeIds = await _getPastRecipeIds();

      // 构建 API 请求参数
      final userPreferences = _buildUserPreferencesForApi();

      // 调用 API 生成计划
      Map<String, dynamic> apiResponse;
      if (selectedPlanType.value == MealPlanType.daily) {
        apiResponse = await MealRecommendationApiService.generateDailyPlan(
          userPreferences: await userPreferences,
          userId: mealRepo.userId,
          pastRecipeIds: pastRecipeIds,
        );
      } else {
        apiResponse = await MealRecommendationApiService.generateWeeklyPlan(
          userPreferences: await userPreferences,
          userId: mealRepo.userId,
          pastRecipeIds: pastRecipeIds,
        );
      }

      if (apiResponse['success'] == true) {
        // 解析 API 返回的计划
        final mealPlan = await _parseMealPlanFromApi(apiResponse['plan']);

        if (mealPlan != null) {
          generatedMealPlan.value = mealPlan;
          await mealHiveStorage.saveActiveMealPlan(mealPlan);

          TLoaders.successSnackBar(
            title: 'Success',
            message: 'Meal plan generated successfully!',
          );

          Get.to(() => const MealPlanPreviewScreen());
        }
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

  /// 解析 API 返回的餐食计划
  Future<MealPlanModel?> _parseMealPlanFromApi(
      Map<String, dynamic> planData) async {
    try {
      planData.forEach((key, value) {
        print('   $key: ${value.runtimeType}');
      });

      final scheduledMeals = <MealPlanMealModel>[];
      final now = DateTime.now();

      // 根据计划类型解析
      if (selectedPlanType.value == MealPlanType.daily) {
        await _parseDailyPlan(planData, scheduledMeals, now);
      } else {
        await _parseWeeklyPlan(planData, scheduledMeals, now);
      }

      if (scheduledMeals.isEmpty) {
        print('❌ No meals were parsed successfully');
        return null;
      }

      // 计算实际的开始和结束日期
      DateTime startDateTime;
      DateTime endDateTime;

      if (scheduledMeals.isNotEmpty) {
        // 从安排的餐食中获取最早的日期
        startDateTime = scheduledMeals
            .map((meal) => meal.scheduledDate)
            .reduce((a, b) => a.isBefore(b) ? a : b);

        // 从安排的餐食中获取最晚的日期
        endDateTime = scheduledMeals
            .map((meal) => meal.scheduledDate)
            .reduce((a, b) => a.isAfter(b) ? a : b);

        print(
            '📅 Calculated date range from meals: $startDateTime to $endDateTime');
      } else {
        // 如果没有餐食，使用默认逻辑
        startDateTime = now;
        endDateTime = selectedPlanType.value == MealPlanType.daily
            ? now
            : now.add(const Duration(days: 6));
      }

      // 创建 MealPlanModel
      return MealPlanModel(
        mealPlanId: const Uuid().v4(),
        userId: mealRepo.userId!,
        scheduledMeals: scheduledMeals,
        planType: selectedPlanType.value,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        adherence: 0,
        status: MealPlanStatus.confirmed,
      );
    } catch (e) {
      print('❌ Error parsing meal plan: $e');
      print('❌ Stack trace: ${e.toString()}');
      return null;
    }
  }

  /// 解析每日计划
  Future<void> _parseDailyPlan(
    Map<String, dynamic> planData,
    List<MealPlanMealModel> scheduledMeals,
    DateTime startDate,
  ) async {
    // 获取用户的糖尿病风险等级
    final userPreferences = await _buildUserPreferencesForApi();
    final diabetesRisk = userPreferences['diabetes_risk'] ?? 'medium';

    // 获取剩余的 meal slots
    final remainingSlots = MealTimeConstants.getRemainingMealSlots(
        DateTime.now(),
        diabetesRisk: diabetesRisk);

    // 如果今天没有剩余 slots，从明天开始
    final actualStartDate = remainingSlots.isEmpty
        ? startDate.add(const Duration(days: 1))
        : startDate;

    int dayOffset = 0;
    int slotIndex = 0;

    // 定义完整的 meal slots 顺序
    final allSlots = [
      MealTimeSlot.breakfast,
      MealTimeSlot.lunch,
      MealTimeSlot.snack,
      MealTimeSlot.dinner,
    ];

    for (var mealType in ['breakfast', 'lunch', 'snack', 'dinner']) {
      if (planData.containsKey(mealType) && planData[mealType] != null) {
        final mealData = planData[mealType] as Map<String, dynamic>;
        final meal = await _fetchMealFromApi(mealData);

        if (meal != null) {
          // 确定这个 meal 的日期和 time slot
          DateTime mealDate;
          MealTimeSlot timeSlot;

          if (remainingSlots.isEmpty) {
            final targetSlotIndex =
                allSlots.indexOf(_mealTypeToTimeSlot(mealType));
            dayOffset = targetSlotIndex ~/ allSlots.length;
            slotIndex = targetSlotIndex % allSlots.length;

            mealDate = actualStartDate.add(Duration(days: dayOffset));
            timeSlot = allSlots[slotIndex];
          } else {
            if (slotIndex < remainingSlots.length) {
              mealDate = actualStartDate;
              timeSlot = remainingSlots[slotIndex];
            } else {
              final nextDayIndex = slotIndex - remainingSlots.length;
              dayOffset = 1 + (nextDayIndex ~/ allSlots.length);
              final nextSlotIndex = nextDayIndex % allSlots.length;

              mealDate = actualStartDate.add(Duration(days: dayOffset));
              timeSlot = allSlots[nextSlotIndex];
            }
          }

          scheduledMeals.add(MealPlanMealModel(
            mealPlanMealId: const Uuid().v4(),
            meal: meal,
            scheduledDate: mealDate,
            mealTimeSlot: timeSlot,
            status: MealConsumptionStatus.pending,
          ));

          slotIndex++;
        } else {
          print('❌ Failed to fetch meal for $mealType');
        }
      } else {
        print('❌ $mealType not found in plan data or is null');
      }
    }

    print('\n📊 Final scheduled meals count: ${scheduledMeals.length}');
  }

  /// 解析每周计划
  Future<void> _parseWeeklyPlan(
    Map<String, dynamic> planData,
    List<MealPlanMealModel> scheduledMeals,
    DateTime startDate,
  ) async {
    // 获取用户的糖尿病风险等级
    final userPreferences = await _buildUserPreferencesForApi();
    final diabetesRisk = userPreferences['diabetes_risk'] ?? 'medium';

    // 获取今天剩余的 meal slots
    final remainingSlots = MealTimeConstants.getRemainingMealSlots(
        DateTime.now(),
        diabetesRisk: diabetesRisk);

    // 如果今天没有剩余 slots，从明天开始
    final actualStartDate = remainingSlots.isEmpty
        ? startDate.add(const Duration(days: 1))
        : startDate;

    int totalMealsAdded = 0;
    int currentDayOffset = 0;

    // 定义完整的 meal slots 顺序
    final allSlots = [
      MealTimeSlot.breakfast,
      MealTimeSlot.lunch,
      MealTimeSlot.snack,
      MealTimeSlot.dinner,
    ];

    // 遍历每一天
    for (int day = 1; day <= 7; day++) {
      final dayKey = 'day_$day';

      if (planData.containsKey(dayKey)) {
        final dayData = planData[dayKey] as Map<String, dynamic>;

        for (var mealType in ['breakfast', 'lunch', 'snack', 'dinner']) {
          if (dayData.containsKey(mealType) && dayData[mealType] != null) {
            final mealData = dayData[mealType] as Map<String, dynamic>;
            final meal = await _fetchMealFromApi(mealData);

            if (meal != null) {
              DateTime mealDate;
              MealTimeSlot timeSlot = _mealTypeToTimeSlot(mealType);

              // 第一天特殊处理
              if (day == 1 && remainingSlots.isNotEmpty) {
                // 使用剩余的 slots
                if (totalMealsAdded < remainingSlots.length) {
                  mealDate = actualStartDate;
                  timeSlot = remainingSlots[totalMealsAdded];
                } else {
                  // 超出今天的 slots，计算下一天
                  final excessMeals = totalMealsAdded - remainingSlots.length;
                  currentDayOffset = 1 + (excessMeals ~/ allSlots.length);
                  mealDate =
                      actualStartDate.add(Duration(days: currentDayOffset));
                }
              } else {
                // 其他天正常处理
                mealDate = actualStartDate.add(Duration(days: day - 1));
              }

              scheduledMeals.add(MealPlanMealModel(
                mealPlanMealId: const Uuid().v4(),
                meal: meal,
                scheduledDate: mealDate,
                mealTimeSlot: timeSlot,
                status: MealConsumptionStatus.pending,
              ));

              totalMealsAdded++;
            }
          }
        }
      }
    }
  }

  /// 将 meal type 转换为 MealTimeSlot
  MealTimeSlot _mealTypeToTimeSlot(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return MealTimeSlot.breakfast;
      case 'lunch':
        return MealTimeSlot.lunch;
      case 'snack':
        return MealTimeSlot.snack;
      case 'dinner':
        return MealTimeSlot.dinner;
      default:
        return MealTimeSlot.lunch;
    }
  }

  /// 从 API 数据获取完整的 MealModel
  Future<MealModel?> _fetchMealFromApi(Map<String, dynamic> mealData) async {
    try {
      final recipeId = mealData['recipe_id'] as String;
      return await mealRepo.getMealById(recipeId);
    } catch (e) {
      print('Error fetching meal: $e');
      return null;
    }
  }

  /// 替换特定餐食
  Future<void> replaceMeal(String mealPlanMealId) async {
    if (generatedMealPlan.value == null) return;

    try {
      isReplacingMeal.value = true;

      final currentPlan = generatedMealPlan.value!;

      // 找到要替换的餐食
      final mealToReplace = currentPlan.scheduledMeals.firstWhere(
        (meal) => meal.mealPlanMealId == mealPlanMealId,
      );

      // 获取当前计划中的所有食谱ID（包括要替换的这个）
      final currentRecipeIds =
          currentPlan.scheduledMeals.map((meal) => meal.meal.mealId).toList();

      print('🔄 Current plan has ${currentRecipeIds.length} recipes');

      // 获取过去的食谱ID
      final pastRecipeIds = await _getPastRecipeIds();

      // 获取被替换过的食谱ID
      final replacedRecipeIds = mealHiveStorage.getReplacedRecipes();

      // 合并所有需要排除的ID（当前计划 + 过去计划 + 被替换过的食谱）
      final allExcludedIds = {
        ...currentRecipeIds,
        ...pastRecipeIds,
        ...replacedRecipeIds
      }.toList();

      // 确定 meal type
      final mealType = _timeSlotToMealType(mealToReplace.mealTimeSlot);

      print('🔄 Replacing meal: ${mealToReplace.meal.mealName}');
      print(
          '📋 Excluding ${allExcludedIds.length} recipes (${currentRecipeIds.length} current, ${pastRecipeIds.length} past, ${replacedRecipeIds.length} replaced)');

      // 调用 API 替换餐食
      final apiResponse = await MealRecommendationApiService.replaceMeal(
        mealType: mealType,
        userPreferences: await _buildUserPreferencesForApi(),
        currentPlanRecipeIds: allExcludedIds,
        replacedRecipeId: mealToReplace.meal.mealId,
        userId: mealRepo.userId,
        pastRecipeIds: pastRecipeIds,
      );

      if (apiResponse['success'] == true) {
        final newMealData = apiResponse['new_meal'] as Map<String, dynamic>;
        final newMeal = await _fetchMealFromApi(newMealData);

        if (newMeal != null) {
          _updateMealInPlan(mealPlanMealId, newMeal);

          // 将被替换的餐食ID保存到 Hive
          await mealHiveStorage.addReplacedRecipe(mealToReplace.meal.mealId);

          TLoaders.successSnackBar(
            title: 'Success',
            message: 'Meal replaced successfully!',
          );

          print(
              '✅ Meal replaced: ${mealToReplace.meal.mealName} → ${newMeal.mealName}');
        } else {
          throw Exception('Failed to fetch new meal from API');
        }
      } else {
        throw Exception('API returned error: ${apiResponse['error']}');
      }
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to replace meal: ${e.toString()}',
      );
      print('❌ Error replacing meal: $e');
    } finally {
      isReplacingMeal.value = false;
    }
  }

  /// 将 MealTimeSlot 转换为 meal type string
  String _timeSlotToMealType(MealTimeSlot timeSlot) {
    switch (timeSlot) {
      case MealTimeSlot.breakfast:
        return 'breakfast';
      case MealTimeSlot.lunch:
        return 'lunch';
      case MealTimeSlot.snack:
        return 'snack';
      case MealTimeSlot.dinner:
        return 'dinner';
    }
  }

  void _updateMealInPlan(String mealPlanMealId, MealModel newMeal) {
    final currentPlan = generatedMealPlan.value;
    if (currentPlan == null) return;

    final updatedMeals = currentPlan.scheduledMeals.map((scheduledMeal) {
      if (scheduledMeal.mealPlanMealId == mealPlanMealId) {
        return scheduledMeal.copyWith(meal: newMeal);
      }
      return scheduledMeal;
    }).toList();

    generatedMealPlan.value =
        currentPlan.copyWith(scheduledMeals: updatedMeals);
    mealHiveStorage.saveActiveMealPlan(generatedMealPlan.value!);
  }

  /// 重新生成整个餐食计划
  Future<void> regenerateMealPlan() async {
    await submitMealPreferences();
  }

  /// 确认餐食计划并保存到 Firestore
  Future<void> confirmMealPlan() async {
    if (generatedMealPlan.value == null) return;

    try {
      isLoading.value = true;

      await mealRepo.saveMealPlan(generatedMealPlan.value!);

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Meal plan confirmed and saved!',
      );

      generatedMealPlan.value = null;
      await mealHiveStorage.deleteMealPlan('active_meal_plan');

      // 清空被替换的食谱记录
      await mealHiveStorage.clearReplacedRecipes();

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

  /// 丢弃生成的餐食计划
  Future<void> discardMealPlan() async {
    try {
      generatedMealPlan.value = null;
      await mealHiveStorage.deleteMealPlan('active_meal_plan');

      TLoaders.successSnackBar(
        title: 'Plan Discarded',
        message: 'Temporary meal plan has been removed',
      );

      if (Get.context != null) {
        Navigator.of(Get.context!, rootNavigator: true).pop(true);
      }
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to discard temporary plan',
      );
      print('Error discarding temp plan: $e');
    }
  }

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

  void navigateToSubscription() {
    Get.to(() => SubscriptionPlanScreen());
  }

  void navigateToDiabetesPrediction() {
    final flowManager = Get.put(DiabetesPredictionFlowManager());
    flowManager.enterPredictionFlow();
  }
}
