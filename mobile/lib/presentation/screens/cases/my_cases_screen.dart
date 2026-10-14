import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/repositories/case_repository.dart';

final _caseRepoProvider = Provider<CaseRepository>((ref) => CaseRepository());

final _myCasesProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.watch(_caseRepoProvider).getMyCases();
});

class MyCasesScreen extends ConsumerWidget {
  const MyCasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final casesAsync = ref.watch(_myCasesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Cases'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(AppRoutes.home),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.reportCase),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.primaryDark,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Report Case', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: casesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (err, _) => Center(
          child: Text('Error: $err', style: const TextStyle(color: AppColors.error)),
        ),
        data: (data) {
          final cases = (data['cases'] as List?) ?? [];
          if (cases.isEmpty) {
            return _EmptyState(
              onReport: () => context.push(AppRoutes.reportCase),
            );
          }
          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () => ref.refresh(_myCasesProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: cases.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final c = cases[index] as Map<String, dynamic>;
                return _CaseCard(caseData: c);
              },
            ),
          );
        },
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  final Map<String, dynamic> caseData;
  const _CaseCard({required this.caseData});

  Color _statusColor(String? status) {
    return switch (status) {
      'submitted' => AppColors.statusSubmitted,
      'under_review' => AppColors.statusUnderReview,
      'investigating' => AppColors.statusInvestigating,
      'awaiting_lawyer_selection' => AppColors.success,
      'waiting_for_lawyer_approval' => AppColors.accent,
      'approved_scheduled' => AppColors.info,
      'assigned_to_police' => AppColors.warning,
      'in_progress_police' => AppColors.info,
      'pending_reassignment' => AppColors.statusRejected,
      'suspect_identified' => AppColors.accent,
      'referred_to_court' => AppColors.warning,
      'police_declined' => AppColors.statusRejected,
      'in_progress' => AppColors.info,
      'completed' => AppColors.statusResolved,
      'lawyer_declined' => AppColors.statusRejected,
      'resolved' => AppColors.statusResolved,
      'closed' => AppColors.statusClosed,
      'rejected' => AppColors.statusRejected,
      _ => AppColors.textMuted,
    };
  }

  @override
  Widget build(BuildContext context) {
    final status = caseData['status'] as String?;
    final statusLabel = AppConstants.caseStatusLabels[status] ?? status ?? 'Unknown';
    final category = caseData['category'] as String?;
    final categoryLabel = AppConstants.caseCategories[category] ?? category ?? '';
    final scheduledDate = caseData['scheduledMeetingDate'] as String?;
    final scheduledTime = caseData['scheduledMeetingTime'] as String?;
    final investigationDate = caseData['investigationStartDate'] as String?;
    final investigationTime = caseData['investigationStartTime'] as String?;

    return GestureDetector(
      onTap: () => context.push('/cases/${caseData['_id']}'),
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
            if (scheduledDate != null && scheduledDate.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_available_rounded, size: 14, color: AppColors.info),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Meeting: $scheduledDate ${scheduledTime != null ? '• $scheduledTime' : ''}',
                        style: const TextStyle(color: AppColors.info, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (investigationDate != null && investigationDate.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_police_rounded, size: 15, color: Colors.indigoAccent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Police Investigation: $investigationDate ${investigationTime != null ? '• $investigationTime' : ''}',
                            style: const TextStyle(color: Colors.indigoAccent, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (caseData['assignedOfficer'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Officer: ${caseData['assignedOfficer'] is Map ? (caseData['assignedOfficer']['name'] ?? caseData['assignedOfficer']['profile']?['fullName'] ?? 'Assigned Officer') : 'Assigned Officer'}'
                        '${caseData['assignedOfficer'] is Map && (caseData['assignedOfficer']['phone'] ?? caseData['assignedOfficer']['profile']?['phone']) != null ? ' • ${(caseData['assignedOfficer']['phone'] ?? caseData['assignedOfficer']['profile']?['phone'])}' : ''}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (status == 'assigned_to_police') ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.hourglass_top_rounded, size: 14, color: Colors.purpleAccent),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Assigned to Police • Awaiting officer review',
                        style: TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (status == 'pending_reassignment') ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.sync_problem_rounded, size: 14, color: Colors.orangeAccent),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Pending Reassignment • Admin will reassign your case',
                        style: TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  caseData['location']?['city'] ?? 'Location not specified',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
              ],
            ),
            if (status == 'awaiting_lawyer_selection' || status == 'lawyer_declined') ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final caseId = caseData['_id']?.toString();
                    final targetPath = caseId != null
                        ? '${AppRoutes.legalAid}?caseId=$caseId'
                        : AppRoutes.legalAid;
                    context.push(targetPath);
                  },
                  icon: const Icon(Icons.person_search_rounded, size: 18),
                  label: Text(
                    status == 'lawyer_declined' ? 'Find another lawyer' : 'Find a Lawyer',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onReport;
  const _EmptyState({required this.onReport});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'No cases yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Report an incident to start tracking your case',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onReport,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Report an Incident'),
            ),
          ],
        ),
      ),
    );
  }
}
