import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../controllers/add_reminder_controller.dart';

class AddReminderForm extends StatelessWidget {
  const AddReminderForm({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddReminderController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
            const Text(
              'Add Reminder',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: TColors.black,
              ),
            ),
            const SizedBox(height: 24),

            // Title Input
            Row(
              crossAxisAlignment: CrossAxisAlignment.end, // Aligns bottom of text with input line
              children: [
                // Title with padding to match TextField's baseline
                Padding(
                  padding: const EdgeInsets.only(bottom: 8), // Matches TextField's contentPadding
                  child: const Text(
                    'Title',
                    style: TextStyle(
                      fontSize: 16,
                      color: TColors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8), // Horizontal spacing
                // Expanded TextField to fill remaining space
                Expanded(
                  child: TextField(
                    controller: controller.titleController,
                    style: TextStyle(
                      fontSize: 16, // Match title font size
                      color: TColors.black, // Adapt to theme
                    ),
                    decoration: InputDecoration(
                      isDense: true, // Reduces vertical padding
                      contentPadding: const EdgeInsets.only(bottom: 8), // Matches title padding
                      border: UnderlineInputBorder(),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: TColors.primary),
                      ),
                      // Remove any built-in labels or hints that might affect alignment
                      labelText: null,
                      hintText: null,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Time Section
            Row(
              children: [
                const Icon(Icons.access_time, color: TColors.black, size: 25),
                const SizedBox(width: 16),
                Expanded(
                  child: Obx(() => InkWell(
                    onTap: () => _showTimePicker(context, controller),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                _formatTime(controller.selectedTime.value),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: TColors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_drop_down),
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
                const Icon(Icons.repeat, color: TColors.black, size: 25),
                const SizedBox(width: 16),
                const Text(
                  'Repeat',
                  style: TextStyle(
                    fontSize: 16,
                    color: TColors.black,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: controller.selectedRepeatType.value,
                      underline: const SizedBox(),
                      isExpanded: true,  // 让内容填充整个宽度
                      icon: const Icon(Icons.arrow_drop_down),  // 保持下拉图标在右侧
                      selectedItemBuilder: (context) {  // 自定义选中项显示
                        return controller.repeatTypes.map((type) {
                          return Align(  // 使用Align实现文字居中
                            alignment: Alignment.center,
                            child: Text(
                              type,
                              style: const TextStyle(fontSize: 16),
                            ),
                          );
                        }).toList();
                      },
                      items: controller.repeatTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),  // 下拉菜单中的选项保持默认左对齐
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
              if (controller.selectedRepeatType.value == 'Custom') {
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
                              color: isSelected ? TColors.primary : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                day.substring(0, 3),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected ? Colors.white : TColors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              }
              return const SizedBox();
            }),

            // Fixed Interval Selection
            Obx(() {
              if (controller.selectedRepeatType.value == 'Fixed Interval') {
                return Column(
                  children: [
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: darkMode ? Colors.grey.shade900 : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: darkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          // Interval Input
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: TextEditingController(
                                text: controller.intervalTime.value.toString(),
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                color: darkMode ? Colors.white : Colors.black,
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

                          // Divider
                          Container(
                            height: 24,
                            width: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            color: darkMode ? Colors.grey.shade700 : Colors.grey.shade500,
                          ),

                          // Unit Selector
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
                                dropdownColor: darkMode ? Colors.grey.shade800 : TColors.white,
                                borderRadius: BorderRadius.circular(8),
                                icon: Transform.translate(  // 使用Transform精准控制位置
                                  offset: const Offset(6, 0),  // 向左移动8像素
                                  child: Icon(
                                    Icons.arrow_drop_down,
                                  ),
                                ),
                                items: controller.intervalUnits.map((unit) {
                                  return DropdownMenuItem(
                                    value: unit,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Text(unit, style: TextStyle(fontSize: 18)),
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
                  ],
                );
              }
              return const SizedBox();
            }),

            const SizedBox(height: 30),

            // Snooze Duration Section
            Row(
              children: [
                const Text(
                  'Snooze Duration',
                  style: TextStyle(
                    fontSize: 16,
                    color: TColors.black,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<int>(
                      value: controller.snoozeDuration.value,
                      underline: const SizedBox(),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      selectedItemBuilder: (context) {
                        return controller.snoozeDurations.map((duration) {
                          return Align(
                            alignment: Alignment.center,
                            child: Text(
                              '$duration mins', // 这里添加了 mins 后缀
                              style: const TextStyle(fontSize: 16),
                            ),
                          );
                        }).toList();
                      },
                      items: controller.snoozeDurations.map((duration) {
                        return DropdownMenuItem(
                          value: duration,
                          child: Text('$duration mins'),
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

            const SizedBox(height: 30),

            // End Date Section
            Row(
              children: [
                const Text(
                  'End Date',
                  style: TextStyle(
                    fontSize: 16,
                    color: TColors.black,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Obx(() => InkWell(
                    onTap: () => _showDatePicker(context, controller),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                _formatDate(controller.endDate.value),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: TColors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.calendar_today, color: TColors.black, size: 18,),
                        ],
                      ),
                    ),
                  )),
                ),
              ],
            ),

            const SizedBox(height: 45),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: TColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: TColors.primary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => controller.saveReminder(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
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
            ),
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
      firstDate: today, // 只能选今天及以后
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      selectableDayPredicate: (DateTime day) {
        // 只允许选择今天及以后的日期
        return day.isAfter(today.subtract(const Duration(days: 1)));
      },
    ).then((date) {
      if (date != null) {
        controller.updateEndDate(date);
      }
    });
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