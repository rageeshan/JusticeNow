import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/case_model.dart';

/// Visual vertical timeline showing case investigation progress
class CaseTimelineWidget extends StatelessWidget {
  final List<TimelineEvent> events;

  const CaseTimelineWidget({super.key, required this.events});

  Color _eventColor(TimelineEventType type) => switch (type) {
        TimelineEventType.submitted => AppColors.statusSubmitted,
        TimelineEventType.review => AppColors.statusUnderReview,
        TimelineEventType.update => AppColors.statusInvestigating,
        TimelineEventType.milestone => AppColors.accent,
        TimelineEventType.resolved => AppColors.statusResolved,
      };

  IconData _eventIcon(TimelineEventType type) => switch (type) {
        TimelineEventType.submitted => Icons.send_outlined,
        TimelineEventType.review => Icons.manage_search_outlined,
        TimelineEventType.update => Icons.update_outlined,
        TimelineEventType.milestone => Icons.flag_outlined,
        TimelineEventType.resolved => Icons.check_circle_outline,
      };

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(events.length, (i) {
        final event = events[i];
        final isLast = i == events.length - 1;
        final color = _eventColor(event.type);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline spine
              SizedBox(
                width: 36,
                child: Column(
                  children: [
                    // Icon circle
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: event.isLatest
                            ? color
                            : color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color,
                          width: event.isLatest ? 0 : 1.5,
                        ),
                      ),
                      child: Icon(
                        _eventIcon(event.type),
                        size: 16,
                        color: event.isLatest ? Colors.white : color,
                      ),
                    ),
                    // Connector line
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: AppColors.divider,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: isLast ? 0 : 24,
                    top: 6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: TextStyle(
                                color: event.isLatest
                                    ? AppColors.textPrimary
                                    : AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: event.isLatest
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (event.isLatest)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Latest',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatDate(event.date),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        event.description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
