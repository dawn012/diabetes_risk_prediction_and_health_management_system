import 'package:flutter/material.dart';

import '../../../../../utils/constants/admin_colors.dart';
import '../../../../../utils/constants/enums.dart';

class AdminChartTypeToggle extends StatelessWidget {
  final ChartType selectedType;
  final Function(ChartType) onTypeChanged;
  final bool darkMode;

  const AdminChartTypeToggle({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceVariantColor(darkMode),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TAdminColors.getBorderColor(darkMode)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildChartToggle(
            icon: Icons.show_chart,
            isSelected: selectedType == ChartType.line,
            onTap: () => onTypeChanged(ChartType.line),
            tooltip: 'Line Chart',
          ),
          _buildChartToggle(
            icon: Icons.bar_chart,
            isSelected: selectedType == ChartType.bar,
            onTap: () => onTypeChanged(ChartType.bar),
            tooltip: 'Bar Chart',
          ),
        ],
      ),
    );
  }

  Widget _buildChartToggle({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? TAdminColors.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected
                ? Colors.white
                : TAdminColors.getOnSurfaceVariantColor(darkMode),
          ),
        ),
      ),
    );
  }
}