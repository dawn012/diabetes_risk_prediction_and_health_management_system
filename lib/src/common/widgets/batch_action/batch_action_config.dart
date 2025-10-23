import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../utils/constants/admin_colors.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/helpers/helper_functions.dart';

class BatchActionConfig {
  final BatchActionType actionType;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const BatchActionConfig({
    required this.actionType,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });
}

class GenericBatchActionBar<T> extends StatelessWidget {
  final RxList<T> selectedItems;
  final VoidCallback onClearSelection;
  final List<BatchActionConfig> actions;
  final String itemName; // e.g., "user", "post", "item"

  const GenericBatchActionBar({
    super.key,
    required this.selectedItems,
    required this.onClearSelection,
    required this.actions,
    this.itemName = 'item',
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return Obx(() => AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: selectedItems.isNotEmpty ? 72 : 0,
      child: selectedItems.isNotEmpty
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
              '${selectedItems.length} ${itemName}${selectedItems.length == 1 ? '' : 's'} selected',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: TAdminColors.getOnSurfaceColor(darkMode),
              ),
            ),

            Spacer(),

            // Actions
            Row(
              children: [
                // Clear selection button
                TextButton.icon(
                  onPressed: onClearSelection,
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

                // Action buttons
                ...actions.map((action) => Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: ElevatedButton.icon(
                    onPressed: action.onPressed,
                    icon: Icon(
                      action.icon,
                      size: 14,
                    ),
                    label: Text(
                      action.label,
                      style: TextStyle(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: action.color,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(color: action.color),
                      elevation: 0,
                    ),
                  ),
                )).toList(),
              ],
            ),
          ],
        ),
      )
          : SizedBox.shrink(),
    ));
  }
}

// Helper factory methods for common batch actions
class BatchActionFactory {
  static BatchActionConfig banUsers(VoidCallback onPressed) {
    return BatchActionConfig(
      actionType: BatchActionType.ban,
      label: 'Ban Selected',
      icon: Iconsax.user_remove_bold,
      color: TAdminColors.error,
      onPressed: onPressed,
    );
  }

  static BatchActionConfig restoreUsers(VoidCallback onPressed) {
    return BatchActionConfig(
      actionType: BatchActionType.restore,
      label: 'Restore Selected',
      icon: Iconsax.refresh_bold,
      color: TAdminColors.success,
      onPressed: onPressed,
    );
  }

  static BatchActionConfig disablePosts(VoidCallback onPressed) {
    return BatchActionConfig(
      actionType: BatchActionType.disable,
      label: 'Disable Selected',
      icon: Iconsax.eye_slash_bold,
      color: TAdminColors.error,
      onPressed: onPressed,
    );
  }

  static BatchActionConfig enablePosts(VoidCallback onPressed) {
    return BatchActionConfig(
      actionType: BatchActionType.enable,
      label: 'Enable Selected',
      icon: Iconsax.eye_bold,
      color: TAdminColors.success,
      onPressed: onPressed,
    );
  }

  static BatchActionConfig deleteItems(VoidCallback onPressed) {
    return BatchActionConfig(
      actionType: BatchActionType.delete,
      label: 'Delete Selected',
      icon: Iconsax.trash_bold,
      color: TAdminColors.error,
      onPressed: onPressed,
    );
  }
}