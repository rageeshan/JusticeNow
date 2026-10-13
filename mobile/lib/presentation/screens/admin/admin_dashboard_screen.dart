import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _isLoadingPending = true;
  List<dynamic> _pendingUsers = [];
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchPendingUsers();
    });
  }

  Future<void> _fetchPendingUsers() async {
    if (!mounted) return;

    try {
      final repo = ref.read(authRepositoryProvider);
      final users = await repo.getAdminUsers(approvalStatus: 'pending');
      if (mounted) {
        setState(() {
          _pendingUsers = users;
          _pendingCount = users.length;
          _isLoadingPending = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingPending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final fullName = user?['profile']?['fullName'] ?? 'Administrator';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Portal'),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            tooltip: 'Refresh',
            onPressed: _fetchPendingUsers,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchPendingUsers,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primaryDark,
                        AppColors.surface,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield_rounded, color: AppColors.accent, size: 28),
                          const SizedBox(width: 10),
                          Text(
                            'System Administration',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Welcome, $fullName',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Manage credential verifications, monitor incidents, and view hotspot geospatial intelligence.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'CORE MODULES',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),

                // ── 1. Big Button: Account Verification ──
                _AdminBigCard(
                  title: 'Account Verification',
                  subtitle: 'Review pending lawyer bar credentials and police officer service IDs',
                  icon: Icons.verified_user_rounded,
                  badgeText: _isLoadingPending
                      ? 'Checking...'
                      : (_pendingCount > 0 ? '$_pendingCount Pending Review' : 'All Clear'),
                  badgeColor: _pendingCount > 0 ? AppColors.warning : AppColors.success,
                  accentColor: AppColors.accent,
                  onTap: () async {
                    await context.push(AppRoutes.adminVerifications);
                    if (mounted) _fetchPendingUsers();
                  },
                ),
                const SizedBox(height: 16),

                // ── 2. Big Button: Case Details ──
                _AdminBigCard(
                  title: 'Case Details',
                  subtitle: 'Browse, search, and monitor all citizen incident reports across the island',
                  icon: Icons.folder_shared_rounded,
                  badgeText: 'Case Registry',
                  accentColor: AppColors.info,
                  onTap: () => context.push(AppRoutes.adminCases),
                ),
                const SizedBox(height: 16),

                // ── 3. Big Button: Hotspot Map ──
                _AdminBigCard(
                  title: 'Hotspot Map',
                  subtitle: 'Interactive map and geospatial clustering analytics of reported human rights incidents',
                  icon: Icons.map_rounded,
                  badgeText: 'Geospatial Analytics',
                  accentColor: AppColors.warning,
                  onTap: () => context.push(AppRoutes.dashboard),
                ),
                const SizedBox(height: 32),

                // ── Direct Pending List on Dashboard ──
                if (_pendingUsers.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'AWAITING APPROVAL (${_pendingUsers.length})',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.warning,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await context.push(AppRoutes.adminVerifications);
                          _fetchPendingUsers();
                        },
                        child: const Text('View All →', style: TextStyle(color: AppColors.accent)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._pendingUsers.take(4).map((rawUser) {
                    final u = rawUser as Map<String, dynamic>;
                    final profile = u['profile'] as Map<String, dynamic>? ?? {};
                    final name = profile['fullName'] ?? 'Applicant';
                    final email = u['email'] ?? 'No email';
                    final role = u['role'] as String?;
                    final isLawyer = role == 'lawyer';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: (isLawyer ? AppColors.accent : AppColors.info).withValues(alpha: 0.15),
                            child: Icon(
                              isLawyer ? Icons.gavel_rounded : Icons.local_police_rounded,
                              color: isLawyer ? AppColors.accent : AppColors.info,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final uid = u['_id'] as String;
                              await context.push('${AppRoutes.adminVerifications}/$uid', extra: u);
                              _fetchPendingUsers();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryDark,
                              foregroundColor: AppColors.accent,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: AppColors.accent),
                              ),
                            ),
                            child: const Text('Review', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],

                // ── Logout Button ──
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go(AppRoutes.login);
                    },
                    icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                    label: const Text('Logout from Admin Portal', style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminBigCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String badgeText;
  final Color? badgeColor;
  final Color accentColor;
  final VoidCallback onTap;

  const _AdminBigCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badgeText,
    this.badgeColor,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBadgeColor = badgeColor ?? accentColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: accentColor, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: effectiveBadgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: effectiveBadgeColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          color: effectiveBadgeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
