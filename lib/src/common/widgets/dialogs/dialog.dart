import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/constants/colors.dart';

class TDialog {
  TDialog._();

  static void deleteDialog({
    required String title,
    required String message,
    required VoidCallback? onConfirm,
  }) {
    final context = Get.context!;

    Get.dialog(
      Dialog(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 24), // 整体内边距
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, // 标题靠左
            children: [
              // 标题
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 12), // 标题和描述之间的间距

              // 提示信息
              Text(
                message,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24), // 信息和按钮的间距

              // 按钮区域
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 取消按钮（灰色）
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        foregroundColor: TColors.black,
                        backgroundColor: Colors.grey[200],
                        padding: const EdgeInsets.symmetric(vertical: 14), // 高度
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20), // 圆角
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12), // 按钮间距

                  // 删除按钮（红色）
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14), // 高度
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        side: BorderSide.none,
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
    return await Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            // 当按钮被点击时，关闭当前弹框，并返回 false 作为结果。
            onPressed: () => Get.back(result: false),
            child: Text('Discard'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('Keep Writing'),
          ),
        ],
      ),
    ) ?? true; // 默认返回 true (Keep Writing)
  }
}
