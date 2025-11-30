import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/loaders/circular_loader.dart';
import '../../../common/widgets/appbar/appbar.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../controllers/add_reminder_controller.dart';
import '../controllers/reminder_controller.dart';
import 'add_reminder_form.dart';
import 'widgets/batch_action_bar.dart';
import 'widgets/reminder_list_item.dart';

class ReminderScreen extends StatelessWidget {
  const ReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReminderController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: darkMode ? TColors.dark : Colors.white,
      appBar: TAppBar(
        backgroundColor: TColors.primary,
        showBackArrow: true,
        title: Obx(() => Text(
          controller.isSelectionMode.value
              ? '${controller.selectedReminderIds.length} Selected'
              : 'Reminder',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        )),
        iconTheme: IconThemeData(color: TColors.white),
        actions: [
          Obx(() {
            if (controller.isSelectionMode.value) {
              // Selection mode: show select all and close buttons
              return Row(
                children: [
                  IconButton(
                    icon: Icon(
                      controller.selectedReminderIds.length == controller.reminders.length
                          ? Icons.deselect
                          : Icons.select_all,
                      color: Colors.white,
                    ),
                    onPressed: controller.selectAllReminders,
                    tooltip: 'Select All',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: controller.exitSelectionMode,
                    tooltip: 'Cancel',
                  ),
                ],
              );
            }

            // Normal mode: show menu
            return PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                switch (value) {
                  case 'refresh':
                    controller.refreshReminders();
                    break;
                  case 'batch':
                    controller.enterSelectionMode();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, size: 20),
                      SizedBox(width: 12),
                      Text('Refresh'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'batch',
                  child: Row(
                    children: [
                      Icon(Icons.checklist, size: 20),
                      SizedBox(width: 12),
                      Text('Batch Manage'),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
      body: Column(
        children: [
          // Main content area
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.reminders.isEmpty) {
                return const CircularLoader(message: 'Loading reminders...');
              }

              if (controller.reminders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 80,
                        color: darkMode ? TColors.darkGrey : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No reminders yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: darkMode ? TColors.darkGrey : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the + button to create one',
                        style: TextStyle(
                          fontSize: 14,
                          color: darkMode ? TColors.darkGrey : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => controller.refreshReminders(),
                color: TColors.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: TSizes.sm),
                  itemCount: controller.reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = controller.reminders[index];
                    return ReminderListItem(reminder: reminder);
                  },
                ),
              );
            }),
          ),

          // 🔧 Batch Action Bar at bottom
          const BatchActionBar(),
        ],
      ),
      floatingActionButton: Obx(() {
        // Hide FAB in selection mode
        if (controller.isSelectionMode.value) {
          return const SizedBox.shrink();
        }

        return FloatingActionButton(
          onPressed: () {
            final controller = Get.put(AddReminderController());
            controller.clearForm();

            showDialog(
              context: context,
              builder: (context) {
                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: const AddReminderForm(),
                );
              },
            );
          },
          backgroundColor: TColors.primary,
          shape: const CircleBorder(),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        );
      }),
    );
  }
}