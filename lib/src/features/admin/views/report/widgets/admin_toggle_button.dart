import 'package:flutter/material.dart';

import '../../../../../utils/constants/admin_colors.dart';

class AdminToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool darkMode;

  const AdminToggleButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? TAdminColors.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : TAdminColors.getOnSurfaceColor(darkMode),
          ),
        ),
      ),
    );
  }
}