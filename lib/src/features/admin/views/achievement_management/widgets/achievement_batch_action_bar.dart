import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../common/widgets/dialogs/batch_confirmation_dialog.dart';
import '../../../../../utils/constants/admin_colors.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/achievement_management_controller.dart';

class AchievementBatchActionsBar extends StatelessWidget {
  final AchievementManagementController controller;

  const AchievementBatchActionsBar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return Obx(() => AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: controller.selectedAchievements.isNotEmpty ? 72 : 0,
      child: controller.selectedAchievements.isNotEmpty
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
              '${controller.selectedAchievements.length} achievement${controller.selectedAchievements.length == 1 ? '' : 's'} selected',
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
                if (controller.showingActiveAchievements.value) ...[
                  // Batch disable for active achievements
                  ElevatedButton.icon(
                    onPressed: () => _showBatchDisableConfirmation(),
                    icon: Icon(
                      Iconsax.eye_slash_bold,
                      size: 14,
                    ),
                    label: Text(
                      'Disable Selected',
                      style: TextStyle(fontSize: 14),
                    ),
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
                  // Batch enable for disabled achievements
                  ElevatedButton.icon(
                    onPressed: () => _showBatchEnableConfirmation(),
                    icon: Icon(
                      Iconsax.eye_bold,
                      size: 14,
                    ),
                    label: Text(
                      'Enable Selected',
                      style: TextStyle(fontSize: 14),
                    ),
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

  void _showBatchDisableConfirmation() {
    final count = controller.selectedAchievements.length;
    final plural = count == 1 ? '' : 's';

    BatchDialog.showBatchAction(
      actionType: BatchActionType.ban, // Reusing ban type for disable
      selectedItems: controller.selectedAchievements,
      onConfirm: () => controller.batchDisableAchievements(),
      getItemDisplayName: (achievement) => achievement.achievementTitle,
      getItemSubtitle: (achievement) => achievement.achievementType.displayName,
      customTitle: 'Disable Multiple Achievements',
      customMessage: 'Are you sure you want to disable $count selected achievement$plural? This action will make the achievement$plural no longer be available to users.',
      customConfirmButtonText: 'Disable Achievement'
    );
  }

  void _showBatchEnableConfirmation() {
    final count = controller.selectedAchievements.length;
    final plural = count == 1 ? '' : 's';

    BatchDialog.showBatchAction(
      actionType: BatchActionType.restore, // Reusing restore type for enable
      selectedItems: controller.selectedAchievements,
      onConfirm: () => controller.batchEnableAchievements(),
      getItemDisplayName: (achievement) => achievement.achievementTitle,
      getItemSubtitle: (achievement) => achievement.achievementType.displayName,
      customTitle: 'Enable Multiple Achievements',
      customMessage: 'Are you sure you want to enable $count selected achievement$plural? This action will make the achievement$plural available to users.',
      customConfirmButtonText: 'Enable Achievement'
    );
  }
}