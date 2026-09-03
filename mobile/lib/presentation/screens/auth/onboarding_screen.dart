import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, AppColors.accentLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.balance_rounded, size: 48, color: AppColors.primaryDark),
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'Speak Up.\nSafely.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Report human rights violations anonymously. Track your case. Connect with legal aid.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
              ),

              const Spacer(),

              // Feature chips
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _FeatureChip(icon: Icons.shield_outlined, label: 'Anonymous'),
                  _FeatureChip(icon: Icons.track_changes_rounded, label: 'Track Cases'),
                  _FeatureChip(icon: Icons.gavel_rounded, label: 'Legal Aid'),
                  _FeatureChip(icon: Icons.lock_outline_rounded, label: 'Encrypted'),
                ],
              ),

              const SizedBox(height: 40),

              // Anonymous Entry CTA
              ElevatedButton.icon(
                onPressed: authState.isLoading
                    ? null
                    : () async {
                        await ref.read(authProvider.notifier).loginAnonymous();
                        if (context.mounted) context.go(AppRoutes.myCases);
                      },
                icon: const Icon(Icons.person_outline_rounded),
                label: authState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark),
                      )
                    : const Text('Continue Anonymously'),
              ),

              const SizedBox(height: 12),

              // Login / Register
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Login or Create Account'),
              ),

              const SizedBox(height: 16),

              // Staff login
              TextButton(
                onPressed: () {
                  // TODO: Navigate to Firebase-based staff login
                },
                child: Text(
                  'Staff / NGO / Officer Login',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
