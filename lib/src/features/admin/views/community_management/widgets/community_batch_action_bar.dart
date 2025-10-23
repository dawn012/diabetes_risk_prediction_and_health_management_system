import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../common/widgets/dialogs/batch_confirmation_dialog.dart';
import '../../../../../utils/constants/admin_colors.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/community_management_controller.dart';

class CommunityBatchActionsBar extends StatelessWidget {
  final CommunityManagementController controller;

  const CommunityBatchActionsBar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return Obx(() =>
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: controller.selectedPosts.isNotEmpty ? 72 : 0,
          child: controller.selectedPosts.isNotEmpty
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
                  '${controller.selectedPosts.length} post${controller
                      .selectedPosts.length == 1 ? '' : 's'} selected',
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
                          color: TAdminColors.getOnSurfaceVariantColor(
                              darkMode),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),

                    SizedBox(width: 8),

                    // Batch action based on current view
                    if (controller.showingActivePosts.value) ...[
                      // Batch disable for active posts
                      ElevatedButton.icon(
                        onPressed: () => _showBatchDisableConfirmation(),
                        icon: Icon(
                          Iconsax.eye_slash_bold,
                          size: 14,
                        ),
                        label: Text(
                          'Disable Selected', style: TextStyle(fontSize: 14),),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TAdminColors.error,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: const BorderSide(color: TAdminColors.error),
                          elevation: 0,
                        ),
                      ),
                    ] else
                      ...[
                        // Batch enable for disabled posts
                        ElevatedButton.icon(
                          onPressed: () => _showBatchEnableConfirmation(),
                          icon: Icon(
                            Iconsax.eye_bold,
                            size: 14,
                          ),
                          label: Text(
                            'Enable Selected', style: TextStyle(fontSize: 14),),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TAdminColors.success,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
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
    BatchDialog.showBatchAction(
      actionType: BatchActionType.ban,
      // Reusing ban type for disable
      selectedItems: controller.selectedPosts,
      onConfirm: () => controller.batchDisablePosts(),
      getItemDisplayName: (post) => 'Post ${post.postId}',
      getItemSubtitle: (post) =>
      controller.posterData[post.posterId]?.username ?? 'Unknown user',
    );
  }

  void _showBatchEnableConfirmation() {
    BatchDialog.showBatchAction(
      actionType: BatchActionType.restore,
      // Reusing restore type for enable
      selectedItems: controller.selectedPosts,
      onConfirm: () => controller.batchEnablePosts(),
      getItemDisplayName: (post) => 'Post ${post.postId}',
      getItemSubtitle: (post) =>
      controller.posterData[post.posterId]?.username ?? 'Unknown user',
    );
  }
}