import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/case_repository.dart';
import 'admin_officer_selection_screen.dart';

class AdminCaseDetailScreen extends StatefulWidget {
  final String caseId;
  final Map<String, dynamic>? initialCase;

  const AdminCaseDetailScreen({
    super.key,
    required this.caseId,
    this.initialCase,
  });

  @override
  State<AdminCaseDetailScreen> createState() => _AdminCaseDetailScreenState();
}

class _AdminCaseDetailScreenState extends State<AdminCaseDetailScreen> {
  final CaseRepository _caseRepo = CaseRepository();
  Map<String, dynamic>? _case;
  bool _isLoading = false;
  bool _isProcessingAction = false;
  String? _errorMessage;

  // Gemini AI Translation State
  String _selectedLang = 'original'; // 'original', 'en', 'si', 'ta'
  bool _isTranslating = false;
  final Map<String, Map<String, String>> _translationCache = {};

  Future<void> _translateContent(String targetLang, String originalTitle, String originalDescription) async {
    if (targetLang == 'original') {
      setState(() => _selectedLang = 'original');
      return;
    }

    if (_translationCache.containsKey(targetLang)) {
      setState(() => _selectedLang = targetLang);
      return;
    }

    setState(() => _isTranslating = true);

    try {
      final res = await _caseRepo.translateReport(
        title: originalTitle,
        text: originalDescription,
        targetLang: targetLang,
      );

      final transTitle = (res['translatedTitle'] as String?)?.trim();
      final transText = (res['translatedText'] as String?)?.trim();

      if (mounted) {
        setState(() {
          _translationCache[targetLang] = {
            'title': (transTitle != null && transTitle.isNotEmpty) ? transTitle : originalTitle,
            'description': (transText != null && transText.isNotEmpty) ? transText : originalDescription,
          };
          _selectedLang = targetLang;
          _isTranslating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTranslating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Translation error: $e'),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _case = widget.initialCase;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadCaseDetails();
    });
  }

  Future<void> _loadCaseDetails() async {
    setState(() {
      _isLoading = _case == null;
      _errorMessage = null;
    });

    try {
      final caseData = await _caseRepo.getCaseById(widget.caseId);
      if (mounted) {
        setState(() {
          _case = caseData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('MMM dd, yyyy • hh:mm a').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatCategory(String? cat) {
    if (cat == null) return 'Not specified';
    return cat.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return '';
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'assigned_to_police':
        return AppColors.info;
      case 'in_progress_police':
        return AppColors.warning;
      case 'pending_reassignment':
      case 'police_declined':
        return AppColors.error;
      case 'awaiting_lawyer_selection':
        return AppColors.accent;
      case 'rejected':
        return AppColors.error;
      case 'resolved':
      case 'closed':
      case 'completed':
        return AppColors.success;
      case 'investigating':
      case 'under_review':
        return AppColors.warning;
      case 'submitted':
      default:
        return AppColors.info;
    }
  }

  String _statusLabel(String? status) {
    if (status == null) return 'Submitted';
    if (status == 'assigned_to_police') return 'Assigned to Police Officer';
    if (status == 'in_progress_police') return 'In Progress – Police';
    if (status == 'pending_reassignment') return 'Pending Reassignment';
    if (status == 'police_declined') return 'Police Declined';
    if (status == 'awaiting_lawyer_selection') return 'Awaiting Lawyer Selection';
    return status.replaceAll('_', ' ').toUpperCase();
  }

  // ── Action 1: Assign to Lawyer ──
  Future<void> _assignToLawyer() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.gavel_rounded, color: AppColors.accent, size: 24),
            SizedBox(width: 10),
            Text('Assign to Lawyer', style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
          ],
        ),
        content: const Text(
          'This will approve the case report and notify the citizen to select and book a lawyer in their area. Proceed?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.primaryDark,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Approve & Notify Citizen', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessingAction = true);
    try {
      await _caseRepo.updateCaseStatus(
        widget.caseId,
        'awaiting_lawyer_selection',
        note: 'Approved by admin for lawyer selection',
      );
      if (mounted) {
        setState(() => _isProcessingAction = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Case assigned to lawyer workflow. Notification sent to citizen!'),
          ),
        );
        context.go(AppRoutes.adminDashboard);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingAction = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error: $e')),
        );
      }
    }
  }

  // ── Action 2: Assign to Police Officer (Full Flow) ──
  Future<void> _assignToPoliceOfficer() async {
    if (_case == null) return;
    final assigned = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminOfficerSelectionScreen(
          caseId: widget.caseId,
          caseData: _case!,
        ),
      ),
    );

    if (assigned == true && mounted) {
      _loadCaseDetails();
    }
  }

  // ── Action 3: Reject Case ──
  Future<void> _rejectCase() async {
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.error, size: 24),
            SizedBox(width: 10),
            Text('Reject Case Report', style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please provide a detailed reason for rejection. This reason will be sent to the citizen.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: reasonCtrl,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Enter reason for rejection (required)...',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Rejection reason is required';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Confirm Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final reason = reasonCtrl.text.trim();

    setState(() => _isProcessingAction = true);
    try {
      await _caseRepo.updateCaseStatus(
        widget.caseId,
        'rejected',
        reason: reason,
        note: reason,
      );
      if (mounted) {
        setState(() => _isProcessingAction = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.warning,
            content: Text('Case marked as Rejected. Notification sent to citizen.'),
          ),
        );
        context.go(AppRoutes.adminDashboard);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingAction = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error: $e')),
        );
      }
    }
  }

  // ── Preview Fullscreen Evidence Item ──
  void _previewEvidence(dynamic ev) {
    final item = ev as Map<String, dynamic>;
    final fileType = item['fileType'] as String? ?? 'image';
    final originalName = item['originalName'] as String? ?? 'Evidence File';
    final storagePath = item['storagePath'] as String? ?? '';
    final fullUrl = storagePath.startsWith('http')
        ? storagePath
        : '${AppConstants.baseUrl.replaceAll('/api', '')}$storagePath';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        originalName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),

              // Preview Content
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: fileType == 'image'
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: InteractiveViewer(
                            panEnabled: true,
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Image.network(
                              fullUrl,
                              fit: BoxFit.contain,
                              loadingBuilder: (_, child, progress) =>
                                  progress == null ? child : const Center(child: CircularProgressIndicator()),
                              errorBuilder: (_, __, ___) => const Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Column(
                                  children: [
                                    Icon(Icons.broken_image_rounded, color: AppColors.error, size: 48),
                                    SizedBox(height: 8),
                                    Text('Unable to load photo', style: TextStyle(color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      : fileType == 'video'
                          ? Container(
                              height: 220,
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.play_circle_filled_rounded, color: AppColors.accent, size: 64),
                                    const SizedBox(height: 12),
                                    Text(
                                      originalName,
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Video Evidence Attachment',
                                      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 56),
                                  const SizedBox(height: 12),
                                  Text(
                                    originalName,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Document / PDF Evidence (${item['mimeType'] ?? 'Document'})',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                ),
              ),

              // Bottom footer
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: const Text('Close Preview'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Case Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && _case == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Case Details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                const SizedBox(height: 12),
                Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _loadCaseDetails, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final c = _case ?? {};
    final String title = c['title'] ?? 'Incident Report';
    final String description = c['description'] ?? 'No description provided';
    final String displayedTitle = (_selectedLang != 'original' && _translationCache.containsKey(_selectedLang))
        ? (_translationCache[_selectedLang]!['title'] ?? title)
        : title;
    final String displayedDescription = (_selectedLang != 'original' && _translationCache.containsKey(_selectedLang))
        ? (_translationCache[_selectedLang]!['description'] ?? description)
        : description;
    final category = c['category'] as String?;
    final status = c['status'] as String?;
    final refNumber = c['referenceNumber'] ?? '';
    final createdAt = c['createdAt'] as String?;

    // Location
    final dynamic locRaw = c['location'];
    final Map<String, dynamic> loc = locRaw is Map
        ? Map<String, dynamic>.from(locRaw)
        : {};
    final address = loc['address'] as String?;
    final city = loc['city'] as String?;
    final state = loc['state'] as String?;
    final locationParts = [address, city, state].where((s) => s != null && s.isNotEmpty).join(', ');
    final locationText = locationParts.isNotEmpty ? locationParts : 'Not mentioned';

    // Citizen Details (reportedBy)
    final dynamic reportedByRaw = c['reportedBy'];
    final Map<String, dynamic> reportedBy = reportedByRaw is Map
        ? Map<String, dynamic>.from(reportedByRaw)
        : {};
    final dynamic profileRaw = reportedBy['profile'];
    final Map<String, dynamic> profile = profileRaw is Map
        ? Map<String, dynamic>.from(profileRaw)
        : {};
    final citizenName = profile['fullName'] ?? reportedBy['alias'] ?? 'Anonymous Citizen';
    final citizenNIC = profile['nic'] ?? 'Not provided';
    final citizenEmail = reportedBy['email'] ?? 'Not provided';
    final citizenPhone = profile['phone'] ?? 'Not provided';
    final citizenGender = profile['gender'] ?? 'Not provided';
    final citizenProvince = profile['province'] ?? 'Not provided';
    final citizenDistrict = profile['district'] ?? 'Not provided';

    // Evidence
    final dynamic evidenceRaw = c['evidence'];
    final List<dynamic> evidenceList = evidenceRaw is List ? evidenceRaw : [];
    final photos = evidenceList.where((e) => e is Map && (e['fileType'] == 'image')).toList();
    final videos = evidenceList.where((e) => e is Map && (e['fileType'] == 'video')).toList();
    final docs = evidenceList.where((e) => e is Map && (e['fileType'] != 'image' && e['fileType'] != 'video')).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(refNumber.isNotEmpty ? refNumber : 'Case Details'),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadCaseDetails,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _statusColor(status).withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: _statusColor(status), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'STATUS: ${_statusLabel(status)}',
                                style: TextStyle(
                                  color: _statusColor(status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _formatDateTime(createdAt),
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ════════════════════════════════════════
                    // SECTION 1 – Citizen Details
                    // ════════════════════════════════════════
                    _buildSectionHeader('SECTION 1 – CITIZEN DETAILS', Icons.person_rounded),
                    const SizedBox(height: 12),
                    _buildCard([
                      _buildRowItem('Full Name', citizenName),
                      _buildRowItem('NIC Number', citizenNIC),
                      _buildRowItem('Email Address', citizenEmail),
                      _buildRowItem('Mobile Number', citizenPhone),
                      _buildRowItem('Gender', citizenGender),
                      _buildRowItem('Province', citizenProvince),
                      _buildRowItem('District', citizenDistrict, isLast: true),
                    ]),
                    const SizedBox(height: 28),

                    // ════════════════════════════════════════
                    // SECTION 2 – Report Details
                    // ════════════════════════════════════════
                    _buildSectionHeader('SECTION 2 – REPORT DETAILS', Icons.description_rounded),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTranslationBar(title, description),
                          // Title
                          const Text('Report Title', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            displayedTitle,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: 16),

                          // Description
                          const Text('Report Description (Full Text)', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          const SizedBox(height: 6),
                          Text(
                            displayedDescription,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: 16),

                          // Meta fields
                          _buildRowItem('Date & Time Submitted', _formatDateTime(createdAt)),
                          _buildRowItem('Location', locationText),
                          _buildRowItem('Category', _formatCategory(category), isLast: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ════════════════════════════════════════
                    // SECTION 3 – Evidence
                    // ════════════════════════════════════════
                    _buildSectionHeader('SECTION 3 – EVIDENCE', Icons.folder_zip_rounded),
                    const SizedBox(height: 12),
                    if (evidenceList.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: Column(
                            children: [
                              Icon(Icons.attachment_rounded, color: AppColors.textMuted, size: 36),
                              SizedBox(height: 8),
                              Text('No evidence files attached to this report', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      // Uploaded Photos Grid
                      if (photos.isNotEmpty) ...[
                        const Text('Uploaded Photos', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: photos.length,
                          itemBuilder: (context, idx) {
                            final p = photos[idx] as Map<String, dynamic>;
                            final pPath = p['storagePath'] as String? ?? '';
                            final pUrl = pPath.startsWith('http')
                                ? pPath
                                : '${AppConstants.baseUrl.replaceAll('/api', '')}$pPath';

                            return GestureDetector(
                              onTap: () => _previewEvidence(p),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      pUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (_, child, prog) => prog == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                      errorBuilder: (_, __, ___) => Container(
                                        color: AppColors.surfaceVariant,
                                        child: const Icon(Icons.broken_image_rounded, color: AppColors.textMuted),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                                        child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Uploaded Videos
                      if (videos.isNotEmpty) ...[
                        const Text('Uploaded Videos', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...videos.map((v) {
                          final vMap = v as Map<String, dynamic>;
                          return GestureDetector(
                            onTap: () => _previewEvidence(vMap),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.play_circle_fill_rounded, color: AppColors.warning, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          vMap['originalName'] ?? 'Video Attachment',
                                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        const Text('Tap to view video preview', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                      ],

                      // Uploaded PDFs / Documents
                      if (docs.isNotEmpty) ...[
                        const Text('Uploaded Documents / PDFs', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...docs.map((d) {
                          final dMap = d as Map<String, dynamic>;
                          return GestureDetector(
                            onTap: () => _previewEvidence(dMap),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dMap['originalName'] ?? 'Document File',
                                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          dMap['mimeType'] ?? 'Document',
                                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _previewEvidence(dMap),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryDark,
                                      foregroundColor: AppColors.accent,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: const BorderSide(color: AppColors.accent),
                                      ),
                                    ),
                                    child: const Text('Open', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ════════════════════════════════════════
            // SECTION 4 – Action Buttons (Bottom)
            // ════════════════════════════════════════
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: const Border(top: BorderSide(color: AppColors.border)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Assign to Lawyer Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isProcessingAction ? null : _assignToLawyer,
                            icon: const Icon(Icons.gavel_rounded, size: 16),
                            label: const Text('Assign to Lawyer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.primaryDark,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Reject Button
                        ElevatedButton.icon(
                          onPressed: _isProcessingAction ? null : _rejectCase,
                          icon: const Icon(Icons.cancel_outlined, size: 16),
                          label: const Text('Reject', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Assign to Police Officer
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessingAction ? null : _assignToPoliceOfficer,
                        icon: const Icon(Icons.local_police_rounded, size: 18),
                        label: const Text(
                          'Assign to Police Officer',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: AppColors.accent,
                          side: const BorderSide(color: AppColors.accent, width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildRowItem(String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(
                label,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildTranslationBar(String originalTitle, String originalDescription) {
    final options = [
      {'code': 'original', 'label': 'Original', 'icon': Icons.restore_rounded},
      {'code': 'en', 'label': 'English', 'icon': Icons.language_rounded},
      {'code': 'si', 'label': 'සිංහල', 'icon': Icons.translate_rounded},
      {'code': 'ta', 'label': 'தமிழ்', 'icon': Icons.translate_rounded},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.accent, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Translate with Gemini AI',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              if (_isTranslating)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: options.map((opt) {
              final isSelected = _selectedLang == opt['code'];
              return ChoiceChip(
                avatar: Icon(
                  opt['icon'] as IconData,
                  size: 14,
                  color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                ),
                label: Text(
                  opt['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.accent,
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? AppColors.accent : AppColors.border,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                visualDensity: VisualDensity.compact,
                onSelected: _isTranslating
                    ? null
                    : (selected) {
                        if (selected) {
                          _translateContent(
                            opt['code'] as String,
                            originalTitle,
                            originalDescription,
                          );
                        }
                      },
              );
            }).toList(),
          ),
          if (_selectedLang != 'original' && !_isTranslating) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 13),
                const SizedBox(width: 6),
                Text(
                  'Showing ${_selectedLang == "si" ? "Sinhala (සිංහල)" : _selectedLang == "ta" ? "Tamil (தமிழ்)" : "English"} translation',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
