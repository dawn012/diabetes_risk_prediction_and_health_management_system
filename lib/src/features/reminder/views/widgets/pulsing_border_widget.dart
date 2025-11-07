import 'package:flutter/material.dart';

class PulsingBorder extends StatefulWidget {
  final Widget child;
  final Color color;
  final double borderRadius;

  const PulsingBorder({
    super.key,
    required this.child,
    required this.color,
    this.borderRadius = 16,
  });

  @override
  State<PulsingBorder> createState() => _PulsingBorderState();
}

class _PulsingBorderState extends State<PulsingBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: widget.color.withOpacity(1 - _controller.value),
              width: 2,
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}