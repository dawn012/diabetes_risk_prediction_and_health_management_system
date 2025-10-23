import 'package:flutter/material.dart';

import '../../../../../utils/constants/admin_colors.dart';

class AdminStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool darkMode;

  const AdminStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}