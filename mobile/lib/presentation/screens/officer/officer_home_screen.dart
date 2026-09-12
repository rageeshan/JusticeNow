import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/officer_cases_provider.dart';

class OfficerHomeScreen extends ConsumerWidget {
  const OfficerHomeScreen({super.key});

  static const _filters = [
    ('all', 'All'),
    ('submitted', 'New'),
    ('under_review', 'Review'),
    ('evidence_requested', 'Evidence'),
    ('investigating', 'Active'),
    ('closed', 'Closed'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cases = ref.watch(officerCasesProvider);
    final filter = ref.watch(officerQueueFilterProvider);
    final filtered = _applyFilter(cases, filter);
    final stats = _computeStats(cases);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Case Officer'),
        actions: [
          IconButton(
            tooltip: 'Citizen view',
            icon: const Icon(Icons.swap_horiz_rounded),
            onPressed: () => context.go(AppRoutes.myCases),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Case Queue',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Review submissions, evidence, and close cases',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                _StatsRow(stats: stats),
                const SizedBox(height: 16),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final (key, label) = _filters[index];
                final selected = filter == key;
                return FilterChip(
                  selected: selected,
                  label: Text(label),
                  onSelected: (_) =>
                      ref.read(officerQueueFilterProvider.notifier).state = key,
                  selectedColor: AppColors.accent.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.accent,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.accent : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                  side: BorderSide(
                    color: selected ? AppColors.accent : AppColors.divider,
                  ),
                  backgroundColor: AppColors.surface,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? const _EmptyQueue()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _OfficerCaseCard(caseData: filtered[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _applyFilter(
    List<Map<String, dynamic>> cases,
    String filter,
  ) {
    if (filter == 'all') return cases;
    if (filter == 'closed') {
      return cases
          .where((c) => c['status'] == 'closed' || c['status'] == 'resolved')
          .toList();
    }
    return cases.where((c) => c['status'] == filter).toList();
  }

  Map<String, int> _computeStats(List<Map<String, dynamic>> cases) {
    int pending = 0;
    int active = 0;
    int evidence = 0;
    int done = 0;
    for (final c in cases) {
      switch (c['status']) {
        case 'submitted':
        case 'under_review':
          pending++;
          break;
        case 'investigating':
        case 'legal_action_initiated':
        case 'referred_to_ngo':
          active++;
          break;
        case 'evidence_requested':
          evidence++;
          break;
        case 'resolved':
        case 'closed':
        case 'rejected':
          done++;
          break;
      }
    }
    return {
      'pending': pending,
      'active': active,
      'evidence': evidence,
      'done': done,
    };
  }
}

class _StatsRow extends StatelessWidget {
  final Map<String, int> stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            label: 'Pending',
            value: '${stats['pending'] ?? 0}',
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStat(
            label: 'Active',
            value: '${stats['active'] ?? 0}',
            color: AppColors.statusInvestigating,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStat(
            label: 'Evidence',
            value: '${stats['evidence'] ?? 0}',
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStat(
            label: 'Closed',
            value: '${stats['done'] ?? 0}',
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _OfficerCaseCard extends ConsumerWidget {
  final Map<String, dynamic> caseData;
  const _OfficerCaseCard({required this.caseData});

  Color _statusColor(String? status) {
    return switch (status) {
      'submitted' => AppColors.statusSubmitted,
      'under_review' => AppColors.statusUnderReview,
      'investigating' => AppColors.statusInvestigating,
      'evidence_requested' => AppColors.warning,
      'resolved' => AppColors.statusResolved,
      'closed' => AppColors.statusClosed,
      'rejected' => AppColors.statusRejected,
      _ => AppColors.textMuted,
    };
  }

  Color _priorityColor(String? priority) {
    return switch (priority) {
      'critical' => AppColors.error,
      'high' => AppColors.warning,
      'medium' => AppColors.info,
      'low' => AppColors.textMuted,
      _ => AppColors.textMuted,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = caseData['status'] as String?;
    final statusLabel = AppConstants.caseStatusLabels[status] ?? status ?? 'Unknown';
    final category = caseData['category'] as String?;
    final categoryLabel = AppConstants.caseCategories[category] ?? category ?? '';
    final priority = caseData['priority'] as String?;
    final priorityLabel = AppConstants.priorityLabels[priority] ?? priority ?? '';
    final evidenceCount = (caseData['evidence'] as List?)?.length ?? 0;
    final caseId = caseData['_id'] as String;

    return GestureDetector(
      onTap: () {
        if (status == 'submitted') {
          ref.read(officerCasesProvider.notifier).markUnderReview(caseId);
        }
        context.push('/officer/cases/$caseId');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    caseData['referenceNumber'] ?? '',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: _statusColor(status),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              caseData['title'] ?? 'Untitled Case',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              categoryLabel,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.flag_outlined, size: 14, color: _priorityColor(priority)),
                const SizedBox(width: 4),
                Text(
                  priorityLabel,
                  style: TextStyle(
                    color: _priorityColor(priority),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(Icons.attach_file_rounded, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  '$evidenceCount evidence',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const Spacer(),
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  caseData['location']?['city'] ?? '—',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              'No cases in this filter',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
