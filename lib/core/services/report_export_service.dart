import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/joyn_colors.dart';
import '../theme/joyn_typography.dart';

class ReportExportService {
  ReportExportService._();

  /// Builds a publication-grade PDF document
  static Future<pw.Document> generateReportPdf({
    required String title,
    required String periodLabel,
    String? businessName,
    Map<String, String>? summaryStats,
    required List<String> tableHeaders,
    required List<List<String>> tableRows,
    Map<int, pw.Alignment>? cellAlignments,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        businessName ?? 'JOYN Merchant',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        title,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey200,
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Text(
                          periodLabel,
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey800,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Generated: ${_formatDate(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 10),

              // Summary Stats Strip (if provided)
              if (summaryStats != null && summaryStats.isNotEmpty) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: summaryStats.entries.map((entry) {
                      return pw.Column(
                        children: [
                          pw.Text(
                            entry.key,
                            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            entry.value,
                            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                pw.SizedBox(height: 14),
              ],
            ],
          );
        },
        footer: (context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Powered by JOYN ERP & Billing',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
              ),
            ],
          );
        },
        build: (context) {
          return [
            pw.TableHelper.fromTextArray(
              context: context,
              headers: tableHeaders,
              data: tableRows,
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF1E293B),
              ),
              headerHeight: 24,
              cellHeight: 22,
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: cellAlignments ?? {
                tableHeaders.length - 1: pw.Alignment.centerRight,
                tableHeaders.length - 2: pw.Alignment.centerRight,
              },
              oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF8FAFC)),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
              ),
            ),
          ];
        },
      ),
    );

    return doc;
  }

  /// Print or Preview PDF (calls system printer & previewer)
  static Future<void> printPdf({
    required BuildContext context,
    required String title,
    required String periodLabel,
    String? businessName,
    Map<String, String>? summaryStats,
    required List<String> tableHeaders,
    required List<List<String>> tableRows,
    Map<int, pw.Alignment>? cellAlignments,
  }) async {
    try {
      final doc = await generateReportPdf(
        title: title,
        periodLabel: periodLabel,
        businessName: businessName,
        summaryStats: summaryStats,
        tableHeaders: tableHeaders,
        tableRows: tableRows,
        cellAlignments: cellAlignments,
      );

      final fileName = '${_sanitize(title)}_${_sanitize(periodLabel)}.pdf';
      await Printing.layoutPdf(
        onLayout: (_) => doc.save(),
        name: fileName,
      );
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Failed to print: $e');
      }
    }
  }

  /// Share PDF directly to WhatsApp, Drive, Email, etc.
  static Future<void> sharePdf({
    required BuildContext context,
    required String title,
    required String periodLabel,
    String? businessName,
    Map<String, String>? summaryStats,
    required List<String> tableHeaders,
    required List<List<String>> tableRows,
    Map<int, pw.Alignment>? cellAlignments,
  }) async {
    try {
      final doc = await generateReportPdf(
        title: title,
        periodLabel: periodLabel,
        businessName: businessName,
        summaryStats: summaryStats,
        tableHeaders: tableHeaders,
        tableRows: tableRows,
        cellAlignments: cellAlignments,
      );

      final bytes = await doc.save();
      final fileName = '${_sanitize(title)}_${_sanitize(periodLabel)}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Failed to share PDF: $e');
      }
    }
  }

  /// Export & Share Excel (CSV with UTF-8 BOM for Microsoft Excel / Sheets)
  static Future<void> exportAndShareExcel({
    required BuildContext context,
    required String title,
    required String periodLabel,
    String? businessName,
    Map<String, String>? summaryStats,
    required List<String> tableHeaders,
    required List<List<String>> tableRows,
  }) async {
    try {
      final buffer = StringBuffer();

      // Excel UTF-8 BOM so characters and ₹ render properly
      buffer.write('\uFEFF');

      // Title & Business Header
      buffer.writeln('"${businessName ?? "JOYN Merchant"}"');
      buffer.writeln('"$title - $periodLabel"');
      buffer.writeln('"Generated On: ${_formatDate(DateTime.now())}"');
      buffer.writeln();

      // Summary Stats (if any)
      if (summaryStats != null && summaryStats.isNotEmpty) {
        buffer.writeln('"--- SUMMARY ---"');
        for (final entry in summaryStats.entries) {
          buffer.writeln('"${entry.key}","${entry.value}"');
        }
        buffer.writeln();
      }

      // Headers
      buffer.writeln(tableHeaders.map((h) => '"${h.replaceAll('"', '""')}"').join(','));

      // Rows
      for (final row in tableRows) {
        buffer.writeln(row.map((cell) => '"${cell.replaceAll('"', '""')}"').join(','));
      }

      final dir = await getTemporaryDirectory();
      final fileName = '${_sanitize(title)}_${_sanitize(periodLabel)}.csv';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(buffer.toString(), encoding: utf8);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: '$title ($periodLabel) Export',
        text: 'Attached $title for $periodLabel',
      );
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Failed to export Excel: $e');
      }
    }
  }

  /// Interactive Bottom Sheet for PDF Export Options
  static Future<void> showPdfOptionsSheet({
    required BuildContext context,
    required String title,
    required String periodLabel,
    String? businessName,
    Map<String, String>? summaryStats,
    required List<String> tableHeaders,
    required List<List<String>> tableRows,
    Map<int, pw.Alignment>? cellAlignments,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: const BoxDecoration(
            color: JoynColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: JoynColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'PDF Export Options',
                    style: JoynTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: JoynColors.primaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildActionTile(
                icon: Icons.print_rounded,
                iconColor: JoynColors.primary,
                title: 'Print / Open PDF Preview',
                subtitle: 'View full layout, zoom, and send to any printer',
                onTap: () {
                  Navigator.pop(sheetContext);
                  printPdf(
                    context: context,
                    title: title,
                    periodLabel: periodLabel,
                    businessName: businessName,
                    summaryStats: summaryStats,
                    tableHeaders: tableHeaders,
                    tableRows: tableRows,
                    cellAlignments: cellAlignments,
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildActionTile(
                icon: Icons.share_rounded,
                iconColor: const Color(0xFF2563EB),
                title: 'Share PDF File',
                subtitle: 'Share via WhatsApp, Email, Drive or save to Files',
                onTap: () {
                  Navigator.pop(sheetContext);
                  sharePdf(
                    context: context,
                    title: title,
                    periodLabel: periodLabel,
                    businessName: businessName,
                    summaryStats: summaryStats,
                    tableHeaders: tableHeaders,
                    tableRows: tableRows,
                    cellAlignments: cellAlignments,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Interactive Bottom Sheet for Excel / Spreadsheet Export Options
  static Future<void> showExcelOptionsSheet({
    required BuildContext context,
    required String title,
    required String periodLabel,
    String? businessName,
    Map<String, String>? summaryStats,
    required List<String> tableHeaders,
    required List<List<String>> tableRows,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: const BoxDecoration(
            color: JoynColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: JoynColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: JoynColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.grid_on_rounded, color: JoynColors.success, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Excel / Spreadsheet Options',
                    style: JoynTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: JoynColors.primaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildActionTile(
                icon: Icons.file_upload_outlined,
                iconColor: JoynColors.success,
                title: 'Export & Share Excel (CSV)',
                subtitle: 'Open in MS Excel, Google Sheets, or share on WhatsApp',
                onTap: () {
                  Navigator.pop(sheetContext);
                  exportAndShareExcel(
                    context: context,
                    title: title,
                    periodLabel: periodLabel,
                    businessName: businessName,
                    summaryStats: summaryStats,
                    tableHeaders: tableHeaders,
                    tableRows: tableRows,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: JoynColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: JoynColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: JoynTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: JoynColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: JoynTypography.caption.copyWith(
                      color: JoynColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: JoynColors.secondaryText),
          ],
        ),
      ),
    );
  }

  static void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: JoynColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  static String _sanitize(String text) {
    return text.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
  }
}

