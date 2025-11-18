import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/helpers/helper_functions.dart';

class AccountBannedDialog {
  AccountBannedDialog._();

  /// Show account banned dialog (non-dismissible)
  static Future<void> show({
    required VoidCallback onConfirm,
  }) async {
    final context = Get.context!;
    final isDark = THelperFunctions.isDarkMode(context);

    await Get.dialog(
      WillPopScope(
        onWillPop: () async => false, // Prevent back button dismiss
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
                  child: const Icon(
                    Iconsax.close_circle_bold,
                    color: TColors.error,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  'Account Banned',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                    color: isDark ? TColors.white : TColors.black,
                  ),
                ),
                const SizedBox(height: 12),

                // Message
                Text(
                  'Your account has been banned due to violation of our community guidelines. '
                      'Please contact support if you believe this is a mistake.',
                  style: TextStyle(
                    color: isDark ? TColors.darkGrey : TColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 24),

                // Confirm button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back(); // Close dialog first
                      onConfirm(); // Then execute logout
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
      barrierDismissible: false, // Prevent tap outside to dismiss
      barrierColor: Colors.black.withOpacity(0.5)
    );
  }
}