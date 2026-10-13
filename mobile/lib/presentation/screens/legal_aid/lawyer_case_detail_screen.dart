import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/legal_aid_repository.dart';

class LawyerCaseDetailScreen extends StatefulWidget {
  final String caseId;

  const LawyerCaseDetailScreen({super.key, required this.caseId});

  @override
  State<LawyerCaseDetailScreen> createState() => _LawyerCaseDetailScreenState();
}

class _LawyerCaseDetailScreenState extends State<LawyerCaseDetailScreen> {
  final LegalAidRepository _legalAidRepo = LegalAidRepository();
  Map<String, dynamic>? _case;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCase();
  }

  Future<void> _fetchCase() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final c = await _legalAidRepo.getLawyerCase(widget.caseId);
      if (mounted) {
        setState(() {
          _case = c;
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

  void _previewEvidence(Map<String, dynamic> item) {
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.perm_media_rounded, color: AppColors.accent, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        originalName,
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
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
              const Divider(color: AppColors.border, height: 1),
              Container(
                constraints: const BoxConstraints(maxHeight: 380),
                padding: const EdgeInsets.all(16),
                child: fileType == 'image'
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          fullUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image, size: 64, color: AppColors.textMuted),
                          ),
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              fileType == 'video' ? Icons.videocam_rounded : Icons.picture_as_pdf_rounded,
                              size: 56,
                              color: AppColors.accent,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              fileType == 'video' ? 'Video Evidence' : 'PDF Document',
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              originalName,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
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
        appBar: AppBar(title: const Text('Case Request Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && _case == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Case Request Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text('Error loading case: $_errorMessage', style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetchCase, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final c = _case ?? {};
    final title = c['title'] as String? ?? 'Untitled Incident';
    final description = c['description'] as String? ?? '';
    final category = AppConstants.caseCategories[c['category']] ?? c['category'] ?? 'Human Rights';

    final incidentDateRaw = c['incidentDate'] as String?;
    DateTime? dt;
    if (incidentDateRaw != null) {
      try {
        dt = DateTime.parse(incidentDateRaw);
      } catch (_) {}
    }
    final formattedDate = dt != null ? DateFormat('MMMM dd, yyyy').format(dt) : 'Not specified';

    final locRaw = c['location'];
    final loc = locRaw is Map ? Map<String, dynamic>.from(locRaw) : <String, dynamic>{};
    final address = loc['address'] as String?;
    final city = loc['city'] as String?;
    final state = loc['state'] as String?;
    final locationParts = [address, city, state].where((s) => s != null && s.isNotEmpty).join(', ');
    final locationText = locationParts.isNotEmpty ? locationParts : 'Not mentioned';

    // Citizen Details
    final reportedByRaw = c['reportedBy'];
    final reportedBy = reportedByRaw is Map ? Map<String, dynamic>.from(reportedByRaw) : <String, dynamic>{};
    final profileRaw = reportedBy['profile'];
    final profile = profileRaw is Map ? Map<String, dynamic>.from(profileRaw) : <String, dynamic>{};

    final citizenName = profile['fullName'] ?? reportedBy['alias'] ?? 'Citizen';
    final citizenNIC = profile['nic'] ?? 'Not specified';
    final citizenEmail = reportedBy['email'] ?? 'Not specified';
    final citizenPhone = profile['phone'] ?? 'Not specified';
    final citizenGender = profile['gender'] ?? 'Not specified';
    final citizenProvince = profile['province'] ?? 'Not specified';
    final citizenDistrict = profile['district'] ?? 'Not specified';

    // Message & Preferences
    final citizenMessage = c['citizenMessageToLawyer'] as String? ?? '';
    final contactMethod = c['preferredContactMethod'] as String? ?? 'In-app';

    // Evidence
    final evidenceRaw = c['evidence'];
    final evidenceList = evidenceRaw is List ? evidenceRaw : [];
    final photos = evidenceList.where((e) => e is Map && e['fileType'] == 'image').toList();
    final videos = evidenceList.where((e) => e is Map && e['fileType'] == 'video').toList();
    final docs = evidenceList.where((e) => e is Map && e['fileType'] != 'image' && e['fileType'] != 'video').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Client Case Request'),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Badge
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded, color: AppColors.accent, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Status: Waiting for Your Review',
                            style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            'Preferred Contact Method: $contactMethod',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Citizen Short Message (if present)
              if (citizenMessage.isNotEmpty) ...[
                _buildHeader('Client\'s Message to Counsel', Icons.mail_outline_rounded),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    citizenMessage,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Section 1: Citizen Details
              _buildHeader('Citizen Details', Icons.person_rounded),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildRow('Full Name', citizenName),
                    _buildRow('NIC', citizenNIC),
                    _buildRow('Email', citizenEmail),
                    _buildRow('Mobile Number', citizenPhone),
                    _buildRow('Gender', citizenGender),
                    _buildRow('Province', citizenProvince),
                    _buildRow('District', citizenDistrict, isLast: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section 2: Report Details
              _buildHeader('Report Details', Icons.assignment_rounded),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRow('Report Title', title, isBold: true),
                    const SizedBox(height: 10),
                    const Text('Description:', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 8),
                    _buildRow('Category', category),
                    _buildRow('Date & Time', formattedDate),
                    _buildRow('Location', locationText, isLast: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section 3: Evidence
              _buildHeader('Attached Evidence', Icons.perm_media_rounded),
              const SizedBox(height: 10),
              if (evidenceList.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text('No evidence files attached.', style: TextStyle(color: AppColors.textSecondary)),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photos Grid
                    if (photos.isNotEmpty) ...[
                      const Text('Photos (Tap to view full)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
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
                              child: Image.network(
                                pUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: AppColors.textMuted),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Videos List
                    if (videos.isNotEmpty) ...[
                      const Text('Videos', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ...videos.map((v) => Card(
                            color: AppColors.surface,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.videocam_rounded, color: AppColors.accent),
                              title: Text(v['originalName'] ?? 'Video Evidence', style: const TextStyle(color: AppColors.textPrimary)),
                              trailing: ElevatedButton(
                                onPressed: () => _previewEvidence(v as Map<String, dynamic>),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: AppColors.primaryDark,
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                child: const Text('Play'),
                              ),
                            ),
                          )),
                      const SizedBox(height: 14),
                    ],

                    // Documents List
                    if (docs.isNotEmpty) ...[
                      const Text('Documents & PDFs', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ...docs.map((d) => Card(
                            color: AppColors.surface,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.accent),
                              title: Text(d['originalName'] ?? 'Document', style: const TextStyle(color: AppColors.textPrimary)),
                              trailing: ElevatedButton(
                                onPressed: () => _previewEvidence(d as Map<String, dynamic>),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.surfaceVariant,
                                  foregroundColor: AppColors.textPrimary,
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                child: const Text('Open'),
                              ),
                            ),
                          )),
                    ],
                  ],
                ),
              const SizedBox(height: 24),

              // Section 4: Action Buttons (Approve / Reject) when pending
              if (c['status'] == 'waiting_for_lawyer_approval') ...[
                _buildHeader('Action Required', Icons.gavel_rounded),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Review this case request and choose to accept and schedule an initial consultation, or decline with a reason.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          // Reject Button
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _showRejectDialog,
                              icon: const Icon(Icons.close_rounded, color: AppColors.error, size: 18),
                              label: const Text('Reject', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.error),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Approve Button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showApproveDialog,
                              icon: const Icon(Icons.check_circle_rounded, size: 18),
                              label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: AppColors.primaryDark,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ] else if (c['status'] == 'approved_scheduled' || c['status'] == 'in_progress') ...[
                _buildHeader('Scheduled Consultation', Icons.event_available_rounded),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.info.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.info),
                          const SizedBox(width: 8),
                          Text(
                            'Date: ${c['scheduledMeetingDate'] ?? 'Scheduled'}',
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.access_time_rounded, size: 16, color: AppColors.info),
                          const SizedBox(width: 8),
                          Text(
                            'Time: ${c['scheduledMeetingTime'] ?? 'N/A'}',
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ] else if (c['status'] == 'lawyer_declined') ...[
                _buildHeader('Declined Case', Icons.cancel_outlined),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Reason provided to citizen:', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        c['lawyerDeclineReason'] ?? 'No reason recorded',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Reject Flow ──
  void _showRejectDialog() {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.cancel_outlined, color: AppColors.error, size: 24),
              SizedBox(width: 10),
              Text('Decline Case Request', style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please provide a reason for declining. This message will be sent directly to the citizen with an option to find another lawyer.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 14),
                const Text('Rejection Message *', style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: reasonController,
                  maxLines: 3,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'e.g. Schedule is full for the requested category, or outside jurisdiction...',
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Rejection message is required' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSubmitting = true);
                      try {
                        await _legalAidRepo.rejectLawyerCase(
                          caseId: widget.caseId,
                          reason: reasonController.text.trim(),
                        );
                        if (mounted) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Case request declined. Citizen notified.'),
                              backgroundColor: AppColors.warning,
                            ),
                          );
                          Navigator.of(context).pop(true); // Return to view cases & refresh
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to decline case: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Approve Flow ──
  void _showApproveDialog() async {
    DateTime? selectedDate;
    String? selectedTimeSlot;
    List<String> availableSlots = [];
    bool isLoadingSchedule = true;
    bool isSubmitting = false;
    Map<String, dynamic> lawyerSchedule = {};

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (isLoadingSchedule) {
            _legalAidRepo.getLawyerAvailability().then((sched) {
              if (context.mounted) {
                setDialogState(() {
                  lawyerSchedule = sched;
                  isLoadingSchedule = false;
                });
              }
            }).catchError((_) {
              if (context.mounted) {
                setDialogState(() {
                  isLoadingSchedule = false;
                });
              }
            });
          }

          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.schedule_rounded, color: AppColors.accent, size: 24),
                SizedBox(width: 10),
                Text('Schedule Meeting', style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: isLoadingSchedule
                  ? const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select a date and consultation slot. Available times are strictly based on your saved Availability schedule.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                        ),
                        const SizedBox(height: 16),

                        // Pick Date Button
                        const Text('Pick a Date *', style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? now.add(const Duration(days: 1)),
                              firstDate: now,
                              lastDate: now.add(const Duration(days: 90)),
                            );
                            if (picked != null) {
                              final dayName = DateFormat('EEEE').format(picked);
                              final dayData = lawyerSchedule[dayName] as Map<String, dynamic>?;
                              final isUnavailable = dayData?['isUnavailable'] == true;
                              final rawSlots = (dayData?['slots'] as List<dynamic>?) ?? [];

                              final List<String> slots = [];
                              if (!isUnavailable) {
                                for (final s in rawSlots) {
                                  if (s is Map) {
                                    final start = s['startTime']?.toString() ?? '';
                                    final end = s['endTime']?.toString() ?? '';
                                    if (start.isNotEmpty && end.isNotEmpty) {
                                      slots.add('$start – $end');
                                    }
                                  }
                                }
                              }

                              setDialogState(() {
                                selectedDate = picked;
                                availableSlots = slots;
                                selectedTimeSlot = slots.isNotEmpty ? slots.first : null;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month_rounded, color: AppColors.accent, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  selectedDate != null
                                      ? DateFormat('EEEE, MMM dd, yyyy').format(selectedDate!)
                                      : 'Tap to pick consultation date',
                                  style: TextStyle(
                                    color: selectedDate != null ? AppColors.textPrimary : AppColors.textMuted,
                                    fontWeight: selectedDate != null ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Pick Time Slot
                        if (selectedDate != null) ...[
                          const Text('Available Time Slot *', style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          if (availableSlots.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${DateFormat('EEEE').format(selectedDate!)} is marked as Unavailable or has no slots in your schedule. Please pick another date or update your schedule in "Set Availability".',
                                      style: const TextStyle(color: AppColors.warning, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            DropdownButtonFormField<String>(
                              value: selectedTimeSlot,
                              dropdownColor: AppColors.surface,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.surfaceVariant,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                              ),
                              items: availableSlots.map((slot) {
                                return DropdownMenuItem(
                                  value: slot,
                                  child: Text(slot, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setDialogState(() => selectedTimeSlot = val);
                              },
                            ),
                        ],
                      ],
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                onPressed: (selectedDate == null || selectedTimeSlot == null || isSubmitting)
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);
                        try {
                          final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate!);
                          await _legalAidRepo.approveLawyerCase(
                            caseId: widget.caseId,
                            scheduledDate: dateStr,
                            scheduledTime: selectedTimeSlot!,
                          );
                          if (mounted) {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Case approved & scheduled! Citizen notified.'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            Navigator.of(context).pop(true); // Return to view cases & refresh
                          }
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to approve case: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.primaryDark,
                ),
                child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark))
                    : const Text('OK'),
              ),
            ],
          );
        },
      ),
    );
  }


  Widget _buildHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value, {bool isLast = false, bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
