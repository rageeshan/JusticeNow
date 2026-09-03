import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/repositories/case_repository.dart';

final _caseDetailProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  return CaseRepository().getCaseById(id);
});

class CaseDetailScreen extends ConsumerWidget {
  final String caseId;
  const CaseDetailScreen({super.key, required this.caseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caseAsync = ref.watch(_caseDetailProvider(caseId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Case Details')),
      body: caseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
        data: (c) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reference + Status badge
              Row(
                children: [
                  Text(c['referenceNumber'] ?? '',
                      style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 13)),
                  const Spacer(),
                  _StatusBadge(status: c['status'] ?? ''),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(c['title'] ?? '', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                AppConstants.caseCategories[c['category']] ?? c['category'] ?? '',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Description
              _SectionTitle('Description'),
              const SizedBox(height: 8),
              Text(c['description'] ?? '', style: const TextStyle(color: AppColors.textPrimary, height: 1.6)),
              const SizedBox(height: 24),

              // Details grid
              _SectionTitle('Details'),
              const SizedBox(height: 12),
              _DetailRow(icon: Icons.calendar_today_outlined, label: 'Incident Date', value: c['incidentDate']?.toString().split('T').first ?? 'N/A'),
              _DetailRow(icon: Icons.location_on_outlined, label: 'Location',
                  value: [c['location']?['city'], c['location']?['country']].where((v) => v != null).join(', ').isNotEmpty
                      ? [c['location']?['city'], c['location']?['country']].where((v) => v != null).join(', ')
                      : 'Not specified'),
              _DetailRow(icon: Icons.priority_high_rounded, label: 'Priority', value: AppConstants.priorityLabels[c['priority']] ?? c['priority'] ?? 'Medium'),
              const SizedBox(height: 24),

              // Timeline
              if ((c['timeline'] as List?)?.isNotEmpty == true) ...[
                _SectionTitle('Case Timeline'),
                const SizedBox(height: 12),
                ...(c['timeline'] as List).map((event) => _TimelineItem(event: event as Map<String, dynamic>)),
                const SizedBox(height: 24),
              ],

              // Public updates
              if ((c['publicUpdates'] as List?)?.isNotEmpty == true) ...[
                _SectionTitle('Updates from Investigators'),
                const SizedBox(height: 12),
                ...(c['publicUpdates'] as List).map((update) => _UpdateCard(update: update as Map<String, dynamic>)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8));
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get color => switch (status) {
    'submitted' => AppColors.statusSubmitted,
    'under_review' => AppColors.statusUnderReview,
    'investigating' => AppColors.statusInvestigating,
    'resolved' => AppColors.statusResolved,
    'closed' => AppColors.statusClosed,
    'rejected' => AppColors.statusRejected,
    _ => AppColors.textMuted,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        AppConstants.caseStatusLabels[status] ?? status,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final Map<String, dynamic> event;
  const _TimelineItem({required this.event});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
            Container(width: 2, height: 40, color: AppColors.divider),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppConstants.caseStatusLabels[event['status']] ?? event['status'] ?? '',
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
              if (event['note'] != null && (event['note'] as String).isNotEmpty)
                Text(event['note'] as String,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _UpdateCard extends StatelessWidget {
  final Map<String, dynamic> update;
  const _UpdateCard({required this.update});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(update['message'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5)),
    );
  }
}
