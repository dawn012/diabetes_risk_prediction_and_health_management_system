import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../common/loaders/loaders.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';

enum ExportType { pdf, csv }

class ChartExportData {
  final String title;
  final List<Map<String, dynamic>> data;
  final GlobalKey chartKey;
  final String timeRange;
  final String? periodFilter;
  final String? trendFilter;
  final bool hasData;

  ChartExportData({
    required this.title,
    required this.data,
    required this.chartKey,
    required this.timeRange,
    this.periodFilter,
    this.trendFilter,
    required this.hasData,
  });
}

class ExportHelper {
  ExportHelper._();

  /// 简单的拒绝次数记录
  static final Map<Permission, int> _denialCount = {};

  /// Export chart data as PDF or CSV
  static Future<void> exportChart({
    required ChartExportData exportData,
    required ExportType exportType,
  }) async {
    try {
      // Check if has data
      if (!exportData.hasData || exportData.data.isEmpty) {
        TLoaders.warningSnackBar(
          title: 'No Data to Export',
          message: 'There is no data available for the current filters.',
        );
        return;
      }

      // Request storage permission with proper dialog
      final hasPermission = await _requestStoragePermissionWithDialog();
      if (!hasPermission) {
        return; // User denied permission or dialog was cancelled
      }

      if (exportType == ExportType.pdf) {
        await _exportAsPDF(exportData);
      } else {
        await _exportAsCSV(exportData);
      }
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Export Failed',
        message: 'Failed to export data: ${e.toString()}',
      );
    }
  }

  /// Request storage permission with user dialog
  static Future<bool> _requestStoragePermissionWithDialog() async {
    if (Platform.isIOS) {
      // iOS doesn't need explicit permission for app documents
      return true;
    }

    if (Platform.isAndroid) {
      // Get Android version
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      Permission targetPermission;

      debugPrint('Android SDK version: $sdkInt');

      // Android 13+ (API 33+) uses different permissions
      if (sdkInt >= 33) {
        // For Android 13+, we need photos permission for media files
        targetPermission = Permission.photos;
      } else if (sdkInt >= 30) {
        // For Android 11-12, we need manageExternalStorage or use scoped storage
        targetPermission = Permission.manageExternalStorage;
      } else {
        // For older Android versions
        targetPermission = Permission.storage;
      }

      debugPrint('Android SDK version: $targetPermission');

      // Check current permission status
      PermissionStatus status = await targetPermission.status;

      if (status.isGranted) {
        return true;
      }

      // Show explanation dialog first
      bool shouldRequest = await _showPermissionExplanationDialog();
      if (!shouldRequest) {
        return false;
      }

      // Request permission
      status = await targetPermission.request();

      if (status.isGranted) {
        return true;
      } else {
        // 检查是否是第一次拒绝还是已经拒绝过
        final shouldOpenSettings = await _checkIfShouldOpenSettings(targetPermission);
        await _showPermissionDeniedDialog(shouldOpenSettings);
        return false;
      }
    }

    return false;
  }

  /// 检查是否需要引导用户去设置
  static Future<bool> _checkIfShouldOpenSettings(Permission permission) async {
    final status = await permission.status;

    // 如果是永久拒绝或者已经拒绝过多次，引导去设置
    if (status.isPermanentlyDenied) {
      return true;
    }

    // 如果已经拒绝过一次，就引导去设置
    return status.isDenied && await _hasBeenDeniedBefore(permission);
  }

  static Future<bool> _hasBeenDeniedBefore(Permission permission) async {
    final status = await permission.status;
    if (status.isDenied) {
      _denialCount[permission] = (_denialCount[permission] ?? 0) + 1;
      return _denialCount[permission]! > 1; // 如果拒绝超过1次，引导去设置
    }
    return false;
  }

  /// Show permission explanation dialog
  static Future<bool> _showPermissionExplanationDialog() async {
    return await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Storage Permission Required'),
            content: const Text(
              'This app needs storage permission to save exported files to your device. '
              'The files will be saved to your Downloads folder and you can share them with other apps.',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 10)),
                child: const Text('Grant Permission', style: TextStyle(
                  fontSize: 12
                ),),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Show permission denied dialog
  static Future<void> _showPermissionDeniedDialog(
      bool shouldOpenSettings) async {
    await Get.dialog(
      AlertDialog(
        title: const Text('Permission Required'),
        content: Text(
          shouldOpenSettings
              ? 'Storage permission has been permanently denied. Please go to app settings to enable it manually.'
              : 'Storage permission is required to export files. Please try again and grant the permission.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
          if (shouldOpenSettings)
            ElevatedButton(
              onPressed: () {
                Get.back();
                // 添加延迟确保对话框完全关闭
                Future.delayed(const Duration(milliseconds: 300), () {
                  openAppSettings();
                });
              },
              style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 10)),
              child: const Text(
                'Open Settings',
                style: TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Export as PDF
  static Future<void> _exportAsPDF(ChartExportData exportData) async {
    try {
      TLoaders.customToast(message: 'Generating PDF...');

      // Capture chart as image
      final chartImage = await _captureChart(exportData.chartKey);

      // Create PDF document
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Title
                pw.Text(
                  exportData.title,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),

                // Filters info
                if (exportData.timeRange.isNotEmpty) ...[
                  pw.Text('Time Range: ${exportData.timeRange}'),
                  pw.SizedBox(height: 5),
                ],
                if (exportData.periodFilter != null &&
                    exportData.periodFilter != 'All') ...[
                  pw.Text('Period Filter: ${exportData.periodFilter}'),
                  pw.SizedBox(height: 5),
                ],
                if (exportData.trendFilter != null &&
                    exportData.trendFilter != 'All') ...[
                  pw.Text('Trend Filter: ${exportData.trendFilter}'),
                  pw.SizedBox(height: 5),
                ],
                pw.SizedBox(height: 20),

                // Chart image
                if (chartImage != null) ...[
                  pw.Image(pw.MemoryImage(chartImage)),
                  pw.SizedBox(height: 20),
                ],

                // Data table
                pw.Text(
                  'Data Summary',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                _buildDataTable(exportData.data),

                // Footer
                pw.Spacer(),
                pw.Divider(),
                pw.Text(
                  'Generated on: ${DateTime.now().toString().substring(0, 19)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            );
          },
        ),
      );

      // Save PDF
      await _savePDF(pdf, exportData.title);
    } catch (e) {
      throw Exception('PDF generation failed: $e');
    }
  }

  /// Export as CSV
  static Future<void> _exportAsCSV(ChartExportData exportData) async {
    try {
      TLoaders.customToast(message: 'Generating CSV...');

      // Generate CSV content
      String csvContent = _generateCSVContent(exportData);

      // Save CSV
      await _saveCSV(csvContent, exportData.title);
    } catch (e) {
      throw Exception('CSV generation failed: $e');
    }
  }

  /// Capture chart as image
  static Future<Uint8List?> _captureChart(GlobalKey chartKey) async {
    try {
      final RenderRepaintBoundary boundary =
          chartKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Failed to capture chart: $e');
      return null;
    }
  }

  /// Build data table for PDF
  static pw.Widget _buildDataTable(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return pw.Text('No data available');
    }

    // Get headers from first data entry
    final headers = data.first.keys.toList();

    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: headers
              .map(
                (header) => pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    header.toString().toUpperCase(),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
              )
              .toList(),
        ),
        // Data rows
        ...data
            .take(20)
            .map(
              (row) => // Limit to first 20 rows for PDF
                  pw.TableRow(
                children: headers
                    .map(
                      (header) => pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(row[header]?.toString() ?? ''),
                      ),
                    )
                    .toList(),
              ),
            )
            .toList(),
      ],
    );
  }

  /// Generate CSV content
  static String _generateCSVContent(ChartExportData exportData) {
    final StringBuffer buffer = StringBuffer();

    // Add metadata
    buffer.writeln('# ${exportData.title}');
    buffer.writeln('# Generated on: ${DateTime.now()}');
    buffer.writeln('# Time Range: ${exportData.timeRange}');
    if (exportData.periodFilter != null && exportData.periodFilter != 'All') {
      buffer.writeln('# Period Filter: ${exportData.periodFilter}');
    }
    if (exportData.trendFilter != null && exportData.trendFilter != 'All') {
      buffer.writeln('# Trend Filter: ${exportData.trendFilter}');
    }
    buffer.writeln();

    if (exportData.data.isEmpty) {
      buffer.writeln('No data available');
      return buffer.toString();
    }

    // Add headers
    final headers = exportData.data.first.keys.toList();
    buffer.writeln(headers.join(','));

    // Add data rows
    for (final row in exportData.data) {
      final values = headers
          .map((header) => _escapeCsvValue(row[header]?.toString() ?? ''))
          .toList();
      buffer.writeln(values.join(','));
    }

    return buffer.toString();
  }

  /// Escape CSV value
  static String _escapeCsvValue(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Save PDF file
  static Future<void> _savePDF(pw.Document pdf, String title) async {
    Directory? directory;

    if (Platform.isAndroid) {
      // Try to get external storage directory first
      try {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } catch (e) {
        directory = await getExternalStorageDirectory();
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    if (directory == null) {
      throw Exception('Could not access storage directory');
    }

    final fileName = _generateFileName(title, 'pdf');
    final file = File('${directory.path}/$fileName');

    await file.writeAsBytes(await pdf.save());

    TLoaders.successSnackBar(
      title: 'PDF Exported',
      message: 'File saved to: ${file.path}',
    );

    // Share file
    await Share.shareXFiles([XFile(file.path)], text: 'Health Data Export');
  }

  /// Save CSV file
  static Future<void> _saveCSV(String content, String title) async {
    Directory? directory;

    if (Platform.isAndroid) {
      // Try to get external storage directory first
      try {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } catch (e) {
        directory = await getExternalStorageDirectory();
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    if (directory == null) {
      throw Exception('Could not access storage directory');
    }

    final fileName = _generateFileName(title, 'csv');
    final file = File('${directory.path}/$fileName');

    await file.writeAsString(content);

    TLoaders.successSnackBar(
      title: 'CSV Exported',
      message: 'File saved to: ${file.path}',
    );

    // Share file
    await Share.shareXFiles([XFile(file.path)], text: 'Health Data Export');
  }

  /// Generate file name
  static String _generateFileName(String title, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanTitle = title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    return '${cleanTitle}_$timestamp.$extension';
  }

  /// Show export type selection dialog
  static void showExportDialog({
    required ChartExportData exportData,
  }) {
    Get.dialog(
      AlertDialog(
        title: const Text('Export Chart'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export "${exportData.title}" data as:',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: TSizes.md),
            if (!exportData.hasData || exportData.data.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(TSizes.md),
                decoration: BoxDecoration(
                  color: TColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
                  border: Border.all(color: TColors.warning),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: TColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: TSizes.sm),
                    const Expanded(
                      child: Text(
                        'No data available for current filters.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TSizes.md),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: exportData.hasData && exportData.data.isNotEmpty
                ? () {
                    Get.back();
                    exportChart(
                      exportData: exportData,
                      exportType: ExportType.csv,
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 10)),
            child: const Text(
              'Export CSV',
              style: TextStyle(fontSize: 12),
            ),
          ),
          ElevatedButton(
            onPressed: exportData.hasData && exportData.data.isNotEmpty
                ? () {
                    Get.back();
                    exportChart(
                      exportData: exportData,
                      exportType: ExportType.pdf,
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 10)),
            child: const Text(
              'Export PDF',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
