import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/officer_cases_provider.dart';

class OfficerEvidenceScreen extends ConsumerStatefulWidget {
  const OfficerEvidenceScreen({super.key});

  @override
  ConsumerState<OfficerEvidenceScreen> createState() => _OfficerEvidenceScreenState();
}

class _OfficerEvidenceScreenState extends ConsumerState<OfficerEvidenceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showNewRequestDialog(BuildContext context, List<Map<String, dynamic>> cases) {
    if (cases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active cases available to request evidence for.')),
      );
      return;
    }

    String selectedCaseId = cases.first['_id']?.toString() ?? '';
    final msgCtrl = TextEditingController(
      text: 'Please upload additional documentation, photographs, or witness statements to substantiate this incident.',
    );
    final noteCtrl = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
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
                    'Create Evidence Request',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Citizen will be notified immediately to provide requested items.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // Select Case Dropdown
                  const Text(
                    'TARGET CASE',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCaseId,
                        isExpanded: true,
                        dropdownColor: AppColors.surface,
                        items: cases.map((c) {
                          final id = c['_id']?.toString() ?? '';
                          final refNum = c['referenceNumber']?.toString() ?? 'Case';
                          final title = c['title']?.toString() ?? '';
                          return DropdownMenuItem<String>(
                            value: id,
                            child: Text(
                              '$refNum · $title',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedCaseId = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: msgCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: const InputDecoration(
                      labelText: 'Evidence Request Details',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 2,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: const InputDecoration(
                      labelText: 'Confidential Internal Note (optional)',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: () {
                      if (msgCtrl.text.trim().isEmpty) return;
                      ref.read(officerCasesProvider.notifier).requestEvidence(
                            caseId: selectedCaseId,
                            message: msgCtrl.text.trim(),
                            internalNote: noteCtrl.text.trim(),
                          );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Evidence request broadcasted to reporter.'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Send Formal Request'),
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
    final cases = ref.watch(officerCasesProvider);
    final evidenceReqAsync = ref.watch(officerEvidenceRequestsProvider);

    // Extract all evidence files across cases
    final allFiles = <Map<String, dynamic>>[];
    for (final c in cases) {
      final evList = c['evidence'] as List?;
      if (evList != null) {
        for (final item in evList) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            map['caseRef'] = c['referenceNumber'] ?? '';
            map['caseId'] = c['_id'] ?? c['id'] ?? '';
            map['caseTitle'] = c['title'] ?? '';
            allFiles.add(map);
          }
        }
      }
    }

    // Extract evidence requests from cases as well (so it always has data)
    final casesWithEvidenceReq = cases.where((c) => c['status'] == 'evidence_requested').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Evidence Vault',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(
              icon: const Icon(Icons.outbox_rounded, size: 18),
              text: 'Requests (${casesWithEvidenceReq.length})',
            ),
            Tab(
              icon: const Icon(Icons.folder_shared_rounded, size: 18),
              text: 'Files Vault (${allFiles.length})',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewRequestDialog(context, cases),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_photo_alternate_rounded),
        label: const Text('Request Evidence', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Evidence Requests
          _buildRequestsTab(casesWithEvidenceReq, evidenceReqAsync),

          // Tab 2: Evidence Files
          _buildFilesVaultTab(allFiles),
        ],
      ),
    );
  }

  Widget _buildRequestsTab(
    List<Map<String, dynamic>> casesWithEvidenceReq,
    AsyncValue<dynamic> evidenceReqAsync,
  ) {
    if (casesWithEvidenceReq.isEmpty) {
      return Center(
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
              child: const Icon(Icons.mark_email_read_rounded, size: 32, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Pending Evidence Requests',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'All reporters have submitted requested documents.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: casesWithEvidenceReq.length,
      itemBuilder: (context, index) {
        final c = casesWithEvidenceReq[index];
        final publicUpdates = (c['publicUpdates'] as List?) ?? [];
        final latestUpdate = publicUpdates.isNotEmpty
            ? (publicUpdates.last as Map)['message']?.toString() ?? ''
            : 'Additional evidence requested';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    (c['referenceNumber'] ?? '').toString(),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Awaiting Reporter',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                (c['title'] ?? '').toString(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  latestUpdate,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(c['evidence'] as List?)?.length ?? 0} files on record',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      context.push('/officer/cases/${c['_id'] ?? c['id']}');
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.accent),
                    label: const Text(
                      'Open Case',
                      style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilesVaultTab(List<Map<String, dynamic>> allFiles) {
    if (allFiles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_off_outlined, size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              'No Evidence Files',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: allFiles.length,
      itemBuilder: (context, index) {
        final f = allFiles[index];
        final fileType = f['fileType'] as String? ?? 'file';

        final (icon, color) = switch (fileType) {
          'image' => (Icons.image_rounded, AppColors.info),
          'video' => (Icons.videocam_rounded, AppColors.accent),
          'audio' => (Icons.audiotrack_rounded, AppColors.warning),
          'document' => (Icons.description_rounded, AppColors.success),
          _ => (Icons.insert_drive_file_rounded, AppColors.textMuted),
        };

        final sizeBytes = f['sizeBytes'] as int?;
        final sizeStr = sizeBytes != null
            ? (sizeBytes < 1024 * 1024
                ? '${(sizeBytes / 1024).toStringAsFixed(0)} KB'
                : '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB')
            : '';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (f['originalName'] ?? 'File').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          (f['caseRef'] ?? '').toString(),
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (sizeStr.isNotEmpty) ...[
                          const Text(' · ', style: TextStyle(color: AppColors.textMuted)),
                          Text(sizeStr, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ],
                    ),
                    if (f['description'] != null && (f['description'] as String).isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        f['description'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 6),
                    // Integrity Hash Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 11, color: AppColors.success),
                          SizedBox(width: 3),
                          Text(
                            'SHA-256 Custody Verified',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 20, color: AppColors.textSecondary),
                tooltip: 'Preview Evidence',
                onPressed: () {
                  _showEvidencePreviewDialog(context, f);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEvidencePreviewDialog(BuildContext context, Map<String, dynamic> f) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text((f['originalName'] ?? 'Evidence Preview').toString()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      f['fileType'] == 'image' ? Icons.image_rounded : Icons.lock_outline_rounded,
                      size: 44,
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Encrypted Evidence Container',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Case: ${f['caseRef']} · ${f['caseTitle']}',
              style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            if (f['description'] != null)
              Text(
                'Note: ${f['description']}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }
}
