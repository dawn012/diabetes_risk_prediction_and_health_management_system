import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../utils/constants/admin_colors.dart';
import '../../../../../utils/helpers/export_helper.dart';
import '../../../../../utils/helpers/helper_functions.dart';

class AdminChartExportButton extends StatelessWidget {
  final ChartExportData exportData;
  final String tooltip;
  final IconData? icon;
  final bool showLabel;

  const AdminChartExportButton({
    super.key,
    required this.exportData,
    this.tooltip = 'Export Chart',
    this.icon,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);

    if (showLabel) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: (darkMode ? Colors.black : Colors.grey).withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: exportData.hasData
              ? () => ExportHelper.showExportDialog(exportData: exportData)
              : null,
          icon: Icon(
            icon ?? Iconsax.document_download_bold,
            size: 18,
          ),
          label: const Text(
            'Export Report',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: exportData.hasData
                ? TAdminColors.primary
                : TAdminColors.getOnSurfaceVariantColor(darkMode).withOpacity(0.3),
            foregroundColor: exportData.hasData
                ? Colors.white
                : TAdminColors.getOnSurfaceVariantColor(darkMode).withOpacity(0.6),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: exportData.hasData ? 2 : 0,
            disabledBackgroundColor: TAdminColors.getOnSurfaceVariantColor(darkMode).withOpacity(0.1),
            disabledForegroundColor: TAdminColors.getOnSurfaceVariantColor(darkMode).withOpacity(0.4),
          ),
        ),
      );
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: exportData.hasData ? [
            BoxShadow(
              color: TAdminColors.primary.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: IconButton(
          onPressed: exportData.hasData
              ? () => ExportHelper.showExportDialog(exportData: exportData)
              : null,
          icon: Icon(
            icon ?? Iconsax.document_download_bold,
            size: 20,
          ),
          style: IconButton.styleFrom(
            backgroundColor: exportData.hasData
                ? TAdminColors.primary
                : TAdminColors.getSurfaceVariantColor(darkMode),
            foregroundColor: exportData.hasData
                ? Colors.white
                : TAdminColors.getOnSurfaceVariantColor(darkMode).withOpacity(0.4),
            padding: const EdgeInsets.all(12),
            minimumSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: exportData.hasData ? 2 : 0,
            hoverColor: exportData.hasData
                ? TAdminColors.primaryDark
                : TAdminColors.getHoverColor(darkMode),
          ),
        ),
      ),
    );
  }
}