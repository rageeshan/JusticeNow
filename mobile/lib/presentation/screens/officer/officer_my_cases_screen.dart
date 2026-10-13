import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/officer_cases_provider.dart';
import '../../widgets/officer/officer_case_card.dart';

class OfficerMyCasesScreen extends ConsumerStatefulWidget {
  const OfficerMyCasesScreen({super.key});

  @override
  ConsumerState<OfficerMyCasesScreen> createState() => _OfficerMyCasesScreenState();
}

class _OfficerMyCasesScreenState extends ConsumerState<OfficerMyCasesScreen> {
  late final TextEditingController _searchCtrl;

  static const _statusFilters = [
    ('all', 'All'),
    ('submitted', 'New'),
    ('under_review', 'Under Review'),
    ('investigating', 'Investigating'),
    ('evidence_requested', 'Evidence Req'),
    ('resolved', 'Resolved'),
    ('closed', 'Closed'),
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: ref.read(officerSearchQueryProvider));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final curPriority = ref.watch(officerPriorityFilterProvider);
            final curCategory = ref.watch(officerCategoryFilterProvider);

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Inquiries',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(officerPriorityFilterProvider.notifier).state = 'all';
                          ref.read(officerCategoryFilterProvider.notifier).state = 'all';
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'Reset',
                          style: TextStyle(color: AppColors.accent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'PRIORITY',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _FilterPill(
                        label: 'All Priorities',
                        selected: curPriority == 'all',
                        onTap: () => ref.read(officerPriorityFilterProvider.notifier).state = 'all',
                      ),
                      _FilterPill(
                        label: 'Critical',
                        selected: curPriority == 'critical',
                        color: AppColors.error,
                        onTap: () => ref.read(officerPriorityFilterProvider.notifier).state = 'critical',
                      ),
                      _FilterPill(
                        label: 'High',
                        selected: curPriority == 'high',
                        color: const Color(0xFFF97316),
                        onTap: () => ref.read(officerPriorityFilterProvider.notifier).state = 'high',
                      ),
                      _FilterPill(
                        label: 'Medium',
                        selected: curPriority == 'medium',
                        color: AppColors.warning,
                        onTap: () => ref.read(officerPriorityFilterProvider.notifier).state = 'medium',
                      ),
                      _FilterPill(
                        label: 'Low',
                        selected: curPriority == 'low',
                        color: AppColors.info,
                        onTap: () => ref.read(officerPriorityFilterProvider.notifier).state = 'low',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'INCIDENT CATEGORY',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterPill(
                        label: 'All Categories',
                        selected: curCategory == 'all',
                        onTap: () => ref.read(officerCategoryFilterProvider.notifier).state = 'all',
                      ),
                      ...AppConstants.caseCategories.entries.map(
                        (e) => _FilterPill(
                          label: e.value,
                          selected: curCategory == e.key,
                          onTap: () => ref.read(officerCategoryFilterProvider.notifier).state = e.key,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.primaryDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCases = ref.watch(filteredOfficerCasesProvider);
    final activeStatus = ref.watch(officerQueueFilterProvider);
    final activePriority = ref.watch(officerPriorityFilterProvider);
    final activeCategory = ref.watch(officerCategoryFilterProvider);
    final hasExtraFilters = activePriority != 'all' || activeCategory != 'all';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        title: const Text(
          'Inquiry Queue',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Filter Options',
            icon: Badge(
              isLabelVisible: hasExtraFilters,
              backgroundColor: AppColors.accent,
              smallSize: 8,
              child: const Icon(Icons.tune_rounded, color: AppColors.textPrimary),
            ),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            color: AppColors.primaryDark,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) {
                ref.read(officerSearchQueryProvider.notifier).state = v;
              },
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search ref #, title, keyword...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(officerSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accent),
                ),
              ),
            ),
          ),

          // Horizontal Status Chips
          Container(
            height: 48,
            color: AppColors.primaryDark,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: _statusFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final (key, label) = _statusFilters[index];
                final isSelected = activeStatus == key;
                return ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (_) {
                    ref.read(officerQueueFilterProvider.notifier).state = key;
                  },
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.accent.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.accent : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.accent : AppColors.divider,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                );
              },
            ),
          ),

          // Result Summary Strip
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredCases.length} CASE${filteredCases.length == 1 ? '' : 'S'} FOUND',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                if (hasExtraFilters)
                  InkWell(
                    onTap: () {
                      ref.read(officerPriorityFilterProvider.notifier).state = 'all';
                      ref.read(officerCategoryFilterProvider.notifier).state = 'all';
                    },
                    child: const Text(
                      'Clear Filters',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Cases List
          Expanded(
            child: RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.surface,
              onRefresh: () async {
                await ref.read(officerCasesProvider.notifier).fetchCases(force: true);
              },
              child: filteredCases.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 60),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: const Icon(
                                  Icons.inbox_rounded,
                                  size: 32,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No Matching Cases',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Try clearing your search or filters to see all cases.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () {
                                  _searchCtrl.clear();
                                  ref.read(officerSearchQueryProvider.notifier).state = '';
                                  ref.read(officerQueueFilterProvider.notifier).state = 'all';
                                  ref.read(officerPriorityFilterProvider.notifier).state = 'all';
                                  ref.read(officerCategoryFilterProvider.notifier).state = 'all';
                                },
                                icon: const Icon(Icons.restart_alt_rounded, size: 16),
                                label: const Text('Reset All Filters'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.accent,
                                  side: const BorderSide(color: AppColors.accent),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: filteredCases.length,
                      itemBuilder: (context, index) {
                        final c = filteredCases[index];
                        return OfficerCaseCard(
                          caseData: c,
                          onTap: () {
                            context.push('/officer/cases/${c['_id'] ?? c['id']}');
                          },
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

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.accent;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? activeColor.withValues(alpha: 0.2) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? activeColor : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? activeColor : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
