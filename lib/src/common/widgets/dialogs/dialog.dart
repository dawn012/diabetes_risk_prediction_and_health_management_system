import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
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
            children: [
              // Icon
              if (icon != null) ...[
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: (iconColor ?? TColors.warning).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? TColors.warning,
                    size: 28,
                  ),
                ),
                SizedBox(height: 16),
              ],

              // Title
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: isDark ? TColors.white : TColors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),

              // Message
              Text(
                message,
                style: TextStyle(
                  color: isDark ? TColors.darkGrey : TColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: isDark ? TColors.white : TColors.black,
                        side: BorderSide(
                          color: isDark
                              ? TColors.darkGrey.withOpacity(0.5)
                              : TColors.grey.withOpacity(0.5),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        cancelText,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back(result: true);
                        onConfirm?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: confirmButtonColor ?? TColors.warning,
                        foregroundColor: TColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        confirmText,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
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

  static void deleteDialog({
    required String title,
    required String message,
    required VoidCallback? onConfirm,
    String? buttonTitle,
  }) {
    final context = Get.context!;
    final isDark = THelperFunctions.isDarkMode(context);

    Get.dialog(
      Dialog(
        backgroundColor: isDark ? TColors.dark : TColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  fontSize: 22,
                  color: isDark ? TColors.white : TColors.black,
                ),
              ),
              const SizedBox(height: 12),

              // 提示信息
              Text(
                message,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: isDark ? TColors.lightGrey : TColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // 按钮区域
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 取消按钮
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
                        'Cancel',
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: isDark ? TColors.white : TColors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 删除按钮
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleConfirm(onConfirm),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        side: BorderSide.none,
                      ),
                      child: Text(
                        buttonTitle ?? 'Delete',
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
    Get.back();
  }

  // 私有方法处理确认
  static void _handleConfirm(VoidCallback? onConfirm) {
    Get.back(); // 先关闭对话框
    if (onConfirm != null) {
      onConfirm!(); // 然后执行回调
    }
  }
}