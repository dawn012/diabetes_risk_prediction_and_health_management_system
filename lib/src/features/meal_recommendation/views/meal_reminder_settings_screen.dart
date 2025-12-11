import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../common/widgets/appbar/appbar.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../controllers/meal_reminder_controller.dart';

class MealReminderSettingsScreen extends StatelessWidget {
  const MealReminderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MealReminderController());
    final isDark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.light,
      appBar: TAppBar(
        title: Text(
          'Meal Reminders',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? TColors.white : TColors.dark,
          ),
        ),
        showBackArrow: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: TColors.primary),
          );
        }

        if (!controller.hasActiveMealPlan.value) {
          return _buildNoActivePlan(isDark);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              _buildInfoCard(isDark),

              const SizedBox(height: TSizes.spaceBtwSections),

              // Meal Reminder Toggles
              _buildMealReminderToggles(controller, isDark),

              const SizedBox(height: TSizes.spaceBtwSections),

              // Active Reminders List
              if (controller.hasAnyActiveReminder)
                _buildActiveRemindersList(controller, isDark),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildNoActivePlan(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.calendar_remove_bold,
              size: 80,
              color: isDark ? TColors.darkGrey : TColors.grey,
            ),
            const SizedBox(height: TSizes.spaceBtwItems),
            Text(
              'No Active Meal Plan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? TColors.white : TColors.dark,
              ),
            ),
            const SizedBox(height: TSizes.sm),
            Text(
              'Create a meal plan first to set up meal reminders',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? TColors.darkGrey : TColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: TColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        border: Border.all(color: TColors.info.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.info_circle_bold,
            color: TColors.info,
            size: 24,
          ),
          const SizedBox(width: TSizes.md),
          Expanded(
            child: Text(
              'Reminders will be sent based on meal preparation time before the meal window starts',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? TColors.white : TColors.dark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealReminderToggles(
      MealReminderController controller,
      bool isDark,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meal Reminders',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? TColors.white : TColors.dark,
          ),
        ),
        const SizedBox(height: TSizes.md),

        // Breakfast
        _buildMealToggle(
          controller,
          MealTimeSlot.breakfast,
          'Breakfast Reminder',
          'Get reminded before breakfast preparation',
          Iconsax.coffee_bold,
          isDark,
        ),

        const SizedBox(height: TSizes.sm),

        // Lunch
        _buildMealToggle(
          controller,
          MealTimeSlot.lunch,
          'Lunch Reminder',
          'Get reminded before lunch preparation',
          Iconsax.cake_bold,
          isDark,
        ),

        const SizedBox(height: TSizes.sm),

        // Snack (only if available in plan)
        Obx(() {
          if (controller.hasSnackInPlan) {
            return Column(
              children: [
                _buildMealToggle(
                  controller,
                  MealTimeSlot.snack,
                  'Snack Reminder',
                  'Get reminded before snack preparation',
                  Iconsax.cup_bold,
                  isDark,
                ),
                const SizedBox(height: TSizes.sm),
              ],
            );
          }
          return const SizedBox.shrink();
        }),

        // Dinner
        _buildMealToggle(
          controller,
          MealTimeSlot.dinner,
          'Dinner Reminder',
          'Get reminded before dinner preparation',
          Iconsax.frame_bold,
          isDark,
        ),
      ],
    );
  }

  Widget _buildMealToggle(
      MealReminderController controller,
      MealTimeSlot slot,
      String title,
      String subtitle,
      IconData icon,
      bool isDark,
      ) {
    return Obx(() {
      final isEnabled = controller.isReminderEnabled(slot);
      final reminderTime = controller.getReminderTimeForSlot(slot);

      return Container(
        decoration: BoxDecoration(
          color: isDark ? TColors.darkContainer : TColors.white,
          borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
          border: Border.all(
            color: isEnabled
                ? TColors.primary.withOpacity(0.3)
                : (isDark ? TColors.darkGrey : TColors.grey).withOpacity(0.3),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
            onTap: () => controller.toggleMealReminder(slot),
            child: Padding(
              padding: const EdgeInsets.all(TSizes.md),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (isEnabled ? TColors.primary : TColors.grey)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: isEnabled ? TColors.primary : TColors.darkGrey,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: TSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? TColors.white : TColors.dark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FutureBuilder<String>(
                          future: controller.getScheduleStatusForSlot(slot),
                          builder: (context, snapshot) {
                            if (!isEnabled) {
                              return Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? TColors.darkGrey : TColors.textSecondary,
                                ),
                              );
                            }

                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Text(
                                'Checking...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? TColors.darkGrey : TColors.textSecondary,
                                ),
                              );
                            }

                            final status = snapshot.data ?? 'no_schedule';

                            if (status == 'no_schedule') {
                              return Text(
                                'No upcoming meals',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: TColors.warning,
                                  fontStyle: FontStyle.italic,
                                ),
                              );
                            }

                            return Text(
                              reminderTime != null
                                  ? 'Reminds at ${_formatTime(reminderTime)}'
                                  : 'Active',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? TColors.darkGrey : TColors.textSecondary,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isEnabled,
                    onChanged: (_) => controller.toggleMealReminder(slot),
                    activeColor: TColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildActiveRemindersList(
      MealReminderController controller,
      bool isDark,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Reminders',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? TColors.white : TColors.dark,
          ),
        ),
        const SizedBox(height: TSizes.md),

        Obx(() {
          // 按 nextTriggerTime 排序
          final sortedReminders = List<dynamic>.from(controller.activeReminders)
            ..sort((a, b) {
              final aTime = a.nextTriggerTime;
              final bTime = b.nextTriggerTime;
              return aTime.compareTo(bTime);
            });

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedReminders.length,  // 使用 sortedReminders
            separatorBuilder: (_, __) => const SizedBox(height: TSizes.sm),
            itemBuilder: (context, index) {
              final reminder = sortedReminders[index];  // 使用 sortedReminders
              return _buildActiveReminderCard(reminder, isDark);
            },
          );
        }),
      ],
    );
  }

  Widget _buildActiveReminderCard(dynamic reminder, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: isDark ? TColors.darkContainer : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        border: Border.all(
          color: TColors.success.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: TColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: TSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.reminderTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? TColors.white : TColors.dark,
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<String>(
                  future: Get.find<MealReminderController>().getScheduleStatusForReminder(
                    reminder.reminderId,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text(
                        'Loading...',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? TColors.darkGrey
                              : TColors.textSecondary,
                        ),
                      );
                    }

                    final status = snapshot.data ?? 'no_schedule';

                    if (status == 'no_schedule') {
                      return Text(
                        'No upcoming schedules',
                        style: TextStyle(
                          fontSize: 12,
                          color: TColors.warning,
                          fontStyle: FontStyle.italic,
                        ),
                      );
                    }

                    // active: 有 schedule 且在 plan 内
                    return Text(
                      _formatNextTriggerTime(reminder.nextTriggerTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? TColors.darkGrey
                            : TColors.textSecondary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Icon(
            Iconsax.notification_bold,
            color: TColors.success,
            size: 20,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _formatNextTriggerTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final triggerDate = DateTime(time.year, time.month, time.day);

    String prefix = 'Next: ';
    if (triggerDate == today) {
      prefix = 'Next: Today ';
    } else if (triggerDate == tomorrow) {
      prefix = 'Next: Tomorrow ';
    }

    return '$prefix${_formatTime(time)}';
  }
}