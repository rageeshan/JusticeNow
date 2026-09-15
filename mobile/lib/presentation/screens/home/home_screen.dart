import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Map backend role strings to user-friendly labels
  String _roleLabel(String? role) {
    switch (role) {
      case 'citizen':
        return 'Citizen';
      case 'police_officer':
        return 'Police Officer';
      case 'lawyer':
        return 'Lawyer';
      case 'admin':
        return 'Admin';
      case 'anonymous':
        return 'Anonymous';
      default:
        return 'User';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final fullName = user?['profile']?['fullName'] ?? user?['alias'] ?? 'User';
    final role = user?['role'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('JusticeNow'),
        backgroundColor: AppColors.primaryDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.onboarding);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Welcome Section ──
              Text(
                'Hello, $fullName',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _roleLabel(role),
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Quick Actions ──
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // Report Incident
              _ActionCard(
                icon: Icons.add_circle_outline_rounded,
                title: 'Report Incident',
                subtitle: 'Submit a new human rights incident report',
                color: AppColors.accent,
                onTap: () => context.push(AppRoutes.reportCase),
              ),
              const SizedBox(height: 12),

              // My Cases
              _ActionCard(
                icon: Icons.folder_outlined,
                title: 'My Cases',
                subtitle: 'View and track your submitted cases',
                color: AppColors.info,
                onTap: () => context.go(AppRoutes.myCases),
              ),
              const SizedBox(height: 12),

              // Legal Aid
              _ActionCard(
                icon: Icons.gavel_rounded,
                title: 'Legal Aid',
                subtitle: 'Find verified NGOs and legal practitioners',
                color: AppColors.success,
                onTap: () => context.push(AppRoutes.legalAid),
              ),
              const SizedBox(height: 12),

              // Dashboard — only for police officers and admins
              if (role == 'police_officer' || role == 'admin') ...[
                _ActionCard(
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  subtitle: 'View case analytics and statistics',
                  color: AppColors.warning,
                  onTap: () => context.push(AppRoutes.dashboard),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable action card widget
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
