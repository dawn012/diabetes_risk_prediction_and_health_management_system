import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/helpers/helper_functions.dart';

class TDialog {
  TDialog._();

  /// Generic confirm dialog - can be used for any confirmation action
  static Future<bool?> confirmDialog({
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    IconData? icon,
    Color? iconColor,
    Color? confirmButtonColor,
    VoidCallback? onConfirm,
  }) async {
    return await _baseConfirmDialog(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      icon: icon,
      iconColor: iconColor,
      confirmButtonColor: confirmButtonColor ?? TColors.warning,
      onConfirm: onConfirm,
    );
  }

  /// Delete dialog with pre-configured red styling
  static Future<bool?> deleteDialog({
    required String title,
    required String message,
    required VoidCallback? onConfirm,
    String? buttonTitle,
  }) async {
    return await _baseConfirmDialog(
      title: title,
      message: message,
      confirmText: buttonTitle ?? 'Delete',
      cancelText: 'Cancel',
      icon: Iconsax.trash_bold,
      iconColor: TColors.error,
      confirmButtonColor: TColors.error,
      onConfirm: onConfirm,
    );
  }

  /// Common base dialog for confirmation actions
  static Future<bool?> _baseConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required String cancelText,
    IconData? icon,
    Color? iconColor,
    Color? confirmButtonColor,
    VoidCallback? onConfirm,
  }) async {
    final context = Get.context!;
    final isDark = THelperFunctions.isDarkMode(context);

    return await Get.dialog<bool>(
      Dialog(
        backgroundColor: isDark ? TColors.dark : TColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: BoxConstraints(maxWidth: 400),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              // if (icon != null) ...[
              //   Container(
              //     width: 56,
              //     height: 56,
              //     decoration: BoxDecoration(
              //       color: (iconColor ?? TColors.warning).withOpacity(0.1),
              //       shape: BoxShape.circle,
              //     ),
              //     child: Icon(
              //       icon,
              //       color: iconColor ?? TColors.warning,
              //       size: 28,
              //     ),
              //   ),
              //   SizedBox(height: 16),
              // ],

              // Title
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: isDark ? TColors.white : TColors.black,
                ),
              ),
              SizedBox(height: 12),

              // Message
              Text(
                message,
                style: TextStyle(
                  color: isDark ? TColors.darkGrey : TColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.left,
              ),
              SizedBox(height: 24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Cancel button
                  Expanded(
                    child: TextButton(
                      onPressed: _handleCancel,
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? TColors.white : TColors.black,
                        backgroundColor: isDark
                            ? TColors.darkGrey.withOpacity(0.5)
                            : Colors.grey[200],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        cancelText,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? TColors.white : TColors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Confirm button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleConfirm(onConfirm),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmButtonColor ?? TColors.warning,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        side: BorderSide.none,
                      ),
                      child: Text(
                        confirmText,
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
            ],
          ),
        ),
      ),
    );
  }

  static Future<bool> keepWriting({
    required String title,
    required String message,
  }) async {
    final context = Get.context!;
    final isDark = THelperFunctions.isDarkMode(context);

    return await Get.dialog(
      AlertDialog(
        backgroundColor: isDark ? TColors.dark : TColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? TColors.white : TColors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: isDark ? TColors.lightGrey : TColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: isDark ? TColors.lightGrey : TColors.textSecondary,
            ),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Get.back(result: false),
            style: TextButton.styleFrom(
              foregroundColor: TColors.primary,
              backgroundColor: TColors.primary.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Keep Writing',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ) ?? true;
  }

  // 私有方法处理取消
  static void _handleCancel() {
    Get.back(result: false);
  }

  // 私有方法处理确认
  static void _handleConfirm(VoidCallback? onConfirm) {
    Get.back(result: true); // 先关闭对话框并返回 true
    if (onConfirm != null) {
      onConfirm(); // 然后执行回调
    }
  }
}