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
import '../../features/subscription/models/user_subscription_model.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';
import 'helper_functions.dart';

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

      // Request storage permission using system dialog
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        return; // User denied permission
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

  /// Request storage permission using system dialog
  static Future<bool> _requestStoragePermission() async {
    if (Platform.isIOS) {
      // iOS doesn't need explicit permission for app documents
      return true;
    }

    if (Platform.isAndroid) {
      // Get Android version
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      debugPrint('Android SDK version: $sdkInt');

      Permission targetPermission;

      // Android 13+ (API 33+) uses granular media permissions
      if (sdkInt >= 33) {
        // For Android 13+, we use scoped storage - no permission needed for app-specific directory
        // But we'll use storage permission for compatibility
        targetPermission = Permission.photos;
      } else if (sdkInt >= 30) {
        // For Android 11-12 (API 30-32)
        // Try storage permission first (for scoped storage)
        targetPermission = Permission.storage;
      } else {
        // For Android 10 and below (API 29-)
        targetPermission = Permission.storage;
      }

      debugPrint('Target permission: $targetPermission');

      // Check current permission status
      PermissionStatus status = await targetPermission.status;

      if (status.isGranted) {
        debugPrint('Permission already granted');
        return true;
      }

      if (status.isDenied) {
        // Request permission - this will show system dialog
        debugPrint('Requesting permission...');
        status = await targetPermission.request();

        if (status.isGranted) {
          debugPrint('Permission granted after request');
          return true;
        } else if (status.isPermanentlyDenied) {
          debugPrint('Permission permanently denied');
          await _showOpenSettingsDialog();
          return false;
        } else {
          debugPrint('Permission denied');
          TLoaders.warningSnackBar(
            title: 'Permission Required',
            message: 'Storage permission is needed to export files.',
          );
          return false;
        }
      }

      if (status.isPermanentlyDenied) {
        debugPrint('Permission permanently denied - opening settings');
        await _showOpenSettingsDialog();
        return false;
      }

      // For Android 11+, if permission is restricted, we can still use app-specific directory
      if (sdkInt >= 30 && (status.isRestricted || status.isLimited)) {
        debugPrint('Permission restricted/limited - using app-specific storage');
        return true; // We can still use getExternalStorageDirectory()
      }

      return false;
    }

    return false;
  }

  /// Show dialog to guide user to open app settings
  static Future<void> _showOpenSettingsDialog() async {
    await Get.dialog(
      AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Storage permission has been denied. Please enable it in app settings to export files.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Add delay to ensure dialog is fully closed
              Future.delayed(const Duration(milliseconds: 300), () {
                openAppSettings();
              });
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
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

      debugPrint('=== PDF Export Debug Info ===');
      debugPrint('Title: ${exportData.title}');
      debugPrint('Time Range: ${exportData.timeRange}');
      debugPrint('Period Filter: ${exportData.periodFilter}');
      debugPrint('Trend Filter: ${exportData.trendFilter}');
      debugPrint('Has Data: ${exportData.hasData}');
      debugPrint('Data Count: ${exportData.data.length}');

      // Capture chart as image
      final chartImage = await _captureChart(exportData.chartKey);

      // Create PDF document
      final pdf = pw.Document();

      // Generate table pages
      final tablePages = _buildDataTablePages(exportData.data);

      // First page (includes title, chart, and first page of table)
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
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    child: pw.Image(
                      pw.MemoryImage(chartImage),
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                ],

                // Data table title
                pw.Text(
                  'Data Summary',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),

                // Display first page of table or no data message
                if (exportData.data.isNotEmpty)
                  tablePages.first
                else
                  pw.Text('No data available'),

                // If there are multiple pages, show continuation indicator
                if (tablePages.length > 1) ...[
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Continued on next page... (Total ${exportData.data.length} records)',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  ),
                ],

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

      // Add additional pages for remaining table data
      for (int i = 1; i < tablePages.length; i++) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${exportData.title} - Data Summary (Continued)',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Page ${i + 1} of ${tablePages.length} - Showing records ${(i * 25) + 1} to ${(i + 1) * 25 > exportData.data.length ? exportData.data.length : (i + 1) * 25} of ${exportData.data.length}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  ),
                  pw.SizedBox(height: 10),
                  tablePages[i],
                  pw.Spacer(),
                  pw.Divider(),
                  pw.Text(
                    'Page ${i + 1} of ${tablePages.length} - Generated on: ${DateTime.now().toString().substring(0, 19)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              );
            },
          ),
        );
      }

      // Save PDF
      await _savePDF(pdf, exportData.title);

      debugPrint('PDF generated successfully');
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
      final ui.Image image = await boundary.toImage(pixelRatio: 1.5);
      final ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Failed to capture chart: $e');
      return null;
    }
  }

  /// Build data table for PDF - supports multiple pages
  static List<pw.Widget> _buildDataTablePages(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      debugPrint('PDF Table: No data available');
      return [pw.Text('No data available')];
    }

    // Get headers from first data entry
    final headers = data.first.keys.toList();

    // Add debug info before generating PDF table
    debugPrint("📊 PDF TABLE DEBUG - Headers: $headers");
    if (data.isNotEmpty) {
      debugPrint("📊 PDF TABLE DEBUG - First row: ${data.first}");
    }

    // Rows per page
    const rowsPerPage = 25;
    final totalPages = (data.length / rowsPerPage).ceil();
    final List<pw.Widget> pages = [];

    for (int page = 0; page < totalPages; page++) {
      final startIndex = page * rowsPerPage;
      final endIndex = (startIndex + rowsPerPage) < data.length
          ? startIndex + rowsPerPage
          : data.length;
      final pageData = data.sublist(startIndex, endIndex);

      // Dynamically calculate column widths
      final columnWidths = <int, pw.FlexColumnWidth>{};
      for (int i = 0; i < headers.length; i++) {
        if (i == 0) {
          columnWidths[i] = const pw.FlexColumnWidth(1.5); // Date/time column wider
        } else {
          columnWidths[i] = const pw.FlexColumnWidth(1);
        }
      }

      final table = pw.Table(
        border: pw.TableBorder.all(),
        columnWidths: columnWidths,
        children: [
          // Header row
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
            children: headers.map((header) {
              return pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  header.toUpperCase(),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.left,
                ),
              );
            }).toList(),
          ),
          // Data rows for current page
          ...pageData.map((row) {
            return pw.TableRow(
              children: headers.map((header) {
                final value = row[header]?.toString() ?? '';
                return pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    value,
                    textAlign: pw.TextAlign.left,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                );
              }).toList(),
            );
          }).toList(),
        ],
      );

      pages.add(table);
    }

    return pages;
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

    // Add debug info before CSV generation
    debugPrint("📊 CSV DEBUG - Headers: ${exportData.data.first.keys.toList()}");
    if (exportData.data.isNotEmpty) {
      debugPrint("📊 CSV DEBUG - First row: ${exportData.data.first}");
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
      // Use app-specific external storage directory (doesn't require permission on Android 10+)
      directory = await getExternalStorageDirectory();

      if (directory != null) {
        // Create a more accessible path within app's external storage
        // This will be something like: /storage/emulated/0/Android/data/your.package/files/
        final appDir = Directory('${directory.path}/Exports');
        if (!await appDir.exists()) {
          await appDir.create(recursive: true);
        }
        directory = appDir;
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

    debugPrint('PDF saved to: ${file.path}');

    TLoaders.successSnackBar(
      title: 'PDF Exported',
      message: 'File saved successfully',
    );

    // Share file - this is the best way to let users save it to Downloads or other locations
    await Share.shareXFiles([XFile(file.path)], text: 'Health Data Export');
  }

  /// Save CSV file
  static Future<void> _saveCSV(String content, String title) async {
    Directory? directory;

    if (Platform.isAndroid) {
      // Use app-specific external storage directory
      directory = await getExternalStorageDirectory();

      if (directory != null) {
        final appDir = Directory('${directory.path}/Exports');
        if (!await appDir.exists()) {
          await appDir.create(recursive: true);
        }
        directory = appDir;
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

    debugPrint('CSV saved to: ${file.path}');

    TLoaders.successSnackBar(
      title: 'CSV Exported',
      message: 'File saved successfully',
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
                padding: const EdgeInsets.symmetric(horizontal: 10)),
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
                padding: const EdgeInsets.symmetric(horizontal: 10)),
            child: const Text(
              'Export PDF',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Export payment receipt as PDF
  static Future<void> exportReceipt({
    required UserSubscriptionModel subscription,
  }) async {
    try {
      // Check if user has necessary permissions
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        return;
      }

      TLoaders.customToast(message: 'Generating receipt...');

      // Create PDF document
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return _buildReceiptPDF(subscription);
          },
        ),
      );

      // Save PDF
      await _saveReceiptPDF(pdf, subscription);
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Export Failed',
        message: 'Failed to generate receipt: ${e.toString()}',
      );
    }
  }

  /// Build receipt PDF content
  static pw.Widget _buildReceiptPDF(UserSubscriptionModel subscription) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header with logo placeholder
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'DIATRACK',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Diabetes Health Management',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.blue600,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'PAYMENT RECEIPT',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Date: ${THelperFunctions.getFormattedDate(subscription.successfulPayment!.transactionDateTime)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 30),

        // Transaction Information
        pw.Text(
          'Transaction Details',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Divider(thickness: 2),
        pw.SizedBox(height: 10),

        // Transaction details table
        _buildReceiptInfoRow('Transaction ID:', subscription.successfulPayment!.transactionId),
        pw.SizedBox(height: 8),
        _buildReceiptInfoRow('Status:', subscription.successfulPayment!.status.displayName.toUpperCase()),
        pw.SizedBox(height: 8),
        _buildReceiptInfoRow('Payment Method:', subscription.successfulPayment!.paymentMethod.toUpperCase()),
        pw.SizedBox(height: 8),
        _buildReceiptInfoRow(
          'Transaction Date:',
          THelperFunctions.getFormattedDate(
            subscription.successfulPayment!.transactionDateTime,
            format: 'dd MMM yyyy, HH:mm',
          ),
        ),

        pw.SizedBox(height: 30),

        // Subscription Information
        pw.Text(
          'Subscription Details',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Divider(thickness: 2),
        pw.SizedBox(height: 10),

        _buildReceiptInfoRow('Plan Name:', subscription.subscriptionPlan.planName),
        pw.SizedBox(height: 8),
        _buildReceiptInfoRow('Subscription ID:', subscription.subscriptionId),
        pw.SizedBox(height: 8),
        _buildReceiptInfoRow(
          'Start Date:',
          THelperFunctions.getFormattedDate(subscription.startDateTime),
        ),
        pw.SizedBox(height: 8),
        _buildReceiptInfoRow(
          'End Date:',
          THelperFunctions.getFormattedDate(subscription.endDateTime),
        ),
        pw.SizedBox(height: 8),
        _buildReceiptInfoRow(
          'Duration:',
          '${subscription.subscriptionPlan.durationDays} days',
        ),

        pw.SizedBox(height: 30),

        // Features included
        pw.Text(
          'Features Included',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Divider(thickness: 2),
        pw.SizedBox(height: 10),

        ...subscription.subscriptionPlan.features.map(
              (feature) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 6,
                  height: 6,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.blue700,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Text(feature),
              ],
            ),
          ),
        ),

        pw.SizedBox(height: 30),

        // Payment Summary
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Subtotal:',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.Text(
                    '${subscription.successfulPayment!.currency.toUpperCase()} ${subscription.successfulPayment!.amount.toStringAsFixed(2)}',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total Amount:',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '${subscription.successfulPayment!.currency.toUpperCase()} ${subscription.successfulPayment!.amount.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        pw.Spacer(),

        // Footer
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                'Thank you for your payment!',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'For any queries, please contact support@diatrack.app',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Generated on: ${DateTime.now().toString().substring(0, 19)}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build receipt info row
  static pw.Widget _buildReceiptInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 150,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  /// Save receipt PDF file
  static Future<void> _saveReceiptPDF(pw.Document pdf, UserSubscriptionModel subscription) async {
    Directory? directory;

    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory();

      if (directory != null) {
        final appDir = Directory('${directory.path}/Receipts');
        if (!await appDir.exists()) {
          await appDir.create(recursive: true);
        }
        directory = appDir;
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    if (directory == null) {
      throw Exception('Could not access storage directory');
    }

    final fileName = _generateReceiptFileName(subscription);
    final file = File('${directory.path}/$fileName');

    await file.writeAsBytes(await pdf.save());

    debugPrint('Receipt saved to: ${file.path}');

    TLoaders.successSnackBar(
      title: 'Receipt Downloaded',
      message: 'Receipt saved successfully',
    );

    // Share file
    await Share.shareXFiles([XFile(file.path)], text: 'Payment Receipt');
  }

  /// Generate receipt file name
  static String _generateReceiptFileName(UserSubscriptionModel subscription) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final transactionId = subscription.successfulPayment!.transactionId.substring(0, 8);
    return 'receipt_${transactionId}_$timestamp.pdf';
  }
}