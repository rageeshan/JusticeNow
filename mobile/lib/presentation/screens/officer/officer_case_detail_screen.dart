import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/officer_cases_provider.dart';

class OfficerCaseDetailScreen extends ConsumerWidget {
  final String caseId;
  const OfficerCaseDetailScreen({super.key, required this.caseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caseData = ref.watch(officerCaseByIdProvider(caseId));

    if (caseData == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Case Details')),
        body: const Center(
          child: Text('Case not found', style: TextStyle(color: AppColors.error)),
        ),
      );
    }

    final status = caseData['status'] as String? ?? '';
    final isTerminal = status == 'resolved' || status == 'closed' || status == 'rejected';
    final evidence = (caseData['evidence'] as List?) ?? [];
    final timeline = (caseData['timeline'] as List?) ?? [];
    final publicUpdates = (caseData['publicUpdates'] as List?) ?? [];
    final internalNotes = (caseData['internalNotes'] as List?) ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(caseData['referenceNumber'] ?? 'Case Details'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      _StatusBadge(status: status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    caseData['title'] ?? '',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppConstants.caseCategories[caseData['category']] ??
                        caseData['category'] ??
                        '',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  _InfoStrip(caseData: caseData),
                  const SizedBox(height: 24),

                  const _SectionTitle('Description'),
                  const SizedBox(height: 8),
                  Text(
                    caseData['description'] ?? '',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      height: 1.6,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      const Expanded(child: _SectionTitle('Evidence Submitted')),
                      Text(
                        '${evidence.length} file${evidence.length == 1 ? '' : 's'}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (evidence.isEmpty)
                    _EmptyBlock(
                      icon: Icons.folder_off_outlined,
                      message: 'No evidence uploaded yet',
                    )
                  else
                    ...evidence.map(
                      (e) => _EvidenceTile(evidence: Map<String, dynamic>.from(e as Map)),
                    ),
                  const SizedBox(height: 24),

                  if (timeline.isNotEmpty) ...[
                    const _SectionTitle('Timeline'),
                    const SizedBox(height: 12),
                    ...timeline.map(
                      (event) => _TimelineItem(
                        event: Map<String, dynamic>.from(event as Map),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (publicUpdates.isNotEmpty) ...[
                    const _SectionTitle('Updates to Reporter'),
                    const SizedBox(height: 12),
                    ...publicUpdates.map(
                      (u) => _MessageCard(
                        text: (u as Map)['message']?.toString() ?? '',
                        accent: AppColors.info,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (internalNotes.isNotEmpty) ...[
                    const _SectionTitle('Internal Notes (Staff)'),
                    const SizedBox(height: 12),
                    ...internalNotes.map(
                      (n) => _MessageCard(
                        text: (n as Map)['note']?.toString() ?? '',
                        accent: AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (caseData['adminFeedback'] != null) ...[
                    const _SectionTitle('Admin Feedback'),
                    const SizedBox(height: 8),
                    _MessageCard(
                      text: caseData['adminFeedback'].toString(),
                      accent: AppColors.accent,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (caseData['userFeedback'] != null) ...[
                    const _SectionTitle('User Feedback'),
                    const SizedBox(height: 8),
                    _MessageCard(
                      text: caseData['userFeedback'].toString(),
                      accent: AppColors.success,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!isTerminal) _ActionBar(caseId: caseId, status: status, caseData: caseData),
        ],
      ),
    );
  }
}

class _ActionBar extends ConsumerWidget {
  final String caseId;
  final String status;
  final Map<String, dynamic> caseData;
  const _ActionBar({
    required this.caseId,
    required this.status,
    required this.caseData,
  });

  bool get canInvestigate =>
      status == 'submitted' ||
      status == 'under_review' ||
      status == 'evidence_requested';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showRequestEvidenceSheet(context, ref),
                  icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
                  label: const Text('Request Evidence'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: canInvestigate
                      ? () => _confirmInvestigate(context, ref)
                      : null,
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text('Investigate'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showCloseFeedbackSheet(context, ref),
              icon: const Icon(Icons.task_alt_rounded, size: 18),
              label: const Text('Feedback & Close Case'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.success,
                side: const BorderSide(color: AppColors.success),
                minimumSize: const Size.fromHeight(46),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmInvestigate(BuildContext context, WidgetRef ref) async {
    final evidenceCount = (caseData['evidence'] as List?)?.length ?? 0;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Start Investigation?'),
        content: Text(
          evidenceCount == 0
              ? 'This case has no evidence. Are you sure you want to investigate without additional files?'
              : 'Evidence looks sufficient ($evidenceCount file${evidenceCount == 1 ? '' : 's'}). Proceed to investigate this case?',
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Investigate', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ref.read(officerCasesProvider.notifier).startInvestigation(caseId: caseId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Case moved to Investigating'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _showRequestEvidenceSheet(BuildContext context, WidgetRef ref) async {
    final messageCtrl = TextEditingController(
      text:
          'Additional evidence is required to proceed. Please upload supporting documents, photos, or witness information.',
    );
    final noteCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              Text(
                'Request More Evidence',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              const Text(
                'The reporter will see this message as a case update.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Message to reporter',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Internal note (optional)',
                  hintText: 'Why evidence is insufficient…',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (messageCtrl.text.trim().isEmpty) return;
                  ref.read(officerCasesProvider.notifier).requestEvidence(
                        caseId: caseId,
                        message: messageCtrl.text.trim(),
                        internalNote: noteCtrl.text,
                      );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Evidence requested from reporter'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                child: const Text('Send Request'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCloseFeedbackSheet(BuildContext context, WidgetRef ref) async {
    final adminCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    var resolve = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  Text(
                    'Feedback & Close',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Provide feedback for admin and the reporter, then close the case.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: adminCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Feedback for Admin',
                      hintText: 'Internal findings, recommendations…',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: userCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Feedback for User',
                      hintText: 'Outcome summary shared with reporter…',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            resolve ? 'Mark as Resolved' : 'Mark as Closed',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Switch(
                          value: resolve,
                          activeThumbColor: AppColors.accent,
                          onChanged: (v) => setModalState(() => resolve = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (adminCtrl.text.trim().isEmpty || userCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Both feedback fields are required'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }
                      ref.read(officerCasesProvider.notifier).submitFeedbackAndClose(
                            caseId: caseId,
                            adminFeedback: adminCtrl.text.trim(),
                            userFeedback: userCtrl.text.trim(),
                            resolve: resolve,
                          );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            resolve ? 'Case resolved and closed' : 'Case closed',
                          ),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    child: Text(resolve ? 'Resolve & Close' : 'Close Case'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _InfoStrip extends StatelessWidget {
  final Map<String, dynamic> caseData;
  const _InfoStrip({required this.caseData});

  @override
  Widget build(BuildContext context) {
    final location = [
      caseData['location']?['city'],
      caseData['location']?['country'],
    ].where((v) => v != null && v.toString().isNotEmpty).join(', ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Incident',
            value: caseData['incidentDate']?.toString().split('T').first ?? 'N/A',
          ),
          _DetailRow(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: location.isNotEmpty ? location : 'Not specified',
          ),
          _DetailRow(
            icon: Icons.priority_high_rounded,
            label: 'Priority',
            value: AppConstants.priorityLabels[caseData['priority']] ??
                caseData['priority'] ??
                'Medium',
          ),
          _DetailRow(
            icon: Icons.person_outline_rounded,
            label: 'Reporter',
            value: caseData['isAnonymous'] == true
                ? 'Anonymous (${caseData['reportedByAlias'] ?? '—'})'
                : (caseData['reportedByAlias'] ?? 'Citizen'),
          ),
        ],
      ),
    );
  }
}

class _EvidenceTile extends StatelessWidget {
  final Map<String, dynamic> evidence;
  const _EvidenceTile({required this.evidence});

  IconData get _icon => switch (evidence['fileType']) {
        'image' => Icons.image_outlined,
        'video' => Icons.videocam_outlined,
        'audio' => Icons.audiotrack_outlined,
        'document' => Icons.description_outlined,
        _ => Icons.insert_drive_file_outlined,
      };

  Color get _color => switch (evidence['fileType']) {
        'image' => AppColors.info,
        'video' => AppColors.accent,
        'audio' => AppColors.warning,
        'document' => AppColors.success,
        _ => AppColors.textMuted,
      };

  String _formatSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: _color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evidence['originalName'] ?? 'File',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if ((evidence['description'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    evidence['description'] as String,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  [
                    (evidence['fileType'] as String?)?.toUpperCase() ?? 'FILE',
                    _formatSize(evidence['sizeBytes'] as int?),
                  ].where((s) => s.isNotEmpty).join(' · '),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Preview: ${evidence['originalName']} (UI stub)'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            icon: const Icon(Icons.visibility_outlined, size: 20, color: AppColors.textSecondary),
            tooltip: 'Preview',
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get color => switch (status) {
        'submitted' => AppColors.statusSubmitted,
        'under_review' => AppColors.statusUnderReview,
        'investigating' => AppColors.statusInvestigating,
        'evidence_requested' => AppColors.warning,
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
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
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
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
            Container(width: 2, height: 40, color: AppColors.divider),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConstants.caseStatusLabels[event['status']] ??
                    event['status'] ??
                    '',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              if (event['note'] != null && (event['note'] as String).isNotEmpty)
                Text(
                  event['note'] as String,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String text;
  final Color accent;
  const _MessageCard({required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyBlock({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 32),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
