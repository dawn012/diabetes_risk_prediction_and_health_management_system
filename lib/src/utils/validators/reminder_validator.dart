import 'package:flutter/material.dart';
import '../constants/enums.dart';

class ReminderValidator {
  ReminderValidator._();

  // Valid day abbreviations
  static const validDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  /// Validate reminder title
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the reminder title.';
    }
    if (value.trim().length < 3) {
      return 'Title must be at least 3 characters';
    }
    if (value.trim().length > 50) {
      return 'Title must not exceed 50 characters';
    }
    return null;
  }

  /// Validate base time
  static String? validateBaseTime(TimeOfDay? time) {
    if (time == null) {
      return 'Please enter the reminder time';
    }
    return null;
  }

  /// Validate repeat type
  static String? validateRepeatType(RepeatType? type) {
    if (type == null) {
      return 'Please select the repeat type.';
    }
    return null;
  }

  /// Validate custom days
  static String? validateCustomDays(RepeatType repeatType, List<String> days) {
    if (repeatType == RepeatType.customDays) {
      if (days.isEmpty) {
        return 'Please select at least one day';
      }

      // Validate each day is valid
      for (final day in days) {
        if (!validDays.contains(day)) {
          return 'Invalid day selected: $day';
        }
      }
    }
    return null;
  }

  /// Validate interval time (in minutes after conversion)
  static String? validateIntervalTime(RepeatType repeatType, int? intervalTime) {
    if (repeatType == RepeatType.fixedInterval) {
      if (intervalTime == null) {
        return 'Please enter the interval time.';
      }
      if (intervalTime < 1) {
        return 'Interval must be at least 1 minute';
      }
      if (intervalTime > 1440) {
        return 'Interval cannot exceed 1440 minutes (24 hours)';
      }
    }
    return null;
  }

  /// Validate end date
  static String? validateEndDate(DateTime? endDate) {
    if (endDate == null) {
      return null;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalizedEndDate = DateTime(endDate.year, endDate.month, endDate.day);

    if (normalizedEndDate.isBefore(today)) {
      return 'End date must be today or later';
    }

    return null;
  }

  /// Validate snooze duration
  static String? validateSnoozeDuration(int? duration) {
    if (duration == null) {
      return 'Please enter the snooze duration.';
    }
    if (duration < 1 || duration > 60) {
      return 'Snooze duration must be between 1 and 60 minutes';
    }
    return null;
  }

  /// Validate complete reminder form
  static Map<String, String> validateReminderForm({
    required String? title,
    required TimeOfDay? baseTime,
    required RepeatType? repeatType,
    required List<String> customDays,
    required int? intervalTime,
    required DateTime? endDate,
    required int? snoozeDuration,
  }) {
    final errors = <String, String>{};

    final titleError = validateTitle(title);
    if (titleError != null) errors['title'] = titleError;

    final timeError = validateBaseTime(baseTime);
    if (timeError != null) errors['baseTime'] = timeError;

    final repeatTypeError = validateRepeatType(repeatType);
    if (repeatTypeError != null) errors['repeatType'] = repeatTypeError;

    if (repeatType != null) {
      final customDaysError = validateCustomDays(repeatType, customDays);
      if (customDaysError != null) errors['customDays'] = customDaysError;

      final intervalError = validateIntervalTime(repeatType, intervalTime);
      if (intervalError != null) errors['intervalTime'] = intervalError;
    }

    final endDateError = validateEndDate(endDate);
    if (endDateError != null) errors['endDate'] = endDateError;

    final snoozeError = validateSnoozeDuration(snoozeDuration);
    if (snoozeError != null) errors['snoozeDuration'] = snoozeError;

    return errors;
  }
}