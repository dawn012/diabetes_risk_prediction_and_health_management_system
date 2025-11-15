import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../utils/constants/admin_colors.dart';
import '../../../utils/helpers/helper_functions.dart';

enum BatchActionType {
  ban,
  restore,
}

class BatchConfirmationDialog extends StatelessWidget {
  final BatchActionType actionType;
  final List<dynamic> selectedItems;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final String Function(dynamic item) getItemDisplayName;
  final String Function(dynamic item) getItemSubtitle;
  final String? customTitle;
  final String? customMessage;
  final String? customConfirmButtonText;

  const BatchConfirmationDialog({
    super.key,
    required this.actionType,
    required this.selectedItems,
    required this.onConfirm,
    this.onCancel,
    required this.getItemDisplayName,
    required this.getItemSubtitle,
    this.customTitle,
    this.customMessage,
    this.customConfirmButtonText,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: TAdminColors.getSurfaceColor(darkMode),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getActionColor().withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getActionIcon(),
                  size: 32,
                  color: _getActionColor(),
                ),
              ),

              SizedBox(height: 16),

              // Title
              Text(
                customTitle ?? _getTitle(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: TAdminColors.getOnSurfaceColor(darkMode),
                ),
              ),

              SizedBox(height: 8),

              // Message
              Text(
                customMessage ?? _getMessage(),
                style: TextStyle(
                  color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 16),

              // Items preview
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxHeight: 150),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: TAdminColors.getSurfaceVariantColor(darkMode),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...selectedItems.take(5).map((item) =>
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                '• ${getItemDisplayName(item)} (${getItemSubtitle(item)})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                                ),
                              ),
                            )
                        ).toList(),
                        if (selectedItems.length > 5)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '• ... and ${selectedItems.length - 5} more',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _handleCancel,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getActionColor(),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 18),
                        side: BorderSide(color: _getActionColor()),
                      ),
                      child: Text(customConfirmButtonText ?? _getConfirmButtonText()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    switch (actionType) {
      case BatchActionType.ban:
        return 'Ban Multiple Users';
      case BatchActionType.restore:
        return 'Restore Multiple Users';
    }
  }

  String _getMessage() {
    final count = selectedItems.length;
    final plural = count == 1 ? '' : 's';

    switch (actionType) {
      case BatchActionType.ban:
        return 'Are you sure you want to ban $count selected user$plural? This action will disable their account$plural.';
      case BatchActionType.restore:
        return 'Are you sure you want to restore $count selected user$plural? This will reactivate their account$plural.';
    }
  }

  String _getConfirmButtonText() {
    switch (actionType) {
      case BatchActionType.ban:
        return 'Ban Users';
      case BatchActionType.restore:
        return 'Restore Users';
    }
  }

  IconData _getActionIcon() {
    switch (actionType) {
      case BatchActionType.ban:
        return Iconsax.warning_2_bold;
      case BatchActionType.restore:
        return Iconsax.shield_tick_bold;
    }
  }

  Color _getActionColor() {
    switch (actionType) {
      case BatchActionType.ban:
        return TAdminColors.error;
      case BatchActionType.restore:
        return TAdminColors.success;
    }
  }

  void _handleConfirm() {
    Get.back();
    onConfirm();
  }

  void _handleCancel() {
    Get.back();
    if (onCancel != null) {
      onCancel!();
    }
  }
}

// Convenience methods
class BatchDialog {
  static void showBatchAction({
    required BatchActionType actionType,
    required List<dynamic> selectedItems,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    required String Function(dynamic item) getItemDisplayName,
    required String Function(dynamic item) getItemSubtitle,
    String? customTitle,
    String? customMessage,
    String? customConfirmButtonText,
  }) {
    Get.dialog(
      BatchConfirmationDialog(
        actionType: actionType,
        selectedItems: selectedItems,
        onConfirm: onConfirm,
        onCancel: onCancel,
        getItemDisplayName: getItemDisplayName,
        getItemSubtitle: getItemSubtitle,
        customTitle: customTitle,
        customMessage: customMessage,
        customConfirmButtonText: customConfirmButtonText,
      ),
    );
  }

  static void showBatchBan({
    required List<dynamic> selectedUsers,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    required String Function(dynamic user) getUserName,
    required String Function(dynamic user) getUserEmail,
  }) {
    showBatchAction(
      actionType: BatchActionType.ban,
      selectedItems: selectedUsers,
      onConfirm: onConfirm,
      onCancel: onCancel,
      getItemDisplayName: getUserName,
      getItemSubtitle: getUserEmail,
    );
  }

  static void showBatchRestore({
    required List<dynamic> selectedUsers,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    required String Function(dynamic user) getUserName,
    required String Function(dynamic user) getUserEmail,
  }) {
    showBatchAction(
      actionType: BatchActionType.restore,
      selectedItems: selectedUsers,
      onConfirm: onConfirm,
      onCancel: onCancel,
      getItemDisplayName: getUserName,
      getItemSubtitle: getUserEmail,
    );
  }
}