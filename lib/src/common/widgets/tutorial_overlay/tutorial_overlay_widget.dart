import 'package:flutter/material.dart';

import '../../../utils/constants/colors.dart';

/// 教学提示位置
enum TooltipPosition {
  top,
  bottom,
  left,
  right,
  center,
}

/// 自定义教学 Overlay Widget
class TutorialOverlay extends StatelessWidget {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final VoidCallback? onNext;
  final VoidCallback? onSkip;
  final VoidCallback? onComplete;
  final bool showNextButton;
  final bool showSkipButton;
  final bool showCompleteButton;
  final String? nextButtonText;
  final String? completeButtonText;
  final TooltipPosition tooltipPosition;
  final bool allowInteraction;
  final EdgeInsets? highlightPadding;
  final Color? highlightColor;
  final Color? overlayColor;

  const TutorialOverlay({
    super.key,
    required this.targetKey,
    required this.title,
    required this.description,
    this.onNext,
    this.onSkip,
    this.onComplete,
    this.showNextButton = true,
    this.showSkipButton = true,
    this.showCompleteButton = false,
    this.nextButtonText,
    this.completeButtonText,
    this.tooltipPosition = TooltipPosition.bottom,
    this.allowInteraction = false,
    this.highlightPadding,
    this.highlightColor,
    this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    final RenderBox? renderBox =
    targetKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) {
      return const SizedBox.shrink();
    }

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final padding = highlightPadding ?? const EdgeInsets.all(8);

    return Stack(
      children: [
        // 半透明遮罩 - 根据 allowInteraction 决定是否拦截点击
        Positioned.fill(
          child: IgnorePointer(
            ignoring: allowInteraction, // 关键改动：如果允许交互，则忽略遮罩的点击
            child: CustomPaint(
              painter: _OverlayPainter(
                targetRect: Rect.fromLTWH(
                  offset.dx - padding.left,
                  offset.dy - padding.top,
                  size.width + padding.horizontal,
                  size.height + padding.vertical,
                ),
                overlayColor: overlayColor ?? Colors.black.withOpacity(0.4),
                allowInteraction: allowInteraction,
              ),
            ),
          ),
        ),

        // 高亮区域边框（仅视觉效果）
        if (!allowInteraction)
          Positioned(
            left: offset.dx - padding.left,
            top: offset.dy - padding.top,
            child: IgnorePointer(
              child: Container(
                width: size.width + padding.horizontal,
                height: size.height + padding.vertical,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: highlightColor ?? TColors.primary.withOpacity(0.8),
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (highlightColor ?? TColors.primary).withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),

        // 提示框
        _buildTooltip(context, offset, size, padding),
      ],
    );
  }

  Widget _buildOverlay(
      BuildContext context, Offset offset, Size size, EdgeInsets padding) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: allowInteraction ? null : () {}, // 阻止点击穿透
        child: CustomPaint(
          painter: _OverlayPainter(
            targetRect: Rect.fromLTWH(
              offset.dx - padding.left,
              offset.dy - padding.top,
              size.width + padding.horizontal,
              size.height + padding.vertical,
            ),
            overlayColor: overlayColor ?? Colors.black.withOpacity(0.4),
            allowInteraction: allowInteraction,
          ),
          // 关键：添加这个属性
          child: allowInteraction
              ? Stack(
            children: [
              // 在目标区域放置一个透明的可交互容器
              Positioned(
                left: offset.dx - padding.left,
                top: offset.dy - padding.top,
                width: size.width + padding.horizontal,
                height: size.height + padding.vertical,
                child: IgnorePointer(
                  ignoring: false, // 允许交互
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ],
          )
              : null,
        ),
      ),
    );
  }

  Widget _buildTooltip(
      BuildContext context, Offset offset, Size size, EdgeInsets padding) {
    final screenSize = MediaQuery.of(context).size;
    final targetCenter = Offset(
      offset.dx + size.width / 2,
      offset.dy + size.height / 2,
    );

    // 计算提示框位置
    Offset tooltipOffset;
    MainAxisAlignment alignment;

    switch (tooltipPosition) {
      case TooltipPosition.top:
        tooltipOffset = Offset(
          targetCenter.dx,
          offset.dy - padding.top - 20,
        );
        alignment = MainAxisAlignment.end;
        break;
      case TooltipPosition.bottom:
        tooltipOffset = Offset(
          targetCenter.dx,
          offset.dy + size.height + padding.bottom + 20,
        );
        alignment = MainAxisAlignment.start;
        break;
      case TooltipPosition.left:
        tooltipOffset = Offset(
          offset.dx - padding.left - 20,
          targetCenter.dy,
        );
        alignment = MainAxisAlignment.center;
        break;
      case TooltipPosition.right:
        tooltipOffset = Offset(
          offset.dx + size.width + padding.right + 20,
          targetCenter.dy,
        );
        alignment = MainAxisAlignment.center;
        break;
      case TooltipPosition.center:
        tooltipOffset = Offset(
          screenSize.width / 2,
          screenSize.height / 2,
        );
        alignment = MainAxisAlignment.center;
        break;
    }

    return Positioned(
      left: tooltipPosition == TooltipPosition.left
          ? null
          : (tooltipPosition == TooltipPosition.right
          ? tooltipOffset.dx
          : 20),
      right: tooltipPosition == TooltipPosition.left
          ? screenSize.width - tooltipOffset.dx
          : (tooltipPosition == TooltipPosition.right ? 20 : 20),
      top: tooltipPosition == TooltipPosition.top
          ? null
          : (tooltipPosition == TooltipPosition.bottom
          ? tooltipOffset.dy
          : tooltipOffset.dy - 100),
      bottom: tooltipPosition == TooltipPosition.top
          ? screenSize.height - tooltipOffset.dy
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: alignment,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: screenSize.width - 40,
            ),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),

                // 描述
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // 按钮行
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Skip 按钮
                    if (showSkipButton)
                      TextButton(
                        onPressed: onSkip,
                        // style: TextButton.styleFrom(
                        //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        // ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),

                    const SizedBox(width: 8),

                    // Complete 按钮
                    if (showCompleteButton)
                      ElevatedButton(
                        onPressed: onComplete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text(completeButtonText ?? 'Complete'),
                      ),

                    // Next 按钮
                    if (showNextButton && !showCompleteButton)
                      ElevatedButton(
                        onPressed: onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text(nextButtonText ?? 'Next'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 自定义画笔绘制遮罩
class _OverlayPainter extends CustomPainter {
  final Rect targetRect;
  final Color overlayColor;
  final bool allowInteraction;

  _OverlayPainter({
    required this.targetRect,
    required this.overlayColor,
    required this.allowInteraction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;

    // 绘制整个屏幕的遮罩
    // canvas.drawRect(
    //   Rect.fromLTWH(0, 0, size.width, size.height),
    //   paint,
    // );

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // 在目标区域挖一个洞（透明区域）
    if (allowInteraction) {
      // 从路径中减去目标区域
      path.addRRect(
        RRect.fromRectAndRadius(targetRect, const Radius.circular(12)),
      );
      path.fillType = PathFillType.evenOdd; // 关键：使用 evenOdd 填充规则
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}