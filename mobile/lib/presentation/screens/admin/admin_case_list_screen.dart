import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/case_repository.dart';

class AdminCaseListScreen extends StatefulWidget {
  const AdminCaseListScreen({super.key});

  @override
  State<AdminCaseListScreen> createState() => _AdminCaseListScreenState();
}

class _AdminCaseListScreenState extends State<AdminCaseListScreen> {
  final CaseRepository _caseRepo = CaseRepository();
  final TextEditingController _searchCtrl = TextEditingController();

  List<dynamic> _cases = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filter tabs / sort: Today | This Week | Last Week | This Month | Last Month | All
  final List<String> _dateFilters = [
    'Today',
    'This Week',
    'Last Week',
    'This Month',
    'Last Month',
    'All',
  ];
  String _selectedDateFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchCases();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _mapFilterToParam(String filter) {
    switch (filter) {
      case 'Today':
        return 'today';
      case 'This Week':
        return 'this_week';
      case 'Last Week':
        return 'last_week';
      case 'This Month':
        return 'this_month';
      case 'Last Month':
        return 'last_month';
      case 'All':
      default:
        return 'all';
    }
  }

  Future<void> _fetchCases() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final search = _searchCtrl.text.trim();
    final dateParam = _mapFilterToParam(_selectedDateFilter);

    try {
      final res = await _caseRepo.getCases(
        search: search.isNotEmpty ? search : null,
        dateFilter: dateParam,
      );
      if (mounted) {
        setState(() {
          _cases = (res['cases'] as List<dynamic>?) ?? [];
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'awaiting_lawyer_selection':
        return AppColors.accent;
      case 'rejected':
        return AppColors.error;
      case 'resolved':
      case 'closed':
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
    if (status == null) return 'SUBMITTED';
    if (status == 'awaiting_lawyer_selection') return 'AWAITING LAWYER';
    return status.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Case Reports'),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _fetchCases,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Top Bar: Search & Filter Tabs ──
          Container(
            color: AppColors.primaryDark,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Input
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search by case title or reference...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _fetchCases();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  onSubmitted: (_) => _fetchCases(),
                ),
                const SizedBox(height: 12),

                // Filter Tabs (Horizontal scrollable chips)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _dateFilters.map((filter) {
                      final isSelected = _selectedDateFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.accent,
                          backgroundColor: AppColors.surface,
                          side: BorderSide(
                            color: isSelected ? AppColors.accent : AppColors.border,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedDateFilter = filter);
                              _fetchCases();
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ── List of Cases ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                              const SizedBox(height: 12),
                              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _fetchCases, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      )
                    : _cases.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.folder_open_rounded, color: AppColors.textMuted, size: 64),
                                const SizedBox(height: 16),
                                const Text(
                                  'No case reports found',
                                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _searchCtrl.text.isNotEmpty || _selectedDateFilter != 'All'
                                      ? 'No cases match "$_selectedDateFilter" filter'
                                      : 'No reports have been submitted yet.',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchCases,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _cases.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final c = _cases[index] as Map<String, dynamic>;
                                final caseId = c['_id'] as String;
                                final title = c['title'] ?? 'Incident Report';
                                final createdAt = c['createdAt'] as String?;
                                final status = c['status'] as String?;
                                final refNumber = c['referenceNumber'] ?? '';

                                // Citizen Info
                                final reportedBy = c['reportedBy'] as Map<String, dynamic>? ?? {};
                                final profile = reportedBy['profile'] as Map<String, dynamic>? ?? {};
                                final citizenName = profile['fullName'] ?? reportedBy['alias'] ?? 'Anonymous Citizen';
                                final citizenNIC = profile['nic'] ?? 'Not provided';

                                return Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header Row: Reference number & Status Badge
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              refNumber,
                                              style: const TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 12,
                                                fontFamily: 'monospace',
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: _statusColor(status).withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: _statusColor(status).withValues(alpha: 0.35)),
                                              ),
                                              child: Text(
                                                _statusLabel(status),
                                                style: TextStyle(
                                                  color: _statusColor(status),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),

                                        // ── 1. Citizen's Name ──
                                        Row(
                                          children: [
                                            const Icon(Icons.person_outline_rounded, color: AppColors.accent, size: 16),
                                            const SizedBox(width: 8),
                                            const Text(
                                              "Citizen: ",
                                              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                                            ),
                                            Expanded(
                                              child: Text(
                                                citizenName,
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),

                                        // ── 2. Citizen's NIC ──
                                        Row(
                                          children: [
                                            const Icon(Icons.badge_outlined, color: AppColors.info, size: 16),
                                            const SizedBox(width: 8),
                                            const Text(
                                              "NIC: ",
                                              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                                            ),
                                            Text(
                                              citizenNIC,
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),

                                        // ── 3. Date submitted ──
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today_rounded, color: AppColors.textMuted, size: 15),
                                            const SizedBox(width: 8),
                                            const Text(
                                              "Submitted: ",
                                              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                                            ),
                                            Text(
                                              _formatDate(createdAt),
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),

                                        // ── 4. Report title (short summary, 1 line) ──
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceVariant,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            title,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(height: 14),

                                        const Divider(height: 1, color: AppColors.border),
                                        const SizedBox(height: 12),

                                        // ── 5. View Case Details button ──
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () async {
                                              await context.push(
                                                '${AppRoutes.adminCases}/$caseId',
                                                extra: c,
                                              );
                                              if (mounted) _fetchCases();
                                            },
                                            icon: const Icon(Icons.visibility_rounded, size: 16),
                                            label: const Text('View Case Details'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primaryDark,
                                              foregroundColor: AppColors.accent,
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                side: const BorderSide(color: AppColors.accent),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
