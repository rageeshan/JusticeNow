import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/notification_repository.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationRepository _notifRepo = NotificationRepository();
  bool _isLoading = true;
  List<dynamic> _notifications = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchNotifications();
    });
  }

  Future<void> _fetchNotifications() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _notifRepo.getMyNotifications();
      if (mounted) {
        setState(() {
          _notifications = (res['notifications'] as List<dynamic>?) ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await _notifRepo.markAsRead(id);
      _fetchNotifications();
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notifRepo.markAllAsRead();
      _fetchNotifications();
    } catch (_) {}
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('MMM dd, yyyy • hh:mm a').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatIncidentDate(dynamic dateVal) {
    if (dateVal == null) return '';
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
        title: const Text('Notifications'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          if (_notifications.any((n) => n['isRead'] == false))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all read', style: TextStyle(color: AppColors.accent, fontSize: 13)),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _fetchNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _fetchNotifications, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          const Text(
                            'No notifications yet',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Updates on your reported incidents will appear here.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchNotifications,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final notif = _notifications[index] as Map<String, dynamic>;
                          final id = notif['_id'] as String;
                          final title = notif['title'] ?? 'Notification';
                          final message = notif['message'] ?? '';
                          final type = notif['type'] as String?;
                          final isRead = notif['isRead'] == true;
                          final createdAt = notif['createdAt'] as String?;
                          final isAwaitingLawyer = type == 'awaiting_lawyer_selection';
                          final isRejected = type == 'case_rejected';
                          final isNewCaseRequest = type == 'new_case_request';
                          final isLawyerDeclined = type == 'lawyer_declined';
                          final isApprovedScheduled = type == 'case_approved_scheduled';

                          final notifData = notif['data'] as Map<String, dynamic>? ?? {};
                          final caseRef = notif['case'] ?? notifData['caseId'];
                          final caseId = caseRef is Map ? caseRef['_id']?.toString() : caseRef?.toString();
                          final caseMap = caseRef is Map<String, dynamic> ? caseRef : null;
                          final incidentTitle = caseMap?['title'] ??
                              notifData['caseTitle'] ??
                              (caseMap?['referenceNumber'] != null ? 'Case #${caseMap!['referenceNumber']}' : null);
                          final incidentDateRaw = caseMap?['incidentDate'] ?? caseMap?['createdAt'] ?? notifData['incidentDate'];

                          Color badgeColor = AppColors.info;
                          IconData iconData = Icons.notifications_rounded;
                          if (isAwaitingLawyer || isApprovedScheduled) {
                            badgeColor = AppColors.success;
                            iconData = isApprovedScheduled ? Icons.event_available_rounded : Icons.gavel_rounded;
                          } else if (isRejected || isLawyerDeclined) {
                            badgeColor = AppColors.error;
                            iconData = Icons.cancel_outlined;
                          } else if (isNewCaseRequest) {
                            badgeColor = AppColors.accent;
                            iconData = Icons.folder_shared_rounded;
                          }

                          return GestureDetector(
                            onTap: () {
                              if (!isRead) _markAsRead(id);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isRead ? AppColors.surface : AppColors.surfaceBlue,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isRead ? AppColors.border : AppColors.borderBlue,
                                  width: isRead ? 1 : 1.5,
                                ),
                                boxShadow: const [AppColors.cardShadow],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Banner: Incident Title and Date
                                  if (incidentTitle != null && incidentTitle.toString().isNotEmpty) ...[
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isRead ? AppColors.surfaceSubtle : AppColors.surface,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isRead ? AppColors.border : AppColors.borderBlue,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.assignment_outlined, size: 14, color: badgeColor),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              incidentTitle.toString(),
                                              style: TextStyle(
                                                color: isRead ? AppColors.textPrimary : AppColors.primary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (incidentDateRaw != null) ...[
                                            const SizedBox(width: 8),
                                            const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textMuted),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatIncidentDate(incidentDateRaw),
                                              style: const TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: badgeColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(iconData, color: badgeColor, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: TextStyle(
                                                color: AppColors.textPrimary,
                                                fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatDate(createdAt),
                                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          margin: const EdgeInsets.only(top: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    message,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      height: 1.45,
                                    ),
                                  ),

                                  // Action Button for Find Lawyer (Citizen - Initial or Declined)
                                  if (isAwaitingLawyer || isLawyerDeclined) ...[
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          if (!isRead) _markAsRead(id);
                                          final targetPath = caseId != null
                                              ? '${AppRoutes.legalAid}?caseId=$caseId'
                                              : AppRoutes.legalAid;
                                          context.push(targetPath);
                                        },
                                        icon: const Icon(Icons.person_search_rounded, size: 18),
                                        label: Text(isLawyerDeclined ? 'Find another lawyer' : 'Find a Lawyer'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 13),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],

                                  // Action Button for Case Approved: View in History
                                  if (isApprovedScheduled) ...[
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          if (!isRead) _markAsRead(id);
                                          context.push(AppRoutes.myCases);
                                        },
                                        icon: const Icon(Icons.history_rounded, size: 18),
                                        label: const Text('View in History'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.success,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 13),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],

                                  // Action Button for Lawyer: View Case Details
                                  if (isNewCaseRequest && caseId != null) ...[
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          if (!isRead) _markAsRead(id);
                                          context.push('/legal-aid/lawyer-case/$caseId');
                                        },
                                        icon: const Icon(Icons.folder_shared_rounded, size: 18),
                                        label: const Text('View Case Request'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 13),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
