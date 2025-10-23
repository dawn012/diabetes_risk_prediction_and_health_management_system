import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/reminder_controller.dart';
import '../../models/reminder_model.dart';
import '../add_reminder_form.dart';

class ReminderListItem extends StatelessWidget {
  final ReminderModel reminder;

  const ReminderListItem({
    super.key,
    required this.reminder,
  });

  @override
  Widget build(BuildContext context) {
    final controller = ReminderController.instance;
    final darkMode = THelperFunctions.isDarkMode(context);

    return Obx(() {
      final isSelectionMode = controller.isSelectionMode.value;
      final isSelected = controller.selectedReminderIds.contains(reminder.reminderId);

      return GestureDetector(
        onTap: () {
          if (isSelectionMode) {
            controller.toggleReminderSelection(reminder.reminderId);
          } else {
            _showEditDialog(context);
          }
        },
        onLongPress: () {
          if (!isSelectionMode) {
            controller.enterSelectionMode();
            controller.toggleReminderSelection(reminder.reminderId);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? TColors.primary.withOpacity(0.1)
                : (darkMode ? TColors.darkerGrey : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? TColors.primary
                  : (darkMode ? TColors.darkGrey : Colors.grey.shade200),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              if (!darkMode)
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Selection Checkbox
                if (isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected ? TColors.primary : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? TColors.primary : Colors.grey,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: isSelected
                          ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                          : null,
                    ),
                  ),

                // Reminder Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: reminder.isActive
                        ? TColors.primary.withOpacity(0.1)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Iconsax.notification_bold,
                    color: reminder.isActive ? TColors.primary : Colors.grey,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // Reminder Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.reminderTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: darkMode ? TColors.white : TColors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(reminder.baseTime),
                        style: TextStyle(
                          fontSize: 14,
                          color: darkMode ? TColors.darkGrey : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getRepeatTypeText(reminder),
                        style: TextStyle(
                          fontSize: 12,
                          color: darkMode ? TColors.darkGrey : Colors.grey.shade500,
                        ),
                      ),
                      // 🆕 End Date Display
                      if (reminder.endDate != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Iconsax.calendar_bold,
                              size: 12,
                              color: _getEndDateColor(reminder.endDate!),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatEndDate(reminder.endDate!),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _getEndDateColor(reminder.endDate!),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Toggle Switch (only if not in selection mode)
                if (!isSelectionMode)
                  Switch(
                    value: reminder.isActive,
                    onChanged: (value) {
                      controller.toggleReminder(reminder.reminderId);
                    },
                    activeColor: TColors.primary,
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  String _formatTime(DateTime time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }

  String _getRepeatTypeText(ReminderModel reminder) {
    switch (reminder.repeatType.name) {
      case 'once':
        return 'Once';
      case 'customDays':
        return 'Custom Days: ${reminder.customDays.join(", ")}';
      case 'fixedInterval':
        final minutes = reminder.intervalTime ?? 0;
        if (minutes >= 1440) {
          return 'Every ${minutes ~/ 1440} day(s)';
        } else if (minutes >= 60) {
          return 'Every ${minutes ~/ 60} hour(s)';
        } else {
          return 'Every $minutes minute(s)';
        }
      default:
        return 'Unknown';
    }
  }

  /// 🆕 Format end date to show "End in X days" or specific date
  String _formatEndDate(DateTime endDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDay = DateTime(endDate.year, endDate.month, endDate.day);
    final daysRemaining = endDay.difference(today).inDays;

    if (daysRemaining < 0) {
      return 'Ended';
    } else if (daysRemaining == 0) {
      return 'Ends today';
    } else if (daysRemaining == 1) {
      return 'Ends tomorrow';
    } else {
      return 'Ends in $daysRemaining days';
    }
  }

  /// 🆕 Get color based on how close the end date is
  Color _getEndDateColor(DateTime endDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDay = DateTime(endDate.year, endDate.month, endDate.day);
    final daysRemaining = endDay.difference(today).inDays;

    if (daysRemaining < 0) {
      return TColors.darkGrey; // Already ended
    } else if (daysRemaining <= 3) {
      return TColors.error; // Ending very soon (red)
    } else if (daysRemaining <= 7) {
      return TColors.warning; // Ending soon (orange)
    } else {
      return TColors.info; // Normal (blue)
    }
  }

  void _showEditDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddReminderForm(
        reminderToEdit: reminder,
        isEditing: true,
      ),
    );
  }
}