import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../common/loaders/loaders.dart';
import '../../../common/widgets/dialogs/dialog.dart';
import '../../../data/repositories/meal_recommendation/meal_repository.dart';
import '../../../services/meal_hive_storage_manager.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/meal_time_constants.dart';
import '../models/meal_plan_meal_model.dart';
import '../models/meal_plan_model.dart';

class MealPlanController extends GetxController {
  static MealPlanController get instance => Get.find();

  final mealRepo = Get.put(MealRepository());

  // Current and past plans
  final Rx<MealPlanModel?> activeMealPlan = Rx<MealPlanModel?>(null);
  final RxList<MealPlanModel> pastMealPlans = <MealPlanModel>[].obs;

  // Loading states
  final isLoadingActive = false.obs;
  final isLoadingPast = false.obs;
  final isUpdatingMeal = false.obs;

  // Search, filter, and sort
  final searchController = TextEditingController();
  final searchQuery = ''.obs;
  final selectedStatus = 'all'.obs;
  final selectedSortOption = 'date_desc'.obs;

  // Filter and sort options
  final statusFilters = ['all', 'completed', 'cancelled', 'expired'];
  final sortOptions = ['date_desc', 'date_asc', 'adherence_desc', 'adherence_asc'];

  final hasTempMealPlan = false.obs;
  Timer? _tempPlanCheckTimer;

  @override
  void onInit() {
    super.onInit();
    _initializeMealPlans();
    _setupTempPlanTimer();
  }

  @override
  void onClose() {
    _tempPlanCheckTimer?.cancel();
    searchController.dispose();
    super.onClose();
  }

  /// 设置临时计划定时检查器
  void _setupTempPlanTimer() {
    // 立即检查一次
    _checkForTempPlan();

    // 每2秒检查一次
    _tempPlanCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkForTempPlan();
    });
  }

  /// Initialize meal plans
  Future<void> _initializeMealPlans() async {
    await loadActiveMealPlan();
    await loadPastMealPlans();
    _listenToActiveMealPlan();
  }

  /// 检查 Hive 中是否有临时计划
  Future<void> _checkForTempPlan() async {
    try {
      final mealHiveStorage = Get.find<MealHiveStorageManager>();
      final hasPlan = mealHiveStorage.hasActiveMealPlan();

      print('🔍 Checking temp plan: hasPlan=$hasPlan');

      if (hasPlan) {
        final tempPlan = mealHiveStorage.getActiveMealPlan();
        final hasValidPlan = tempPlan != null &&
            tempPlan.scheduledMeals.isNotEmpty &&
            tempPlan.scheduledMeals.any((meal) => meal.meal != null);

        print('🔍 Temp plan details: hasValidPlan=$hasValidPlan, mealCount=${tempPlan?.scheduledMeals.length}');

        if (hasTempMealPlan.value != hasValidPlan) {
          hasTempMealPlan.value = hasValidPlan;
          print('✅ Temp plan status updated: $hasValidPlan');
          update(); // 强制更新界面
        }
      } else {
        if (hasTempMealPlan.value != false) {
          hasTempMealPlan.value = false;
          print('✅ Temp plan status updated: false');
          update(); // 强制更新界面
        }
      }
    } catch (e) {
      print('❌ Error checking for temp plan: $e');
      hasTempMealPlan.value = false;
      update(); // 强制更新界面
    }
  }

  /// 丢弃临时计划
  Future<void> discardTempPlan() async {
    try {
      final mealHiveStorage = Get.find<MealHiveStorageManager>();
      await mealHiveStorage.deleteMealPlan('active_meal_plan');
      hasTempMealPlan.value = false;

      TLoaders.successSnackBar(
        title: 'Plan Discarded',
        message: 'Temporary meal plan has been removed',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to discard temporary plan',
      );
      print('Error discarding temp plan: $e');
    }
  }

  /// Listen to active meal plan changes
  void _listenToActiveMealPlan() {
    mealRepo.streamActiveMealPlan().listen((plan) {
      activeMealPlan.value = plan;

      // Auto-mark meals as skipped if time window passed
      if (plan != null) {
        _autoMarkSkippedMeals(plan);
      }
    });
  }

  /// Load active meal plan
  Future<void> loadActiveMealPlan() async {
    try {
      isLoadingActive.value = true;
      final plan = await mealRepo.getActiveMealPlan();
      activeMealPlan.value = plan;
    } catch (e) {
      print('Error loading active meal plan: $e');
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to load active meal plan',
      );
    } finally {
      isLoadingActive.value = false;
    }
  }

  /// Load past meal plans
  Future<void> loadPastMealPlans() async {
    try {
      isLoadingPast.value = true;
      final plans = await mealRepo.getPastMealPlans();
      pastMealPlans.assignAll(plans);
    } catch (e) {
      print('Error loading past meal plans: $e');
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to load past meal plans',
      );
    } finally {
      isLoadingPast.value = false;
    }
  }

  /// Auto-mark meals as skipped if consumption window has passed
  Future<void> _autoMarkSkippedMeals(MealPlanModel plan) async {
    try {
      final now = DateTime.now();

      for (var meal in plan.scheduledMeals) {
        // Skip if already consumed or skipped
        if (meal.status != MealConsumptionStatus.pending) continue;

        // Check if meal is for today or past
        final isTodayOrPast = meal.scheduledDate.isBefore(
          DateTime(now.year, now.month, now.day).add(const Duration(days: 1)),
        );

        if (isTodayOrPast) {
          // Check if consumption window has passed
          final hasPassed = MealTimeConstants.hasMealWindowPassed(
            meal.mealTimeSlot,
            now,
          );

          if (hasPassed) {
            await markMealAsSkipped(
              plan.mealPlanId,
              meal.mealPlanMealId,
              autoMarked: true,
            );
          }
        }
      }
    } catch (e) {
      print('Error auto-marking skipped meals: $e');
    }
  }

  /// Mark meal as consumed
  Future<void> markMealAsConsumed(
      String mealPlanId,
      String mealPlanMealId,
      ) async {
    try {
      isUpdatingMeal.value = true;

      await mealRepo.updateMealConsumptionStatus(
        mealPlanId,
        mealPlanMealId,
        MealConsumptionStatus.consumed,
      );

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Meal marked as consumed',
      );

      // Refresh active plan
      await loadActiveMealPlan();
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to update meal status',
      );
    } finally {
      isUpdatingMeal.value = false;
    }
  }

  /// Mark meal as skipped
  Future<void> markMealAsSkipped(
      String mealPlanId,
      String mealPlanMealId, {
        bool autoMarked = false,
      }) async {
    try {
      isUpdatingMeal.value = true;

      await mealRepo.updateMealConsumptionStatus(
        mealPlanId,
        mealPlanMealId,
        MealConsumptionStatus.skipped,
      );

      if (!autoMarked) {
        TLoaders.warningSnackBar(
          title: 'Meal Skipped',
          message: 'Meal marked as skipped',
        );
      }

      // Refresh active plan
      await loadActiveMealPlan();
    } catch (e) {
      if (!autoMarked) {
        TLoaders.errorSnackBar(
          title: 'Error',
          message: 'Failed to update meal status',
        );
      }
    } finally {
      isUpdatingMeal.value = false;
    }
  }

  /// Show cancel meal plan confirmation
  void showCancelMealPlanDialog() {
    if (activeMealPlan.value == null) return;

    TDialog.confirmDialog(
      title: 'Cancel Meal Plan',
      message:
      'Are you sure you want to cancel this meal plan? This action cannot be undone.',
      confirmText: 'Cancel Plan',
      confirmButtonColor: TColors.error,
      icon: Iconsax.close_circle_bold,
      iconColor: TColors.error,
      onConfirm: () => cancelMealPlan(),
    );
  }

  /// Cancel active meal plan
  Future<void> cancelMealPlan() async {
    if (activeMealPlan.value == null) return;

    try {
      await mealRepo.cancelMealPlan(activeMealPlan.value!.mealPlanId);

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Meal plan cancelled',
      );

      // Refresh plans
      await loadActiveMealPlan();
      await loadPastMealPlans();
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to cancel meal plan',
      );
    }
  }

  /// Check if meal can be consumed (within time window)
  bool canConsumeMeal(MealPlanMealModel meal) {
    final now = DateTime.now();

    final isToday = meal.scheduledDate.year == now.year &&
        meal.scheduledDate.month == now.month &&
        meal.scheduledDate.day == now.day;
    if (!isToday) return false;

    if (meal.status != MealConsumptionStatus.pending) return false;

    // 这里严一点：只有在窗口内才算“可操作”
    return MealTimeConstants.isWithinMealWindow(meal.mealTimeSlot, now);
  }

  MealPlanMealModel? getNextUpcomingMeal() {
    final plan = activeMealPlan.value;
    if (plan == null) return null;

    final now = DateTime.now();

    // 1. 只保留 pending 且窗口还没结束的餐
    final upcoming = plan.scheduledMeals.where((meal) {
      if (meal.status != MealConsumptionStatus.pending) return false;

      // 计算这顿饭的结束时间（含日期）
      final endHour = MealTimeConstants.mealEndTimes[meal.mealTimeSlot]!;
      final mealEndDateTime = DateTime(
        meal.scheduledDate.year,
        meal.scheduledDate.month,
        meal.scheduledDate.day,
        endHour,
      );

      // 结束时间要在当前时间之后，才算“未来的餐”
      return mealEndDateTime.isAfter(now);
    }).toList();

    if (upcoming.isEmpty) return null;

    // 2. 按“实际开始时间”排序（日期 + startHour）
    upcoming.sort((a, b) {
      final aStartHour = MealTimeConstants.mealStartTimes[a.mealTimeSlot]!;
      final bStartHour = MealTimeConstants.mealStartTimes[b.mealTimeSlot]!;

      final aStart = DateTime(
        a.scheduledDate.year,
        a.scheduledDate.month,
        a.scheduledDate.day,
        aStartHour,
      );
      final bStart = DateTime(
        b.scheduledDate.year,
        b.scheduledDate.month,
        b.scheduledDate.day,
        bStartHour,
      );

      return aStart.compareTo(bStart);
    });

    return upcoming.first;
  }

  /// Check if meal is current (should be highlighted)
  bool isCurrentMeal(MealPlanMealModel meal) {
    final now = DateTime.now();

    // Check if meal is for today
    final isToday = meal.scheduledDate.year == now.year &&
        meal.scheduledDate.month == now.month &&
        meal.scheduledDate.day == now.day;

    if (!isToday) return false;

    // Check if current time is within meal window
    return MealTimeConstants.isWithinMealWindow(meal.mealTimeSlot, now);
  }

  /// Get time remaining until meal window closes
  String getTimeRemaining(MealPlanMealModel meal) {
    final now = DateTime.now();

    // 先算距离开始时间
    final untilStart = MealTimeConstants.getTimeUntilWindowOpens(
      meal.mealTimeSlot,
      now,
      mealDate: meal.scheduledDate,
    );

    if (untilStart > Duration.zero) {
      // 还没开始：显示 upcoming time
      if (untilStart.inHours > 0) {
        return 'Starts in ${untilStart.inHours}h ${untilStart.inMinutes % 60}m';
      } else {
        return 'Starts in ${untilStart.inMinutes}m';
      }
    }

    // 已经开始：再算距离结束时间
    final untilEnd = MealTimeConstants.getTimeUntilWindowCloses(
      meal.mealTimeSlot,
      now,
      mealDate: meal.scheduledDate, // 记得给它也加 mealDate 参数
    );

    if (untilEnd > Duration.zero) {
      if (untilEnd.inHours > 0) {
        return '${untilEnd.inHours}h ${untilEnd.inMinutes % 60}m remaining';
      } else {
        return '${untilEnd.inMinutes}m remaining';
      }
    }

    return 'Window closed';
  }

  /// Get meal status color
  Color getMealStatusColor(MealConsumptionStatus status) {
    switch (status) {
      case MealConsumptionStatus.consumed:
        return TColors.success;
      case MealConsumptionStatus.skipped:
        return TColors.error;
      case MealConsumptionStatus.pending:
        return TColors.warning;
    }
  }

  /// Get meal status icon
  IconData getMealStatusIcon(MealConsumptionStatus status) {
    switch (status) {
      case MealConsumptionStatus.consumed:
        return Iconsax.tick_circle_bold;
      case MealConsumptionStatus.skipped:
        return Iconsax.close_circle_bold;
      case MealConsumptionStatus.pending:
        return Iconsax.clock_bold;
    }
  }

  /// Get adherence color
  Color getAdherenceColor(int adherence) {
    if (adherence >= 80) return TColors.success;
    if (adherence >= 60) return TColors.warning;
    return TColors.error;
  }

  /// Get today's meals
  List<MealPlanMealModel> getTodaysMeals() {
    if (activeMealPlan.value == null) return [];

    final now = DateTime.now();
    return activeMealPlan.value!.scheduledMeals.where((meal) {
      return meal.scheduledDate.year == now.year &&
          meal.scheduledDate.month == now.month &&
          meal.scheduledDate.day == now.day;
    }).toList()
      ..sort((a, b) {
        final aTime = MealTimeConstants.mealStartTimes[a.mealTimeSlot]!;
        final bTime = MealTimeConstants.mealStartTimes[b.mealTimeSlot]!;
        return aTime.compareTo(bTime);
      });
  }

  /// Get meals for a specific date (for weekly plans)
  List<MealPlanMealModel> getMealsForDate(DateTime date) {
    if (activeMealPlan.value == null) return [];

    // 只按日期筛选，保留 scheduledMeals 里的原始顺序
    return activeMealPlan.value!.scheduledMeals.where((meal) {
      return meal.scheduledDate.year == date.year &&
          meal.scheduledDate.month == date.month &&
          meal.scheduledDate.day == date.day;
    }).toList();
  }

  /// Get unique dates in meal plan (for weekly plans)
  List<DateTime> getUniqueDates() {
    if (activeMealPlan.value == null) return [];

    final dates = activeMealPlan.value!.scheduledMeals
        .map((meal) => DateTime(
      meal.scheduledDate.year,
      meal.scheduledDate.month,
      meal.scheduledDate.day,
    ))
        .toSet()
        .toList()
      ..sort();

    return dates;
  }

  // ========== Search, Filter, and Sort ==========

  /// Handle search query change
  void onSearchChanged(String query) {
    searchQuery.value = query.toLowerCase();
  }

  /// Clear search
  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }

  /// Handle status filter change
  void onStatusFilterChanged(String status) {
    selectedStatus.value = status;
  }

  /// Handle sort option change
  void onSortOptionChanged(String sortOption) {
    selectedSortOption.value = sortOption;
  }

  /// Get status label for display
  String getStatusLabel(String status) {
    switch (status) {
      case 'all':
        return 'All';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'expired':
        return 'Expired';
      default:
        return status.capitalizeFirst ?? status;
    }
  }

  /// Get sort option label for display
  String getSortOptionLabel(String sortOption) {
    switch (sortOption) {
      case 'date_desc':
        return 'Latest First';
      case 'date_asc':
        return 'Oldest First';
      case 'adherence_desc':
        return 'Highest Adherence';
      case 'adherence_asc':
        return 'Lowest Adherence';
      default:
        return sortOption;
    }
  }

  /// Get filtered and sorted meal plans
  List<MealPlanModel> get filteredMealPlans {
    var plans = pastMealPlans.toList();

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      plans = plans.where((plan) {
        final planType = plan.planTypeDisplay.toLowerCase();
        final status = plan.statusDisplay.toLowerCase();
        return planType.contains(searchQuery.value) ||
            status.contains(searchQuery.value);
      }).toList();
    }

    // Apply status filter
    if (selectedStatus.value != 'all') {
      plans = plans.where((plan) {
        return plan.status.value == selectedStatus.value;
      }).toList();
    }

    // Apply sorting
    switch (selectedSortOption.value) {
      case 'date_desc':
        plans.sort((a, b) => b.startDateTime.compareTo(a.startDateTime));
        break;
      case 'date_asc':
        plans.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
        break;
      case 'adherence_desc':
        plans.sort((a, b) => b.adherence.compareTo(a.adherence));
        break;
      case 'adherence_asc':
        plans.sort((a, b) => a.adherence.compareTo(b.adherence));
        break;
    }

    return plans;
  }

  /// Refresh all data
  Future<void> refreshAllData() async {
    await Future.wait([
      loadActiveMealPlan(),
      loadPastMealPlans(),
    ]);
    _checkForTempPlan();
  }

  /// Check if has active meal plan
  bool get hasActiveMealPlan => activeMealPlan.value != null;
}