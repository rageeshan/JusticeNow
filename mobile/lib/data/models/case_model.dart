import '../../core/constants/app_constants.dart';

enum CaseStatus {
  submitted,
  underReview,
  investigating,
  resolved,
  closed;

  String get label => switch (this) {
        CaseStatus.submitted => 'Submitted',
        CaseStatus.underReview => 'Under Review',
        CaseStatus.investigating => 'Being Investigated',
        CaseStatus.resolved => 'Resolved',
        CaseStatus.closed => 'Closed',
      };

  String get description => switch (this) {
        CaseStatus.submitted => 'Your report has been received and is in the queue.',
        CaseStatus.underReview => 'A case officer is reviewing your submission.',
        CaseStatus.investigating => 'An investigation is actively underway.',
        CaseStatus.resolved => 'The case has been resolved or referred appropriately.',
        CaseStatus.closed => 'This case has been formally closed.',
      };
}

enum TimelineEventType { submitted, review, update, milestone, resolved }

class TimelineEvent {
  final String id;
  final DateTime date;
  final String title;
  final String description;
  final TimelineEventType type;
  final bool isLatest;

  const TimelineEvent({
    required this.id,
    required this.date,
    required this.title,
    required this.description,
    required this.type,
    this.isLatest = false,
  });
}

class InvestigatorRemark {
  final DateTime date;
  final String officerAlias; // e.g. "Officer A" — never a real name
  final String message;

  const InvestigatorRemark({
    required this.date,
    required this.officerAlias,
    required this.message,
  });
}

class CaseModel {
  final String id; // e.g. "JN-2024-0042"
  final DateTime submittedAt;
  final String category;
  final String categoryLabel;
  final CaseStatus status;
  final String title;
  final String location;
  final DateTime incidentDate;
  final bool isAnonymous;
  final String summary;
  final List<TimelineEvent> timeline;
  final List<InvestigatorRemark> remarks;
  final String? nextStep;
  final DateTime? expectedUpdateBy;
  final bool hasEvidence;
  final String rawStatus;
  final String? assignedOfficerName;
  final String? assignedOfficerPhone;
  final String? assignedOfficerEmail;
  final String? assignedOfficerDistrict;
  final String? investigationStartDate;
  final String? investigationStartTime;
  final String? policeAcceptNotes;

  const CaseModel({
    required this.id,
    required this.submittedAt,
    required this.category,
    required this.categoryLabel,
    required this.status,
    required this.title,
    required this.location,
    required this.incidentDate,
    required this.isAnonymous,
    required this.summary,
    required this.timeline,
    required this.remarks,
    this.nextStep,
    this.expectedUpdateBy,
    this.hasEvidence = false,
    this.rawStatus = 'submitted',
    this.assignedOfficerName,
    this.assignedOfficerPhone,
    this.assignedOfficerEmail,
    this.assignedOfficerDistrict,
    this.investigationStartDate,
    this.investigationStartTime,
    this.policeAcceptNotes,
  });

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status']?.toString() ?? 'submitted';
    final status = switch (statusStr) {
      'submitted' => CaseStatus.submitted,
      'under_review' => CaseStatus.underReview,
      'investigating' ||
      'evidence_requested' ||
      'awaiting_lawyer_selection' ||
      'legal_action_initiated' ||
      'assigned_to_police' ||
      'in_progress_police' ||
      'referred_to_ngo' =>
        CaseStatus.investigating,
      'resolved' || 'completed' => CaseStatus.resolved,
      'closed' || 'rejected' => CaseStatus.closed,
      _ => CaseStatus.submitted,
    };

    final categoryStr = json['category']?.toString() ?? 'other';
    final categoryLabel = AppConstants.caseCategories[categoryStr] ??
        categoryStr.replaceAll('_', ' ').toUpperCase();

    String locStr = 'Unknown Location';
    if (json['location'] is Map) {
      final loc = json['location'] as Map;
      final parts = [loc['address'], loc['city'], loc['state'], loc['country']]
          .where((e) => e != null && e.toString().trim().isNotEmpty)
          .map((e) => e.toString().trim())
          .toList();
      if (parts.isNotEmpty) {
        locStr = parts.join(', ');
      }
    } else if (json['location'] is String && (json['location'] as String).trim().isNotEmpty) {
      locStr = json['location'] as String;
    }

    final rawTimeline = json['timeline'] as List? ?? [];
    final timelineEvents = <TimelineEvent>[];
    for (int i = 0; i < rawTimeline.length; i++) {
      final t = rawTimeline[i];
      if (t is Map) {
        final tStatus = t['status']?.toString() ?? 'Update';
        timelineEvents.add(TimelineEvent(
          id: t['_id']?.toString() ?? 'ev-$i',
          date: DateTime.tryParse(t['createdAt']?.toString() ?? '') ?? DateTime.now(),
          title: tStatus.replaceAll('_', ' ').toUpperCase(),
          description: t['note']?.toString() ?? '',
          type: switch (tStatus) {
            'submitted' => TimelineEventType.submitted,
            'under_review' => TimelineEventType.review,
            'resolved' => TimelineEventType.resolved,
            _ => TimelineEventType.update,
          },
          isLatest: i == rawTimeline.length - 1,
        ));
      }
    }

    final rawUpdates = (json['publicUpdates'] as List?) ?? [];
    final remarksList = <InvestigatorRemark>[];
    for (final u in rawUpdates) {
      if (u is Map) {
        remarksList.add(InvestigatorRemark(
          date: DateTime.tryParse(u['createdAt']?.toString() ?? '') ?? DateTime.now(),
          officerAlias: u['officerAlias']?.toString() ?? 'Case Officer',
          message: u['message']?.toString() ?? '',
        ));
      }
    }

    final rawEvidence = json['evidence'] as List?;
    final hasEv = rawEvidence != null && rawEvidence.isNotEmpty;

    String? officerName;
    String? officerPhone;
    String? officerEmail;
    String? officerDistrict;
    if (json['assignedOfficer'] is Map) {
      final o = json['assignedOfficer'] as Map;
      officerName = o['name']?.toString() ??
          (o['profile'] is Map ? o['profile']['fullName']?.toString() : null) ??
          o['email']?.toString();
      officerPhone = o['phone']?.toString() ??
          (o['profile'] is Map ? o['profile']['phone']?.toString() : null);
      officerEmail = o['email']?.toString();
      officerDistrict = o['district']?.toString() ??
          (o['profile'] is Map ? o['profile']['district']?.toString() : null);
    }

    String? invDate;
    if (json['investigationStartDate'] != null) {
      final d = DateTime.tryParse(json['investigationStartDate'].toString());
      if (d != null) {
        invDate = '${d.day}/${d.month}/${d.year}';
      } else {
        invDate = json['investigationStartDate'].toString();
      }
    }

    return CaseModel(
      id: json['referenceNumber']?.toString() ?? json['_id']?.toString() ?? '',
      submittedAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.tryParse(json['submittedAt']?.toString() ?? '') ??
          DateTime.now(),
      category: categoryStr,
      categoryLabel: categoryLabel,
      status: status,
      title: json['title']?.toString() ?? 'Untitled Report',
      location: locStr,
      incidentDate: DateTime.tryParse(json['incidentDate']?.toString() ?? '') ?? DateTime.now(),
      isAnonymous: json['isAnonymous'] == true,
      summary: json['description']?.toString() ?? '',
      timeline: timelineEvents,
      remarks: remarksList,
      nextStep: json['adminFeedback']?.toString(),
      hasEvidence: hasEv,
      rawStatus: statusStr,
      assignedOfficerName: officerName,
      assignedOfficerPhone: officerPhone,
      assignedOfficerEmail: officerEmail,
      assignedOfficerDistrict: officerDistrict,
      investigationStartDate: invDate,
      investigationStartTime: json['investigationStartTime']?.toString(),
      policeAcceptNotes: json['policeAcceptNotes']?.toString(),
    );
  }
}
