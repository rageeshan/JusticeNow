import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CaseReportPdfService {
  CaseReportPdfService._();

  /// Generates a professional multi-page PDF report and opens the system print/share sheet
  static Future<void> exportCasesPdf({
    required List<Map<String, dynamic>> cases,
    required String timeRangeLabel,
    required String provinceLabel,
    required String districtLabel,
    required String statusLabel,
    required String sortByLabel,
    String? adminName,
  }) async {
    final pdf = pw.Document();

    pw.Font fontRegular;
    pw.Font fontBold;
    try {
      fontRegular = await PdfGoogleFonts.interRegular();
      fontBold = await PdfGoogleFonts.interBold();
    } catch (_) {
      fontRegular = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    final nowStr = DateFormat('MMMM dd, yyyy • hh:mm a').format(DateTime.now());

    // Compute basic statistics
    final totalCases = cases.length;
    final casesWithAge = cases.where((c) => c['personAge'] != null).length;
    final avgAge = casesWithAge > 0
        ? (cases
                    .where((c) => c['personAge'] != null)
                    .map((c) => c['personAge'] as num)
                    .reduce((a, b) => a + b) /
                casesWithAge)
            .toStringAsFixed(1)
        : 'N/A';

    final provincesCovered = cases
        .map((c) => c['province'] as String? ?? '')
        .where((p) => p.isNotEmpty && p != 'Unspecified')
        .toSet()
        .length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 14),
            padding: const pw.EdgeInsets.only(bottom: 10),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.blueGrey800, width: 1.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'JUSTICENOW — HUMAN RIGHTS PLATFORM',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 13,
                        color: PdfColors.indigo900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Incident & Case Demographics Intelligence Report',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 16,
                        color: PdfColors.black,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Generated: $nowStr',
                      style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey700),
                    ),
                    if (adminName != null && adminName.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Officer/Admin: $adminName',
                        style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey700),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
        footer: (context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 12),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'CONFIDENTIAL • Official Legal Aid & Case Registry Record',
                  style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.grey800),
                ),
              ],
            ),
          );
        },
        build: (context) => [
          // Filter Parameters & Metrics Box
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            margin: const pw.EdgeInsets.only(bottom: 14),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text('Date Range: ', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                        pw.Text(timeRangeLabel, style: pw.TextStyle(font: fontRegular, fontSize: 9)),
                        pw.SizedBox(width: 16),
                        pw.Text('Province: ', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                        pw.Text(provinceLabel, style: pw.TextStyle(font: fontRegular, fontSize: 9)),
                        pw.SizedBox(width: 16),
                        pw.Text('District: ', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                        pw.Text(districtLabel, style: pw.TextStyle(font: fontRegular, fontSize: 9)),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      children: [
                        pw.Text('Status: ', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                        pw.Text(statusLabel, style: pw.TextStyle(font: fontRegular, fontSize: 9)),
                        pw.SizedBox(width: 16),
                        pw.Text('Sorted By: ', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                        pw.Text(sortByLabel, style: pw.TextStyle(font: fontRegular, fontSize: 9)),
                      ],
                    ),
                  ],
                ),
                pw.Row(
                  children: [
                    _buildStatPill('Total Cases', '$totalCases', fontRegular, fontBold),
                    pw.SizedBox(width: 8),
                    _buildStatPill('Avg Citizen Age', avgAge, fontRegular, fontBold),
                    pw.SizedBox(width: 8),
                    _buildStatPill('Provinces', '$provincesCovered', fontRegular, fontBold),
                  ],
                ),
              ],
            ),
          ),

          // Main Cases Data Table
          if (cases.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(32),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'No cases found matching the selected filter criteria.',
                style: pw.TextStyle(font: fontRegular, fontSize: 12, color: PdfColors.grey600),
              ),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FixedColumnWidth(80), // Ref / Case ID
                1: pw.FlexColumnWidth(2.2), // Case Title & Category
                2: pw.FlexColumnWidth(1.5), // Person / Citizen Age
                3: pw.FlexColumnWidth(2.3), // Location Details
                4: pw.FixedColumnWidth(85), // Incident Date
                5: pw.FixedColumnWidth(85), // Status
              },
              children: [
                // Table Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.indigo900),
                  children: [
                    _th('Case ID', fontBold),
                    _th('Case Title & Category', fontBold),
                    _th('Person / Citizen Age', fontBold),
                    _th('Location Details', fontBold),
                    _th('Incident Date', fontBold),
                    _th('Status', fontBold),
                  ],
                ),
                // Table Data Rows
                ...cases.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final c = entry.value;

                  final refNum = c['referenceNumber'] ?? 'N/A';
                  final title = c['title'] ?? 'Untitled';
                  final category = (c['category'] as String? ?? 'other').replaceAll('_', ' ').toUpperCase();
                  final personName = c['personName'] ?? 'Anonymous';
                  final personAge = c['personAge'] != null ? '${c['personAge']} yrs' : 'Age: N/A';
                  final fullLoc = c['fullLocation'] ?? 'Not specified';
                  final province = c['province'] ?? '';
                  final dateStr = _formatDate(c['incidentDate'] ?? c['createdAt']);
                  final status = (c['status'] as String? ?? 'submitted').replaceAll('_', ' ').toUpperCase();

                  final rowBg = idx % 2 == 0 ? PdfColors.white : PdfColors.grey100;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: rowBg),
                    children: [
                      // 0. Case ID
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: pw.Text(
                          refNum,
                          style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColors.indigo900),
                        ),
                      ),
                      // 1. Case Title & Category
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              title,
                              style: pw.TextStyle(font: fontBold, fontSize: 8.5),
                              maxLines: 2,
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              category,
                              style: pw.TextStyle(font: fontRegular, fontSize: 7, color: PdfColors.grey700),
                            ),
                          ],
                        ),
                      ),
                      // 2. Person / Age
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              personName,
                              style: pw.TextStyle(font: fontBold, fontSize: 8.5),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: const pw.BoxDecoration(
                                color: PdfColors.blueGrey100,
                                borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                              ),
                              child: pw.Text(
                                personAge,
                                style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.blueGrey900),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 3. Location Details
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              fullLoc,
                              style: pw.TextStyle(font: fontRegular, fontSize: 8),
                              maxLines: 2,
                            ),
                            if (province.isNotEmpty && province != 'Unspecified') ...[
                              pw.SizedBox(height: 1),
                              pw.Text(
                                'Province: $province',
                                style: pw.TextStyle(font: fontBold, fontSize: 7, color: PdfColors.grey600),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // 4. Incident Date
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: pw.Text(
                          dateStr,
                          style: pw.TextStyle(font: fontRegular, fontSize: 8),
                        ),
                      ),
                      // 5. Status
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: pw.Text(
                          status,
                          style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: _getPdfStatusColor(c['status'])),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
        ],
      ),
    );

    final filename =
        'JusticeNow_Case_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: filename,
    );
  }

  static pw.Widget _th(String text, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: fontBold,
          fontSize: 8.5,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _buildStatPill(String label, String value, pw.Font fontRegular, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        children: [
          pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.indigo900)),
          pw.Text(label, style: pw.TextStyle(font: fontRegular, fontSize: 6.5, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  static String _formatDate(dynamic dateVal) {
    if (dateVal == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateVal.toString());
      return DateFormat('MMM dd, yyyy').format(dt);
    } catch (_) {
      return dateVal.toString();
    }
  }

  static PdfColor _getPdfStatusColor(dynamic status) {
    switch (status) {
      case 'completed':
      case 'resolved':
        return PdfColors.green800;
      case 'rejected':
      case 'lawyer_declined':
        return PdfColors.red800;
      case 'awaiting_lawyer_selection':
      case 'waiting_for_lawyer_approval':
      case 'approved_scheduled':
        return PdfColors.amber800;
      case 'in_progress':
      case 'investigating':
        return PdfColors.orange800;
      default:
        return PdfColors.blueGrey800;
    }
  }
}
