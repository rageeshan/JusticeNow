import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/api_service.dart';

class AdminOfficerSelectionScreen extends StatefulWidget {
  final String caseId;
  final Map<String, dynamic> caseData;

  const AdminOfficerSelectionScreen({
    super.key,
    required this.caseId,
    required this.caseData,
  });

  @override
  State<AdminOfficerSelectionScreen> createState() =>
      _AdminOfficerSelectionScreenState();
}

class _AdminOfficerSelectionScreenState
    extends State<AdminOfficerSelectionScreen> {
  bool _isLoading = true;
  bool _isAssigning = false;
  String _searchQuery = '';
  String _sortBy = 'fewest_cases'; // fewest_cases, name, age, most_available

  List<dynamic> _officers = [];
  String _targetProvince = '';
  String _targetDistrict = '';

  @override
  void initState() {
    super.initState();
    _extractCaseLocation();
    _fetchOfficers();
  }

  void _extractCaseLocation() {
    final reportedBy = widget.caseData['reportedBy'];
    final profile = reportedBy is Map ? (reportedBy['profile'] as Map? ?? {}) : {};
    final location = widget.caseData['location'] as Map? ?? {};

    _targetProvince = (profile['province'] ?? location['state'] ?? 'Western').toString();
    _targetDistrict = (profile['district'] ?? location['city'] ?? 'Colombo').toString();
  }

  String get _actualCaseId => widget.caseData['_id']?.toString() ?? widget.caseId;

  Future<void> _fetchOfficers() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.instance.client.get(
        '/cases/$_actualCaseId/officers-available',
        queryParameters: {
          'sortBy': _sortBy,
          if (_targetProvince.isNotEmpty) 'province': _targetProvince,
          if (_targetDistrict.isNotEmpty) 'district': _targetDistrict,
        },
      );

      final data = response.data['data'];
      if (data is Map && mounted) {
        setState(() {
          _officers = (data['officers'] as List<dynamic>?) ?? [];
          if (data['targetProvince'] != null) {
            _targetProvince = data['targetProvince'].toString();
          }
          if (data['targetDistrict'] != null) {
            _targetDistrict = data['targetDistrict'].toString();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load officers: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  List<dynamic> get _filteredOfficers {
    if (_searchQuery.trim().isEmpty) return _officers;
    final q = _searchQuery.trim().toLowerCase();
    return _officers.where((item) {
      if (item is! Map) return false;
      final name = (item['name'] ?? '').toString().toLowerCase();
      final policeId = (item['policeId'] ?? '').toString().toLowerCase();
      final district = (item['district'] ?? '').toString().toLowerCase();
      return name.contains(q) || policeId.contains(q) || district.contains(q);
    }).toList();
  }

  Future<void> _confirmAndAssign(Map<String, dynamic> officer) async {
    final officerName = officer['name'] ?? 'Officer';
    final district = officer['district'] ?? _targetDistrict;
    final pendingCases = officer['pendingCasesCount'] ?? 0;
    final officerId = officer['_id']?.toString() ?? '';

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.local_police_rounded, color: AppColors.accent, size: 24),
            SizedBox(width: 10),
            Text(
              'Confirm Police Assignment',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assign case to $officerName?',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('District:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Text(district, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Current pending cases:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: pendingCases == 0
                              ? AppColors.success.withValues(alpha: 0.15)
                              : pendingCases <= 2
                                  ? AppColors.warning.withValues(alpha: 0.15)
                                  : AppColors.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$pendingCases ${pendingCases == 1 ? "case" : "cases"}',
                          style: TextStyle(
                            color: pendingCases == 0
                                ? AppColors.success
                                : pendingCases <= 2
                                    ? AppColors.warning
                                    : AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This officer will be notified and will review the case in their Pending queue.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isAssigning = true);
      try {
        await ApiService.instance.client.patch(
          '/cases/$_actualCaseId/assign-officer',
          data: {'officerId': officerId},
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Case assigned to $officerName! Officer & Citizen notified.'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isAssigning = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to assign officer: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final caseTitle = widget.caseData['title'] ?? 'Incident Report';
    final refNum = widget.caseData['referenceNumber'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Assign to Police Officer'),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Auto-Filtered Location Banner ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.location_on_rounded, color: AppColors.accent, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              caseTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (refNum.isNotEmpty)
                              Text(
                                refNum,
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Jurisdiction pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Auto-filtered: Showing approved officers in $_targetDistrict, $_targetProvince',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Search & Sort Control Bar ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: AppColors.surfaceVariant.withValues(alpha: 0.3),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search by officer name or police ID...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                      filled: true,
                      fillColor: AppColors.primaryDark,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Sort By Selector
                  Row(
                    children: [
                      const Icon(Icons.sort_rounded, size: 16, color: AppColors.accent),
                      const SizedBox(width: 6),
                      const Text(
                        'Sort by:',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
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
                              value: _sortBy,
                              isExpanded: true,
                              dropdownColor: AppColors.primaryDark,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                              items: const [
                                DropdownMenuItem(
                                  value: 'fewest_cases',
                                  child: Text('Fewest Pending Cases (Balanced Load)'),
                                ),
                                DropdownMenuItem(
                                  value: 'name',
                                  child: Text('Name (A–Z)'),
                                ),
                                DropdownMenuItem(
                                  value: 'age',
                                  child: Text('Age (Youngest First)'),
                                ),
                                DropdownMenuItem(
                                  value: 'most_available',
                                  child: Text('Most Available Duty Slots'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _sortBy = val);
                                  _fetchOfficers();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Officers List ──
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredOfficers.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.person_search_rounded, size: 48, color: AppColors.textMuted),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No police officers match "$_searchQuery"'
                                      : 'No approved police officers found in $_targetDistrict, $_targetProvince',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _targetProvince = '';
                                      _targetDistrict = '';
                                    });
                                    _fetchOfficers();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.accent,
                                    side: const BorderSide(color: AppColors.accent),
                                  ),
                                  child: const Text('Show All Approved Officers'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredOfficers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final officer = Map<String, dynamic>.from(_filteredOfficers[index] as Map);
                            final name = officer['name'] ?? 'Police Officer';
                            final age = officer['age'] != null ? '${officer["age"]} yrs' : 'N/A';
                            final aboutMe = (officer['aboutMe'] ?? '').toString();
                            final availability = officer['availability'] ?? 'Mon–Fri, 08:00 AM – 04:00 PM';
                            final pendingCases = officer['pendingCasesCount'] ?? 0;
                            final district = officer['district'] ?? '';
                            final policeId = officer['policeId'] ?? 'PO-OFFICER';

                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row 1: Avatar, Name, Age, Pending Badge
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                                          child: const Icon(Icons.local_police_rounded, color: AppColors.accent, size: 24),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      name,
                                                      style: const TextStyle(
                                                        color: AppColors.textPrimary,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.surfaceVariant,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      age,
                                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'ID: $policeId • $district',
                                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Pending Cases Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: pendingCases == 0
                                                ? AppColors.success.withValues(alpha: 0.15)
                                                : pendingCases <= 2
                                                    ? AppColors.warning.withValues(alpha: 0.15)
                                                    : AppColors.error.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: pendingCases == 0
                                                  ? AppColors.success.withValues(alpha: 0.3)
                                                  : pendingCases <= 2
                                                      ? AppColors.warning.withValues(alpha: 0.3)
                                                      : AppColors.error.withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                '$pendingCases',
                                                style: TextStyle(
                                                  color: pendingCases == 0
                                                      ? AppColors.success
                                                      : pendingCases <= 2
                                                          ? AppColors.warning
                                                          : AppColors.error,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                'Pending',
                                                style: TextStyle(
                                                  color: pendingCases == 0
                                                      ? AppColors.success
                                                      : pendingCases <= 2
                                                          ? AppColors.warning
                                                          : AppColors.error,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Row 2: About Me Preview
                                    if (aboutMe.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        aboutMe,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 12),
                                    const Divider(color: AppColors.divider, height: 1),
                                    const SizedBox(height: 12),

                                    // Row 3: Availability & Assign Button
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              const Icon(Icons.schedule_rounded, size: 14, color: AppColors.accent),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  availability,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: AppColors.textPrimary,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        ElevatedButton.icon(
                                          onPressed: _isAssigning ? null : () => _confirmAndAssign(officer),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.accent,
                                            foregroundColor: AppColors.primaryDark,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          icon: const Icon(Icons.assignment_ind_rounded, size: 16),
                                          label: const Text(
                                            'Assign',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
