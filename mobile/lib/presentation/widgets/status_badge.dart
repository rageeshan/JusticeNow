import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/case_model.dart';

/// Colored status badge chip matching the existing AppColors palette
class StatusBadge extends StatelessWidget {
  final CaseStatus status;
  final bool large;

  const StatusBadge({super.key, required this.status, this.large = false});

  Color get _color => switch (status) {
        CaseStatus.submitted => AppColors.statusSubmitted,
        CaseStatus.underReview => AppColors.statusUnderReview,
        CaseStatus.investigating => AppColors.statusInvestigating,
        CaseStatus.resolved => AppColors.statusResolved,
        CaseStatus.closed => AppColors.statusClosed,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 8,
        vertical: large ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: _color,
              fontSize: large ? 13 : 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
