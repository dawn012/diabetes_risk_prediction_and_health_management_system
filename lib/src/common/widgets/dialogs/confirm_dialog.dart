import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = "Keep Writing",
    this.cancelText = "Discard",
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          // 当按钮被点击时，关闭当前弹框，并返回 false 作为结果。
          onPressed: () => Get.back(result: false), // 用户点击 Discard
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () => Get.back(result: true), // 用户点击 Keep Writing
          child: Text(confirmText),
        ),
      ],
    );
  }
}
