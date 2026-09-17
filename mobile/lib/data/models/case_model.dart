// ─────────────────────────────────────────────────────────────────────────────
//  JusticeNow — Citizen Case Model
//  All data structures for the citizen-facing case experience
// ─────────────────────────────────────────────────────────────────────────────

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
  });
}
