import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/constants/app_constants.dart';
import '../repositories/auth_repository.dart';
import '../repositories/legal_aid_repository.dart';
import 'api_service.dart';

class LawyerCasePdfService {
  LawyerCasePdfService._();

  /// High-level method to fetch full case details, generate the report, and launch the PDF viewer/print dialog
  static Future<void> exportCaseById(String caseId, BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFD4AF37)),
              ),
              SizedBox(width: 18),
              Text(
                'Generating Case PDF Report...',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final caseData = await LegalAidRepository().getLawyerCase(caseId);
      Map<String, dynamic>? lawyerData;
      try {
        lawyerData = await AuthRepository().getMe();
      } catch (_) {}

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading
      }

      await exportCaseReport(
        caseData: caseData,
        lawyerData: lawyerData,
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Generates the PDF document and invokes the system print/share sheet
  static Future<void> exportCaseReport({
    required Map<String, dynamic> caseData,
    Map<String, dynamic>? lawyerData,
  }) async {
    final pdf = pw.Document();

    // Fonts setup
    pw.Font fontRegular;
    pw.Font fontBold;
    try {
      fontRegular = await PdfGoogleFonts.interRegular();
      fontBold = await PdfGoogleFonts.interBold();
    } catch (_) {
      fontRegular = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    // ── Extraction: Header ──
    final caseId = caseData['_id']?.toString() ?? 'N/A';
    final refNumber = caseData['referenceNumber']?.toString() ??
        (caseId.length > 8 ? 'JN-${caseId.substring(caseId.length - 8).toUpperCase()}' : caseId);
    final caseTitle = caseData['title']?.toString() ?? 'Untitled Case';
    final generatedDateStr = DateFormat('MMMM dd, yyyy • hh:mm a').format(DateTime.now());

    // ── Extraction: Section 1 – Lawyer Details ──
    final assignedLawyer = caseData['assignedLawyer'] is Map
        ? Map<String, dynamic>.from(caseData['assignedLawyer'])
        : (lawyerData ?? <String, dynamic>{});
    final lawyerProfile = assignedLawyer['profile'] is Map
        ? Map<String, dynamic>.from(assignedLawyer['profile'])
        : (lawyerData != null && lawyerData['profile'] is Map
            ? Map<String, dynamic>.from(lawyerData['profile'])
            : <String, dynamic>{});

    final lawyerName = lawyerProfile['fullName']?.toString() ??
        assignedLawyer['alias']?.toString() ??
        'Assigned Counsel';
    final courtNumber = lawyerProfile['courtNumber']?.toString() ??
        lawyerProfile['lawyerId']?.toString() ??
        'Not specified';
    final lawyerProvince = lawyerProfile['province']?.toString() ?? 'Not specified';
    final lawyerDistrict = lawyerProfile['district']?.toString() ?? 'Not specified';
    final lawyerLocation = '$lawyerProvince, $lawyerDistrict';
    final preferredLanguage = lawyerProfile['preferredLanguage']?.toString() ?? 'English';

    // ── Extraction: Section 2 – Citizen Details ──
    final reportedBy = caseData['reportedBy'] is Map
        ? Map<String, dynamic>.from(caseData['reportedBy'])
        : <String, dynamic>{};
    final citizenProfile = reportedBy['profile'] is Map
        ? Map<String, dynamic>.from(reportedBy['profile'])
        : <String, dynamic>{};

    final citizenName = citizenProfile['fullName']?.toString() ??
        reportedBy['alias']?.toString() ??
        'Citizen';
    final citizenNIC = citizenProfile['nic']?.toString() ?? 'Not specified';
    final citizenEmail = reportedBy['email']?.toString() ?? 'Not specified';
    final citizenMobile = citizenProfile['phone']?.toString() ?? 'Not specified';
    final citizenGender = citizenProfile['gender']?.toString() ?? 'Not specified';
    final citizenProvince = citizenProfile['province']?.toString() ?? 'Not specified';
    final citizenDistrict = citizenProfile['district']?.toString() ?? 'Not specified';
    final citizenLocation = '$citizenProvince, $citizenDistrict';

    // ── Extraction: Section 3 – Incident Report ──
    final rawCategory = caseData['category']?.toString() ?? '';
    final category = AppConstants.caseCategories[rawCategory] ??
        (rawCategory.isNotEmpty ? rawCategory : 'Human Rights');
    final description = caseData['description']?.toString() ?? 'No detailed description provided.';

    final locRaw = caseData['location'];
    final loc = locRaw is Map ? Map<String, dynamic>.from(locRaw) : <String, dynamic>{};
    final address = loc['address']?.toString();
    final city = loc['city']?.toString();
    final state = loc['state']?.toString();
    final locationParts = [address, city, state].where((s) => s != null && s.isNotEmpty).join(', ');
    final incidentLocation = locationParts.isNotEmpty ? locationParts : 'Not mentioned';

    final incidentDateRaw = caseData['incidentDate'];
    String incidentDateTimeStr = 'Not specified';
    if (incidentDateRaw != null) {
      try {
        final dt = DateTime.parse(incidentDateRaw.toString()).toLocal();
        incidentDateTimeStr = DateFormat('MMMM dd, yyyy • hh:mm a').format(dt);
      } catch (_) {
        incidentDateTimeStr = incidentDateRaw.toString();
      }
    }

    final createdAtRaw = caseData['createdAt'];
    String submittedDateStr = 'Not specified';
    if (createdAtRaw != null) {
      try {
        final dt = DateTime.parse(createdAtRaw.toString()).toLocal();
        submittedDateStr = DateFormat('MMMM dd, yyyy • hh:mm a').format(dt);
      } catch (_) {
        submittedDateStr = createdAtRaw.toString();
      }
    }

    // ── Extraction: Section 4 – Evidence Summary ──
    final evidenceRaw = caseData['evidence'];
    final List<Map<String, dynamic>> evidenceList = [];
    if (evidenceRaw is List) {
      for (final e in evidenceRaw) {
        if (e is Map) {
          evidenceList.add(Map<String, dynamic>.from(e));
        }
      }
    }

    // Optional: Fetch thumbnail for first image evidence
    Uint8List? firstThumbnailBytes;
    try {
      final firstImage = evidenceList.firstWhere(
        (e) => (e['fileType']?.toString().toLowerCase() == 'image' ||
                e['fileType']?.toString().toLowerCase().startsWith('image/') == true),
        orElse: () => {},
      );
      if (firstImage.isNotEmpty && firstImage['storagePath'] != null) {
        final path = firstImage['storagePath'].toString();
        final fullUrl = path.startsWith('http')
            ? path
            : '${AppConstants.baseUrl.replaceAll('/api', '')}$path';
        final res = await ApiService.instance.client
            .get<List<int>>(
              fullUrl,
              options: Options(responseType: ResponseType.bytes),
            )
            .timeout(const Duration(seconds: 3));
        if (res.data != null && res.data!.isNotEmpty) {
          firstThumbnailBytes = Uint8List.fromList(res.data!);
        }
      }
    } catch (_) {
      // Graceful fallback: skip thumbnail preview if network or parse fails
    }

    // ── Extraction: Section 5 – Case Timeline ──
    String assignedDateStr = submittedDateStr;
    final assignedAtRaw = caseData['assignedAt'] ?? caseData['assignedToPoliceAt'];
    if (assignedAtRaw != null) {
      try {
        final dt = DateTime.parse(assignedAtRaw.toString()).toLocal();
        assignedDateStr = DateFormat('MMMM dd, yyyy • hh:mm a').format(dt);
      } catch (_) {}
    }

    final scheduledDate = caseData['scheduledMeetingDate']?.toString();
    final scheduledTime = caseData['scheduledMeetingTime']?.toString();
    String approvedScheduledStr = 'Not yet scheduled';
    if (scheduledDate != null && scheduledDate.isNotEmpty) {
      approvedScheduledStr = scheduledDate;
      if (scheduledTime != null && scheduledTime.isNotEmpty) {
        approvedScheduledStr += ' at $scheduledTime';
      }
    }

    final completedAtRaw = caseData['completedAt'];
    String? completionDateStr;
    if (completedAtRaw != null) {
      try {
        final dt = DateTime.parse(completedAtRaw.toString()).toLocal();
        completionDateStr = DateFormat('MMMM dd, yyyy • hh:mm a').format(dt);
      } catch (_) {
        completionDateStr = completedAtRaw.toString();
      }
    } else if (caseData['status'] == 'completed') {
      completionDateStr = 'Completed';
    }

    final rawTimeline = caseData['timeline'];
    final List<Map<String, dynamic>> timelineEvents = [];
    if (rawTimeline is List) {
      for (final t in rawTimeline) {
        if (t is Map) timelineEvents.add(Map<String, dynamic>.from(t));
      }
    }

    // ── Extraction: Section 6 – Notes ──
    final citizenMessage = caseData['citizenMessageToLawyer']?.toString();
    final lawyerNotes = caseData['lawyerNotes']?.toString() ??
        caseData['internalNotes']?.toString() ??
        caseData['policeAcceptNotes']?.toString();

    // ── PDF Palette ──
    const primaryNavy = PdfColor.fromInt(0xFF0F1E36);
    const accentGold = PdfColor.fromInt(0xFFC59B27);
    const borderGray = PdfColor.fromInt(0xFFE2E8F0);
    const textDark = PdfColor.fromInt(0xFF1E293B);
    const textMuted = PdfColor.fromInt(0xFF64748B);

    // ── MultiPage Document ──
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
        header: (context) {
          // On later pages, show minimal running header
          if (context.pageNumber > 1) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 16),
              padding: const pw.EdgeInsets.only(bottom: 8),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: borderGray, width: 1),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'JUSTICENOW LEGAL AID • CASE REPORT',
                    style: pw.TextStyle(font: fontBold, fontSize: 8, color: accentGold, letterSpacing: 0.8),
                  ),
                  pw.Text(
                    'Case ID: $refNumber',
                    style: pw.TextStyle(font: fontRegular, fontSize: 8, color: textMuted),
                  ),
                ],
              ),
            );
          }
          return const pw.SizedBox();
        },
        footer: (context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 18),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: borderGray, width: 1),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated by JusticeNow • Official Legal Aid Record',
                  style: pw.TextStyle(font: fontRegular, fontSize: 8, color: textMuted),
                ),
                pw.Text(
                  'Case ID: $refNumber  |  Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(font: fontBold, fontSize: 8, color: textDark),
                ),
              ],
            ),
          );
        },
        build: (context) => [
          // ── Header Block ──
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: primaryNavy,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: const pw.BoxDecoration(
                              color: accentGold,
                              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                            ),
                            child: pw.Text(
                              'JUSTICENOW',
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 9,
                                color: primaryNavy,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            'LEGAL AID MANAGEMENT SYSTEM',
                            style: pw.TextStyle(
                              font: fontRegular,
                              fontSize: 8,
                              color: PdfColors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Case Report – $caseTitle',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 16,
                          color: PdfColors.white,
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white.shade(0.12),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        border: pw.Border.all(color: accentGold, width: 0.8),
                      ),
                      child: pw.Text(
                        'ID: $refNumber',
                        style: pw.TextStyle(font: fontBold, fontSize: 10, color: accentGold),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Generated:',
                      style: pw.TextStyle(font: fontRegular, fontSize: 7, color: PdfColors.grey400),
                    ),
                    pw.Text(
                      generatedDateStr,
                      style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey200),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // ── Section 1 & Section 2: Two Columns ──
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Section 1: Lawyer Details
              pw.Expanded(
                child: _buildCardContainer(
                  title: 'Section 1 – Lawyer Details',
                  accentColor: accentGold,
                  fontBold: fontBold,
                  fontRegular: fontRegular,
                  children: [
                    _buildInfoRow('Lawyer Name', lawyerName, fontBold, fontRegular),
                    _buildInfoRow('Court Number', courtNumber, fontBold, fontRegular),
                    _buildInfoRow('Province + District', lawyerLocation, fontBold, fontRegular),
                    _buildInfoRow('Preferred Language', preferredLanguage, fontBold, fontRegular, isLast: true),
                  ],
                ),
              ),
              pw.SizedBox(width: 14),

              // Section 2: Citizen Details
              pw.Expanded(
                child: _buildCardContainer(
                  title: 'Section 2 – Citizen Details',
                  accentColor: primaryNavy,
                  fontBold: fontBold,
                  fontRegular: fontRegular,
                  children: [
                    _buildInfoRow('Name', citizenName, fontBold, fontRegular),
                    _buildInfoRow('NIC', citizenNIC, fontBold, fontRegular),
                    _buildInfoRow('Email', citizenEmail, fontBold, fontRegular),
                    _buildInfoRow('Mobile', citizenMobile, fontBold, fontRegular),
                    _buildInfoRow('Gender', citizenGender, fontBold, fontRegular),
                    _buildInfoRow('Province + District', citizenLocation, fontBold, fontRegular, isLast: true),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          // ── Section 3: Incident Report ──
          _buildCardContainer(
            title: 'Section 3 – Incident Report',
            accentColor: primaryNavy,
            fontBold: fontBold,
            fontRegular: fontRegular,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: _buildInfoRow('Report Title', caseTitle, fontBold, fontRegular),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    flex: 1,
                    child: _buildInfoRow('Category', category, fontBold, fontRegular),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Description (full):',
                style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: textMuted),
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: borderGray, width: 0.8),
                ),
                child: pw.Text(
                  description,
                  style: pw.TextStyle(font: fontRegular, fontSize: 9.5, color: textDark, lineSpacing: 2),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _buildInfoRow('Location of Incident', incidentLocation, fontBold, fontRegular),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: _buildInfoRow('Date & Time of Incident', incidentDateTimeStr, fontBold, fontRegular),
                  ),
                ],
              ),
              _buildInfoRow('Date Submitted', submittedDateStr, fontBold, fontRegular, isLast: true),
            ],
          ),
          pw.SizedBox(height: 14),

          // ── Section 4: Evidence Summary ──
          _buildCardContainer(
            title: 'Section 4 – Evidence Summary',
            accentColor: accentGold,
            fontBold: fontBold,
            fontRegular: fontRegular,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Optional Thumbnail Preview Box
                  if (firstThumbnailBytes != null) ...[
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 72,
                          height: 72,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: borderGray, width: 1),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                          ),
                          child: pw.ClipRRect(
                            horizontalRadius: 6,
                            verticalRadius: 6,
                            child: pw.Image(
                              pw.MemoryImage(firstThumbnailBytes),
                              fit: pw.BoxFit.cover,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Preview Thumbnail',
                          style: pw.TextStyle(font: fontRegular, fontSize: 6.5, color: textMuted),
                        ),
                      ],
                    ),
                    pw.SizedBox(width: 12),
                  ],

                  // Evidence Files Table
                  pw.Expanded(
                    child: evidenceList.isEmpty
                        ? pw.Container(
                            padding: const pw.EdgeInsets.symmetric(vertical: 8),
                            child: pw.Text(
                              'No evidence files attached to this case.',
                              style: pw.TextStyle(font: fontRegular, fontSize: 9, color: textMuted),
                            ),
                          )
                        : pw.Table(
                            border: pw.TableBorder.all(color: borderGray, width: 0.5),
                            columnWidths: const {
                              0: pw.FlexColumnWidth(3),
                              1: pw.FlexColumnWidth(1.2),
                              2: pw.FlexColumnWidth(2),
                            },
                            children: [
                              // Table Header
                              pw.TableRow(
                                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                                children: [
                                  _buildTableCell('File Name', fontBold, isHeader: true),
                                  _buildTableCell('Type', fontBold, isHeader: true),
                                  _buildTableCell('Uploaded Date', fontBold, isHeader: true),
                                ],
                              ),
                              // Table Rows
                              ...evidenceList.map((item) {
                                final fileName = item['originalName']?.toString() ?? 'Evidence File';
                                final fileType = item['fileType']?.toString().toUpperCase() ?? 'FILE';
                                final uploadedRaw = item['createdAt'] ?? item['uploadedAt'];
                                String uploadDateStr = 'Attached';
                                if (uploadedRaw != null) {
                                  try {
                                    final dt = DateTime.parse(uploadedRaw.toString()).toLocal();
                                    uploadDateStr = DateFormat('MMM dd, yyyy').format(dt);
                                  } catch (_) {}
                                }
                                return pw.TableRow(
                                  children: [
                                    _buildTableCell(fileName, fontRegular),
                                    _buildTableCell(fileType, fontRegular),
                                    _buildTableCell(uploadDateStr, fontRegular),
                                  ],
                                );
                              }),
                            ],
                          ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Note: Media files are archived securely in the cloud repository and summarized above.',
                style: pw.TextStyle(font: fontRegular, fontSize: 7, color: textMuted, fontStyle: pw.FontStyle.italic),
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          // ── Section 5: Case Timeline ──
          _buildCardContainer(
            title: 'Section 5 – Case Timeline',
            accentColor: primaryNavy,
            fontBold: fontBold,
            fontRegular: fontRegular,
            children: [
              _buildTimelineRow('Assigned Date', assignedDateStr, fontBold, fontRegular),
              _buildTimelineRow(
                'Approved Date + Scheduled Consultation',
                approvedScheduledStr,
                fontBold,
                fontRegular,
              ),
              if (timelineEvents.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text('Status Updates & Progress Log:', style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: textMuted)),
                pw.SizedBox(height: 4),
                ...timelineEvents.map((t) {
                  final statusName = (t['status']?.toString() ?? 'Update').replaceAll('_', ' ').toUpperCase();
                  final note = t['note']?.toString();
                  final tDateRaw = t['createdAt'];
                  String tDateStr = '';
                  if (tDateRaw != null) {
                    try {
                      final dt = DateTime.parse(tDateRaw.toString()).toLocal();
                      tDateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(dt);
                    } catch (_) {}
                  }
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 6,
                          height: 6,
                          margin: const pw.EdgeInsets.only(top: 3, right: 6),
                          decoration: const pw.BoxDecoration(
                            color: accentGold,
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.RichText(
                            text: pw.TextSpan(
                              children: [
                                pw.TextSpan(
                                  text: '$statusName ',
                                  style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: textDark),
                                ),
                                if (tDateStr.isNotEmpty)
                                  pw.TextSpan(
                                    text: '($tDateStr) ',
                                    style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: textMuted),
                                  ),
                                if (note != null && note.isNotEmpty)
                                  pw.TextSpan(
                                    text: '— $note',
                                    style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: textDark),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              if (completionDateStr != null) ...[
                pw.SizedBox(height: 4),
                _buildTimelineRow('Completion Date', completionDateStr, fontBold, fontRegular, isLast: true),
              ],
            ],
          ),
          pw.SizedBox(height: 14),

          // ── Section 6: Notes ──
          _buildCardContainer(
            title: 'Section 6 – Notes',
            accentColor: accentGold,
            fontBold: fontBold,
            fontRegular: fontRegular,
            children: [
              pw.Text(
                'Citizen\'s Message to Lawyer:',
                style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: textMuted),
              ),
              pw.SizedBox(height: 3),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: borderGray, width: 0.8),
                ),
                child: pw.Text(
                  (citizenMessage != null && citizenMessage.isNotEmpty)
                      ? citizenMessage
                      : 'No message provided by citizen.',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 8.5,
                    color: (citizenMessage != null && citizenMessage.isNotEmpty) ? textDark : textMuted,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Lawyer\'s Own Notes:',
                style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: textMuted),
              ),
              pw.SizedBox(height: 3),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: borderGray, width: 0.8),
                ),
                child: pw.Text(
                  (lawyerNotes != null && lawyerNotes.isNotEmpty)
                      ? lawyerNotes
                      : 'No additional lawyer notes recorded.',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 8.5,
                    color: (lawyerNotes != null && lawyerNotes.isNotEmpty) ? textDark : textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // Launch system print / preview sheet
    final safeName = refNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Case_Report_$safeName.pdf',
    );
  }

  // ── Helper UI Components for PDF ──

  static pw.Widget _buildCardContainer({
    required String title,
    required PdfColor accentColor,
    required pw.Font fontBold,
    required pw.Font fontRegular,
    required List<pw.Widget> children,
  }) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF8FAFC),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header Bar
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF1F5F9),
              borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(7)),
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0), width: 1),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 3.5,
                  height: 12,
                  decoration: pw.BoxDecoration(
                    color: accentColor,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Text(
                  title.toUpperCase(),
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 9,
                    color: const PdfColor.fromInt(0xFF1E293B),
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          // Content
          pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(
    String label,
    String value,
    pw.Font fontBold,
    pw.Font fontRegular, {
    bool isLast = false,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: isLast ? 0 : 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 110,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                font: fontRegular,
                fontSize: 8.5,
                color: const PdfColor.fromInt(0xFF64748B),
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 8.5,
                color: const PdfColor.fromInt(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTimelineRow(
    String label,
    String value,
    pw.Font fontBold,
    pw.Font fontRegular, {
    bool isLast = false,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: isLast ? 0 : 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 180,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: const PdfColor.fromInt(0xFF334155)),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: const PdfColor.fromInt(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text,
    pw.Font font, {
    bool isHeader = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 8 : 7.5,
          color: isHeader ? const PdfColor.fromInt(0xFF1E293B) : const PdfColor.fromInt(0xFF334155),
        ),
      ),
    );
  }
}
