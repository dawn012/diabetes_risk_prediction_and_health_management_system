import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../controllers/reminder_controller.dart';
import '../models/reminder_model.dart';
import 'add_reminder_form.dart';

class ReminderScreen extends StatelessWidget {
  const ReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReminderController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: Colors.white, // 固定白色背景
      appBar: AppBar(
        backgroundColor: TColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Reminder',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // Show options menu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(
              () => Padding(
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 每行 2 列
                    crossAxisSpacing: TSizes.gridViewSpacing, // 列与列之间的间距
                    mainAxisSpacing: TSizes.gridViewSpacing, // 行与行之间的间距
                    childAspectRatio: 0.85, // 宽高比（宽 / 高 = 0.85）
                  ),
                  itemCount: controller.reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = controller.reminders[index];
                    return ReminderCard(
                      reminder: reminder,
                      darkMode: darkMode,
                      onToggle: () => controller.toggleReminder(reminder.reminderId),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const AddReminderForm(),
              );
            },
          );
        },
        backgroundColor: TColors.primary,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.notifications_outlined,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

// Reusable Reminder Card Widget
class ReminderCard extends StatelessWidget {
  final ReminderModel reminder;
  final bool darkMode;
  final VoidCallback onToggle;

  const ReminderCard({
    super.key,
    required this.reminder,
    required this.darkMode,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        border: Border.all(
          color: reminder.isActive ? TColors.primary : Colors.grey.shade300,
          width: reminder.isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(TSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              reminder.reminderTitle,
              style: TextStyle(
                fontSize: 14,
                color: reminder.isActive
                    ? Colors.grey.shade600
                    : Colors.grey.shade400,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: TSizes.xs),

            // Time
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  DateFormat('h:mm').format(reminder.baseTime), // 12小时制，不带AM/PM
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color:
                        reminder.isActive ? Colors.black : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('a').format(reminder.baseTime), // AM/PM
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color:
                        reminder.isActive ? Colors.black : Colors.grey.shade400,
                  ),
                ),
              ],
            ),

            const SizedBox(height: TSizes.sm),

            // Days with dots
            _buildDayIndicators(reminder),

            const Spacer(),

            // Toggle Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: reminder.isActive,
                    onChanged: (_) => onToggle(),
                    activeColor: TColors.primary,
                    inactiveThumbColor: Colors.grey.shade400,
                    inactiveTrackColor: Colors.grey.shade300,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayIndicators(ReminderModel reminder) {
    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final fullDayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        final dayAbbr = fullDayNames[index];
        final isSelected = reminder.customDays.contains(dayAbbr);
        final isActive = reminder.isActive;

        return Column(
          children: [
            // Dot indicator
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? (isActive ? TColors.primary : Colors.grey.shade400)
                    : Colors.transparent,
              ),
            ),
            const SizedBox(height: 2),
            // Day label
            Text(
              dayLabels[index],
              style: TextStyle(
                fontSize: 12,
                color: isSelected && isActive
                    ? TColors.primary
                    : isActive
                    ? Colors.grey.shade600
                    : Colors.grey.shade400,
                fontWeight: isSelected && isActive
                    ? FontWeight.w600
                    : FontWeight.w400,
                letterSpacing: 0.5,
              ),
            ),
          ],
        );
      }),
    );
  }
}
