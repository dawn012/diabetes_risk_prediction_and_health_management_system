import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../common/widgets/dialogs/batch_confirmation_dialog.dart';
import '../../../../../utils/constants/admin_colors.dart';
import '../../../../../utils/helpers/helper_functions.dart';

class BatchActionsBar<T> extends StatelessWidget {
  final RxList<T> selectedItems;
  final RxBool showingActive;
  final VoidCallback onClearSelection;
  final VoidCallback onBatchBan;
  final VoidCallback onBatchRestore;
  final String itemLabel;
  final String Function(T) getUserName;
  final String Function(T) getUserEmail;

  const BatchActionsBar({
    super.key,
    required this.selectedItems,
    required this.showingActive,
    required this.onClearSelection,
    required this.onBatchBan,
    required this.onBatchRestore,
    required this.itemLabel,
    required this.getUserName,
    required this.getUserEmail,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return Obx(() => AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: selectedItems.isNotEmpty ? 72 : 0,
      child: selectedItems.isNotEmpty
          ? Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
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
            const Icon(
              Iconsax.tick_square_bold,
              color: TAdminColors.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              '${selectedItems.length} $itemLabel${selectedItems.length == 1 ? '' : 's'} selected',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: TAdminColors.getOnSurfaceColor(darkMode),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onClearSelection,
                  icon: Icon(
                    Iconsax.close_circle_bold,
                    size: 16,
                    color:
                    TAdminColors.getOnSurfaceVariantColor(darkMode),
                  ),
                  label: Text(
                    'Clear',
                    style: TextStyle(
                      color: TAdminColors.getOnSurfaceVariantColor(
                          darkMode),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                if (showingActive.value)
                  ElevatedButton.icon(
                    onPressed: () => BatchDialog.showBatchBan(
                      selectedUsers: selectedItems,
                      onConfirm: onBatchBan,
                      getUserName: (user) => getUserName(user as T),
                      getUserEmail: (user) => getUserEmail(user as T),
                    ),
                    icon: const Icon(Iconsax.user_remove_bold, size: 14),
                    label: const Text('Ban Selected',
                        style: TextStyle(fontSize: 14)),
                    style: _buttonStyle(TAdminColors.error),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => BatchDialog.showBatchRestore(
                      selectedUsers: selectedItems,
                      onConfirm: onBatchRestore,
                      getUserName: (user) => getUserName(user as T),
                      getUserEmail: (user) => getUserEmail(user as T),
                    ),
                    icon: const Icon(Iconsax.refresh_bold, size: 14),
                    label: const Text('Restore Selected',
                        style: TextStyle(fontSize: 14)),
                    style: _buttonStyle(TAdminColors.success),
                  ),
              ],
            ),
          ],
        ),
      )
          : const SizedBox.shrink(),
    ));
  }

  ButtonStyle _buttonStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      side: BorderSide(color: color),
      elevation: 0,
    );
  }
}
