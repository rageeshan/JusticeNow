import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/legal_aid_repository.dart';
import '../../../data/services/lawyer_case_pdf_service.dart';
import 'lawyer_case_detail_screen.dart';

class CounselCasesScreen extends StatefulWidget {
  final int initialTabIndex;

  const CounselCasesScreen({super.key, this.initialTabIndex = 0});

  @override
  State<CounselCasesScreen> createState() => _CounselCasesScreenState();
}

class _CounselCasesScreenState extends State<CounselCasesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LegalAidRepository _repo = LegalAidRepository();

  bool _isLoading = false;
  List<dynamic> _pendingCases = [];
  List<dynamic> _inProgressCases = [];
  List<dynamic> _completedCases = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _fetchCasesForTab(_tabController.index);
      }
    });
    _fetchAllCases();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllCases() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchTab(0),
      _fetchTab(1),
      _fetchTab(2),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchTab(int tabIndex) async {
    try {
      final tabKey = tabIndex == 0
          ? 'pending'
          : tabIndex == 1
              ? 'in_progress'
              : 'completed';
      final list = await _repo.getLawyerCases(tabKey);
      if (mounted) {
        setState(() {
          if (tabIndex == 0) _pendingCases = list;
          if (tabIndex == 1) _inProgressCases = list;
          if (tabIndex == 2) _completedCases = list;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchCasesForTab(int tabIndex) async {
    setState(() => _isLoading = true);
    await _fetchTab(tabIndex);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _markCompleted(String caseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Mark Case as Completed?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Are you sure you have concluded all legal proceedings or consultations for this case?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Mark Completed'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _repo.completeLawyerCase(caseId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Case marked as completed!'),
              backgroundColor: AppColors.success,
            ),
          );
          _fetchAllCases();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to complete case: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateVal.toString()).toLocal();
      return DateFormat('MMM dd, yyyy').format(dt);
    } catch (_) {
      return dateVal.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('View Cases'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _fetchAllCases,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Pending'),
                  if (_pendingCases.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _buildBadge('${_pendingCases.length}', AppColors.accent),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('In Progress'),
                  if (_inProgressCases.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _buildBadge('${_inProgressCases.length}', AppColors.info),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Completed'),
                  if (_completedCases.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _buildBadge('${_completedCases.length}', AppColors.success),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPendingTab(),
                _buildInProgressTab(),
                _buildCompletedTab(),
              ],
            ),
    );
  }

  Widget _buildBadge(String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ── 1. Pending Tab ──
  Widget _buildPendingTab() {
    if (_pendingCases.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_rounded,
        title: 'No Pending Case Requests',
        subtitle: 'New case requests submitted by citizens will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAllCases,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingCases.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final c = _pendingCases[index] as Map<String, dynamic>;
          final caseId = c['_id'] as String;
          final title = c['title'] as String? ?? 'Untitled Case';
          final citizen = _extractCitizen(c);
          final dateSubmitted = _formatDate(c['createdAt']);

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Citizen Name + Status badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            citizen['name'] ?? 'Citizen',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Date submitted: $dateSubmitted',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    // Badge: New Request
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAmber,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderAmber),
                      ),
                      child: const Text(
                        'New Request',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 12),

                // Case Title
                Row(
                  children: [
                    const Icon(Icons.article_outlined, color: AppColors.textSecondary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // View Details Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => LawyerCaseDetailScreen(caseId: caseId)),
                      );
                      if (result == true) {
                        _fetchAllCases();
                      }
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('View Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── 2. In Progress Tab ──
  Widget _buildInProgressTab() {
    if (_inProgressCases.isEmpty) {
      return _buildEmptyState(
        icon: Icons.pending_actions_rounded,
        title: 'No Cases In Progress',
        subtitle: 'Cases you have accepted and scheduled will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAllCases,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _inProgressCases.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final c = _inProgressCases[index] as Map<String, dynamic>;
          final caseId = c['_id'] as String;
          final title = c['title'] as String? ?? 'Untitled Case';
          final citizen = _extractCitizen(c);

          final scheduledDate = c['scheduledMeetingDate'] as String? ?? 'Scheduled';
          final scheduledTime = c['scheduledMeetingTime'] as String? ?? '';
          final scheduledText = '$scheduledDate ${scheduledTime.isNotEmpty ? '• $scheduledTime' : ''}';

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Citizen Name + In Progress Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            citizen['name'] ?? 'Citizen',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.event_available_rounded, size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  scheduledText,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Status Badge: In Progress
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBlue,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderBlue),
                      ),
                      child: const Text(
                        'In Progress',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Small "Export PDF" icon button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => LawyerCasePdfService.exportCaseById(caseId, context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.picture_as_pdf_rounded, color: AppColors.accent, size: 14),
                              SizedBox(width: 3),
                              Text(
                                'PDF',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 12),

                // Case Title
                Row(
                  children: [
                    const Icon(Icons.article_outlined, color: AppColors.textSecondary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Contact Info Block (Email & Mobile)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 16, color: AppColors.accent),
                          const SizedBox(width: 8),
                          const Text('Email: ', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          Expanded(
                            child: Text(
                              citizen['email'] ?? 'Not specified',
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 16, color: AppColors.accent),
                          const SizedBox(width: 8),
                          const Text('Mobile: ', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          Expanded(
                            child: Text(
                              citizen['phone'] ?? 'Not specified',
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Actions: View Details + Export PDF + Mark as Completed
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(builder: (_) => LawyerCaseDetailScreen(caseId: caseId)),
                          );
                          if (result == true) {
                            _fetchAllCases();
                          }
                        },
                        icon: const Icon(Icons.visibility_outlined, size: 15),
                        label: const Text('View Details', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => LawyerCasePdfService.exportCaseById(caseId, context),
                      tooltip: 'Export PDF Report',
                      icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.accent, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                        side: BorderSide(color: AppColors.accent.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: () => _markCompleted(caseId),
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
                        label: const Text('Complete', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── 3. Completed Tab ──
  Widget _buildCompletedTab() {
    if (_completedCases.isEmpty) {
      return _buildEmptyState(
        icon: Icons.task_alt_rounded,
        title: 'No Completed Cases',
        subtitle: 'Cases you have marked as finished will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAllCases,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _completedCases.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final c = _completedCases[index] as Map<String, dynamic>;
          final caseId = c['_id'] as String;
          final title = c['title'] as String? ?? 'Untitled Case';
          final citizen = _extractCitizen(c);
          final completedDate = _formatDate(c['completedAt'] ?? c['updatedAt']);

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Citizen Name + Completed Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.check_rounded, color: AppColors.success, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            citizen['name'] ?? 'Citizen',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Date completed: $completedDate',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    // Badge: Completed
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceGreen,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderGreen),
                      ),
                      child: const Text(
                        'Completed',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Small "Export PDF" icon button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => LawyerCasePdfService.exportCaseById(caseId, context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.picture_as_pdf_rounded, color: AppColors.accent, size: 14),
                              SizedBox(width: 3),
                              Text(
                                'PDF',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 12),

                // Case Title
                Row(
                  children: [
                    const Icon(Icons.article_outlined, color: AppColors.textSecondary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Actions: View Details + Export PDF
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => LawyerCaseDetailScreen(caseId: caseId)),
                          );
                        },
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => LawyerCasePdfService.exportCaseById(caseId, context),
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                        label: const Text('Export PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, String> _extractCitizen(Map<String, dynamic> c) {
    final reportedBy = c['reportedBy'];
    if (reportedBy is Map) {
      final profile = reportedBy['profile'];
      if (profile is Map) {
        return {
          'name': profile['fullName']?.toString() ?? reportedBy['alias']?.toString() ?? 'Citizen',
          'email': reportedBy['email']?.toString() ?? 'Not specified',
          'phone': profile['phone']?.toString() ?? 'Not specified',
        };
      }
      return {
        'name': reportedBy['alias']?.toString() ?? 'Citizen',
        'email': reportedBy['email']?.toString() ?? 'Not specified',
        'phone': 'Not specified',
      };
    }
    return {
      'name': 'Citizen',
      'email': 'Not specified',
      'phone': 'Not specified',
    };
  }
}
