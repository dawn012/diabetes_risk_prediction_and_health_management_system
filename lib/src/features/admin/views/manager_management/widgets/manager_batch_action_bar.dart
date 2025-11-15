import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../common/widgets/dialogs/batch_confirmation_dialog.dart';
import '../../../../../utils/constants/admin_colors.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/manager_management_controller.dart';

class ManagerBatchActionsBar extends StatelessWidget {
  final ManagerManagementController controller;

  const ManagerBatchActionsBar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return Obx(() => AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: controller.selectedManagers.isNotEmpty ? 72 : 0,
      child: controller.selectedManagers.isNotEmpty
          ? Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        margin: EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: TAdminColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: TAdminColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Selection info
            Icon(
              Iconsax.tick_square_bold,
              color: TAdminColors.primary,
              size: 20,
            ),
            SizedBox(width: 12),
            Text(
              '${controller.selectedManagers.length} manager${controller.selectedManagers.length == 1 ? '' : 's'} selected',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: TAdminColors.getOnSurfaceColor(darkMode),
              ),
            ),

            Spacer(),

            // Batch actions
            Row(
              children: [
                // Clear selection
                TextButton.icon(
                  onPressed: () => controller.toggleSelectAll(false),
                  icon: Icon(
                    Iconsax.close_circle_bold,
                    size: 16,
                    color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                  ),
                  label: Text(
                    'Clear',
                    style: TextStyle(
                      color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),

                SizedBox(width: 8),

                // Batch action based on current view
                if (controller.showingActiveManagers.value) ...[
                  // Batch ban for active managers
                  ElevatedButton.icon(
                    onPressed: () => _showBatchBanConfirmation(),
                    icon: Icon(
                      Iconsax.user_remove_bold,
                      size: 14,
                    ),
                    label: Text('Ban Selected', style: TextStyle(fontSize: 14),),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TAdminColors.error,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: const BorderSide(color: TAdminColors.error),
                      elevation: 0,
                    ),
                  ),
                ] else ...[
                  // Batch restore for banned managers
                  ElevatedButton.icon(
                    onPressed: () => _showBatchRestoreConfirmation(),
                    icon: Icon(
                      Iconsax.refresh_bold,
                      size: 14,
                    ),
                    label: Text('Restore Selected', style: TextStyle(fontSize: 14),),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TAdminColors.success,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: const BorderSide(color: TAdminColors.success),
                      elevation: 0,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      )
          : SizedBox.shrink(),
    ));
  }

  void _showBatchBanConfirmation() {
    BatchDialog.showBatchBan(
      selectedUsers: controller.selectedManagers,
      onConfirm: () => controller.batchBanManagers(),
      getUserName: (manager) => manager.username,
      getUserEmail: (manager) => manager.email,
    );
  }

  void _showBatchRestoreConfirmation() {
    BatchDialog.showBatchRestore(
      selectedUsers: controller.selectedManagers,
      onConfirm: () => controller.batchRestoreManagers(),
      getUserName: (manager) => manager.username,
      getUserEmail: (manager) => manager.email,
    );
  }
}