import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../common/widgets/dialogs/batch_confirmation_dialog.dart';
import '../../../../../utils/constants/admin_colors.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/reward_management_controller.dart';

class RewardBatchActionsBar extends StatelessWidget {
  final RewardManagementController controller;

  const RewardBatchActionsBar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return Obx(() => AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: controller.selectedRewards.isNotEmpty ? 72 : 0,
      child: controller.selectedRewards.isNotEmpty
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
              '${controller.selectedRewards.length} reward${controller.selectedRewards.length == 1 ? '' : 's'} selected',
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
                if (controller.showingActiveRewards.value) ...[
                  // Batch disable for active rewards
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
                  // Batch enable for disabled rewards
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
    final count = controller.selectedRewards.length;
    final plural = count == 1 ? '' : 's';

    BatchDialog.showBatchAction(
      actionType: BatchActionType.ban,
      selectedItems: controller.selectedRewards,
      onConfirm: () => controller.batchDisableRewards(),
      getItemDisplayName: (reward) => reward.title,
      getItemSubtitle: (reward) => '${reward.costPoints} points',
      customTitle: 'Disable Multiple Rewards',
      customMessage: 'Are you sure you want to disable $count selected reward$plural? This action will make the reward$plural no longer be available to users.',
      customConfirmButtonText: 'Disable Reward'
    );
  }

  void _showBatchEnableConfirmation() {
    final count = controller.selectedRewards.length;
    final plural = count == 1 ? '' : 's';

    BatchDialog.showBatchAction(
      actionType: BatchActionType.restore,
      selectedItems: controller.selectedRewards,
      onConfirm: () => controller.batchEnableRewards(),
      getItemDisplayName: (reward) => reward.title,
      getItemSubtitle: (reward) => '${reward.costPoints} points',
      customTitle: 'Enable Multiple Rewards',
      customMessage: 'Are you sure you want to enable $count selected reward$plural? This action will make the reward$plural available to users.',
      customConfirmButtonText: 'Enable Reward'
    );
  }
}