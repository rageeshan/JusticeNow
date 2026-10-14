import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/case_repository.dart';
import '../../../data/services/api_service.dart';
import 'officer_case_preview_modal.dart';

class OfficerCaseDetailScreen extends StatefulWidget {
  final String caseId;
  final Map<String, dynamic>? initialCase;

  const OfficerCaseDetailScreen({
    super.key,
    required this.caseId,
    this.initialCase,
  });

  @override
  State<OfficerCaseDetailScreen> createState() => _OfficerCaseDetailScreenState();
}

class _OfficerCaseDetailScreenState extends State<OfficerCaseDetailScreen> {
  final CaseRepository _repo = CaseRepository();

  bool _isLoading = true;
  bool _isActionLoading = false;
  Map<String, dynamic>? _case;

  // Saved availability schedule for slot selection
  Map<String, dynamic> _availability = {};
  List<dynamic> _activeCases = [];

  @override
  void initState() {
    super.initState();
    _case = widget.initialCase;
    _fetchCaseDetails();
    _fetchOfficerAvailability();
  }

  Future<void> _fetchCaseDetails() async {
    setState(() => _isLoading = _case == null);
    try {
      final data = await _repo.getCaseById(widget.caseId);
      if (mounted) {
        setState(() {
          _case = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load case details: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _fetchOfficerAvailability() async {
    try {
      final response = await ApiService.instance.client.get('/cases/officer/availability');
      final avail = response.data['data']?['availability'];
      final active = await _repo.getPoliceCases('in_progress');
      if (mounted) {
        setState(() {
          if (avail is Map) {
            _availability = Map<String, dynamic>.from(avail);
          }
          _activeCases = active;
        });
      }
    } catch (_) {}
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateVal.toString()).toLocal();
      return DateFormat('MMMM dd, yyyy').format(dt);
    } catch (_) {
      return dateVal.toString();
    }
  }

  /// Accept Case Flow with Availability slot picker
  Future<void> _showAcceptDialog() async {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String? selectedTimeSlot;
    final notesController = TextEditingController();

    // Check if the weekday is marked Unavailable
    bool isDayUnavailable(DateTime dt) {
      final dayName = DateFormat('EEEE').format(dt);
      final dayData = _availability[dayName];
      return dayData is Map && dayData['isUnavailable'] == true;
    }

    // Get ONLY saved duty slots for the day
    List<String> getSavedSlotsForDay(DateTime dt) {
      final dayName = DateFormat('EEEE').format(dt);
      final dayData = _availability[dayName];
      if (dayData is Map && dayData['isUnavailable'] != true) {
        final rawSlots = dayData['slots'] as List<dynamic>? ?? [];
        return rawSlots.map((s) {
          if (s is Map) {
            return '${s['startTime']} - ${s['endTime']}';
          }
          return s.toString();
        }).toList();
      }
      return [];
    }

    // Identify already booked slots for the officer on this specific date
    Set<String> getBookedSlotsForDate(DateTime dt) {
      final dateStr = DateFormat('yyyy-MM-dd').format(dt);
      final booked = <String>{};
      for (final activeCase in _activeCases) {
        if (activeCase is Map && activeCase['_id']?.toString() != widget.caseId) {
          final caseDateRaw = activeCase['investigationStartDate'];
          if (caseDateRaw != null) {
            try {
              final cDate = DateTime.parse(caseDateRaw.toString()).toLocal();
              final cDateStr = DateFormat('yyyy-MM-dd').format(cDate);
              if (cDateStr == dateStr && activeCase['investigationStartTime'] != null) {
                booked.add(activeCase['investigationStartTime'].toString().trim());
              }
            } catch (_) {}
          }
        }
      }
      return booked;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final dayName = DateFormat('EEEE').format(selectedDate);
            final dayUnavailable = isDayUnavailable(selectedDate);
            final savedSlots = getSavedSlotsForDay(selectedDate);
            final bookedSlots = getBookedSlotsForDate(selectedDate);
            final availableSlots = savedSlots.where((s) => !bookedSlots.contains(s.trim())).toList();

            if (selectedTimeSlot == null && availableSlots.isNotEmpty) {
              selectedTimeSlot = availableSlots.first;
            } else if (selectedTimeSlot != null && !availableSlots.contains(selectedTimeSlot)) {
              selectedTimeSlot = availableSlots.isNotEmpty ? availableSlots.first : null;
            }

            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: AppColors.success),
                  SizedBox(width: 8),
                  Text(
                    'Accept Case Investigation',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pick investigation start date & time from your saved duty availability slots:',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    // Date Picker Trigger
                    const Text('Investigation Start Date *',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 60)),
                          builder: (c, child) => Theme(
                            data: Theme.of(c).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppColors.accent,
                                surface: AppColors.surface,
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                            final slots = getSavedSlotsForDay(picked);
                            final booked = getBookedSlotsForDate(picked);
                            final open = slots.where((s) => !booked.contains(s.trim())).toList();
                            selectedTimeSlot = open.isNotEmpty ? open.first : null;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('EEEE, MMM dd, yyyy').format(selectedDate),
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                            ),
                            const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.accent),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Time Slot Picker with double-booking prevention
                    const Text('Saved Duty Time Slot *',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    if (dayUnavailable)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'You are marked Unavailable on $dayName. Please pick another date or update your schedule in Set Availability.',
                          style: const TextStyle(color: AppColors.error, fontSize: 12),
                        ),
                      )
                    else if (savedSlots.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'No duty slots saved for $dayName. Please define availability in Set Availability.',
                          style: const TextStyle(color: AppColors.warning, fontSize: 12),
                        ),
                      )
                    else if (availableSlots.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'All saved duty slots for this day are already booked for active investigations (${bookedSlots.join(', ')}). Choose another date to prevent double-booking.',
                          style: const TextStyle(color: AppColors.error, fontSize: 12),
                        ),
                      )
                    else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedTimeSlot,
                            isExpanded: true,
                            dropdownColor: AppColors.primaryDark,
                            items: availableSlots.map((slot) {
                              return DropdownMenuItem(
                                value: slot,
                                child: Text(slot, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setDialogState(() => selectedTimeSlot = val);
                            },
                          ),
                        ),
                      ),
                      if (bookedSlots.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Note: ${bookedSlots.length} slot(s) already booked on this day (double-booking prevented).',
                          style: const TextStyle(color: AppColors.warning, fontSize: 11),
                        ),
                      ],
                    ],
                    const SizedBox(height: 14),

                    // Notes (optional)
                    const Text('Notes (Optional)',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. Will visit location on Monday morning...',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        filled: true,
                        fillColor: AppColors.primaryDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Notification Info
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.notifications_active_outlined, color: AppColors.info, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'A notification with this start schedule will be automatically dispatched to the citizen.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  onPressed: (selectedTimeSlot == null)
                      ? null
                      : () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && selectedTimeSlot != null) {
      setState(() => _isActionLoading = true);
      try {
        final formattedDateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
        await ApiService.instance.client.patch(
          '/cases/officer/cases/${widget.caseId}/accept',
          data: {
            'startDate': formattedDateStr,
            'startTime': selectedTimeSlot!,
            'notes': notesController.text.trim(),
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Case accepted! Investigation started & citizen notified.'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isActionLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to accept case: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  /// Reject / Forward Back Flow with required reason
  Future<void> _showRejectDialog() async {
    String selectedReasonType = 'Not enough evidence';
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.cancel_outlined, color: AppColors.error),
              SizedBox(width: 8),
              Text(
                'Reject Case',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select a reason for declining. This case will be returned to the admin pool and the citizen will be notified of reassignment.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  const Text('Reason Type *',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedReasonType,
                        isExpanded: true,
                        dropdownColor: AppColors.primaryDark,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        items: const [
                          DropdownMenuItem(value: 'Not enough evidence', child: Text('Not enough evidence')),
                          DropdownMenuItem(value: 'Need more details', child: Text('Need more details')),
                          DropdownMenuItem(value: 'Outside my jurisdiction', child: Text('Outside my jurisdiction')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedReasonType = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    selectedReasonType == 'Other' ? 'Message (Required for Other) *' : 'Message (Optional)',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: reasonController,
                    maxLines: 3,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: selectedReasonType == 'Other'
                          ? 'Please explain specific reason why you cannot proceed...'
                          : 'Additional comments or details...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      filled: true,
                      fillColor: AppColors.primaryDark,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
                      contentPadding: const EdgeInsets.all(10),
                    ),
                    validator: (v) {
                      if (selectedReasonType == 'Other' && (v == null || v.trim().isEmpty)) {
                        return 'Please provide a message when "Other" is selected';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx, true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      setState(() => _isActionLoading = true);
      try {
        final fullReason = selectedReasonType == 'Other'
            ? reasonController.text.trim()
            : reasonController.text.trim().isNotEmpty
                ? '$selectedReasonType: ${reasonController.text.trim()}'
                : selectedReasonType;

        await ApiService.instance.client.patch(
          '/cases/officer/cases/${widget.caseId}/reject',
          data: {
            'reason': fullReason,
            'reasonType': selectedReasonType,
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Case returned to admin pool. Citizen notified of reassignment.'),
              backgroundColor: AppColors.warning,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isActionLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to decline case: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  /// Update stage dropdown
  Future<void> _updateStage(String stage) async {
    setState(() => _isActionLoading = true);
    try {
      await _repo.updatePoliceCaseStage(widget.caseId, stage: stage);
      await _fetchCaseDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Investigation stage updated to ${stage.replaceAll('_', ' ').toUpperCase()}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update stage: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  /// Complete Case
  Future<void> _markCompleted() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Conclude Investigation?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Are you sure you want to mark this investigation as Completed? This will conclude the active case.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Mark Completed'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isActionLoading = true);
      try {
        await _repo.completePoliceCase(widget.caseId);
        await _fetchCaseDetails();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Case successfully marked as Completed!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to complete case: $e'), backgroundColor: AppColors.error),
          );
        }
      } finally {
        if (mounted) setState(() => _isActionLoading = false);
      }
    }
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

    final c = _case ?? {};
    final status = c['status']?.toString() ?? 'submitted';
    final isPending = status == 'assigned_to_police' || status == 'submitted' || status == 'under_review';
    final isInProgress = status == 'in_progress_police' ||
        status == 'in_progress' ||
        status == 'investigating' ||
        status == 'suspect_identified' ||
        status == 'referred_to_court';

    // Section 1: Citizen Details
    final reportedBy = c['reportedBy'] as Map<String, dynamic>? ?? {};
    final profile = reportedBy['profile'] as Map<String, dynamic>? ?? {};
    final citizenName = profile['fullName']?.toString().isNotEmpty == true
        ? profile['fullName']
        : (reportedBy['alias']?.toString() ?? 'Citizen (Anonymous)');
    final nic = profile['nic']?.toString() ?? 'Not provided';
    final email = reportedBy['email']?.toString() ?? 'Not provided';
    final phone = profile['phone']?.toString() ?? 'Not provided';
    final gender = profile['gender']?.toString() ?? 'Not specified';
    final province = profile['province']?.toString() ?? 'Not specified';
    final district = profile['district']?.toString() ?? 'Not specified';

    // Section 2: Report Details
    final title = c['title']?.toString() ?? 'Untitled Case';
    final description = c['description']?.toString() ?? 'No description provided';
    final category = AppConstants.caseCategories[c['category']] ?? c['category'] ?? 'Human Rights';
    final incidentDate = _formatDate(c['incidentDate']);

    final locRaw = c['location'];
    final loc = locRaw is Map ? Map<String, dynamic>.from(locRaw) : <String, dynamic>{};
    final locationText = [loc['address'], loc['city'], loc['state']]
        .where((s) => s != null && s.toString().trim().isNotEmpty)
        .join(', ');
    final incidentLocation = locationText.isNotEmpty ? locationText : 'Not mentioned';

    // Section 3: Evidence
    final evidenceList = (c['evidence'] as List<dynamic>? ?? []).cast<dynamic>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(c['referenceNumber']?.toString() ?? 'Police Case Detail'),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _fetchCaseDetails,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Case Status Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isPending
                            ? AppColors.warning.withValues(alpha: 0.15)
                            : (isInProgress
                                ? AppColors.info.withValues(alpha: 0.15)
                                : AppColors.success.withValues(alpha: 0.15)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPending
                            ? Icons.pending_actions_rounded
                            : (isInProgress
                                ? Icons.run_circle_outlined
                                : Icons.check_circle_outline_rounded),
                        color: isPending
                            ? AppColors.warning
                            : (isInProgress ? AppColors.info : AppColors.success),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPending
                                ? 'Assigned by Admin (Pending Acceptance)'
                                : (isInProgress
                                    ? 'Investigation In Progress'
                                    : 'Investigation Completed'),
                            style: TextStyle(
                              color: isPending
                                  ? AppColors.warning
                                  : (isInProgress ? AppColors.info : AppColors.success),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ref: ${c['referenceNumber'] ?? 'N/A'}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ─────────────────────────────────────────────────────────────
              // Section 1 – Citizen Details
              // ─────────────────────────────────────────────────────────────
              _buildSectionHeader(Icons.person_rounded, 'Section 1 – Citizen Details'),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Name', citizenName),
                    _buildDetailRow('NIC', nic),
                    _buildDetailRow('Email', email),
                    _buildDetailRow('Mobile', phone),
                    _buildDetailRow('Gender', gender),
                    _buildDetailRow('Province', province),
                    _buildDetailRow('District', district, isLast: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─────────────────────────────────────────────────────────────
              // Section 2 – Report Details
              // ─────────────────────────────────────────────────────────────
              _buildSectionHeader(Icons.article_rounded, 'Section 2 – Report Details'),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Report Title', title),
                    _buildDetailRow('Category', category),
                    _buildDetailRow('Incident Date', incidentDate),
                    _buildDetailRow('Incident Location', incidentLocation),
                    const SizedBox(height: 10),
                    const Text(
                      'Description',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        description,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─────────────────────────────────────────────────────────────
              // Section 3 – Evidence
              // ─────────────────────────────────────────────────────────────
              _buildSectionHeader(Icons.perm_media_rounded, 'Section 3 – Evidence (${evidenceList.length})'),
              const SizedBox(height: 10),
              if (evidenceList.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.perm_media_outlined, color: AppColors.textMuted, size: 36),
                      SizedBox(height: 8),
                      Text('No evidence files uploaded for this case',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                )
              else
                _buildEvidenceSection(evidenceList),

              // In Progress extra options: Stages & Schedule
              if (isInProgress) ...[
                const SizedBox(height: 20),
                _buildSectionHeader(Icons.timeline_rounded, 'Investigation Stages & Status'),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (c['investigationStartDate'] != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.alarm_on_rounded, color: AppColors.accent, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Scheduled Start: ${_formatDate(c['investigationStartDate'])} • ${c['investigationStartTime'] ?? 'On Duty'}',
                                style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: AppColors.divider, height: 24),
                      ],
                      const Text(
                        'Update Investigation Stage',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: ['investigating', 'suspect_identified', 'referred_to_court', 'closed'].contains(status)
                            ? status
                            : 'investigating',
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.assignment_turned_in_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'investigating', child: Text('Investigating')),
                          DropdownMenuItem(value: 'suspect_identified', child: Text('Suspect Identified')),
                          DropdownMenuItem(value: 'referred_to_court', child: Text('Referred to Court')),
                          DropdownMenuItem(value: 'closed', child: Text('Closed')),
                        ],
                        onChanged: (newStage) {
                          if (newStage != null && newStage != status) {
                            _updateStage(newStage);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),

      // ─────────────────────────────────────────────────────────────
      // Section 4 – Action Buttons (bottom)
      // ─────────────────────────────────────────────────────────────
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: _isActionLoading
            ? const Center(child: CircularProgressIndicator())
            : isPending
                ? Row(
                    children: [
                      // Reject / Forward Back to Admin
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showRejectDialog,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Forward to Admin', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Accept Case
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showAcceptDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Accept Case', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                : isInProgress
                    ? SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _markCompleted,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.done_all_rounded),
                          label: const Text(
                            'Mark as Completed',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_rounded, color: AppColors.success, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'This case investigation is completed',
                              style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.accent),
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

  Widget _buildDetailRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceSection(List<dynamic> evidence) {
    final images = evidence.where((e) {
      final t = (e is Map ? e['fileType']?.toString() : '')?.toLowerCase() ?? '';
      final mime = (e is Map ? e['mimeType']?.toString() : '')?.toLowerCase() ?? '';
      return t == 'image' || mime.contains('image');
    }).toList();

    final videos = evidence.where((e) {
      final t = (e is Map ? e['fileType']?.toString() : '')?.toLowerCase() ?? '';
      final mime = (e is Map ? e['mimeType']?.toString() : '')?.toLowerCase() ?? '';
      return t == 'video' || mime.contains('video');
    }).toList();

    final docs = evidence.where((e) {
      final t = (e is Map ? e['fileType']?.toString() : '')?.toLowerCase() ?? '';
      final mime = (e is Map ? e['mimeType']?.toString() : '')?.toLowerCase() ?? '';
      return !t.contains('image') && !t.contains('video') && !mime.contains('image') && !mime.contains('video');
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Photo Grid
        if (images.isNotEmpty) ...[
          const Text('Photos (Tap to preview)',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: images.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (ctx, idx) {
              final item = Map<String, dynamic>.from(images[idx] as Map);
              final url = item['fileUrl']?.toString() ?? item['url']?.toString() ?? '';
              return InkWell(
                onTap: () => OfficerCasePreviewModal.show(context, item),
                borderRadius: BorderRadius.circular(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    color: AppColors.surface,
                    child: url.isNotEmpty
                        ? Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.image_not_supported, color: AppColors.textMuted),
                            ),
                          )
                        : const Icon(Icons.image, color: AppColors.accent),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
        ],

        // Video Thumbnails
        if (videos.isNotEmpty) ...[
          const Text('Videos (Tap to preview)',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...videos.map((v) {
            final item = Map<String, dynamic>.from(v as Map);
            return Card(
              color: AppColors.surface,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.videocam_rounded, color: AppColors.accent),
                ),
                title: Text(
                  item['originalName']?.toString() ?? 'Video Evidence',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Tap to view details', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                trailing: const Icon(Icons.play_circle_outline_rounded, color: AppColors.accent),
                onTap: () => OfficerCasePreviewModal.show(context, item),
              ),
            );
          }),
          const SizedBox(height: 14),
        ],

        // Documents / PDFs
        if (docs.isNotEmpty) ...[
          const Text('PDFs & Documents (Tap to preview)',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...docs.map((d) {
            final item = Map<String, dynamic>.from(d as Map);
            return Card(
              color: AppColors.surface,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error),
                ),
                title: Text(
                  item['originalName']?.toString() ?? 'Document',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Size: ${(item['fileSize'] != null ? (item['fileSize'] / 1024).toStringAsFixed(1) : 'Unknown')} KB',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                trailing: const Icon(Icons.open_in_new_rounded, color: AppColors.accent, size: 18),
                onTap: () => OfficerCasePreviewModal.show(context, item),
              ),
            );
          }),
        ],
      ],
    );
  }
}
