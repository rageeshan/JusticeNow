import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/case_report_pdf_service.dart';
import '../../../providers/auth_provider.dart';

class AdminExportDataScreen extends ConsumerStatefulWidget {
  const AdminExportDataScreen({super.key});

  @override
  ConsumerState<AdminExportDataScreen> createState() => _AdminExportDataScreenState();
}

class _AdminExportDataScreenState extends ConsumerState<AdminExportDataScreen> {
  // Filters
  String _selectedTimeRange = 'all';
  String _selectedProvince = 'All';
  String _selectedDistrict = 'All';
  String _selectedStatus = 'All';
  String _selectedSortBy = 'date_desc';
  final TextEditingController _searchCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isExportingPdf = false;
  List<Map<String, dynamic>> _cases = [];
  String? _errorMessage;

  static const List<Map<String, String>> _timeRangeOptions = [
    {'code': 'all', 'label': 'All Time'},
    {'code': 'today', 'label': 'Today'},
    {'code': 'this_week', 'label': 'This Week'},
    {'code': 'last_week', 'label': 'Last Week'},
    {'code': 'this_month', 'label': 'This Month'},
    {'code': 'last_month', 'label': 'Last Month'},
    {'code': 'last_3_months', 'label': 'Last 3 Months'},
  ];

  static const List<String> _provinces = [
    'All',
    'Western',
    'Central',
    'Southern',
    'Northern',
    'Eastern',
    'North Western',
    'North Central',
    'Uva',
    'Sabaragamuwa',
  ];

  static const List<String> _districts = [
    'All',
    'Ampara',
    'Anuradhapura',
    'Badulla',
    'Batticaloa',
    'Colombo',
    'Galle',
    'Gampaha',
    'Hambantota',
    'Jaffna',
    'Kalutara',
    'Kandy',
    'Kegalle',
    'Kilinochchi',
    'Kurunegala',
    'Mannar',
    'Matale',
    'Matara',
    'Monaragala',
    'Mullaitivu',
    'Nuwara Eliya',
    'Polonnaruwa',
    'Puttalam',
    'Ratnapura',
    'Trincomalee',
    'Vavuniya',
  ];

  static const List<Map<String, String>> _statusOptions = [
    {'code': 'All', 'label': 'All Statuses'},
    {'code': 'submitted', 'label': 'Submitted'},
    {'code': 'under_review', 'label': 'Under Review'},
    {'code': 'investigating', 'label': 'Investigating'},
    {'code': 'awaiting_lawyer_selection', 'label': 'Awaiting Lawyer'},
    {'code': 'approved_scheduled', 'label': 'Scheduled'},
    {'code': 'in_progress', 'label': 'In Progress'},
    {'code': 'completed', 'label': 'Completed'},
    {'code': 'rejected', 'label': 'Rejected'},
  ];

  static const List<Map<String, String>> _sortOptions = [
    {'code': 'date_desc', 'label': 'Date (Newest First)'},
    {'code': 'date_asc', 'label': 'Date (Oldest First)'},
    {'code': 'location', 'label': 'Location (A–Z)'},
    {'code': 'age_asc', 'label': 'People Age (Youngest First)'},
    {'code': 'age_desc', 'label': 'People Age (Oldest First)'},
    {'code': 'title', 'label': 'Case Title (A–Z)'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchData();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      final res = await repo.getExportCases(
        timeRange: _selectedTimeRange,
        province: _selectedProvince,
        district: _selectedDistrict,
        status: _selectedStatus,
        sortBy: _selectedSortBy,
        search: _searchCtrl.text.trim(),
      );

      final rawList = res['cases'] as List<dynamic>? ?? [];
      final list = rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      if (mounted) {
        setState(() {
          _cases = list;
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

  Future<void> _exportPdf() async {
    if (_cases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.warning,
          content: Text('No cases to export with the selected filters.'),
        ),
      );
      return;
    }

    setState(() => _isExportingPdf = true);

    try {
      final authState = ref.read(authProvider);
      final adminName = authState.user?['profile']?['fullName'] ?? 'Admin Officer';

      final timeRangeLabel = _timeRangeOptions.firstWhere(
        (o) => o['code'] == _selectedTimeRange,
        orElse: () => {'label': _selectedTimeRange},
      )['label']!;

      final statusLabel = _statusOptions.firstWhere(
        (o) => o['code'] == _selectedStatus,
        orElse: () => {'label': _selectedStatus},
      )['label']!;

      final sortLabel = _sortOptions.firstWhere(
        (o) => o['code'] == _selectedSortBy,
        orElse: () => {'label': _selectedSortBy},
      )['label']!;

      await CaseReportPdfService.exportCasesPdf(
        cases: _cases,
        timeRangeLabel: timeRangeLabel,
        provinceLabel: _selectedProvince,
        districtLabel: _selectedDistrict,
        statusLabel: statusLabel,
        sortByLabel: sortLabel,
        adminName: adminName,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('PDF generation error: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExportingPdf = false);
      }
    }
  }

  String _formatDateTime(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr.toString()).toLocal();
      return DateFormat('MMM dd, yyyy • hh:mm a').format(dt);
    } catch (_) {
      return dateStr.toString();
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'completed':
      case 'resolved':
        return AppColors.success;
      case 'rejected':
      case 'lawyer_declined':
        return AppColors.error;
      case 'awaiting_lawyer_selection':
      case 'waiting_for_lawyer_approval':
      case 'approved_scheduled':
        return AppColors.accent;
      case 'in_progress':
      case 'investigating':
      case 'under_review':
        return AppColors.warning;
      case 'submitted':
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final knownAgeCount = _cases.where((c) => c['personAge'] != null).length;
    final avgAge = knownAgeCount > 0
        ? (_cases.where((c) => c['personAge'] != null).map((c) => c['personAge'] as num).reduce((a, b) => a + b) /
                knownAgeCount)
            .toStringAsFixed(1)
        : 'N/A';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Export Data & Reports'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Data',
            onPressed: _fetchData,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: (_isLoading || _isExportingPdf || _cases.isEmpty) ? null : _exportPdf,
            icon: _isExportingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.picture_as_pdf_rounded, size: 22),
            label: Text(
              _isExportingPdf ? 'Generating PDF Document...' : 'Export to PDF (${_cases.length} Cases)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.surfaceVariant,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header description card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [AppColors.cardShadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.analytics_rounded, color: AppColors.primary, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'DATA EXPORT & PDF GENERATOR',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Filter cases by locations, provinces, date ranges, and people demographics. Preview matching records live and generate formatted PDF intelligence reports.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Filter Controls Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [AppColors.cardShadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.filter_list_rounded, color: AppColors.accent, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Filter & Sort Options',
                          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedTimeRange = 'all';
                              _selectedProvince = 'All';
                              _selectedDistrict = 'All';
                              _selectedStatus = 'All';
                              _selectedSortBy = 'date_desc';
                              _searchCtrl.clear();
                            });
                            _fetchData();
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Reset All', style: TextStyle(color: AppColors.accent, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Time Range Selector
                    const Text('TIME RANGE', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _timeRangeOptions.map((opt) {
                          final isSelected = _selectedTimeRange == opt['code'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(opt['label']!),
                              selected: isSelected,
                              selectedColor: AppColors.accent,
                              backgroundColor: AppColors.surfaceVariant,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: isSelected ? AppColors.accent : AppColors.border),
                              ),
                              onSelected: (val) {
                                if (val) {
                                  setState(() => _selectedTimeRange = opt['code']!);
                                  _fetchData();
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Province & District Row
                    Row(
                      children: [
                        // Province Dropdown
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PROVINCE', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedProvince,
                                    isExpanded: true,
                                    dropdownColor: AppColors.surface,
                                    items: _provinces
                                        .map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _selectedProvince = val);
                                        _fetchData();
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // District Dropdown
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DISTRICT', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedDistrict,
                                    isExpanded: true,
                                    dropdownColor: AppColors.surface,
                                    items: _districts
                                        .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _selectedDistrict = val);
                                        _fetchData();
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Status & Sort By Row
                    Row(
                      children: [
                        // Status Dropdown
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('STATUS', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedStatus,
                                    isExpanded: true,
                                    dropdownColor: AppColors.surface,
                                    items: _statusOptions
                                        .map((s) => DropdownMenuItem(value: s['code'], child: Text(s['label']!, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _selectedStatus = val);
                                        _fetchData();
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Sort By Dropdown
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('SORT BY', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedSortBy,
                                    isExpanded: true,
                                    dropdownColor: AppColors.surface,
                                    items: _sortOptions
                                        .map((s) => DropdownMenuItem(value: s['code'], child: Text(s['label']!, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _selectedSortBy = val);
                                        _fetchData();
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Search Location or Title input
                    TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search city, location keywords, case title...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  _fetchData();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                      onSubmitted: (_) => _fetchData(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Summary Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Matching Cases',
                      value: '${_cases.length}',
                      icon: Icons.folder_rounded,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Avg Citizen Age',
                      value: avgAge,
                      icon: Icons.people_outline_rounded,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'With Known Age',
                      value: '$knownAgeCount / ${_cases.length}',
                      icon: Icons.badge_outlined,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Live Preview Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.preview_rounded, color: AppColors.accent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'REPORT PREVIEW (${_cases.length} RECORDS)',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                      ),
                    ],
                  ),
                  if (!_isLoading && _cases.isNotEmpty)
                    Text(
                      'Ready to Export',
                      style: TextStyle(color: AppColors.success.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // State handling: loading / error / empty / list
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 36),
                      const SizedBox(height: 8),
                      Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _fetchData, child: const Text('Retry')),
                    ],
                  ),
                )
              else if (_cases.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.inbox_rounded, color: AppColors.textMuted, size: 48),
                        SizedBox(height: 12),
                        Text(
                          'No cases found for the selected filters',
                          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Try selecting "All Time" or "All Provinces" to broaden the report scope.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _cases.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final c = _cases[idx];
                    final refNum = c['referenceNumber'] ?? 'N/A';
                    final title = c['title'] ?? 'Untitled Case';
                    final personName = c['personName'] ?? 'Anonymous';
                    final personAge = c['personAge'];
                    final fullLoc = c['fullLocation'] ?? 'Location not specified';
                    final province = c['province'] ?? 'Unspecified';
                    final status = c['status'] as String? ?? 'submitted';
                    final incidentDate = c['incidentDate'] ?? c['createdAt'];

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [AppColors.cardShadow],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Ref number & status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceBlue,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.borderBlue),
                                ),
                                child: Text(
                                  refNum,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(status).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status.replaceAll('_', ' ').toUpperCase(),
                                  style: TextStyle(
                                    color: _statusColor(status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Title
                          Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Person Details & Age
                          Row(
                            children: [
                              const Icon(Icons.person_rounded, size: 16, color: AppColors.textMuted),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  personName,
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: personAge != null ? AppColors.info.withValues(alpha: 0.15) : AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  personAge != null ? 'Age: $personAge yrs' : 'Age: N/A',
                                  style: TextStyle(
                                    color: personAge != null ? AppColors.info : AppColors.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Location
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on_rounded, size: 16, color: AppColors.accent),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  fullLoc,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ),
                              if (province.isNotEmpty && province != 'Unspecified') ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    province,
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Date
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 6),
                              Text(
                                _formatDateTime(incidentDate),
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [AppColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}
