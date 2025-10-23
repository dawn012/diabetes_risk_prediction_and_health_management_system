import 'package:flutter/material.dart';

import '../../../../../utils/constants/admin_colors.dart';

class AdminDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final Function(T?) onChanged;
  final String Function(T) getLabel;
  final bool darkMode;
  final double? width;

  const AdminDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.getLabel,
    required this.darkMode,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: TAdminColors.getOnSurfaceColor(darkMode),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: width ?? 120,
          height: 44, // Fixed height to match period selector
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: TAdminColors.getSurfaceVariantColor(darkMode),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: TAdminColors.getBorderColor(darkMode)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: TAdminColors.getOnSurfaceVariantColor(darkMode),
              ),
              items: items
                  .map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text(
                  getLabel(item),
                  style: TextStyle(
                    color: TAdminColors.getOnSurfaceColor(darkMode),
                  ),
                ),
              ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}