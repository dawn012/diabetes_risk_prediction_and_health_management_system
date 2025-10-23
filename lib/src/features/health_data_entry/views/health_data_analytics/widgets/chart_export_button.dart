import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/export_helper.dart';
import '../../../../../utils/helpers/helper_functions.dart';

class ChartExportButton extends StatelessWidget {
  final ChartExportData exportData;
  final Color? buttonColor;
  final Color? iconColor;
  final Color? disabledColor;
  final double iconSize;
  final EdgeInsets? padding;
  final bool showTooltip;
  final String? tooltip;

  const ChartExportButton({
    super.key,
    required this.exportData,
    this.buttonColor,
    this.iconColor,
    this.disabledColor,
    this.iconSize = 20,
    this.padding,
    this.showTooltip = true,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);
    final isEnabled = exportData.hasData && exportData.data.isNotEmpty;

    final button = IconButton(
      onPressed: isEnabled
          ? () => ExportHelper.showExportDialog(exportData: exportData)
          : null,
      padding: padding ?? const EdgeInsets.all(8),
      icon: Icon(
        Iconsax.export_bold,
        size: iconSize,
        color: isEnabled
            ? (iconColor ?? (darkMode ? TColors.white : TColors.textPrimary))
            : (disabledColor ?? TColors.textSecondary),
      ),
      style: IconButton.styleFrom(
        backgroundColor: isEnabled
            ? (buttonColor ?? Colors.transparent)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
        ),
      ),
    );

    if (showTooltip) {
      return Tooltip(
        message: tooltip ?? (isEnabled ? 'Export Chart' : 'No data to export'),
        child: button,
      );
    }

    return button;
  }
}

/// Alternative elevated button style for more prominent placement
class ChartExportElevatedButton extends StatelessWidget {
  final ChartExportData exportData;
  final String? text;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsets? padding;
  final double? width;

  const ChartExportElevatedButton({
    super.key,
    required this.exportData,
    this.text,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);
    final isEnabled = exportData.hasData && exportData.data.isNotEmpty;

    return SizedBox(
      width: width,
      child: ElevatedButton.icon(
        onPressed: isEnabled
            ? () => ExportHelper.showExportDialog(exportData: exportData)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled
              ? (backgroundColor ?? TColors.primary)
              : (darkMode ? TColors.darkGrey : TColors.grey),
          foregroundColor: isEnabled
              ? (foregroundColor ?? Colors.white)
              : TColors.textSecondary,
          padding: padding ?? const EdgeInsets.symmetric(
            horizontal: TSizes.md,
            vertical: TSizes.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
          ),
        ),
        icon: Icon(
          Iconsax.export_bold,
          size: 16,
        ),
        label: Text(
          text ?? 'Export',
          style: const TextStyle(
            fontSize: TSizes.fontSizeSm,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Floating action button style for export
class ChartExportFAB extends StatelessWidget {
  final ChartExportData exportData;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool mini;

  const ChartExportFAB({
    super.key,
    required this.exportData,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.mini = false,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);
    final isEnabled = exportData.hasData && exportData.data.isNotEmpty;

    return FloatingActionButton(
      onPressed: isEnabled
          ? () => ExportHelper.showExportDialog(exportData: exportData)
          : null,
      backgroundColor: isEnabled
          ? (backgroundColor ?? TColors.primary)
          : (darkMode ? TColors.darkGrey : TColors.grey),
      foregroundColor: isEnabled
          ? (foregroundColor ?? Colors.white)
          : TColors.textSecondary,
      elevation: elevation ?? 4.0,
      mini: mini,
      tooltip: isEnabled ? 'Export Chart' : 'No data to export',
      child: Icon(
        Iconsax.export_bold,
        size: mini ? 16 : 20,
      ),
    );
  }
}