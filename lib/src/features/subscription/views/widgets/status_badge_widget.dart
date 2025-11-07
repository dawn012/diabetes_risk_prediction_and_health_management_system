import 'package:flutter/material.dart';

class StatusBadgeWidget extends StatelessWidget {
  final String statusText;
  final Color statusColor;

  const StatusBadgeWidget({
    super.key,
    required this.statusText,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText.toUpperCase(),
        style: TextStyle(
          color: statusColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}