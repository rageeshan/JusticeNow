import 'case_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  JusticeNow — Local Mock Cases
//  ⚠️  ALL DATA IS DEMO / SAMPLE — Not real incidents
// ─────────────────────────────────────────────────────────────────────────────

final List<CaseModel> kMockCases = [
  CaseModel(
    id: 'JN-2024-0042',
    submittedAt: DateTime(2024, 11, 3, 9, 15),
    category: 'police_brutality',
    categoryLabel: 'Police Brutality',
    status: CaseStatus.investigating,
    title: 'Excessive use of force during peaceful demonstration',
    location: 'Colombo, Western Province',
    incidentDate: DateTime(2024, 10, 28),
    isAnonymous: false,
    summary:
        'An individual reported being subjected to excessive physical force by uniformed officers during a peaceful protest gathering. Multiple witnesses were present at the scene.',
    hasEvidence: true,
    nextStep:
        'Field investigators are scheduled to interview witnesses. You will be notified once preliminary findings are ready.',
    expectedUpdateBy: DateTime(2024, 12, 15),
    timeline: [
      TimelineEvent(
        id: 'ev-1',
        date: DateTime(2024, 11, 3, 9, 15),
        title: 'Case Submitted',
        description:
            'Your report was received and a unique case ID was assigned. Your submission is encrypted and secure.',
        type: TimelineEventType.submitted,
      ),
      TimelineEvent(
        id: 'ev-2',
        date: DateTime(2024, 11, 5, 14, 30),
        title: 'Initial Review Completed',
        description:
            'A case officer reviewed your submission and confirmed it meets the criteria for investigation. The case has been escalated.',
        type: TimelineEventType.review,
      ),
      TimelineEvent(
        id: 'ev-3',
        date: DateTime(2024, 11, 10, 10, 0),
        title: 'Evidence Verified',
        description:
            'Submitted evidence (photographs and video footage) has been authenticated and logged into the secure evidence chain.',
        type: TimelineEventType.milestone,
      ),
      TimelineEvent(
        id: 'ev-4',
        date: DateTime(2024, 11, 18, 11, 45),
        title: 'Field Investigation Opened',
        description:
            'A field investigation team has been assigned. They will gather additional witness statements and on-site evidence.',
        type: TimelineEventType.update,
        isLatest: true,
      ),
    ],
    remarks: [
      InvestigatorRemark(
        date: DateTime(2024, 11, 5, 14, 30),
        officerAlias: 'Officer A',
        message:
            'Initial review complete. The report is detailed and corroborated by photographic evidence. Escalating for full investigation.',
      ),
      InvestigatorRemark(
        date: DateTime(2024, 11, 18, 11, 45),
        officerAlias: 'Officer B',
        message:
            'Field team assigned. We are coordinating with local authorities to arrange witness interviews. Please ensure your contact information is up to date.',
      ),
    ],
  ),

  CaseModel(
    id: 'JN-2024-0071',
    submittedAt: DateTime(2024, 11, 20, 16, 40),
    category: 'arbitrary_detention',
    categoryLabel: 'Unlawful Detention',
    status: CaseStatus.underReview,
    title: 'Unlawful detention without formal charges',
    location: 'Kandy, Central Province',
    incidentDate: DateTime(2024, 11, 17),
    isAnonymous: true,
    summary:
        'An anonymous report describes an individual being detained for over 72 hours without being formally charged or given access to legal counsel.',
    hasEvidence: false,
    nextStep:
        'A case officer will complete the initial review within 5 business days and may request additional information.',
    expectedUpdateBy: DateTime(2024, 12, 1),
    timeline: [
      TimelineEvent(
        id: 'ev-1',
        date: DateTime(2024, 11, 20, 16, 40),
        title: 'Case Submitted Anonymously',
        description:
            'Your anonymous report was received. No personal information was recorded. A case ID was generated for tracking.',
        type: TimelineEventType.submitted,
      ),
      TimelineEvent(
        id: 'ev-2',
        date: DateTime(2024, 11, 21, 9, 0),
        title: 'Assigned to Review Queue',
        description:
            'Your report has been added to the review queue and will be assessed by a trained case officer.',
        type: TimelineEventType.review,
        isLatest: true,
      ),
    ],
    remarks: [
      InvestigatorRemark(
        date: DateTime(2024, 11, 21, 9, 0),
        officerAlias: 'Officer C',
        message:
            'Report received. We acknowledge the sensitivity of this case and the anonymous submission. We will proceed with care and discretion.',
      ),
    ],
  ),

  CaseModel(
    id: 'JN-2024-0019',
    submittedAt: DateTime(2024, 9, 10, 8, 0),
    category: 'gender_based_violence',
    categoryLabel: 'Gender-Based Violence',
    status: CaseStatus.resolved,
    title: 'Workplace harassment and intimidation',
    location: 'Galle, Southern Province',
    incidentDate: DateTime(2024, 9, 5),
    isAnonymous: false,
    summary:
        'A reported case of sustained workplace harassment and intimidation based on gender. The case was investigated and referred to the relevant tribunal.',
    hasEvidence: true,
    nextStep: null,
    expectedUpdateBy: null,
    timeline: [
      TimelineEvent(
        id: 'ev-1',
        date: DateTime(2024, 9, 10, 8, 0),
        title: 'Case Submitted',
        description: 'Report received with supporting documentation.',
        type: TimelineEventType.submitted,
      ),
      TimelineEvent(
        id: 'ev-2',
        date: DateTime(2024, 9, 12, 11, 0),
        title: 'Initial Review Completed',
        description: 'Case validated and escalated for full investigation.',
        type: TimelineEventType.review,
      ),
      TimelineEvent(
        id: 'ev-3',
        date: DateTime(2024, 9, 20, 9, 30),
        title: 'Investigation In Progress',
        description:
            'Investigators gathered testimony and reviewed workplace records.',
        type: TimelineEventType.update,
      ),
      TimelineEvent(
        id: 'ev-4',
        date: DateTime(2024, 10, 1, 14, 0),
        title: 'Referred to Tribunal',
        description:
            'Case referred to the relevant employment tribunal with a full investigation dossier.',
        type: TimelineEventType.milestone,
      ),
      TimelineEvent(
        id: 'ev-5',
        date: DateTime(2024, 10, 22, 10, 0),
        title: 'Case Resolved',
        description:
            'The tribunal issued a ruling. Remedial measures have been mandated. The case is formally closed.',
        type: TimelineEventType.resolved,
        isLatest: true,
      ),
    ],
    remarks: [
      InvestigatorRemark(
        date: DateTime(2024, 10, 22, 10, 0),
        officerAlias: 'Officer A',
        message:
            'The tribunal has issued its ruling and appropriate remedies have been ordered. Thank you for your courage in bringing this forward. This case has been formally resolved.',
      ),
    ],
  ),
];
