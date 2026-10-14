import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class RegistrationSuccessScreen extends StatelessWidget {
  final String? role;

  const RegistrationSuccessScreen({super.key, this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Icon Container
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.warning.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.4), width: 2),
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  size: 50,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                'Your account is pending admin approval',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'Thank you for registering with JusticeNow. Your professional credentials and submission details are currently being reviewed by our administrative verification team.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.85),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Verification Note Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, color: AppColors.accent, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You will receive access to your account once verification is completed.',
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Back to Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.go(AppRoutes.login),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back to Login'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
