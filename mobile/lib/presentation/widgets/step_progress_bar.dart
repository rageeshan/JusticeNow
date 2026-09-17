import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Animated step progress bar for the multi-step report flow.
/// Shows current step out of total, with filled/outlined circles.
class StepProgressBar extends StatelessWidget {
  final int currentStep; // 1-indexed
  final int totalSteps;
  final List<String> labels;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Step circles + connector lines
        Row(
          children: List.generate(totalSteps * 2 - 1, (i) {
            if (i.isOdd) {
              // Connector line
              final stepIndex = (i ~/ 2) + 1;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 2,
                  color: stepIndex < currentStep
                      ? AppColors.accent
                      : AppColors.divider,
                ),
              );
            }

            // Step circle
            final step = i ~/ 2 + 1;
            final isDone = step < currentStep;
            final isActive = step == currentStep;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? AppColors.accent
                    : isActive
                        ? AppColors.accent.withValues(alpha: 0.15)
                        : Colors.transparent,
                border: Border.all(
                  color: isDone || isActive
                      ? AppColors.accent
                      : AppColors.divider,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check_rounded,
                        size: 16, color: AppColors.primaryDark)
                    : Text(
                        '$step',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? AppColors.accent
                              : AppColors.textMuted,
                        ),
                      ),
              ),
            );
          }),
        ),

        const SizedBox(height: 8),

        // Labels row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(totalSteps, (i) {
            final step = i + 1;
            final isActive = step == currentStep;
            final isDone = step < currentStep;
            return SizedBox(
              width: 56,
              child: Text(
                labels[i],
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isDone || isActive
                      ? AppColors.accent
                      : AppColors.textMuted,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
