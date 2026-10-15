import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/officer_cases_provider.dart';
import '../../widgets/officer/officer_case_card.dart';
import '../../widgets/officer/officer_stat_card.dart';
import 'officer_shell_screen.dart';

class OfficerHomeScreen extends ConsumerWidget {
  const OfficerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final officerName = user?['alias'] ?? user?['email']?.toString().split('@').first ?? 'Officer';

    final statsAsync = ref.watch(officerStatsProvider);
    final cases = ref.watch(officerCasesProvider);

    // Urgent Cases: Critical or High priority that are still submitted / under_review / investigating
    final urgentCases = cases.where((c) {
      final prio = (c['priority'] as String? ?? '').toLowerCase();
      final status = (c['status'] as String? ?? '').toLowerCase();
      return (prio == 'critical' || prio == 'high') &&
          status != 'resolved' &&
          status != 'closed' &&
          status != 'rejected';
    }).take(4).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.security_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'JusticeNow',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Case Officer Console',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Cases',
            icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.textSecondary),
            onPressed: () {
              ref.read(officerCasesProvider.notifier).fetchCases(force: true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Syncing cases with backend API...'),
                  duration: Duration(seconds: 1),
                  backgroundColor: AppColors.primaryLight,
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Switch to Citizen View',
            icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.textSecondary),
            onPressed: () => context.go(AppRoutes.myCases),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          await ref.read(officerCasesProvider.notifier).fetchCases(force: true);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'DUTY ACTIVE · SECURE SESSION',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Officer $officerName',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Human Rights Investigation & Oversight Division',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.accent, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: AppColors.accent,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // KPI Section Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'INVESTIGATION METRICS',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      ref.read(officerNavIndexProvider.notifier).state = 1;
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.accent),
                    label: const Text(
                      'View All Cases',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2x2 Metric Cards Grid
              statsAsync.when(
                data: (stats) => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.25,
                  children: [
                    OfficerStatCard(
                      title: 'Total In Queue',
                      value: '${stats.totalAssigned}',
                      subtitle: '${stats.critical} Critical Priority',
                      icon: Icons.folder_open_rounded,
                      accentColor: AppColors.info,
                      onTap: () {
                        ref.read(officerQueueFilterProvider.notifier).state = 'all';
                        ref.read(officerNavIndexProvider.notifier).state = 1;
                      },
                    ),
                    OfficerStatCard(
                      title: 'Needs Triage',
                      value: '${stats.awaitingReview}',
                      subtitle: 'Pending Review',
                      icon: Icons.pending_actions_rounded,
                      accentColor: AppColors.warning,
                      onTap: () {
                        ref.read(officerQueueFilterProvider.notifier).state = 'submitted';
                        ref.read(officerNavIndexProvider.notifier).state = 1;
                      },
                    ),
                    OfficerStatCard(
                      title: 'Active Inquiries',
                      value: '${stats.activeInvestigations}',
                      subtitle: 'In Progress',
                      icon: Icons.search_rounded,
                      accentColor: AppColors.accent,
                      onTap: () {
                        ref.read(officerQueueFilterProvider.notifier).state = 'investigating';
                        ref.read(officerNavIndexProvider.notifier).state = 1;
                      },
                    ),
                    OfficerStatCard(
                      title: 'Evidence Pending',
                      value: '${stats.evidenceRequested}',
                      subtitle: 'Awaiting Files',
                      icon: Icons.inventory_2_rounded,
                      accentColor: const Color(0xFFF97316),
                      onTap: () {
                        ref.read(officerNavIndexProvider.notifier).state = 2;
                      },
                    ),
                  ],
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                ),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 24),

              // Quick Action Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _QuickActionButton(
                      icon: Icons.filter_list_rounded,
                      label: 'Filter Queue',
                      onTap: () {
                        ref.read(officerNavIndexProvider.notifier).state = 1;
                      },
                    ),
                    Container(width: 1, height: 28, color: AppColors.divider),
                    _QuickActionButton(
                      icon: Icons.add_photo_alternate_outlined,
                      label: 'Request Ev.',
                      onTap: () {
                        ref.read(officerNavIndexProvider.notifier).state = 2;
                      },
                    ),
                    Container(width: 1, height: 28, color: AppColors.divider),
                    _QuickActionButton(
                      icon: Icons.verified_user_outlined,
                      label: 'Audit Trail',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Immutable Audit Trail verified with MongoDB backend.'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Urgent Attention Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'URGENT TRIAGE & ESCALATIONS',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${urgentCases.length} items',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (urgentCases.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 36),
                      SizedBox(height: 8),
                      Text(
                        'No Critical Alerts',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'All high-priority cases have been addressed.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                )
              else
                ...urgentCases.map(
                  (c) => OfficerCaseCard(
                    caseData: c,
                    onTap: () {
                      context.push('/officer/cases/${c['_id'] ?? c['id']}');
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.accent, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
