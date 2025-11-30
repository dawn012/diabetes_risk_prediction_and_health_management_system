import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/reminder/reminder_repository.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/validators/reminder_validator.dart';
import '../models/reminder_model.dart';

class AddReminderController extends GetxController {
  static AddReminderController get instance => Get.find();

  final _reminderRepo = Get.put(ReminderRepository());

  // Form controllers
  final titleController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Observable states
  final selectedTime = TimeOfDay.now().obs;
  final selectedRepeatType = Rx<RepeatType>(RepeatType.once);
  final selectedDays = <String>[].obs; // 🔧 指定类型为 String
  final intervalTime = 1.obs;
  final intervalUnit = 'minute'.obs;
  final snoozeDuration = 10.obs;
  final endDate = Rx<DateTime>(DateTime.now().add(const Duration(days: 30)));
  final hasEndDate = false.obs;
  final isLoading = false.obs;
  final isEditing = false.obs;
  var isInitialized = false.obs;

  // Original reminder for editing
  ReminderModel? originalReminder;

  // Available options
  final repeatTypes = RepeatType.values;
  final intervalUnits = ['minute', 'hour', 'day'];
  final snoozeDurations = [5, 10, 15, 30];
  final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  // Validation errors
  final validationErrors = <String, String>{}.obs; // 🔧 指定类型

  @override
  void onInit() {
    super.onInit();
    _initializeEndDate();
  }

  /// Initialize for editing existing reminder
  void initializeForEditing(ReminderModel reminder) {
    isEditing.value = true;
    originalReminder = reminder;

    // baseTime 已经是 Malaysia time，直接使用
    titleController.text = reminder.reminderTitle;
    selectedTime.value = TimeOfDay(
      hour: reminder.baseTime.hour,
      minute: reminder.baseTime.minute,
    );
    selectedRepeatType.value = reminder.repeatType;

    // 🔧 确保类型正确
    selectedDays.value = List<String>.from(reminder.customDays);
    snoozeDuration.value = reminder.snoozeDuration;

    // Handle interval time
    if (reminder.repeatType == RepeatType.fixedInterval) {
      // Handle interval time
      if (reminder.intervalTime != null) {
        final minutes = reminder.intervalTime!;
        if (minutes % (24 * 60) == 0) {
          intervalTime.value = minutes ~/ (24 * 60);
          intervalUnit.value = 'day';
        } else if (minutes % 60 == 0) {
          intervalTime.value = minutes ~/ 60;
          intervalUnit.value = 'hour';
        } else {
          intervalTime.value = minutes;
          intervalUnit.value = 'minute';
        }
      } else {
        // 如果没有 intervalTime，设置默认值
        intervalTime.value = 1;
        intervalUnit.value = 'minute';
      }
    } else {
      // 对于其他类型，设置默认值
      intervalTime.value = 1;
      intervalUnit.value = 'minute';
    }

    // Handle end date
    if (reminder.endDate != null) {
      hasEndDate.value = true;
      endDate.value = reminder.endDate!;
    }
  }

  void _initializeEndDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    endDate.value = today.add(const Duration(days: 30));
  }

  void updateTime(TimeOfDay time) {
    selectedTime.value = time;
    validationErrors.remove('baseTime');
  }

  void updateRepeatType(RepeatType type) {
    selectedRepeatType.value = type;
    validationErrors.remove('repeatType');

    if (type != RepeatType.customDays) {
      selectedDays.clear();
      validationErrors.remove('customDays');
    }
    if (type != RepeatType.fixedInterval) {
      intervalTime.value = 1;
      validationErrors.remove('intervalTime');
    }

    if (type == RepeatType.once) {
      hasEndDate.value = false;
    }
  }

  void toggleDay(String day) {
    if (selectedDays.contains(day)) {
      selectedDays.remove(day);
    } else {
      selectedDays.add(day);
    }
    validationErrors.remove('customDays');
  }

  void updateIntervalTime(int time) {
    if (time >= 1) {
      intervalTime.value = time;
      validationErrors.remove('intervalTime');
    }
  }

  void updateIntervalUnit(String unit) {
    intervalUnit.value = unit;
  }

  void updateSnoozeDuration(int duration) {
    snoozeDuration.value = duration;
    validationErrors.remove('snoozeDuration');
  }

  void updateEndDate(DateTime date) {
    endDate.value = date;
    validationErrors.remove('endDate');
  }

  void toggleEndDate(bool value) {
    hasEndDate.value = value;
    if (value) {
      _initializeEndDate();
    }
    validationErrors.remove('endDate');
  }

  int? getIntervalInMinutes() {
    if (selectedRepeatType.value != RepeatType.fixedInterval) {
      return null;
    }

    switch (intervalUnit.value) {
      case 'hour':
        return intervalTime.value * 60;
      case 'day':
        return intervalTime.value * 24 * 60;
      default:
        return intervalTime.value;
    }
  }

  bool _validateForm() {
    validationErrors.clear();

    final errors = ReminderValidator.validateReminderForm(
      title: titleController.text,
      baseTime: selectedTime.value,
      repeatType: selectedRepeatType.value,
      customDays: selectedDays.toList(),
      intervalTime: getIntervalInMinutes(),
      endDate: hasEndDate.value ? endDate.value : null,
      snoozeDuration: snoozeDuration.value,
    );

    if (errors.isNotEmpty) {
      validationErrors.addAll(errors);
      return false;
    }

    return true;
  }

  Future<void> saveReminder() async {
    if (!_validateForm()) return;

    try {
      isLoading.value = true;

      final now = DateTime.now();

      // 创建 Malaysia time，去掉秒数和毫秒
      final baseDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        selectedTime.value.hour,
        selectedTime.value.minute,
        0, // 秒数设为 0
        0, // 毫秒设为 0
      );

      DateTime? finalEndDate;
      if (selectedRepeatType.value != RepeatType.once) {
        if (hasEndDate.value) {
          finalEndDate = DateTime(
            endDate.value.year,
            endDate.value.month,
            endDate.value.day,
            23,
            59,
            59,
          );
        }
      }

      if (isEditing.value && originalReminder != null) {
        // Update existing reminder
        final updatedReminder = originalReminder!.copyWith(
          reminderTitle: titleController.text.trim(),
          baseTime: baseDateTime,
          repeatType: selectedRepeatType.value,
          customDays: selectedDays.toList(), // 🔧 已经是 List<String>
          intervalTime: getIntervalInMinutes(),
          endDate: finalEndDate,
          snoozeDuration: snoozeDuration.value,
          isActive: true,
        );

        await _reminderRepo.updateReminder(updatedReminder);

        TLoaders.successSnackBar(
          title: 'Success',
          message: 'Reminder updated successfully',
        );
      } else {
        // Create new reminder
        final userId = AuthenticationRepository.instance.authUser?.uid ?? '';
        if (userId.isEmpty) {
          TLoaders.errorSnackBar(
            title: 'Error',
            message: 'User not authenticated',
          );
          return;
        }

        await _reminderRepo.createReminder(
          reminderTitle: titleController.text.trim(),
          baseTime: baseDateTime,
          repeatType: selectedRepeatType.value,
          customDays: selectedDays.toList(),
          intervalTime: getIntervalInMinutes(),
          endDate: finalEndDate,
          snoozeDuration: snoozeDuration.value,
          isActive: true,
        );

        TLoaders.successSnackBar(
          title: 'Success',
          message: 'Reminder created successfully',
        );
      }

      clearForm();
      if (Get.context != null) {
        Navigator.of(Get.context!, rootNavigator: true).pop(true);
      }
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: e.toString(),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteReminder() async {
    if (!isEditing.value || originalReminder == null) return;

    try {
      isLoading.value = true;

      await _reminderRepo.deleteReminder(originalReminder!.reminderId);

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Reminder deleted successfully',
      );

      clearForm();
      if (Get.context != null) {
        Navigator.of(Get.context!, rootNavigator: true).pop(true);
      }
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to delete reminder: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  void clearForm() {
    titleController.clear();
    selectedTime.value = TimeOfDay.now();
    selectedRepeatType.value = RepeatType.once;
    selectedDays.clear();
    intervalTime.value = 1;
    intervalUnit.value = 'minute';
    snoozeDuration.value = 10;
    hasEndDate.value = false;
    _initializeEndDate();
    validationErrors.clear();
    isEditing.value = false;
    originalReminder = null;
  }

  @override
  void onClose() {
    titleController.dispose();
    super.onClose();
  }
}