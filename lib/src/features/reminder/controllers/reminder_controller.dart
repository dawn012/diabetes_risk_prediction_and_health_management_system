import 'dart:async';
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/reminder/reminder_repository.dart';
import '../models/reminder_model.dart';

class ReminderController extends GetxController {
  static ReminderController get instance => Get.find();

  final _reminderRepo = Get.put(ReminderRepository());

  // Observable list of reminders
  final reminders = <ReminderModel>[].obs;
  final isLoading = false.obs;
  final selectedReminder = ReminderModel.empty().obs;

  // Batch management
  final isSelectionMode = false.obs;
  final selectedReminderIds = <String>[].obs;

  // Stream subscription
  StreamSubscription<List<ReminderModel>>? _reminderSubscription;

  @override
  void onInit() {
    super.onInit();
    _listenToReminders();
  }

  @override
  void onClose() {
    _reminderSubscription?.cancel();
    super.onClose();
  }

  /// Listen to real-time reminders stream from repository
  void _listenToReminders() {
    isLoading.value = true;

    _reminderSubscription = _reminderRepo.getAllRemindersStream().listen(
          (reminderList) {
        reminders.assignAll(reminderList);
        isLoading.value = false;
      },
      onError: (error) {
        isLoading.value = false;
        TLoaders.errorSnackBar(
          title: 'Error',
          message: 'Failed to load reminders: $error',
        );
      },
    );
  }

  /// Refresh reminders (manual refresh if needed)
  Future<void> refreshReminders() async {
    reminders.refresh();
    TLoaders.customToast(message: 'Reminders refreshed');
  }

  /// Get active reminders only
  List<ReminderModel> get activeReminders {
    return reminders.where((reminder) => reminder.isActive).toList();
  }

  /// Get inactive reminders only
  List<ReminderModel> get inactiveReminders {
    return reminders.where((reminder) => !reminder.isActive).toList();
  }

  /// Toggle reminder enabled/disabled
  Future<void> toggleReminder(String id) async {
    try {
      final reminder = reminders.firstWhere(
            (r) => r.reminderId == id,
        orElse: () => throw Exception('Reminder not found'),
      );

      final updatedReminder = reminder.copyWith(
        isActive: !reminder.isActive,
      );

      // Update in repository - stream will automatically update the local list
      await _reminderRepo.updateReminder(updatedReminder);
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to toggle reminder: $e',
      );
    }
  }

  /// Update reminder
  Future<void> updateReminder(ReminderModel updatedReminder) async {
    try {
      isLoading.value = true;

      // Update in repository - stream will automatically update the local list
      await _reminderRepo.updateReminder(updatedReminder);

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Reminder updated successfully',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to update reminder: $e',
      );
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete reminder
  Future<void> deleteReminder(String id) async {
    try {
      isLoading.value = true;

      // Delete from repository - stream will automatically update the local list
      await _reminderRepo.deleteReminder(id);

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Reminder deleted successfully',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to delete reminder: $e',
      );
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // ============ Batch Management Methods ============

  /// Enter selection mode
  void enterSelectionMode() {
    isSelectionMode.value = true;
    selectedReminderIds.clear();
    update();
  }

  /// Exit selection mode
  void exitSelectionMode() {
    isSelectionMode.value = false;
    selectedReminderIds.clear();
    update();
  }

  /// Toggle reminder selection
  void toggleReminderSelection(String reminderId) {
    if (selectedReminderIds.contains(reminderId)) {
      selectedReminderIds.remove(reminderId);
    } else {
      selectedReminderIds.add(reminderId);
    }
    selectedReminderIds.refresh();
    update();
  }

  /// Select all reminders
  void selectAllReminders() {
    if (selectedReminderIds.length == reminders.length) {
      // Deselect all
      selectedReminderIds.clear();
    } else {
      // Select all
      selectedReminderIds.clear();
      selectedReminderIds.addAll(reminders.map((r) => r.reminderId));
    }
    selectedReminderIds.refresh();
    update();
  }

  /// Batch delete reminders
  Future<void> batchDeleteReminders() async {
    if (selectedReminderIds.isEmpty) {
      TLoaders.warningSnackBar(
        title: 'Warning',
        message: 'No reminders selected',
      );
      return;
    }

    try {
      isLoading.value = true;

      // Delete all selected reminders
      final deleteFutures = selectedReminderIds.map(
            (id) => _reminderRepo.deleteReminder(id),
      );

      await Future.wait(deleteFutures);

      final count = selectedReminderIds.length;
      selectedReminderIds.clear();
      exitSelectionMode();

      TLoaders.successSnackBar(
        title: 'Success',
        message: '$count reminder${count > 1 ? 's' : ''} deleted successfully',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to delete reminders: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Batch toggle reminders (enable/disable)
  Future<void> batchToggleReminders(bool enable) async {
    if (selectedReminderIds.isEmpty) {
      TLoaders.warningSnackBar(
        title: 'Warning',
        message: 'No reminders selected',
      );
      return;
    }

    try {
      isLoading.value = true;

      final updateFutures = selectedReminderIds.map((id) {
        final reminder = reminders.firstWhere((r) => r.reminderId == id);
        final updatedReminder = reminder.copyWith(isActive: enable);
        return _reminderRepo.updateReminder(updatedReminder);
      });

      await Future.wait(updateFutures);

      final count = selectedReminderIds.length;
      selectedReminderIds.clear();
      exitSelectionMode();

    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to update reminders: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ============ Other Methods ============

  /// Set selected reminder for editing
  void setSelectedReminder(ReminderModel reminder) {
    selectedReminder.value = reminder;
  }

  /// Clear selected reminder
  void clearSelectedReminder() {
    selectedReminder.value = ReminderModel.empty();
  }

  /// Get reminder by ID
  ReminderModel? getReminderById(String id) {
    try {
      return reminders.firstWhere((reminder) => reminder.reminderId == id);
    } catch (e) {
      return null;
    }
  }

  /// Check if reminder exists
  bool reminderExists(String id) {
    return reminders.any((reminder) => reminder.reminderId == id);
  }

  /// Get reminders for specific day
  List<ReminderModel> getRemindersForDay(DateTime date) {
    return reminders.where((reminder) {
      if (!reminder.isActive) return false;

      final reminderTime = DateTime(
        date.year,
        date.month,
        date.day,
        reminder.baseTime.hour,
        reminder.baseTime.minute,
      );

      return reminderTime.isAfter(DateTime.now()) ||
          reminderTime.isAtSameMomentAs(DateTime.now());
    }).toList();
  }

  /// Get upcoming reminders (next 24 hours)
  List<ReminderModel> getUpcomingReminders() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    return reminders.where((reminder) {
      if (!reminder.isActive) return false;
      return reminder.nextTriggerTime.isAfter(now) &&
          reminder.nextTriggerTime.isBefore(tomorrow);
    }).toList();
  }
}