import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
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
  bool _isLoading = false;
  String? _errorMessage;

  String? _selectedStatus;
  String? _selectedCategory;

  final List<String> _statuses = [
    'All',
    'submitted',
    'verified',
    'under_investigation',
    'legal_aid_assigned',
    'closed',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCases();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCases() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final search = _searchCtrl.text.trim();
    final status = _selectedStatus == null || _selectedStatus == 'All' ? null : _selectedStatus;
    final category = _selectedCategory == null || _selectedCategory == 'All' ? null : _selectedCategory;

    try {
      final res = await _caseRepo.getCases(
        search: search.isNotEmpty ? search : null,
        status: status,
        category: category,
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
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'verified':
        return AppColors.info;
      case 'under_investigation':
        return AppColors.warning;
      case 'legal_aid_assigned':
        return AppColors.accent;
      case 'closed':
        return AppColors.success;
      case 'submitted':
      default:
        return AppColors.textMuted;
    }
  }

  String _statusLabel(String? status) {
    if (status == null) return 'Submitted';
    return status.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Case Details Registry'),
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
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search cases by title, case number, or city...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
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

                // Filters Row
                Row(
                  children: [
                    // Status Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus ?? 'All',
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        dropdownColor: AppColors.surface,
                        items: _statuses.map((s) {
                          return DropdownMenuItem(value: s, child: Text(_statusLabel(s)));
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedStatus = val);
                          _fetchCases();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Category Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory ?? 'All',
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        dropdownColor: AppColors.surface,
                        items: ['All', ...AppConstants.caseCategories.values].map((String c) {
                          return DropdownMenuItem<String>(
                            value: c,
                            child: Text(
                              c == 'All' ? 'ALL CATEGORIES' : c,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedCategory = val);
                          _fetchCases();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Case List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                            const SizedBox(height: 12),
                            Text(_errorMessage!, style: const TextStyle(color: AppColors.error)),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: _fetchCases, child: const Text('Retry')),
                          ],
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
                                  'No cases found',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _searchCtrl.text.isNotEmpty
                                      ? 'Try adjusting your search filters'
                                      : 'No reported cases match the selected filters',
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
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final c = _cases[index] as Map<String, dynamic>;
                                final caseId = c['_id'] as String;
                                final title = c['title'] ?? 'Untitled Case';
                                final caseNumber = c['caseNumber'] ?? '';
                                final category = c['category'] ?? 'General Incident';
                                final status = c['status'] as String?;
                                final createdAt = c['createdAt'] as String?;
                                final location = c['location'] as Map<String, dynamic>? ?? {};
                                final city = location['city'] ?? 'Location not specified';

                                final statusCol = _statusColor(status);

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      context.push('/cases/$caseId');
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Top Row: Category & Status Badge
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  category,
                                                  style: const TextStyle(
                                                    color: AppColors.accent,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: statusCol.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: statusCol.withValues(alpha: 0.4)),
                                                ),
                                                child: Text(
                                                  _statusLabel(status),
                                                  style: TextStyle(
                                                    color: statusCol,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),

                                          // Case Title
                                          Text(
                                            title,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),

                                          // Case Number & Location
                                          Row(
                                            children: [
                                              if (caseNumber.isNotEmpty) ...[
                                                Text(
                                                  caseNumber,
                                                  style: const TextStyle(
                                                    color: AppColors.textMuted,
                                                    fontSize: 12,
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                const Text('•', style: TextStyle(color: AppColors.textMuted)),
                                                const SizedBox(width: 8),
                                              ],
                                              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  city,
                                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          const Divider(height: 1, color: AppColors.border),
                                          const SizedBox(height: 8),

                                          // Date Submitted & Arrow
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Reported: ${_formatDate(createdAt)}',
                                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                              ),
                                              const Row(
                                                children: [
                                                  Text(
                                                    'View Full Details',
                                                    style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600),
                                                  ),
                                                  SizedBox(width: 4),
                                                  Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.accent),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
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
