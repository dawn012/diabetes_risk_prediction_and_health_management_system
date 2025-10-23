import 'package:flutter/material.dart';

import '../../../../../utils/constants/admin_colors.dart';
import '../../../../../utils/constants/enums.dart';
import 'admin_toggle_button.dart';

class AdminPeriodSelector extends StatelessWidget {
  final ReportPeriod selectedPeriod;
  final Function(ReportPeriod) onPeriodChanged;
  final bool darkMode;

  const AdminPeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Report Period',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: TAdminColors.getOnSurfaceColor(darkMode),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: TAdminColors.getSurfaceVariantColor(darkMode),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: TAdminColors.getBorderColor(darkMode)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AdminToggleButton(
                label: 'Monthly',
                isSelected: selectedPeriod == ReportPeriod.monthly,
                onTap: () => onPeriodChanged(ReportPeriod.monthly),
                darkMode: darkMode,
              ),
              AdminToggleButton(
                label: 'Yearly',
                isSelected: selectedPeriod == ReportPeriod.yearly,
                onTap: () => onPeriodChanged(ReportPeriod.yearly),
                darkMode: darkMode,
              ),
            ],
          ),
        ),
      ],
    );
  }
}