import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/meal_recommendation/meal_repository.dart';
import '../../../data/repositories/reminder/reminder_repository.dart';
import '../../../data/repositories/reminder/reminder_schedule_repository.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/meal_time_constants.dart';
import '../../reminder/models/reminder_model.dart';
import '../models/meal_plan_model.dart';

class MealReminderController extends GetxController {
  static MealReminderController get instance => Get.find();

  final reminderRepo = Get.put(ReminderRepository());
  final reminderScheduleRepo = Get.put(ReminderScheduleRepository());
  final mealRepo = MealRepository.instance;

  final isLoading = false.obs;
  final hasActiveMealPlan = false.obs;
  final activeMealPlan = Rx<MealPlanModel?>(null);

  // Track which meal slots have reminders enabled
  final breakfastReminderEnabled = false.obs;
  final lunchReminderEnabled = false.obs;
  final snackReminderEnabled = false.obs;
  final dinnerReminderEnabled = false.obs;

  // Track active meal reminders
  final activeReminders = <ReminderModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    await loadActiveMealPlan();
    await loadMealReminders();
  }

  /// Load active meal plan
  Future<void> loadActiveMealPlan() async {
    try {
      isLoading.value = true;
      final plan = await mealRepo.getActiveMealPlan();

      if (plan != null) {
        activeMealPlan.value = plan;
        hasActiveMealPlan.value = true;
      } else {
        hasActiveMealPlan.value = false;
      }
    } catch (e) {
      print('Error loading active meal plan: $e');
      hasActiveMealPlan.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Load existing meal reminders
  Future<void> loadMealReminders() async {
    try {
      final allReminders = await reminderRepo.fetchAllReminders();

      if (activeMealPlan.value != null) {
        final planEnd = activeMealPlan.value!.endDateTime;

        final mealReminders = allReminders.where((r) =>
        r.isMealReminder &&
            r.isActive &&
            r.mealPlanId == activeMealPlan.value!.mealPlanId,
        );

        activeReminders.assignAll(
          mealReminders.map((r) {
            // 如果 nextTriggerTime 在 plan 之后，当成没有 upcoming
            if (r.nextTriggerTime != null &&
                r.nextTriggerTime!.isAfter(planEnd)) {
              return r.copyWith(nextTriggerTime: null);
            }
            return r;
          }).toList(),
        );
      } else {
        activeReminders.clear();
      }

      _updateToggleStates();
    } catch (e) {
      print('Error loading meal reminders: $e');
    }
  }

  /// Update toggle states based on active reminders
  void _updateToggleStates() {
    breakfastReminderEnabled.value = activeReminders.any(
          (r) => r.mealTimeSlot == MealTimeSlot.breakfast,
    );
    lunchReminderEnabled.value = activeReminders.any(
          (r) => r.mealTimeSlot == MealTimeSlot.lunch,
    );
    snackReminderEnabled.value = activeReminders.any(
          (r) => r.mealTimeSlot == MealTimeSlot.snack,
    );
    dinnerReminderEnabled.value = activeReminders.any(
          (r) => r.mealTimeSlot == MealTimeSlot.dinner,
    );
  }

  /// Check if snack exists in current plan
  bool get hasSnackInPlan {
    if (activeMealPlan.value == null) return false;
    return activeMealPlan.value!.scheduledMeals.any(
          (meal) => meal.mealTimeSlot == MealTimeSlot.snack,
    );
  }

  /// Check if any reminder is active
  bool get hasAnyActiveReminder {
    return activeReminders.isNotEmpty;
  }

  /// Check if reminder is enabled for a slot
  bool isReminderEnabled(MealTimeSlot slot) {
    switch (slot) {
      case MealTimeSlot.breakfast:
        return breakfastReminderEnabled.value;
      case MealTimeSlot.lunch:
        return lunchReminderEnabled.value;
      case MealTimeSlot.snack:
        return snackReminderEnabled.value;
      case MealTimeSlot.dinner:
        return dinnerReminderEnabled.value;
    }
  }

  /// Get reminder time for a specific slot
  DateTime? getReminderTimeForSlot(MealTimeSlot slot) {
    final reminder = activeReminders.firstWhereOrNull(
          (r) => r.mealTimeSlot == slot,
    );
    return reminder?.nextTriggerTime;
  }

  /// Check if reminder has any pending schedules
  Future<bool> hasSchedulesForReminder(String reminderId) async {
    try {
      final schedules =
      await reminderScheduleRepo.fetchPendingSchedules(reminderId);
      return schedules.isNotEmpty;
    } catch (e) {
      print('❌ Error checking schedules: $e');
      return false;
    }
  }

  /// Get schedule status for a specific reminder (by id)
  Future<String> getScheduleStatusForReminder(String reminderId) async {
    final reminder = activeReminders
        .firstWhereOrNull((r) => r.reminderId == reminderId);

    if (reminder == null) return 'no_reminder';

    final planEnd = activeMealPlan.value?.endDateTime;
    final next = reminder.nextTriggerTime;

    // 1. 没有 nextTriggerTime
    if (next == null) {
      return 'no_schedule';
    }

    // 2. 超出 plan 结束时间
    if (planEnd != null && next.isAfter(planEnd)) {
      return 'no_schedule';
    }

    // 3. 查看数据库里还有没有 pending schedules
    final hasSchedules = await hasSchedulesForReminder(reminderId);
    if (!hasSchedules) {
      return 'no_schedule';
    }

    // 4. 其他情况统一视为 active
    return 'active';
  }

  /// Get schedule status for a meal slot
  Future<String> getScheduleStatusForSlot(MealTimeSlot slot) async {
    final reminder = activeReminders.firstWhereOrNull(
          (r) => r.mealTimeSlot == slot,
    );
    if (reminder == null) return 'no_reminder';

    return getScheduleStatusForReminder(reminder.reminderId);
  }

  /// Toggle meal reminder for a specific slot
  Future<void> toggleMealReminder(MealTimeSlot slot) async {
    if (activeMealPlan.value == null) {
      TLoaders.warningSnackBar(
        title: 'No Active Plan',
        message: 'Create a meal plan first',
      );
      return;
    }

    // Check if meal exists in plan (important for snack)
    final hasMealInPlan = activeMealPlan.value!.scheduledMeals.any(
          (meal) => meal.mealTimeSlot == slot,
    );

    if (!hasMealInPlan) {
      TLoaders.warningSnackBar(
        title: 'Meal Not Available',
        message: 'This meal is not in your current plan',
      );
      return;
    }

    final isCurrentlyEnabled = isReminderEnabled(slot);

    if (isCurrentlyEnabled) {
      // Disable: Delete existing reminder
      await _deleteMealReminder(slot);
    } else {
      // Enable: Create new reminder
      await _createMealReminder(slot);
    }

    // Reload reminders
    await loadMealReminders();
  }

  /// Create meal reminder for a specific slot
  Future<void> _createMealReminder(MealTimeSlot slot) async {
    try {
      // Get meals for this slot from active plan
      final mealsForSlot = activeMealPlan.value!.scheduledMeals
          .where((meal) => meal.mealTimeSlot == slot)
          .toList();

      if (mealsForSlot.isEmpty) return;

      // Calculate preparation time (use first meal as reference)
      final firstMeal = mealsForSlot.first;
      final prepTime = firstMeal.meal.preparationTime + firstMeal.meal.cookingTime;

      // Calculate reminder time
      final reminderTime = _calculateReminderTime(slot, prepTime);

      // Calculate end date from meal plan
      final planEndDate = activeMealPlan.value!.endDateTime;

      // Set end date to the last day of the plan at 23:59:59
      final reminderEndDate = DateTime(
        planEndDate.year,
        planEndDate.month,
        planEndDate.day,
        23,
        59,
        59,
      );

      // Create reminder with end date
      final reminder = await reminderRepo.createReminder(
        reminderTitle: '${_getMealName(slot)} Preparation',
        baseTime: reminderTime,
        repeatType: RepeatType.customDays,
        customDays: _getCustomDaysForPlan(),
        endDate: reminderEndDate,  // 🔧 添加结束日期
        snoozeDuration: 5,
        isActive: true,
        isMealReminder: true,
        mealPlanId: activeMealPlan.value!.mealPlanId,
        mealTimeSlot: slot,
      );

      TLoaders.successSnackBar(
        title: 'Reminder Created',
        message: '${_getMealName(slot)} reminder set successfully',
      );

      print('✅ Meal reminder created: ${reminder.reminderId}, ends: $reminderEndDate');
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to create reminder',
      );
      print('❌ Error creating meal reminder: $e');
    }
  }

  /// Delete meal reminder for a specific slot
  Future<void> _deleteMealReminder(MealTimeSlot slot) async {
    try {
      final reminder = activeReminders.firstWhereOrNull(
            (r) => r.mealTimeSlot == slot,
      );

      if (reminder != null) {
        await reminderRepo.deleteReminder(reminder.reminderId);

        TLoaders.successSnackBar(
          title: 'Reminder Deleted',
          message: '${_getMealName(slot)} reminder removed',
        );
      }
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to delete reminder',
      );
      print('❌ Error deleting meal reminder: $e');
    }
  }

  /// Calculate reminder time based on meal slot and preparation time
  DateTime _calculateReminderTime(MealTimeSlot slot, int prepMinutes) {
    final now = DateTime.now();
    final mealStartHour = MealTimeConstants.mealStartTimes[slot]!;

    // Create a DateTime for today at the meal start time
    var reminderTime = DateTime(
      now.year,
      now.month,
      now.day,
      mealStartHour,
      0,
    );

    // Subtract preparation time
    reminderTime = reminderTime.subtract(Duration(minutes: prepMinutes));

    return reminderTime;
  }

  /// Get custom days based on meal plan type
  List<String> _getCustomDaysForPlan() {
    if (activeMealPlan.value == null) return [];

    final plan = activeMealPlan.value!;

    if (plan.planType == MealPlanType.daily) {
      // Daily plan: get all unique dates from scheduled meals
      final uniqueDays = plan.scheduledMeals
          .map((meal) => _getDayName(meal.scheduledDate.weekday))
          .toSet()
          .toList();

      print('📅 Daily plan reminder days: $uniqueDays');
      return uniqueDays;
    } else {
      // Weekly plan: get all days from plan
      final days = plan.scheduledMeals
          .map((meal) => _getDayName(meal.scheduledDate.weekday))
          .toSet()
          .toList();

      print('📅 Weekly plan reminder days: $days');
      return days;
    }
  }

  /// Convert weekday to day name
  String _getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return 'Mon';
    }
  }

  /// Get meal name from slot
  String _getMealName(MealTimeSlot slot) {
    switch (slot) {
      case MealTimeSlot.breakfast:
        return 'Breakfast';
      case MealTimeSlot.lunch:
        return 'Lunch';
      case MealTimeSlot.snack:
        return 'Snack';
      case MealTimeSlot.dinner:
        return 'Dinner';
    }
  }

  /// Refresh all data
  Future<void> refreshData() async {
    await loadActiveMealPlan();
    await loadMealReminders();
  }
}