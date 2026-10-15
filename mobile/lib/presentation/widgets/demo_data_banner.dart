import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Reusable amber demo data banner — shown on all citizen screens
/// to make clear that data is sample/demonstration only.
class DemoDataBanner extends StatelessWidget {
  const DemoDataBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: const Color(0xFF92400E).withValues(alpha: 0.15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.science_outlined, size: 14, color: Color(0xFFD97706)),
          const SizedBox(width: 6),
          Text(
            'DEMO DATA — This is a prototype. No real data is shown.',
            style: TextStyle(
              color: const Color(0xFFD97706),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable privacy notice card shown before sensitive steps
class PrivacyNoticeCard extends StatelessWidget {
  final String message;
  final IconData icon;

  const PrivacyNoticeCard({
    super.key,
    required this.message,
    this.icon = Icons.shield_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
