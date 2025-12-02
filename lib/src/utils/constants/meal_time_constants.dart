import 'enums.dart';

/// Constants for meal time slots and consumption windows
class MealTimeConstants {
  MealTimeConstants._();

  /// Meal time slot start times (24-hour format)
  static const Map<MealTimeSlot, int> mealStartTimes = {
    MealTimeSlot.breakfast: 7,  // 7:00 AM
    MealTimeSlot.lunch: 12,     // 12:00 PM
    MealTimeSlot.snack: 15,     // 3:00 PM
    MealTimeSlot.dinner: 19,    // 7:00 PM
  };

  /// Meal time slot end times (consumption deadline in 24-hour format)
  static const Map<MealTimeSlot, int> mealEndTimes = {
    MealTimeSlot.breakfast: 9,  // 9:00 AM
    MealTimeSlot.lunch: 15,      // 3:00 PM
    MealTimeSlot.snack: 17,      // 5:00 PM
    MealTimeSlot.dinner: 22,     // 10:00 PM
  };

  /// Display names for meal time slots
  static const Map<MealTimeSlot, String> mealDisplayNames = {
    MealTimeSlot.breakfast: 'Breakfast',
    MealTimeSlot.lunch: 'Lunch',
    MealTimeSlot.snack: 'Snack',
    MealTimeSlot.dinner: 'Dinner',
  };

  /// Get current meal time slot based on current hour
  static MealTimeSlot getCurrentMealTimeSlot(DateTime dateTime) {
    final hour = dateTime.hour;

    if (hour >= mealStartTimes[MealTimeSlot.breakfast]! &&
        hour < mealStartTimes[MealTimeSlot.lunch]!) {
      return MealTimeSlot.breakfast;
    } else if (hour >= mealStartTimes[MealTimeSlot.lunch]! &&
        hour < mealStartTimes[MealTimeSlot.snack]!) {
      return MealTimeSlot.lunch;
    } else if (hour >= mealStartTimes[MealTimeSlot.snack]! &&
        hour < mealStartTimes[MealTimeSlot.dinner]!) {
      return MealTimeSlot.snack;
    } else {
      return MealTimeSlot.dinner;
    }
  }

  /// Get remaining meal slots for today based on diabetes risk level
  static List<MealTimeSlot> getRemainingMealSlots(DateTime dateTime, {String? diabetesRisk}) {
    final currentHour = dateTime.hour;
    final List<MealTimeSlot> remainingSlots = [];

    // 根据风险等级确定包含哪些餐食
    final bool includeSnack = diabetesRisk == 'high';

    for (final slot in MealTimeSlot.values) {
      // 如果不是高风险用户，跳过snack
      if (slot == MealTimeSlot.snack && !includeSnack) {
        continue;
      }

      final startTime = mealStartTimes[slot]!;
      if (currentHour < startTime) {
        remainingSlots.add(slot);
      }
    }

    return remainingSlots;
  }

  /// Check if meal can still be consumed (within allowed time window)
  static bool canConsumeMeal(MealTimeSlot slot, DateTime currentTime) {
    final endHour = mealEndTimes[slot]!;
    return currentTime.hour < endHour;
  }

  /// Check if meal consumption window has passed
  static bool hasMealWindowPassed(MealTimeSlot slot, DateTime currentTime) {
    final endHour = mealEndTimes[slot]!;
    return currentTime.hour >= endHour;
  }

  /// Get time remaining until meal window closes
  static Duration getTimeUntilWindowCloses(
      MealTimeSlot slot,
      DateTime currentTime, {
        required DateTime mealDate,
      }) {
    final endHour = mealEndTimes[slot]!;
    final windowClose = DateTime(
      mealDate.year,
      mealDate.month,
      mealDate.day,
      endHour,
    );

    if (currentTime.isBefore(windowClose)) {
      return windowClose.difference(currentTime);
    }
    return Duration.zero;
  }

  /// Get display name for meal slot
  static String getMealDisplayName(MealTimeSlot slot) {
    return mealDisplayNames[slot] ?? slot.value;
  }

  /// Check if current time is within meal slot window
  static bool isWithinMealWindow(MealTimeSlot slot, DateTime currentTime) {
    final startHour = mealStartTimes[slot]!;
    final endHour = mealEndTimes[slot]!;
    final currentHour = currentTime.hour;

    return currentHour >= startHour && currentHour < endHour;
  }

  /// Get next meal slot
  static MealTimeSlot? getNextMealSlot(DateTime currentTime) {
    final remaining = getRemainingMealSlots(currentTime);
    return remaining.isNotEmpty ? remaining.first : null;
  }

  /// 距离这顿饭开始还有多久（如果已经开始则返回 Duration.zero）
  static Duration getTimeUntilWindowOpens(
      MealTimeSlot slot,
      DateTime currentTime, {
        required DateTime mealDate,
      }) {
    final startHour = mealStartTimes[slot]!;
    final startDateTime = DateTime(
      mealDate.year,
      mealDate.month,
      mealDate.day,
      startHour,
    );

    if (currentTime.isBefore(startDateTime)) {
      return startDateTime.difference(currentTime);
    }
    return Duration.zero;
  }

  /// Format time window display (e.g., "7:00 AM - 11:00 AM")
  static String getMealTimeWindow(MealTimeSlot slot) {
    final startHour = mealStartTimes[slot]!;
    final endHour = mealEndTimes[slot]!;

    return '${_formatHour(startHour)} - ${_formatHour(endHour)}';
  }

  /// Helper method to format hour in 12-hour format
  static String _formatHour(int hour) {
    if (hour == 0) return '12:00 AM';
    if (hour < 12) return '$hour:00 AM';
    if (hour == 12) return '12:00 PM';
    return '${hour - 12}:00 PM';
  }
}