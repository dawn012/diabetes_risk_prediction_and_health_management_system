import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../models/reminder_model.dart';

class AddReminderController extends GetxController {
  static AddReminderController get instance => Get.find();

  // Add Reminder Form States
  final titleController = TextEditingController();
  final selectedTime = TimeOfDay.now().obs;
  final selectedRepeatType = 'Once'.obs;
  final selectedDays = <String>[].obs;
  final intervalTime = 1.obs;
  final intervalUnit = 'minute'.obs;
  final snoozeDuration = 10.obs;
  final endDate = DateTime.now().obs;

  // Available options
  final repeatTypes = ['Once', 'Custom', 'Fixed Interval'];
  final intervalUnits = ['minute', 'hour', 'day'];
  final snoozeDurations = [5, 10, 15, 30];
  final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  // Methods for Add Reminder Form
  void updateTime(TimeOfDay time) {
    selectedTime.value = time;
  }

  void updateRepeatType(String type) {
    selectedRepeatType.value = type;
    if (type == 'Once') {
      selectedDays.clear();
    }
  }

  void toggleDay(String day) {
    if (selectedDays.contains(day)) {
      selectedDays.remove(day);
    } else {
      selectedDays.add(day);
    }
  }

  void updateIntervalTime(int time) {
    intervalTime.value = time;
  }

  void updateIntervalUnit(String unit) {
    intervalUnit.value = unit;
  }

  void updateSnoozeDuration(int duration) {
    snoozeDuration.value = duration;
  }

  void updateEndDate(DateTime date) {
    endDate.value = date;
  }

  // Convert interval to minutes for storage
  int getIntervalInMinutes() {
    switch (intervalUnit.value) {
      case 'hour':
        return intervalTime.value * 60;
      case 'day':
        return intervalTime.value * 24 * 60;
      default:
        return intervalTime.value;
    }
  }

  // Save new reminder
  void saveReminder() {
    if (titleController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter a title');
      return;
    }

    final now = DateTime.now();
    final baseDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      selectedTime.value.hour,
      selectedTime.value.minute,
    );

    final newReminder = ReminderModel(
      reminderId: DateTime.now().millisecondsSinceEpoch.toString(),
      reminderTitle: titleController.text,
      baseTime: baseDateTime,
      repeatType: selectedRepeatType.value,
      customDays: selectedDays.toList(),
      intervalTime: selectedRepeatType.value == 'Fixed Interval'
          ? getIntervalInMinutes()
          : null,
      endDate: endDate.value,
      nextTriggerTime: baseDateTime,
      snoozeDuration: snoozeDuration.value,
      reminderSchedules: [],
      isActive: true,
    );

    _clearForm();
    Get.back();
    Get.snackbar('Success', 'Reminder added successfully');
  }

  void _clearForm() {
    titleController.clear();
    selectedTime.value = TimeOfDay.now();
    selectedRepeatType.value = 'Once';
    selectedDays.clear();
    intervalTime.value = 1;
    intervalUnit.value = 'minute';
    snoozeDuration.value = 10;
    endDate.value = DateTime.now().add(const Duration(days: 30));
  }

  @override
  void onClose() {
    titleController.dispose();
    super.onClose();
  }
}