import 'package:flutter/material.dart';

import '../../../utils/constants/colors.dart';

class RoundButton extends StatelessWidget {
  const RoundButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.color = TColors.primary,
    this.height = 50,
  });

  final VoidCallback? onPressed;
  final String label;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: color,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: TColors.white,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}
