import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/case_repository.dart';
import '../../../data/repositories/legal_aid_repository.dart';
import '../../../providers/auth_provider.dart';

class BookLawyerScreen extends ConsumerStatefulWidget {
  final String lawyerId;
  final Map<String, dynamic>? lawyerData;
  final String? caseId;
  final Map<String, dynamic>? initialCase;

  const BookLawyerScreen({
    super.key,
    required this.lawyerId,
    this.lawyerData,
    this.caseId,
    this.initialCase,
  });

  @override
  ConsumerState<BookLawyerScreen> createState() => _BookLawyerScreenState();
}

class _BookLawyerScreenState extends ConsumerState<BookLawyerScreen> {
  final LegalAidRepository _legalAidRepo = LegalAidRepository();
  final CaseRepository _caseRepo = CaseRepository();

  Map<String, dynamic>? _lawyer;
  Map<String, dynamic>? _case;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Extra user input fields
  String _selectedContactMethod = 'In-app';
  final TextEditingController _messageCtrl = TextEditingController();

  final List<String> _contactMethods = ['Call', 'Email', 'In-app'];

  @override
  void initState() {
    super.initState();
    _lawyer = widget.lawyerData;
    _case = widget.initialCase;
    _loadInitialData();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Fetch lawyer if not passed
      if (_lawyer == null) {
        _lawyer = await _legalAidRepo.getLawyerById(widget.lawyerId);
      }

      // 2. Fetch case if not passed
      if (_case == null && widget.caseId != null && widget.caseId!.isNotEmpty) {
        _case = await _caseRepo.getCaseById(widget.caseId!);
      } else if (_case == null) {
        // Fallback: look for citizen's most recent case
        final res = await _caseRepo.getMyCases();
        final cases = (res['cases'] as List<dynamic>?) ?? [];
        if (cases.isNotEmpty) {
          final pending = cases.firstWhere(
            (c) =>
                c is Map &&
                (c['status'] == 'awaiting_lawyer_selection' ||
                    c['status'] == 'submitted' ||
                    c['status'] == 'under_review'),
            orElse: () => cases.first,
          );
          if (pending != null && pending is Map) {
            _case = Map<String, dynamic>.from(pending);
          }
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
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

  Future<void> _submitBooking() async {
    final caseId = _case?['_id']?.toString() ?? widget.caseId;
    if (caseId == null || caseId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('No active case report found to attach to this booking.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _legalAidRepo.bookLawyer(
        caseId: caseId,
        lawyerId: widget.lawyerId,
        preferredContactMethod: _selectedContactMethod,
        shortMessage: _messageCtrl.text.trim(),
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        // Navigate to Booking Success Page
        context.pushReplacement('/legal-aid/booking-success');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Booking failed: $e'),
          ),
        );
      }
    }
  }

  void _previewEvidenceItem(Map<String, dynamic> item) {
    final fileType = item['fileType'] as String? ?? 'image';
    final originalName = item['originalName'] as String? ?? 'Evidence';
    final storagePath = item['storagePath'] as String? ?? '';
    final fullUrl = storagePath.startsWith('http')
        ? storagePath
        : '${AppConstants.baseUrl.replaceAll('/api', '')}$storagePath';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                originalName,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              if (fileType == 'image')
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    fullUrl,
                    fit: BoxFit.contain,
                    height: 250,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 60, color: AppColors.textMuted),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        fileType == 'video' ? Icons.videocam_rounded : Icons.description_rounded,
                        size: 48,
                        color: AppColors.accent,
                      ),
                      const SizedBox(height: 8),
                      Text(fileType.toUpperCase(), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
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
        appBar: AppBar(title: const Text('Book Lawyer')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && _lawyer == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Book Lawyer')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text('Error: $_errorMessage', style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadInitialData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final user = ref.watch(authProvider).user;
    final userProfile = user?['profile'] as Map<String, dynamic>? ?? {};

    // Lawyer data
    final lawyerProfile = _lawyer?['profile'] as Map<String, dynamic>? ?? {};
    final lawyerName = lawyerProfile['fullName'] ?? _lawyer?['email'] ?? 'Attorney at Law';
    final courtNumber = lawyerProfile['courtNumber'] ?? lawyerProfile['lawyerId'] ?? 'Supreme Court Counsel';

    // Case data (auto-filled)
    final c = _case ?? {};
    final title = c['title'] as String? ?? 'Incident Report';
    final description = c['description'] as String? ?? 'No description provided';
    final category = AppConstants.caseCategories[c['category']] ?? c['category'] ?? 'Human Rights';

    final incidentDateRaw = c['incidentDate'] as String?;
    DateTime? dt;
    if (incidentDateRaw != null) {
      try {
        dt = DateTime.parse(incidentDateRaw);
      } catch (_) {}
    }
    final formattedDate = dt != null ? DateFormat('MMMM dd, yyyy').format(dt) : 'Not specified';

    final loc = c['location'] as Map<String, dynamic>? ?? {};
    final address = loc['address'] as String?;
    final city = loc['city'] as String?;
    final state = loc['state'] as String?;
    final locationParts = [address, city, state].where((s) => s != null && s.isNotEmpty).join(', ');
    final locationText = locationParts.isNotEmpty ? locationParts : 'Sri Lanka';

    // Citizen Name & NIC (Read-only)
    final citizenName = userProfile['fullName'] ?? user?['alias'] ?? 'Registered Citizen';
    final citizenNIC = userProfile['nic'] ?? 'On Verified File';

    // Evidence
    final evidenceList = (c['evidence'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Book Lawyer'),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
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
                    // Selected Lawyer Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accent.withValues(alpha: 0.2),
                              border: Border.all(color: AppColors.accent),
                            ),
                            child: const Center(
                              child: Icon(Icons.gavel_rounded, color: AppColors.accent, size: 24),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Booking Legal Representation with:',
                                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  lawyerName,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'SC Reg: $courtNumber',
                                  style: const TextStyle(color: AppColors.accent, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 1: Citizen Details (Read-only)
                    _buildSectionTitle('Citizen Details', Icons.person_rounded),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildReadonlyItem('Citizen Name', citizenName),
                          ),
                          Container(width: 1, height: 40, color: AppColors.border),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildReadonlyItem('Citizen NIC', citizenNIC),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 2: Auto-Filled Report Details
                    _buildSectionTitle('Report Details (Auto-Filled)', Icons.assignment_rounded),
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
                          _buildReportField('Report Title', title, isBold: true),
                          const SizedBox(height: 12),
                          _buildReportField('Report Description', description),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildReportField('Category', category)),
                              Expanded(child: _buildReportField('Date of Incident', formattedDate)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildReportField('Location of Incident', locationText),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 3: Attached Evidence Thumbnails
                    _buildSectionTitle('Attached Evidence', Icons.perm_media_rounded),
                    const SizedBox(height: 10),
                    if (evidenceList.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'No evidence files attached to this report.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        height: 95,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: evidenceList.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, idx) {
                            final ev = evidenceList[idx] as Map<String, dynamic>;
                            final fileType = ev['fileType'] as String? ?? 'image';
                            final originalName = ev['originalName'] as String? ?? 'Evidence';
                            final storagePath = ev['storagePath'] as String? ?? '';
                            final pUrl = storagePath.startsWith('http')
                                ? storagePath
                                : '${AppConstants.baseUrl.replaceAll('/api', '')}$storagePath';

                            return GestureDetector(
                              onTap: () => _previewEvidenceItem(ev),
                              child: Container(
                                width: 95,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      if (fileType == 'image')
                                        Image.network(
                                          pUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Center(
                                            child: Icon(Icons.image_rounded, color: AppColors.textMuted),
                                          ),
                                        )
                                      else
                                        Center(
                                          child: Icon(
                                            fileType == 'video' ? Icons.videocam_rounded : Icons.picture_as_pdf_rounded,
                                            size: 32,
                                            color: AppColors.accent,
                                          ),
                                        ),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          child: Text(
                                            originalName,
                                            style: const TextStyle(color: Colors.white, fontSize: 9),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 24),

                    // SECTION 4: Extra Fields to Fill Now
                    _buildSectionTitle('Booking Preferences', Icons.tune_rounded),
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
                          const Text(
                            'Preferred Contact Method *',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: _contactMethods.map((method) {
                              final isSelected = _selectedContactMethod == method;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(method),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    setState(() => _selectedContactMethod = method);
                                  },
                                  selectedColor: AppColors.accent,
                                  labelStyle: TextStyle(
                                    color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                  backgroundColor: AppColors.surfaceVariant,
                                  side: BorderSide(
                                    color: isSelected ? AppColors.accent : AppColors.border,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Short Message to Lawyer (Optional)',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _messageCtrl,
                            maxLines: 3,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Describe your immediate legal need or urgency...',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom Submit Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark),
                        )
                      : const Text(
                          'OK / Submit Booking',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildReadonlyItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildReportField(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
