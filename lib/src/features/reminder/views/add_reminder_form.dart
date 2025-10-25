import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/widgets/dialogs/dialog.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../controllers/add_reminder_controller.dart';
import '../models/reminder_model.dart';

class AddReminderForm extends StatelessWidget {
  final ReminderModel? reminderToEdit;
  final bool isEditing;

  const AddReminderForm({
    super.key,
    this.reminderToEdit,
    this.isEditing = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddReminderController());
    final darkMode = THelperFunctions.isDarkMode(context);

    // Initialize with existing reminder data if editing
    if (isEditing && reminderToEdit != null) {
      controller.initializeForEditing(reminderToEdit!);
    } else {
      controller.clearForm();
    }

    return Container(
      decoration: BoxDecoration(
        color: darkMode ? TColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Section
            Text(
              isEditing ? 'Edit Reminder' : 'Add Reminder',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: darkMode ? TColors.white : TColors.black,
              ),
            ),
            const SizedBox(height: 24),

            // Title Input
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Title',
                    style: TextStyle(
                      fontSize: 16,
                      color: darkMode ? TColors.white : TColors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Obx(() => TextField(
                    controller: controller.titleController,
                    style: TextStyle(
                      fontSize: 16,
                      color: darkMode ? TColors.white : TColors.black,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.only(bottom: 8),
                      border: UnderlineInputBorder(),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: darkMode ? TColors.darkGrey : Colors.grey,
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: TColors.primary),
                      ),
                      errorBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: TColors.error),
                      ),
                      errorText: controller.validationErrors['title'],
                      errorStyle: TextStyle(fontSize: 12),
                    ),
                    onChanged: (_) => controller.validationErrors.remove('title'),
                  )),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Time Section
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: darkMode ? TColors.white : TColors.black,
                  size: 25,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Obx(() => InkWell(
                    onTap: () => _showTimePicker(context, controller),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: darkMode ? TColors.darkerGrey : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: controller.validationErrors.containsKey('baseTime')
                            ? Border.all(color: TColors.error)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                _formatTime(controller.selectedTime.value),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: darkMode ? TColors.white : TColors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_drop_down,
                            color: darkMode ? TColors.white : TColors.black,
                          ),
                        ],
                      ),
                    ),
                  )),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Repeat Section
            Row(
              children: [
                Icon(
                  Icons.repeat,
                  color: darkMode ? TColors.white : TColors.black,
                  size: 25,
                ),
                const SizedBox(width: 16),
                Text(
                  'Repeat',
                  style: TextStyle(
                    fontSize: 16,
                    color: darkMode ? TColors.white : TColors.black,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: darkMode ? TColors.darkerGrey : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<RepeatType>(
                      value: controller.selectedRepeatType.value,
                      underline: const SizedBox(),
                      isExpanded: true,
                      dropdownColor: darkMode ? TColors.darkerGrey : Colors.white,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: darkMode ? TColors.white : TColors.black,
                      ),
                      selectedItemBuilder: (context) {
                        return controller.repeatTypes.map((type) {
                          return Align(
                            alignment: Alignment.center,
                            child: Text(
                              type.displayName,
                              style: TextStyle(
                                fontSize: 16,
                                color: darkMode ? TColors.white : TColors.black,
                              ),
                            ),
                          );
                        }).toList();
                      },
                      items: controller.repeatTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(
                            type.displayName,
                            style: TextStyle(
                              color: darkMode ? TColors.white : TColors.black,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          controller.updateRepeatType(value);
                        }
                      },
                    ),
                  )),
                ),
              ],
            ),

            // Custom Days Selection
            Obx(() {
              if (controller.selectedRepeatType.value == RepeatType.customDays) {
                return Column(
                  children: [
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: controller.dayNames.map((day) {
                        final isSelected = controller.selectedDays.contains(day);
                        return GestureDetector(
                          onTap: () => controller.toggleDay(day),
                          child: Container(
                            width: 40,
                            height: 35,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? TColors.primary
                                  : (darkMode ? TColors.darkerGrey : Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                day.substring(0, 3),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.white
                                      : (darkMode ? TColors.white : TColors.black),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (controller.validationErrors.containsKey('customDays'))
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          controller.validationErrors['customDays']!,
                          style: TextStyle(
                            color: TColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                );
              }
              return const SizedBox();
            }),

            // Fixed Interval Selection
            Obx(() {
              if (controller.selectedRepeatType.value == RepeatType.fixedInterval) {
                return Column(
                  children: [
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: darkMode ? TColors.darkerGrey : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: controller.validationErrors.containsKey('intervalTime')
                              ? TColors.error
                              : (darkMode ? TColors.darkGrey : Colors.grey.shade200),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: TextEditingController(
                                text: controller.intervalTime.value.toString(),
                              )..selection = TextSelection.fromPosition(
                                TextPosition(offset: controller.intervalTime.value.toString().length),
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                color: darkMode ? TColors.white : TColors.black,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Interval',
                                labelStyle: TextStyle(
                                  color: darkMode ? TColors.white : TColors.black,
                                ),
                                floatingLabelBehavior: FloatingLabelBehavior.auto,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                final intValue = int.tryParse(value) ?? 1;
                                controller.updateIntervalTime(intValue);
                              },
                            ),
                          ),
                          Container(
                            height: 24,
                            width: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            color: darkMode ? TColors.darkGrey : Colors.grey.shade500,
                          ),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: controller.intervalUnit.value,
                                isExpanded: true,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: darkMode ? TColors.white : TColors.black,
                                ),
                                dropdownColor: darkMode ? TColors.darkerGrey : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                icon: Transform.translate(
                                  offset: const Offset(6, 0),
                                  child: Icon(
                                    Icons.arrow_drop_down,
                                    color: darkMode ? TColors.white : TColors.black,
                                  ),
                                ),
                                items: controller.intervalUnits.map((unit) {
                                  return DropdownMenuItem(
                                    value: unit,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Text(
                                        unit,
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: darkMode ? TColors.white : TColors.black,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    controller.updateIntervalUnit(value);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (controller.validationErrors.containsKey('intervalTime'))
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          controller.validationErrors['intervalTime']!,
                          style: TextStyle(
                            color: TColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                );
              }
              return const SizedBox();
            }),

            const SizedBox(height: 30),

            // Snooze Duration Section
            Row(
              children: [
                Text(
                  'Snooze Duration',
                  style: TextStyle(
                    fontSize: 16,
                    color: darkMode ? TColors.white : TColors.black,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: darkMode ? TColors.darkerGrey : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<int>(
                      value: controller.snoozeDuration.value,
                      underline: const SizedBox(),
                      isExpanded: true,
                      dropdownColor: darkMode ? TColors.darkerGrey : Colors.white,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: darkMode ? TColors.white : TColors.black,
                      ),
                      selectedItemBuilder: (context) {
                        return controller.snoozeDurations.map((duration) {
                          return Align(
                            alignment: Alignment.center,
                            child: Text(
                              '$duration mins',
                              style: TextStyle(
                                fontSize: 16,
                                color: darkMode ? TColors.white : TColors.black,
                              ),
                            ),
                          );
                        }).toList();
                      },
                      items: controller.snoozeDurations.map((duration) {
                        return DropdownMenuItem(
                          value: duration,
                          child: Text(
                            '$duration mins',
                            style: TextStyle(
                              color: darkMode ? TColors.white : TColors.black,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          controller.updateSnoozeDuration(value);
                        }
                      },
                    ),
                  )),
                ),
              ],
            ),

            // End Date Section
            Obx(() {
              if (controller.selectedRepeatType.value != RepeatType.once) {
                return Column(
                  children: [
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Text(
                          'End Date',
                          style: TextStyle(
                            fontSize: 16,
                            color: darkMode ? TColors.white : TColors.black,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: controller.hasEndDate.value
                                ? () => _showDatePicker(context, controller)
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: controller.hasEndDate.value
                                    ? (darkMode ? TColors.darkerGrey : Colors.grey.shade100)
                                    : (darkMode ? Colors.grey.shade800 : Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(8),
                                border: controller.validationErrors.containsKey('endDate')
                                    ? Border.all(color: TColors.error)
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        controller.hasEndDate.value
                                            ? _formatDate(controller.endDate.value)
                                            : 'No End Date',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: controller.hasEndDate.value
                                              ? (darkMode ? TColors.white : TColors.black)
                                              : (darkMode ? TColors.darkGrey : Colors.grey.shade500),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.calendar_today,
                                    color: controller.hasEndDate.value
                                        ? (darkMode ? TColors.white : TColors.black)
                                        : (darkMode ? TColors.darkGrey : Colors.grey.shade500),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Checkbox(
                          value: controller.hasEndDate.value,
                          onChanged: (value) {
                            controller.toggleEndDate(value ?? false);
                          },
                          activeColor: TColors.primary,
                        ),
                      ],
                    ),
                  ],
                );
              }
              return const SizedBox();
            }),

            const SizedBox(height: 45),

            // Action Buttons
            Obx(() => Row(
              children: [
                if (isEditing) ...[
                  // Delete Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : () => _showDeleteDialog(context, controller),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: TColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          color: TColors.error,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Save Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : () => controller.saveReminder(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: controller.isLoading.value
                          ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Cancel Button (for add mode)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: controller.isLoading.value ? null : () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: TColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: TColors.primary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // OK Button (for add mode)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : () => controller.saveReminder(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: controller.isLoading.value
                          ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            )),
          ],
        ),
      ),
    );
  }

  void _showTimePicker(BuildContext context, AddReminderController controller) {
    showTimePicker(
      context: context,
      initialTime: controller.selectedTime.value,
    ).then((time) {
      if (time != null) {
        controller.updateTime(time);
      }
    });
  }

  void _showDatePicker(BuildContext context, AddReminderController controller) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    showDatePicker(
      context: context,
      initialDate: controller.endDate.value.isBefore(today) ? today : controller.endDate.value,
      firstDate: today,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      selectableDayPredicate: (DateTime day) {
        return day.isAfter(today.subtract(const Duration(days: 1)));
      },
    ).then((date) {
      if (date != null) {
        controller.updateEndDate(date);
      }
    });
  }

  void _showDeleteDialog(BuildContext context, AddReminderController controller) {
    TDialog.deleteDialog(
      title: 'Delete Reminder',
      message: 'Are you sure you want to delete this reminder? This action cannot be undone.',
      onConfirm: () async {
        await controller.deleteReminder();
      },
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}