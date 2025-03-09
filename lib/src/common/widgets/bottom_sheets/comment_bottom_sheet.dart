import 'package:diabetes_risk_prediction_and_health_management_system/src/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';

import '../../../utils/constants/colors.dart';

class CommentBottomSheet extends StatelessWidget {
  final String title;
  final List<BottomSheetOption> options;

  const CommentBottomSheet({
    super.key,
    required this.title,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// **🔹 标题**
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 15), // 靠近顶部
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: dark ? TColors.darkGrey : TColors.black,
            ),
          ),
        ),

        /// **🔹 选项列表**
        Column(
          children: options.map((option) {
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              leading: option.icon != null
                  ? Row(
                mainAxisSize: MainAxisSize.min, // 避免占满整行
                children: [
                  Icon(option.icon, color: option.iconColor, size: 34),
                  const SizedBox(width: 12), // 这里调整 icon 和文字之间的宽度
                ],
              ) : null,
              title: Text(
                option.text,
                style: TextStyle(
                  fontSize: 22,
                  color: dark ? TColors.white : TColors.black,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                option.onTap?.call();
              },
            );
          }).toList(),
        ),

        /// **🔹 底部间距**
        const SizedBox(height: 15),
      ],
    );
  }
}

class BottomSheetOption {
  final String text;
  final IconData? icon; // 让 icon 可选
  final Color? iconColor;
  final VoidCallback? onTap;

  BottomSheetOption({
    required this.text,
    this.icon, // 允许为空
    this.iconColor,
    this.onTap,
  });
}
