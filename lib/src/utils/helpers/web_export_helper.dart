import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// For web: Use universal_html instead of dart:html
import 'package:universal_html/html.dart' as html;

import '../../common/loaders/loaders.dart';
import '../constants/colors.dart';
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

class WebExportHelper {
  WebExportHelper._();

  /// Export chart data as PDF or CSV for web
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

  /// Export as PDF
  static Future<void> _exportAsPDF(ChartExportData exportData) async {
    try {
      TLoaders.customToast(message: 'Generating PDF...');

      debugPrint('=== PDF Export Debug Info ===');
      debugPrint('Title: ${exportData.title}');
      debugPrint('Time Range: ${exportData.timeRange}');
      debugPrint('Has Data: ${exportData.hasData}');
      debugPrint('Data Count: ${exportData.data.length}');

      // Capture chart as image
      final chartImage = await _captureChart(exportData.chartKey);

      // Create PDF document
      final pdf = pw.Document();

      // Generate table pages
      final tablePages = _buildDataTablePages(exportData.data);

      // First page (title, chart, and first page of table)
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with branding
                _buildPDFHeader(exportData),
                pw.SizedBox(height: 24),

                // Chart section
                if (chartImage != null) ...[
                  pw.Text(
                    'Visual Analytics',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    padding: const pw.EdgeInsets.all(16),
                    child: pw.Center(
                      child: pw.Image(
                        pw.MemoryImage(chartImage),
                        fit: pw.BoxFit.contain,
                        height: 280,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 24),
                ],

                // Data table section
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Detailed Data',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.Text(
                      'Total Records: ${exportData.data.length}',
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),

                // First page table or no data message
                if (exportData.data.isNotEmpty)
                  tablePages.first
                else
                  pw.Center(
                    child: pw.Text(
                      'No data available',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ),

                // Continuation indicator
                if (tablePages.length > 1) ...[
                  pw.SizedBox(height: 12),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'Continued on next page... (${exportData.data.length} total records)',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.blue800,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],

                // Footer
                pw.Spacer(),
                _buildPDFFooter(1, tablePages.length),
              ],
            );
          },
        ),
      );

      // Additional pages for remaining table data
      for (int i = 1; i < tablePages.length; i++) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
            build: (pw.Context context) {
              final startRecord = (i * 15) + 1;
              final endRecord = ((i + 1) * 15) > exportData.data.length
                  ? exportData.data.length
                  : (i + 1) * 15;

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Page header
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '${exportData.title} (Continued)',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.Text(
                        'Records $startRecord-$endRecord of ${exportData.data.length}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 16),

                  // Table content
                  tablePages[i],

                  // Footer
                  pw.Spacer(),
                  _buildPDFFooter(i + 1, tablePages.length),
                ],
              );
            },
          ),
        );
      }

      // Save PDF for web
      await _savePDFWeb(pdf, exportData.title);

      debugPrint('PDF generated successfully');
    } catch (e) {
      throw Exception('PDF generation failed: $e');
    }
  }

  /// Build PDF header with branding and metadata
  static pw.Widget _buildPDFHeader(ChartExportData exportData) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [PdfColors.blue700, PdfColors.blue900],
        ),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'DIATRACK',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Analytics Report',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.blue100,
                        fontWeight: pw.FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  THelperFunctions.getFormattedDate(
                    DateTime.now(),
                    format: 'dd MMM yyyy',
                  ),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(color: PdfColors.blue300, thickness: 1),
          pw.SizedBox(height: 12),

          // Report title
          pw.Text(
            exportData.title,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 8),

          // Metadata
          pw.Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (exportData.timeRange.isNotEmpty)
                _buildMetadataChip('Time Range', exportData.timeRange),
              if (exportData.periodFilter != null &&
                  exportData.periodFilter != 'All')
                _buildMetadataChip('Period', exportData.periodFilter!),
              if (exportData.trendFilter != null &&
                  exportData.trendFilter != 'All')
                _buildMetadataChip('Filter', exportData.trendFilter!),
            ],
          ),
        ],
      ),
    );
  }

  /// Build metadata chip
  static pw.Widget _buildMetadataChip(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFCCCCCC),
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.blue300),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            '$label: ',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.blue400,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            value,
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Build PDF footer
  static pw.Widget _buildPDFFooter(int currentPage, int totalPages) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated on ${THelperFunctions.getFormattedDate(DateTime.now(), format: 'dd MMM yyyy HH:mm')}',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
              ),
            ),
            pw.Text(
              'Page $currentPage of $totalPages',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Export as CSV
  static Future<void> _exportAsCSV(ChartExportData exportData) async {
    try {
      TLoaders.customToast(message: 'Generating CSV...');

      // Generate CSV content
      String csvContent = _generateCSVContent(exportData);

      // Save CSV for web
      await _saveCSVWeb(csvContent, exportData.title);
    } catch (e) {
      throw Exception('CSV generation failed: $e');
    }
  }

  /// Capture chart as image
  static Future<Uint8List?> _captureChart(GlobalKey chartKey) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));

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

  /// Build data table for PDF - intelligent pagination
  static List<pw.Widget> _buildDataTablePages(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return [pw.Text('No data available')];
    }

    final headers = data.first.keys.toList();
    final List<pw.Widget> pages = [];

    // 分页配置
    const PageConfig firstPageConfig =
        PageConfig(maxRows: 5, description: "First page with chart");
    const PageConfig subsequentPageConfig =
        PageConfig(maxRows: 15, description: "Subsequent pages");

    // 计算每页内容
    final pageConfigs = _calculatePageConfigs(
        data.length, firstPageConfig, subsequentPageConfig);

    int currentIndex = 0;

    for (int pageIndex = 0; pageIndex < pageConfigs.length; pageIndex++) {
      final config = pageConfigs[pageIndex];
      final endIndex = currentIndex + config.rowsThisPage;
      final pageData = data.sublist(currentIndex, endIndex);

      final table = _buildTable(headers, pageData);
      pages.add(table);

      currentIndex = endIndex;
    }

    return pages;
  }

  /// Calculate optimal page configurations
  static List<PageConfig> _calculatePageConfigs(
      int totalRows, PageConfig firstPage, PageConfig subsequentPage) {
    final List<PageConfig> configs = [];
    int remainingRows = totalRows;
    int pageNumber = 0;

    while (remainingRows > 0) {
      int rowsThisPage;

      if (pageNumber == 0) {
        // 第一页
        rowsThisPage = remainingRows.clamp(1, firstPage.maxRows);
      } else {
        // 后续页面
        rowsThisPage = remainingRows.clamp(1, subsequentPage.maxRows);
      }

      configs.add(PageConfig(
        maxRows: pageNumber == 0 ? firstPage.maxRows : subsequentPage.maxRows,
        rowsThisPage: rowsThisPage,
        description: pageNumber == 0
            ? firstPage.description
            : subsequentPage.description,
      ));

      remainingRows -= rowsThisPage;
      pageNumber++;
    }

    // 调试信息
    debugPrint('=== Table Pagination Debug ===');
    debugPrint('Total rows: $totalRows');
    debugPrint('Total pages: ${configs.length}');
    for (int i = 0; i < configs.length; i++) {
      debugPrint('Page ${i + 1}: ${configs[i].rowsThisPage} rows');
    }

    return configs;
  }

  /// Build individual table widget
  static pw.Widget _buildTable(
      List<String> headers, List<Map<String, dynamic>> pageData) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: _calculateColumnWidths(headers),
      children: [
        // Header row with gradient
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [PdfColors.blue700, PdfColors.blue800],
            ),
          ),
          children: headers.map((header) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                _formatHeader(header),
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 10,
                ),
                textAlign: pw.TextAlign.left,
              ),
            );
          }).toList(),
        ),
        // Data rows with alternating colors
        ...pageData.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: index.isEven ? PdfColors.white : PdfColors.blue50,
            ),
            children: headers.map((header) {
              final value = row[header]?.toString() ?? '';
              return pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  value,
                  textAlign: pw.TextAlign.left,
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey800,
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ],
    );
  }

  /// Calculate column widths dynamically
  static Map<int, pw.TableColumnWidth> _calculateColumnWidths(
      List<String> headers) {
    final columnWidths = <int, pw.TableColumnWidth>{};
    for (int i = 0; i < headers.length; i++) {
      if (headers[i].toLowerCase().contains('id')) {
        columnWidths[i] = const pw.FlexColumnWidth(1.5);
      } else if (headers[i].toLowerCase().contains('date') ||
          headers[i].toLowerCase().contains('time')) {
        columnWidths[i] = const pw.FlexColumnWidth(1.3);
      } else {
        columnWidths[i] = const pw.FlexColumnWidth(1);
      }
    }
    return columnWidths;
  }

  /// Format header text
  static String _formatHeader(String header) {
    return header.toUpperCase().replaceAll('_', ' ');
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

  /// Save PDF file for web
  static Future<void> _savePDFWeb(pw.Document pdf, String title) async {
    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', _generateFileName(title, 'pdf'))
      ..click();
    html.Url.revokeObjectUrl(url);

    TLoaders.successSnackBar(
      title: 'PDF Downloaded',
      message: 'Report has been downloaded successfully.',
    );
  }

  /// Save CSV file for web
  static Future<void> _saveCSVWeb(String content, String title) async {
    final bytes = Uint8List.fromList(content.codeUnits);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', _generateFileName(title, 'csv'))
      ..click();
    html.Url.revokeObjectUrl(url);

    TLoaders.successSnackBar(
      title: 'CSV Downloaded',
      message: 'Report has been downloaded successfully.',
    );
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
    final context = Get.context!;
    final isDark = THelperFunctions.isDarkMode(context);
    final selectedFormat = Rx<ExportType?>(null);

    Get.dialog(
      Dialog(
        backgroundColor: isDark ? TColors.dark : TColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: TColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.file_download_outlined,
                      color: TColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export Report',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? TColors.white : TColors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose your preferred format',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? TColors.darkGrey
                                : TColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Report info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isDark ? TColors.darkGrey : Colors.grey[100])!
                      .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? TColors.darkGrey : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exportData.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? TColors.white : TColors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Time Range',
                      exportData.timeRange,
                      isDark,
                    ),
                    if (exportData.data.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _buildInfoRow(
                        Icons.assessment_outlined,
                        'Records',
                        '${exportData.data.length} entries',
                        isDark,
                      ),
                    ],
                  ],
                ),
              ),

              // Warning for no data
              if (!exportData.hasData || exportData.data.isEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: TColors.warning),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: TColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No data available for export with current filters.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? TColors.white : TColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Export format options
              Text(
                'Select Format',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? TColors.lightGrey : TColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              Obx(() => Row(
                    children: [
                      // PDF option
                      Expanded(
                        child: _buildExportOption(
                          context: context,
                          icon: Icons.picture_as_pdf,
                          label: 'PDF',
                          description: 'Visual report',
                          color: Colors.red,
                          isDark: isDark,
                          enabled:
                              exportData.hasData && exportData.data.isNotEmpty,
                          isSelected: selectedFormat.value == ExportType.pdf,
                          onTap: () {
                            if (exportData.hasData &&
                                exportData.data.isNotEmpty) {
                              selectedFormat.value = ExportType.pdf;
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // CSV option
                      Expanded(
                        child: _buildExportOption(
                          context: context,
                          icon: Icons.table_chart,
                          label: 'CSV',
                          description: 'Raw data',
                          color: Colors.green,
                          isDark: isDark,
                          enabled:
                              exportData.hasData && exportData.data.isNotEmpty,
                          isSelected: selectedFormat.value == ExportType.csv,
                          onTap: () {
                            if (exportData.hasData &&
                                exportData.data.isNotEmpty) {
                              selectedFormat.value = ExportType.csv;
                            }
                          },
                        ),
                      ),
                    ],
                  )),

              const SizedBox(height: 20),

              // Action buttons
              Obx(() => Row(
                    children: [
                      // Cancel button
                      Expanded(
                        child: TextButton(
                          onPressed: () => Get.back(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: isDark
                                ? TColors.darkGrey.withOpacity(0.5)
                                : Colors.grey[200],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark ? TColors.white : TColors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Export button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: selectedFormat.value != null
                              ? () async {
                                  // 先关闭 dialog
                                  Get.back();

                                  // 添加一个小延迟确保 dialog 完全关闭
                                  await Future.delayed(
                                      const Duration(milliseconds: 300));

                                  await exportChart(
                                    exportData: exportData,
                                    exportType: selectedFormat.value!,
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: TColors.primary,
                            disabledBackgroundColor: isDark
                                ? TColors.darkGrey.withOpacity(0.3)
                                : Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Export',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: selectedFormat.value != null
                                  ? Colors.white
                                  : (isDark
                                      ? TColors.darkGrey
                                      : Colors.grey[500]),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )),
            ],
          ),
        ),
      ),
    );
  }

  /// Build info row for dialog
  static Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    bool isDark,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: TColors.primary,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? TColors.lightGrey : TColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? TColors.white : TColors.black,
            ),
          ),
        ),
      ],
    );
  }

  /// Build export option card
  static Widget _buildExportOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required bool isDark,
    required bool enabled,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: enabled
              ? (isSelected
                  ? color.withOpacity(0.1)
                  : (isDark ? TColors.darkGrey : Colors.grey[100]))
              : (isDark ? TColors.darkGrey.withOpacity(0.3) : Colors.grey[50]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled
                ? (isSelected ? color : color.withOpacity(0.3))
                : (isDark ? TColors.darkGrey : Colors.grey[300]!),
            width: isSelected ? 2.5 : 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: enabled
                    ? (isSelected
                        ? color.withOpacity(0.2)
                        : color.withOpacity(0.1))
                    : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: enabled ? color : Colors.grey,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: enabled
                    ? (isSelected
                        ? color
                        : (isDark ? TColors.white : TColors.black))
                    : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: enabled
                    ? (isDark ? TColors.darkGrey : TColors.textSecondary)
                    : Colors.grey,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Selected',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Page configuration
class PageConfig {
  final int maxRows;
  final int rowsThisPage;
  final String description;

  const PageConfig({
    required this.maxRows,
    required this.description,
    this.rowsThisPage = 0,
  });
}
