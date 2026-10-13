import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class OfficerCaseCard extends StatelessWidget {
  final Map<String, dynamic> caseData;
  final VoidCallback onTap;

  const OfficerCaseCard({
    super.key,
    required this.caseData,
    required this.onTap,
  });

  Color _getStatusColor(String status) => switch (status) {
        'submitted' => AppColors.statusSubmitted,
        'under_review' => AppColors.statusUnderReview,
        'investigating' => AppColors.statusInvestigating,
        'evidence_requested' => AppColors.warning,
        'resolved' => AppColors.statusResolved,
        'closed' => AppColors.statusClosed,
        'rejected' => AppColors.statusRejected,
        _ => AppColors.textMuted,
      };

  Color _getPriorityColor(String priority) => switch (priority.toLowerCase()) {
        'critical' => AppColors.error,
        'high' => const Color(0xFFF97316),
        'medium' => AppColors.warning,
        'low' => AppColors.info,
        _ => AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    final status = caseData['status'] as String? ?? 'submitted';
    final priority = caseData['priority'] as String? ?? 'medium';
    final category = caseData['category'] as String? ?? 'other';
    final evidence = (caseData['evidence'] as List?) ?? [];
    final isAnonymous = caseData['isAnonymous'] == true;

    final locationMap = caseData['location'] is Map ? caseData['location'] as Map : null;
    final locationText = [
      locationMap?['city'],
      locationMap?['country'],
    ].where((v) => v != null && v.toString().isNotEmpty).join(', ');

    final dateStr = caseData['incidentDate']?.toString().split('T').first ??
        caseData['createdAt']?.toString().split('T').first ??
        '';

    final statusColor = _getStatusColor(status);
    final priorityColor = _getPriorityColor(priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: priority == 'critical'
              ? AppColors.error.withValues(alpha: 0.35)
              : AppColors.divider,
          width: priority == 'critical' ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.accent.withValues(alpha: 0.08),
          highlightColor: AppColors.accent.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Ref number + Priority & Status Badges
                Row(
                  children: [
                    Text(
                      (caseData['referenceNumber'] ?? 'Case').toString(),
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    // Priority Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: priorityColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppConstants.priorityLabels[priority] ?? priority.toUpperCase(),
                            style: TextStyle(
                              color: priorityColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        AppConstants.caseStatusLabels[status] ?? status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  (caseData['title'] ?? 'Untitled Case').toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),

                // Description snippet
                if (caseData['description'] != null)
                  Text(
                    caseData['description'].toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                const SizedBox(height: 12),

                // Meta Row: Category, Date, Evidence Count, Anonymous badge
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Category
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.folder_outlined, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          AppConstants.caseCategories[category] ?? category,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // Date
                    if (dateStr.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.event_outlined, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),

                    // Location
                    if (locationText.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.place_outlined, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            locationText,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),

                    // Evidence Count
                    if (evidence.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.attach_file_rounded, size: 14, color: AppColors.accent),
                          const SizedBox(width: 2),
                          Text(
                            '${evidence.length}',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                    // Anonymous Shield
                    if (isAnonymous)
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined, size: 13, color: AppColors.textMuted),
                          SizedBox(width: 3),
                          Text(
                            'Anon',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
