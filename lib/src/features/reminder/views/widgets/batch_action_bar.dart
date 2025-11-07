import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../common/widgets/dialogs/dialog.dart';
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
      final hasSelection = selectedCount > 0;

      return AnimatedSlide(
        offset: controller.isSelectionMode.value ? Offset.zero : const Offset(0, 1),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: darkMode
                  ? [
                const Color(0xFF1A1D2E),
                const Color(0xFF0A0E21),
              ]
                  : [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: darkMode ? Colors.black45 : Colors.grey.shade300,
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
            border: Border(
              top: BorderSide(
                color: darkMode ? const Color(0xFF2D3E5F) : Colors.grey.shade200,
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Selection info and select all
                Row(
                  children: [
                    // Selection count with animation
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: hasSelection
                            ? LinearGradient(
                          colors: [
                            TColors.primary.withOpacity(0.2),
                            TColors.primary.withOpacity(0.1),
                          ],
                        )
                            : null,
                        color: hasSelection ? null : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.tick_square_bold,
                            size: 16,
                            color: hasSelection ? TColors.primary : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$selectedCount selected',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: hasSelection
                                  ? (darkMode ? TColors.white : TColors.primary)
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Select All button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: controller.selectAllReminders,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: darkMode
                                  ? const Color(0xFF2D3E5F)
                                  : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                selectedCount == controller.reminders.length
                                    ? Iconsax.minus_square_bold
                                    : Iconsax.add_square_bold,
                                size: 18,
                                color: darkMode ? TColors.white : TColors.black,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                selectedCount == controller.reminders.length
                                    ? 'Deselect All'
                                    : 'Select All',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: darkMode ? TColors.white : TColors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    // Enable/Disable button
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        icon: Iconsax.toggle_on_circle_bold,
                        label: 'Toggle',
                        color: TColors.info,
                        darkMode: darkMode,
                        enabled: hasSelection,
                        onTap: hasSelection
                            ? () => _showEnableDisableDialog(context, controller)
                            : null,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Delete button
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        icon: Iconsax.trash_bold,
                        label: 'Delete',
                        color: TColors.error,
                        darkMode: darkMode,
                        enabled: hasSelection,
                        onTap: hasSelection
                            ? () => _showDeleteDialog(context, controller)
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required bool darkMode,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: enabled
                ? LinearGradient(
              colors: [
                color,
                color.withOpacity(0.8),
              ],
            )
                : null,
            color: enabled ? null : (darkMode ? const Color(0xFF2D3E5F) : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(14),
            boxShadow: enabled
                ? [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: enabled ? Colors.white : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: enabled ? Colors.white : Colors.grey,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEnableDisableDialog(BuildContext context, ReminderController controller) {
    final darkMode = THelperFunctions.isDarkMode(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: darkMode ? const Color(0xFF1A1D2E) : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: TColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Iconsax.toggle_on_circle_bold,
                color: TColors.info,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Choose Action',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkMode ? TColors.white : TColors.black,
              ),
            ),
          ],
        ),
        content: Text(
          'Do you want to enable or disable the selected reminders?',
          style: TextStyle(
            fontSize: 15,
            color: darkMode ? TColors.darkGrey : Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              controller.batchToggleReminders(false);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Disable',
              style: TextStyle(
                color: darkMode ? TColors.white : TColors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.batchToggleReminders(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TColors.success,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Enable',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ReminderController controller) {
    final count = controller.selectedReminderIds.length;
    TDialog.deleteDialog(
      title: 'Delete Reminders',
      message: 'Are you sure you want to delete $count reminder${count > 1 ? 's' : ''}? This action cannot be undone.',
      onConfirm: () {
        controller.batchDeleteReminders();
      },
    );
  }
}