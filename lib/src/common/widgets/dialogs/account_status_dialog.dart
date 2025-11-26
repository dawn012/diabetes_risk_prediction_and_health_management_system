import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/helpers/helper_functions.dart';

enum AccountStatusType {
  banned,
  deleted,
}

class AccountStatusDialog {
  AccountStatusDialog._();

  /// Show account status dialog (non-dismissible)
  static Future<void> show({
    required AccountStatusType statusType,
    required VoidCallback onConfirm,
    String? customMessage,
  }) async {
    final context = Get.context!;
    final isDark = THelperFunctions.isDarkMode(context);

    await Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: isDark ? TColors.dark : TColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: TColors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIcon(statusType),
                    color: TColors.error,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  _getTitle(statusType),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                    color: isDark ? TColors.white : TColors.black,
                  ),
                ),
                const SizedBox(height: 12),

                // Message
                Text(
                  customMessage ?? _getDefaultMessage(statusType),
                  style: TextStyle(
                    color: isDark ? TColors.darkGrey : TColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Confirm button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      side: BorderSide.none,
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
    );
  }

  static IconData _getIcon(AccountStatusType statusType) {
    switch (statusType) {
      case AccountStatusType.banned:
        return Iconsax.close_circle_bold;
      case AccountStatusType.deleted:
        return Iconsax.trash_bold;
    }
  }

  static String _getTitle(AccountStatusType statusType) {
    switch (statusType) {
      case AccountStatusType.banned:
        return 'Account Banned';
      case AccountStatusType.deleted:
        return 'Account Deleted';
    }
  }

  static String _getDefaultMessage(AccountStatusType statusType) {
    switch (statusType) {
      case AccountStatusType.banned:
        return 'Your account has been banned due to violation of our community guidelines. '
            'Please contact support if you believe this is a mistake.';
      case AccountStatusType.deleted:
        return 'Your account deletion request has been approved by an administrator. '
            'Your account will be logged out now.';
    }
  }

  /// Convenience method for showing banned dialog
  static Future<void> showBanned({
    required VoidCallback onConfirm,
    String? customMessage,
  }) async {
    await show(
      statusType: AccountStatusType.banned,
      onConfirm: onConfirm,
      customMessage: customMessage,
    );
  }

  /// Convenience method for showing deleted dialog
  static Future<void> showDeleted({
    required VoidCallback onConfirm,
    String? customMessage,
  }) async {
    await show(
      statusType: AccountStatusType.deleted,
      onConfirm: onConfirm,
      customMessage: customMessage,
    );
  }
}