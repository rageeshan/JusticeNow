import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/case_repository.dart';
import '../../../data/services/api_service.dart';
import 'officer_case_detail_screen.dart';

class OfficerMyCasesScreen extends StatefulWidget {
  final int initialTabIndex;

  const OfficerMyCasesScreen({super.key, this.initialTabIndex = 0});

  @override
  State<OfficerMyCasesScreen> createState() => _OfficerMyCasesScreenState();
}

class _OfficerMyCasesScreenState extends State<OfficerMyCasesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CaseRepository _repo = CaseRepository();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _isLoading = false;
  String _searchQuery = '';
  List<dynamic> _pendingCases = [];
  List<dynamic> _inProgressCases = [];
  List<dynamic> _completedCases = [];
  Map<String, dynamic> _availability = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _fetchCasesForTab(_tabController.index);
      }
    });
    _fetchAllCases();
    _fetchOfficerAvailability();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchOfficerAvailability() async {
    try {
      final response = await ApiService.instance.client.get('/cases/officer/availability');
      final avail = response.data['data']?['availability'];
      if (avail is Map && mounted) {
        setState(() => _availability = Map<String, dynamic>.from(avail));
      }
    } catch (_) {}
  }

  Future<void> _fetchAllCases() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchTab(0),
      _fetchTab(1),
      _fetchTab(2),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchTab(int tabIndex) async {
    try {
      final tabKey = tabIndex == 0
          ? 'pending'
          : tabIndex == 1
              ? 'in_progress'
              : 'completed';
      final list = await _repo.getPoliceCases(tabKey);
      if (mounted) {
        setState(() {
          if (tabIndex == 0) _pendingCases = list;
          if (tabIndex == 1) _inProgressCases = list;
          if (tabIndex == 2) _completedCases = list;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchCasesForTab(int tabIndex) async {
    setState(() => _isLoading = true);
    await _fetchTab(tabIndex);
    if (mounted) setState(() => _isLoading = false);
  }

  List<dynamic> _filterList(List<dynamic> list) {
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.trim().toLowerCase();
    return list.where((item) {
      if (item is! Map) return false;
      final c = Map<String, dynamic>.from(item);
      final title = (c['title'] ?? '').toString().toLowerCase();
      final refNum = (c['referenceNumber'] ?? '').toString().toLowerCase();
      final id = (c['_id'] ?? '').toString().toLowerCase();

      final reportedBy = c['reportedBy'] as Map<String, dynamic>? ?? {};
      final profile = reportedBy['profile'] as Map<String, dynamic>? ?? {};
      final citizenName = (profile['fullName'] ?? reportedBy['alias'] ?? '').toString().toLowerCase();
      final nic = (profile['nic'] ?? '').toString().toLowerCase();

      return title.contains(q) ||
          refNum.contains(q) ||
          id.contains(q) ||
          citizenName.contains(q) ||
          nic.contains(q);
    }).toList();
  }

  Future<void> _updateStage(String caseId, String stage) async {
    try {
      await _repo.updatePoliceCaseStage(caseId, stage: stage);
      _fetchTab(1);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to: ${stage.replaceAll('_', ' ').toUpperCase()}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update stage: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _markCompleted(String caseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Conclude Investigation?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Are you sure you want to conclude this case investigation and mark it as Completed?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Mark Completed'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _repo.completePoliceCase(caseId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Case marked as completed!'),
              backgroundColor: AppColors.success,
            ),
          );
          _fetchAllCases();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to complete case: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  /// Accept Case Flow with Availability slot picker
  Future<void> _showInlineAccept(Map<String, dynamic> c) async {
    final caseId = c['_id'].toString();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String? selectedTimeSlot;

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
      for (final activeCase in _inProgressCases) {
        if (activeCase is Map && activeCase['_id']?.toString() != caseId) {
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
              title: Row(
                children: const [
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
                      'Pick investigation start date & time slot from your saved duty availability:',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    // Date Picker
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
                          'Already booked on this date: ${bookedSlots.join(", ")}',
                          style: const TextStyle(color: AppColors.warning, fontSize: 11),
                        ),
                      ],
                    ],
                    const SizedBox(height: 14),

                    // Notification Info
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.notifications_active_outlined, color: AppColors.info, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'A notification with this investigation schedule will be automatically dispatched to the citizen.',
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
                  child: const Text('Confirm & Accept'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && selectedTimeSlot != null) {
      try {
        final formattedDateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
        await _repo.acceptPoliceCase(
          caseId,
          startDate: formattedDateStr,
          startTime: selectedTimeSlot!,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Case accepted! Investigation started & citizen notified.'),
              backgroundColor: AppColors.success,
            ),
          );
          _fetchAllCases();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to accept case: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  /// Reject / Forward Back Flow with required reason
  Future<void> _showInlineReject(Map<String, dynamic> c) async {
    final caseId = c['_id'].toString();
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.assignment_return_outlined, color: AppColors.error),
            SizedBox(width: 8),
            Text(
              'Forward Back to Admin',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please provide a reason for declining. This case will be returned to the admin pool for reassignment.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Enter reason (e.g. Jurisdiction conflict, heavy caseload, outside division)...',
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Please enter a decline reason' : null,
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
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Send to Admin'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repo.rejectPoliceCase(caseId, reason: reasonController.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Case declined and forwarded back to admin.'),
              backgroundColor: AppColors.warning,
            ),
          );
          _fetchAllCases();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to decline case: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateVal.toString()).toLocal();
      return DateFormat('MMM dd, yyyy').format(dt);
    } catch (_) {
      return dateVal.toString();
    }
  }

  Widget _buildBadge(String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        count,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: AppColors.surface,
      child: TextField(
        controller: _searchCtrl,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search by Citizen Name / NIC / Title / ID...',
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.accent, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.primaryDark,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.accent),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredPending = _filterList(_pendingCases);
    final filteredInProgress = _filterList(_inProgressCases);
    final filteredCompleted = _filterList(_completedCases);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('View Cases'),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _fetchAllCases,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textMuted,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Pending'),
                  if (_pendingCases.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _buildBadge('${_pendingCases.length}', AppColors.warning),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('To-Do'),
                  if (_inProgressCases.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _buildBadge('${_inProgressCases.length}', AppColors.info),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Completed'),
                  if (_completedCases.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _buildBadge('${_completedCases.length}', AppColors.success),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 🔍 Search + Filter bar across all tabs
                _buildSearchBar(),

                // Active tab view
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPendingList(filteredPending),
                      _buildInProgressList(filteredInProgress),
                      _buildCompletedList(filteredCompleted),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  🕓 Pending Tab
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPendingList(List<dynamic> casesList) {
    if (casesList.isEmpty) {
      return _buildEmptyState(
        icon: Icons.assignment_outlined,
        title: _searchQuery.isNotEmpty ? 'No Matching Cases' : 'No Pending Cases',
        subtitle: _searchQuery.isNotEmpty
            ? 'No pending cases match "$_searchQuery"'
            : 'New cases assigned to you by the admin will appear here for review.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchCasesForTab(0),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: casesList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, idx) {
          final c = Map<String, dynamic>.from(casesList[idx] as Map);
          final reportedBy = c['reportedBy'] as Map<String, dynamic>? ?? {};
          final profile = reportedBy['profile'] as Map<String, dynamic>? ?? {};

          final citizenName = profile['fullName']?.toString().isNotEmpty == true
              ? profile['fullName']
              : (reportedBy['alias']?.toString() ?? 'Citizen (Anonymous)');
          final nic = profile['nic']?.toString().isNotEmpty == true
              ? profile['nic'].toString()
              : 'Not provided';
          final caseTitle = c['title']?.toString() ?? 'Untitled Case';
          final refNum = c['referenceNumber']?.toString() ?? 'N/A';

          final locRaw = c['location'];
          final loc = locRaw is Map ? Map<String, dynamic>.from(locRaw) : <String, dynamic>{};
          final districtLocation = [loc['city'], loc['state'], profile['district']]
              .where((s) => s != null && s.toString().trim().isNotEmpty)
              .firstOrNull ??
              'Sri Lanka';

          final dateAssigned = _formatDate(c['assignedToPoliceAt'] ?? c['createdAt']);

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Ref & Status Badge -> Pending Review
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      refNum,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.hourglass_empty_rounded, size: 12, color: AppColors.warning),
                          SizedBox(width: 4),
                          Text(
                            'Pending Review',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Case Title
                Text(
                  caseTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Citizen Name
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      citizenName,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // NIC
                Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 16, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      'NIC: $nic',
                      style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // District / Location
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      districtLocation.toString(),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Date assigned
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Assigned: $dateAssigned',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Row Action: View Details button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final updated = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OfficerCaseDetailScreen(
                            caseId: c['_id'].toString(),
                            initialCase: c,
                          ),
                        ),
                      );
                      if (updated == true) _fetchAllCases();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Inline shortcut buttons: Accept / Reject
                Row(
                  children: [
                    // Reject Shortcut
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showInlineReject(c),
                        icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                        label: const Text('Reject', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Accept Shortcut
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showInlineAccept(c),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  🚧 To-Do Tab (Active work)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildInProgressList(List<dynamic> casesList) {
    if (casesList.isEmpty) {
      return _buildEmptyState(
        icon: Icons.pending_actions_rounded,
        title: _searchQuery.isNotEmpty ? 'No Matching Cases' : 'No To-Do Cases',
        subtitle: _searchQuery.isNotEmpty
            ? 'No To-Do cases match "$_searchQuery"'
            : 'Cases you accept will appear here for active investigation.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchCasesForTab(1),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: casesList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, idx) {
          final c = Map<String, dynamic>.from(casesList[idx] as Map);
          final caseId = c['_id'].toString();
          final reportedBy = c['reportedBy'] as Map<String, dynamic>? ?? {};
          final profile = reportedBy['profile'] as Map<String, dynamic>? ?? {};

          final citizenName = profile['fullName']?.toString().isNotEmpty == true
              ? profile['fullName']
              : (reportedBy['alias']?.toString() ?? 'Citizen (Anonymous)');
          final nic = profile['nic']?.toString().isNotEmpty == true
              ? profile['nic'].toString()
              : 'Not provided';
          final email = reportedBy['email']?.toString() ?? 'Not provided';
          final phone = profile['phone']?.toString() ?? 'Not provided';
          final caseTitle = c['title']?.toString() ?? 'Untitled Case';
          final refNum = c['referenceNumber']?.toString() ?? 'N/A';

          final locRaw = c['location'];
          final loc = locRaw is Map ? Map<String, dynamic>.from(locRaw) : <String, dynamic>{};
          final locationText = [loc['city'], loc['state'], profile['district']]
              .where((s) => s != null && s.toString().trim().isNotEmpty)
              .firstOrNull ??
              'Sri Lanka';

          final startDateStr = _formatDate(c['investigationStartDate']);
          final startTimeStr = c['investigationStartTime']?.toString() ?? 'Scheduled';
          final currentStatus = c['status']?.toString() ?? 'in_progress_police';

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Ref & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      refNum,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.info.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.autorenew_rounded, size: 12, color: AppColors.info),
                          SizedBox(width: 4),
                          Text(
                            'In Progress',
                            style: TextStyle(
                              color: AppColors.info,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Case Title
                Text(
                  caseTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Citizen Name
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      citizenName,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // NIC
                Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 16, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      'NIC: $nic',
                      style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Location / District
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(locationText.toString(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),

                // Start Date + Time
                Row(
                  children: [
                    const Icon(Icons.alarm_on_rounded, size: 14, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      'Start: $startDateStr • $startTimeStr',
                      style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Contact info block
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              email,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              phone,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Update Status Dropdown
                Row(
                  children: [
                    const Text('Status Stage: ',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: ['investigating', 'suspect_identified', 'referred_to_court', 'closed'].contains(currentStatus)
                                ? currentStatus
                                : 'investigating',
                            isExpanded: true,
                            dropdownColor: AppColors.primaryDark,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                            items: const [
                              DropdownMenuItem(value: 'investigating', child: Text('Investigating')),
                              DropdownMenuItem(value: 'suspect_identified', child: Text('Suspect Identified')),
                              DropdownMenuItem(value: 'referred_to_court', child: Text('Referred to Court')),
                              DropdownMenuItem(value: 'closed', child: Text('Closed')),
                            ],
                            onChanged: (newStage) {
                              if (newStage != null && newStage != currentStatus) {
                                _updateStage(caseId, newStage);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Row Actions: View Details + Mark as Completed
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final updated = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OfficerCaseDetailScreen(
                                caseId: caseId,
                                initialCase: c,
                              ),
                            ),
                          );
                          if (updated == true) _fetchAllCases();
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.accent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('View Details', style: TextStyle(color: AppColors.accent)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _markCompleted(caseId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Mark Completed', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  ✅ Completed Tab
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCompletedList(List<dynamic> casesList) {
    if (casesList.isEmpty) {
      return _buildEmptyState(
        icon: Icons.task_alt_rounded,
        title: _searchQuery.isNotEmpty ? 'No Matching Cases' : 'No Completed Cases',
        subtitle: _searchQuery.isNotEmpty
            ? 'No completed cases match "$_searchQuery"'
            : 'Investigations you finish will be safely archived here.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchCasesForTab(2),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: casesList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, idx) {
          final c = Map<String, dynamic>.from(casesList[idx] as Map);
          final reportedBy = c['reportedBy'] as Map<String, dynamic>? ?? {};
          final profile = reportedBy['profile'] as Map<String, dynamic>? ?? {};

          final citizenName = profile['fullName']?.toString().isNotEmpty == true
              ? profile['fullName']
              : (reportedBy['alias']?.toString() ?? 'Citizen (Anonymous)');
          final caseTitle = c['title']?.toString() ?? 'Untitled Case';
          final refNum = c['referenceNumber']?.toString() ?? 'N/A';
          final dateCompleted = _formatDate(c['completedAt'] ?? c['updatedAt']);

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Ref & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      refNum,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 12, color: AppColors.success),
                          SizedBox(width: 4),
                          Text(
                            'Completed',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Case Title
                Text(
                  caseTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Citizen Name
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      citizenName,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Date completed
                Row(
                  children: [
                    const Icon(Icons.event_available_outlined, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Completed: $dateCompleted',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // View Details button (read-only)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OfficerCaseDetailScreen(
                            caseId: c['_id'].toString(),
                            initialCase: c,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.accent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text(
                      'View Details (Read-only)',
                      style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
