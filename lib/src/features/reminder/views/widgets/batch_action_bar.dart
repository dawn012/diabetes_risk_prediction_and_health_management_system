import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../common/widgets/dialogs/common_confirmation_dialog.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/reminder_controller.dart';

class BatchActionBar extends StatelessWidget {
  const BatchActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ReminderController.instance;
    final darkMode = THelperFunctions.isDarkMode(context);

    return Obx(() {
      if (!controller.isSelectionMode.value) {
        return const SizedBox.shrink();
      }

      final selectedCount = controller.selectedReminderIds.length;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: darkMode ? TColors.dark : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Close button
              IconButton(
                onPressed: controller.exitSelectionMode,
                icon: const Icon(Icons.close),
                color: darkMode ? TColors.white : TColors.black,
              ),

              const SizedBox(width: 8),

              // Selected count
              Expanded(
                child: Text(
                  '$selectedCount selected',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: darkMode ? TColors.white : TColors.black,
                  ),
                ),
              ),

              // Select All button
              TextButton.icon(
                onPressed: controller.selectAllReminders,
                icon: Icon(
                  selectedCount == controller.reminders.length
                      ? Iconsax.tick_square_bold
                      : Iconsax.square_bold,
                  size: 20,
                ),
                label: const Text('All'),
                style: TextButton.styleFrom(
                  foregroundColor: TColors.primary,
                ),
              ),

              const SizedBox(width: 8),

              // Enable/Disable button
              IconButton(
                onPressed: selectedCount > 0
                    ? () => _showEnableDisableDialog(context, controller)
                    : null,
                icon: const Icon(Iconsax.toggle_on_bold),
                color: selectedCount > 0 ? TColors.primary : Colors.grey,
                tooltip: 'Enable/Disable',
              ),

              const SizedBox(width: 8),

              // Delete button
              IconButton(
                onPressed: selectedCount > 0
                    ? () => _showDeleteDialog(context, controller)
                    : null,
                icon: const Icon(Iconsax.trash_bold),
                color: selectedCount > 0 ? TColors.error : Colors.grey,
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showEnableDisableDialog(BuildContext context, ReminderController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Action'),
        content: const Text('Do you want to enable or disable the selected reminders?'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              controller.batchToggleReminders(false);
            },
            child: const Text('Disable'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.batchToggleReminders(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TColors.primary,
            ),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ReminderController controller) {
    final count = controller.selectedReminderIds.length;
    ConfirmationDialog.show(
      title: 'Delete Reminders',
      message: 'Are you sure you want to delete $count reminder${count > 1 ? 's' : ''}? This action cannot be undone.',
      confirmButtonText: 'Delete',
      customIcon: Iconsax.trash_bold,
      iconColor: TColors.error,
      confirmButtonColor: TColors.error,
      onConfirm: () {
        controller.batchDeleteReminders();
      },
    );
  }
}