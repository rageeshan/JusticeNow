import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/case_model.dart';
import '../../../providers/citizen_cases_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/case_timeline_widget.dart';
import '../../widgets/investigator_remark_card.dart';
import '../../widgets/demo_data_banner.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Case Detail Screen — Full case view with visual timeline
// ─────────────────────────────────────────────────────────────────────────────

class CaseDetailScreen extends ConsumerWidget {
  final String caseId;
  const CaseDetailScreen({super.key, required this.caseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caseAsync = ref.watch(caseDetailProvider(caseId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(caseId,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: 'Copy Case ID',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: caseId));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Case ID copied to clipboard'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: DemoDataBanner(),
        ),
      ),
      body: caseAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (e, _) => _NotFoundState(caseId: caseId),
        data: (c) {
          if (c == null) return _NotFoundState(caseId: caseId);
          return _CaseDetailBody(caseModel: c);
        },
      ),
    );
  }
}

class _CaseDetailBody extends StatelessWidget {
  final CaseModel caseModel;
  const _CaseDetailBody({required this.caseModel});

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final c = caseModel;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header card
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        c.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    StatusBadge(status: c.status, large: true),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  c.categoryLabel,
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Text(
                  c.summary,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.65,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Details grid
          _SectionCard(
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.tag_rounded,
                  label: 'Case ID',
                  value: c.id,
                  valueColor: AppColors.accent,
                ),
                _Divider(),
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Incident Date',
                  value: _formatDate(c.incidentDate),
                ),
                _Divider(),
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  value: c.location,
                ),
                _Divider(),
                _DetailRow(
                  icon: Icons.send_outlined,
                  label: 'Submitted On',
                  value: _formatDate(c.submittedAt),
                ),
                _Divider(),
                _DetailRow(
                  icon: c.isAnonymous
                      ? Icons.visibility_off_outlined
                      : Icons.person_outline,
                  label: 'Reported As',
                  value: c.isAnonymous ? 'Anonymously' : 'Identified',
                ),
                _Divider(),
                _DetailRow(
                  icon: Icons.attach_file_outlined,
                  label: 'Evidence',
                  value: c.hasEvidence ? 'Files attached' : 'No files',
                  valueColor:
                      c.hasEvidence ? AppColors.statusResolved : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Status description card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _statusBgColor(c.status),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _statusBorderColor(c.status)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_statusIcon(c.status),
                    size: 20, color: _statusIconColor(c.status)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status: ${c.status.label}',
                        style: TextStyle(
                          color: _statusIconColor(c.status),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.status.description,
                        style: TextStyle(
                          color: _statusIconColor(c.status)
                              .withValues(alpha: 0.8),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Next step card
          if (c.nextStep != null) ...[
            _SectionTitle('Expected Next Step'),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.navigate_next_rounded,
                          size: 18, color: AppColors.accent),
                      const SizedBox(width: 8),
                      const Text('What to expect next',
                          style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    c.nextStep!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                  if (c.expectedUpdateBy != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.schedule_outlined,
                            size: 14, color: AppColors.accent),
                        const SizedBox(width: 6),
                        Text(
                          'Expected update by: ${_formatDate(c.expectedUpdateBy!)}',
                          style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Investigation timeline
          _SectionTitle('Investigation Timeline'),
          const SizedBox(height: 12),
          _SectionCard(
            child: CaseTimelineWidget(events: c.timeline),
          ),
          const SizedBox(height: 20),

          // ── Investigator remarks
          if (c.remarks.isNotEmpty) ...[
            _SectionTitle('Updates from Our Team'),
            const SizedBox(height: 4),
            const Text(
              'Messages from the case team. Officer identities are kept confidential for their safety.',
              style:
                  TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 12),
            ...c.remarks.map((r) => InvestigatorRemarkCard(remark: r)),
            const SizedBox(height: 8),
          ],

          // ── Contact / support
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.support_agent_outlined,
                        size: 18, color: AppColors.accent),
                    SizedBox(width: 8),
                    Text('Need help with your case?',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'If you have new information, feel unsafe, or need to update your case, you can contact the support team.',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                              '⚠ Support contact is not available in this demo.'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      );
                    },
                    icon: const Icon(Icons.mail_outline_rounded),
                    label: const Text('Contact Support Team'),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 46)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Privacy footer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lock_outline,
                        size: 14, color: AppColors.textMuted),
                    SizedBox(width: 6),
                    Text('Privacy & Security',
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'All case data is encrypted and stored securely. Access is restricted to trained case officers only. Your information is never shared with the media, government agencies, or third parties without your explicit consent.',
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: 12, height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusBgColor(CaseStatus s) => switch (s) {
        CaseStatus.submitted =>
          AppColors.statusSubmitted.withValues(alpha: 0.08),
        CaseStatus.underReview =>
          AppColors.statusUnderReview.withValues(alpha: 0.08),
        CaseStatus.investigating =>
          AppColors.statusInvestigating.withValues(alpha: 0.08),
        CaseStatus.resolved =>
          AppColors.statusResolved.withValues(alpha: 0.08),
        CaseStatus.closed =>
          AppColors.statusClosed.withValues(alpha: 0.08),
      };

  Color _statusBorderColor(CaseStatus s) => switch (s) {
        CaseStatus.submitted =>
          AppColors.statusSubmitted.withValues(alpha: 0.3),
        CaseStatus.underReview =>
          AppColors.statusUnderReview.withValues(alpha: 0.3),
        CaseStatus.investigating =>
          AppColors.statusInvestigating.withValues(alpha: 0.3),
        CaseStatus.resolved =>
          AppColors.statusResolved.withValues(alpha: 0.3),
        CaseStatus.closed => AppColors.statusClosed.withValues(alpha: 0.3),
      };

  Color _statusIconColor(CaseStatus s) => switch (s) {
        CaseStatus.submitted => AppColors.statusSubmitted,
        CaseStatus.underReview => AppColors.statusUnderReview,
        CaseStatus.investigating => AppColors.statusInvestigating,
        CaseStatus.resolved => AppColors.statusResolved,
        CaseStatus.closed => AppColors.statusClosed,
      };

  IconData _statusIcon(CaseStatus s) => switch (s) {
        CaseStatus.submitted => Icons.inbox_outlined,
        CaseStatus.underReview => Icons.manage_search_outlined,
        CaseStatus.investigating => Icons.policy_outlined,
        CaseStatus.resolved => Icons.check_circle_outline,
        CaseStatus.closed => Icons.archive_outlined,
      };
}

// ── Reusable sub-widgets

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: AppColors.divider);
  }
}

// ── Not found state
class _NotFoundState extends StatelessWidget {
  final String caseId;
  const _NotFoundState({required this.caseId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Case not found',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(
              'We could not find case "$caseId". Please check the ID and try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
