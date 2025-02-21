import 'package:flutter/material.dart';

/// -- 用于 显示一个标题，并可选地显示一个按钮。
class TSectionHeading extends StatelessWidget {
  const TSectionHeading({
    super.key,
    this.textColor,
    this.showActionButton = true,  // 是否显示按钮
    required this.title,
    this.buttonTitle = 'View all',
    this.onPressed
  });

  final Color? textColor;
  final bool showActionButton;
  final String title, buttonTitle;
  // final void Function()? onPressed;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .headlineSmall!
              .apply(color: textColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (showActionButton)
          TextButton(onPressed: onPressed, child: Text(buttonTitle)),
      ],
    );
  }
}
