import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/sri_lanka_locations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/case_repository.dart';
import '../../../data/repositories/legal_aid_repository.dart';

class LegalAidScreen extends ConsumerStatefulWidget {
  final String? caseId;

  const LegalAidScreen({super.key, this.caseId});

  @override
  ConsumerState<LegalAidScreen> createState() => _LegalAidScreenState();
}

class _LegalAidScreenState extends ConsumerState<LegalAidScreen> {
  final LegalAidRepository _legalAidRepo = LegalAidRepository();
  final CaseRepository _caseRepo = CaseRepository();

  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounceTimer;
  List<dynamic> _allLawyers = [];
  List<dynamic> _displayedLawyers = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String? _errorMessage;

  // Active Case for context
  String? _activeCaseId;
  Map<String, dynamic>? _activeCase;

  // Filter & Sorting state (All default to 'All')
  String _selectedSortBy = 'All';
  String _selectedLanguage = 'All';
  String _selectedProvince = 'All';
  String _selectedDistrict = 'All';

  final List<String> _sortOptions = ['All', 'Name (A–Z)', 'Age', 'Nearest location'];
  final List<String> _languageOptions = ['All', 'Sinhala', 'Tamil', 'English'];

  @override
  void initState() {
    super.initState();
    _activeCaseId = widget.caseId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initCitizenLocationAndLoad();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // Instant client-side filtering on all available lawyer records
    _filterLawyersLocally(query);

    // Debounced real-time server fetch to guarantee database synchronization
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fetchLawyers(silent: true);
      }
    });
  }

  void _filterLawyersLocally(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _displayedLawyers = List.from(_allLawyers);
      } else {
        _displayedLawyers = _allLawyers.where((l) {
          if (l is! Map) return false;
          final profile = l['profile'] as Map<String, dynamic>? ?? {};
          final name = (profile['fullName'] ?? l['email'] ?? '').toString().toLowerCase();
          final district = (profile['district'] ?? '').toString().toLowerCase();
          final province = (profile['province'] ?? '').toString().toLowerCase();
          final courtNo = (profile['courtNumber'] ?? profile['lawyerId'] ?? '').toString().toLowerCase();
          final about = (profile['aboutMe'] ?? '').toString().toLowerCase();
          final email = (l['email'] ?? '').toString().toLowerCase();

          return name.contains(q) ||
              district.contains(q) ||
              province.contains(q) ||
              courtNo.contains(q) ||
              about.contains(q) ||
              email.contains(q);
        }).toList();
      }
    });
  }

  Future<void> _initCitizenLocationAndLoad() async {
    // If caseId is provided, fetch the case details for booking context
    if (_activeCaseId != null && _activeCaseId!.isNotEmpty) {
      try {
        final c = await _caseRepo.getCaseById(_activeCaseId!);
        _activeCase = c;
      } catch (_) {}
    } else {
      // Find latest case awaiting lawyer selection
      try {
        final res = await _caseRepo.getMyCases();
        final cases = (res['cases'] as List<dynamic>?) ?? [];
        final pendingCase = cases.firstWhere(
          (c) =>
              c is Map &&
              (c['status'] == 'awaiting_lawyer_selection' ||
                  c['status'] == 'submitted' ||
                  c['status'] == 'under_review'),
          orElse: () => cases.isNotEmpty ? cases.first : null,
        );
        if (pendingCase != null && pendingCase is Map) {
          _activeCase = Map<String, dynamic>.from(pendingCase);
          _activeCaseId = _activeCase?['_id']?.toString();
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _selectedSortBy = 'All';
        _selectedLanguage = 'All';
        _selectedProvince = 'All';
        _selectedDistrict = 'All';
      });
      _fetchLawyers();
    }
  }

  Future<void> _fetchLawyers({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isSearching = true;
      });
    }

    try {
      final list = await _legalAidRepo.getLawyers(
        search: _searchCtrl.text,
        language: _selectedLanguage,
        province: _selectedProvince,
        district: _selectedDistrict,
        sortBy: _selectedSortBy,
      );
      if (mounted) {
        setState(() {
          _allLawyers = list;
          _isLoading = false;
          _isSearching = false;
        });
        _filterLawyersLocally(_searchCtrl.text);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (!silent) {
            _errorMessage = e.toString();
          }
          _isLoading = false;
          _isSearching = false;
        });
      }
    }
  }

  void _navigateToProfile(String lawyerId, Map<String, dynamic> lawyerData) {
    context.push(
      '/legal-aid/lawyer/$lawyerId',
      extra: {
        'lawyer': lawyerData,
        'caseId': _activeCaseId,
        'case': _activeCase,
      },
    );
  }

  void _navigateToBooking(String lawyerId, Map<String, dynamic> lawyerData) {
    context.push(
      '/legal-aid/book/$lawyerId',
      extra: {
        'lawyer': lawyerData,
        'caseId': _activeCaseId,
        'case': _activeCase,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableDistricts = _selectedProvince == 'All'
        ? <String>['All']
        : ['All', ...SriLankaLocations.getDistrictsForProvince(_selectedProvince)];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Find a Lawyer'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Lawyers',
            onPressed: _fetchLawyers,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Active Case Banner (if linked)
            if (_activeCase != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: AppColors.accent.withValues(alpha: 0.12),
                child: Row(
                  children: [
                    const Icon(Icons.gavel_rounded, color: AppColors.accent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Booking for Case: ${_activeCase?['title'] ?? _activeCase?['referenceNumber'] ?? 'Approved Report'}',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // Top Bar: Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                onChanged: _onSearchChanged,
                onSubmitted: (_) => _fetchLawyers(),
                decoration: InputDecoration(
                  hintText: 'Search by name, district, province, court no...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                          ),
                        )
                      : _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                              onPressed: () {
                                _searchCtrl.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),

            // Sorting & Filter Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Sort By Dropdown Chip
                    _buildDropdownChip<String>(
                      icon: Icons.sort_rounded,
                      labelPrefix: 'Sort',
                      value: _selectedSortBy,
                      items: _sortOptions,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedSortBy = val);
                          _fetchLawyers();
                        }
                      },
                    ),
                    const SizedBox(width: 8),

                    // Language Filter Chip
                    _buildDropdownChip<String>(
                      icon: Icons.translate_rounded,
                      labelPrefix: 'Language',
                      value: _selectedLanguage,
                      items: _languageOptions,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedLanguage = val);
                          _fetchLawyers();
                        }
                      },
                    ),
                    const SizedBox(width: 8),

                    // Province Filter Chip
                    _buildDropdownChip<String>(
                      icon: Icons.location_city_rounded,
                      labelPrefix: 'Province',
                      value: _selectedProvince,
                      items: ['All', ...SriLankaLocations.provinces],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedProvince = val;
                            _selectedDistrict = 'All';
                          });
                          _fetchLawyers();
                        }
                      },
                    ),
                    const SizedBox(width: 8),

                    // District Filter Chip
                    _buildDropdownChip<String>(
                      icon: Icons.map_outlined,
                      labelPrefix: 'District',
                      value: availableDistricts.contains(_selectedDistrict) ? _selectedDistrict : 'All',
                      items: availableDistricts,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedDistrict = val);
                          _fetchLawyers();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const Divider(color: AppColors.border, height: 16),

            // Lawyer List / Status
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  'Error loading lawyers:\n$_errorMessage',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _fetchLawyers,
                                  child: const Text('Try Again'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _displayedLawyers.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.gavel_rounded, color: AppColors.textMuted, size: 64),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No Lawyers Found',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Try adjusting your search criteria, language, or location filters.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                    ),
                                    const SizedBox(height: 16),
                                    OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          _searchCtrl.clear();
                                          _selectedLanguage = 'All';
                                          _selectedProvince = 'All';
                                          _selectedDistrict = 'All';
                                          _selectedSortBy = 'All';
                                        });
                                        _fetchLawyers();
                                      },
                                      child: const Text('Reset All Filters'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchLawyers,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                itemCount: _displayedLawyers.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final lawyer = _displayedLawyers[index] as Map<String, dynamic>;
                                  return _buildLawyerRow(lawyer);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownChip<T>({
    required IconData icon,
    required String labelPrefix,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    final isSelected = value != 'All' && value != 'Default';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.8) : AppColors.border,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: items.contains(value) ? value : items.first,
          isDense: true,
          dropdownColor: AppColors.surfaceVariant,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.accent, size: 20),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
          selectedItemBuilder: (context) {
            return items.map((item) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Text(
                    '$labelPrefix: $item',
                    style: TextStyle(
                      color: item != 'All' && item != 'Default' ? AppColors.accent : AppColors.textPrimary,
                      fontWeight: item != 'All' && item != 'Default' ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              );
            }).toList();
          },
          items: items.map((item) {
            final isDefault = item == 'All' || item == 'Default';
            return DropdownMenuItem<T>(
              value: item,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: isDefault ? AppColors.accent : AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    isDefault ? '$item (Default)' : '$item',
                    style: TextStyle(
                      color: isDefault ? AppColors.accent : AppColors.textPrimary,
                      fontWeight: isDefault ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildLawyerRow(Map<String, dynamic> lawyer) {
    final lawyerId = lawyer['_id']?.toString() ?? '';
    final profile = lawyer['profile'] as Map<String, dynamic>? ?? {};
    final name = profile['fullName'] ?? lawyer['email'] ?? 'Attorney';
    final district = profile['district'] ?? '';
    final province = profile['province'] ?? '';
    final locationText = [district, province].where((s) => s.isNotEmpty).join(', ');
    final age = lawyer['age'] ?? profile['age'] ?? 35;
    final courtNumber = profile['courtNumber'] ?? profile['lawyerId'];
    final language = profile['preferredLanguage'] ?? 'English';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        // Tapping the row itself skips profile and goes straight to Book Lawyer form
        onTap: () => _navigateToBooking(lawyerId, lawyer),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with verified badge
                  Stack(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceBlue,
                          border: Border.all(color: AppColors.borderBlue, width: 1.5),
                        ),
                        child: const Center(
                          child: Icon(Icons.person_rounded, color: AppColors.primary, size: 28),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified_rounded, color: AppColors.success, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                locationText.isNotEmpty ? locationText : 'Sri Lanka',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Age: $age',
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (courtNumber != null && courtNumber.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceBlueMuted,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'SC: $courtNumber',
                                  style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                language,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 10),

              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tap card to Book directly',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
                  ),

                  // View Details Button
                  ElevatedButton(
                    onPressed: () => _navigateToProfile(lawyerId, lawyer),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceBlue,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      side: const BorderSide(color: AppColors.borderBlue),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('View Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, size: 11),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
