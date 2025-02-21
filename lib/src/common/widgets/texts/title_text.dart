import 'package:flutter/material.dart';

/// -- 可自定义大小、行数、对齐方式的文本组件
class TTitleText extends StatelessWidget {
  const TTitleText({
    super.key,
    required this.title,
    this.smallSize = false,
    this.maxLines = 2,
    this.textAlign = TextAlign.left,
  });

  final String title;
  final bool smallSize; // 是否使用较小的文本样式
  final int maxLines; // 最多允许显示的行数（超出部分省略）
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: smallSize
          ? Theme.of(context).textTheme.labelLarge
          : Theme.of(context).textTheme.titleSmall,
      overflow: TextOverflow.ellipsis,
      maxLines: maxLines,
      textAlign: textAlign,
    );
  }
}
