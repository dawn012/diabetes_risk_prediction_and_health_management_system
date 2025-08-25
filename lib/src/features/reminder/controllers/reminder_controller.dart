import 'package:get/get.dart';

import '../models/reminder_model.dart';

class ReminderController extends GetxController {
  static ReminderController get instance => Get.find();

  // Observable list of reminders
  final reminders = <ReminderModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadDefaultReminders();
  }

  // Load default reminders
  void _loadDefaultReminders() {
    final now = DateTime.now();
    reminders.value = [
      ReminderModel(
        reminderId: '1',
        reminderTitle: 'Track glucose',
        baseTime: DateTime(now.year, now.month, now.day, 8, 30),
        repeatType: 'Custom',
        customDays: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'], // M T W T F S S
        intervalTime: null,
        endDate: DateTime(2025, 9, 18),
        nextTriggerTime: DateTime(2025, 9, 15, 8, 30),
        snoozeDuration: 5,
        reminderSchedules: [],
        isActive: true,
      ),
      ReminderModel(
        reminderId: '2',
        reminderTitle: 'Track glucose',
        baseTime: DateTime(now.year, now.month, now.day, 8, 30),
        repeatType: 'Custom',
        customDays: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'], // M T W T F S S
        intervalTime: null,
        endDate: DateTime(2025, 9, 18),
        nextTriggerTime: DateTime(2025, 9, 15, 8, 30),
        snoozeDuration: 5,
        reminderSchedules: [],
        isActive: true,
      ),
      ReminderModel(
        reminderId: '3',
        reminderTitle: 'Track glucose',
        baseTime: DateTime(now.year, now.month, now.day, 8, 30),
        repeatType: 'Custom',
        customDays: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'], // M T W T F S S
        intervalTime: null,
        endDate: DateTime(2025, 9, 18),
        nextTriggerTime: DateTime(2025, 9, 15, 8, 30),
        snoozeDuration: 5,
        reminderSchedules: [],
        isActive: true,
      ),
      ReminderModel(
        reminderId: '4',
        reminderTitle: 'Track glucose',
        baseTime: DateTime(now.year, now.month, now.day, 14, 30),
        repeatType: 'Custom',
        customDays: ['Sun', 'Tue', 'Wed', 'Thu', 'Fri'], // M T W T F S S
        intervalTime: null,
        endDate: DateTime(2025, 9, 18),
        nextTriggerTime: DateTime(2025, 9, 15, 8, 30),
        snoozeDuration: 5,
        reminderSchedules: [],
        isActive: true,
      ),
      ReminderModel(
        reminderId: '5',
        reminderTitle: 'Track glucose',
        baseTime: DateTime(now.year, now.month, now.day, 12, 30),
        repeatType: 'Custom',
        customDays: ['Sun', 'Mon', 'Tue', 'Wed'], // M T W T F S S
        intervalTime: null,
        endDate: DateTime(2025, 9, 18),
        nextTriggerTime: DateTime(2025, 9, 15, 8, 30),
        snoozeDuration: 5,
        reminderSchedules: [],
        isActive: false,
      ),
      ReminderModel(
        reminderId: '6',
        reminderTitle: 'Track glucose',
        baseTime: DateTime(now.year, now.month, now.day, 15, 30),
        repeatType: 'Custom',
        customDays: ['Sun', 'Mon', 'Tue', 'Fri'], // M T W T F S S
        intervalTime: null,
        endDate: DateTime(2025, 9, 18),
        nextTriggerTime: DateTime(2025, 9, 15, 8, 30),
        snoozeDuration: 5,
        reminderSchedules: [],
        isActive: false,
      ),
    ];
  }

  // Toggle reminder enabled/disabled
  void toggleReminder(String id) {
    final index = reminders.indexWhere((reminder) => reminder.reminderId == id);
    if (index != -1) {
      reminders[index] = reminders[index].copyWith(
        isActive: !reminders[index].isActive,
      );
      reminders.refresh();
    }
  }

  // Add new reminder
  void addReminder(ReminderModel reminder) {
    reminders.add(reminder);
  }

  // Update reminder
  void updateReminder(String id, ReminderModel updatedReminder) {
    final index = reminders.indexWhere((reminder) => reminder.reminderId == id);
    if (index != -1) {
      reminders[index] = updatedReminder;
      reminders.refresh();
    }
  }

  // Delete reminder
  void deleteReminder(String id) {
    reminders.removeWhere((reminder) => reminder.reminderId == id);
  }
}