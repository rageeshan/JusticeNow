/// Static mock data for Case Officer UI (no API yet).

class OfficerStaticData {
  OfficerStaticData._();

  static List<Map<String, dynamic>> seedCases() => [
        {
          '_id': 'off-case-001',
          'referenceNumber': 'JN-2026-00041',
          'title': 'Arbitrary detention during peaceful protest',
          'description':
              'On 12 March 2026, the reporter and several others were detained without charge while participating in a peaceful assembly near Central Square. They were held for approximately 18 hours, denied access to legal counsel, and released without documentation.',
          'category': 'arbitrary_detention',
          'incidentDate': '2026-03-12T00:00:00.000Z',
          'location': {
            'address': 'Central Square',
            'city': 'Colombo',
            'state': 'Western',
            'country': 'Sri Lanka',
          },
          'status': 'submitted',
          'priority': 'high',
          'isAnonymous': true,
          'reportedByAlias': 'User_A8F2C1',
          'submittedAt': '2026-03-13T08:22:00.000Z',
          'evidence': [
            {
              '_id': 'ev-001',
              'fileType': 'image',
              'originalName': 'detention_site_photo.jpg',
              'mimeType': 'image/jpeg',
              'sizeBytes': 2400000,
              'description': 'Photo of the holding facility entrance taken from the street',
              'uploadedAt': '2026-03-13T08:25:00.000Z',
            },
            {
              '_id': 'ev-002',
              'fileType': 'document',
              'originalName': 'witness_statement.pdf',
              'mimeType': 'application/pdf',
              'sizeBytes': 180000,
              'description': 'Signed statement from a fellow detainee',
              'uploadedAt': '2026-03-13T08:30:00.000Z',
            },
          ],
          'timeline': [
            {
              'status': 'submitted',
              'note': 'Case submitted by anonymous reporter',
              'createdAt': '2026-03-13T08:22:00.000Z',
            },
          ],
          'publicUpdates': <Map<String, dynamic>>[],
          'internalNotes': <Map<String, dynamic>>[],
          'adminFeedback': null,
          'userFeedback': null,
        },
        {
          '_id': 'off-case-002',
          'referenceNumber': 'JN-2026-00038',
          'title': 'Torture allegations at district police station',
          'description':
              'The reporter alleges physical abuse and prolonged interrogation without breaks at the District Police Station following a night-time arrest. Visible injuries were documented the following morning at a private clinic.',
          'category': 'torture',
          'incidentDate': '2026-03-05T00:00:00.000Z',
          'location': {
            'address': 'District Police Station',
            'city': 'Kandy',
            'state': 'Central',
            'country': 'Sri Lanka',
          },
          'status': 'under_review',
          'priority': 'critical',
          'isAnonymous': false,
          'reportedByAlias': 'citizen@example.com',
          'submittedAt': '2026-03-06T14:10:00.000Z',
          'evidence': [
            {
              '_id': 'ev-003',
              'fileType': 'image',
              'originalName': 'injury_documentation_1.jpg',
              'mimeType': 'image/jpeg',
              'sizeBytes': 3100000,
              'description': 'Clinical photo of bruises on left forearm',
              'uploadedAt': '2026-03-06T14:15:00.000Z',
            },
            {
              '_id': 'ev-004',
              'fileType': 'image',
              'originalName': 'injury_documentation_2.jpg',
              'mimeType': 'image/jpeg',
              'sizeBytes': 2800000,
              'description': 'Clinical photo of facial swelling',
              'uploadedAt': '2026-03-06T14:16:00.000Z',
            },
            {
              '_id': 'ev-005',
              'fileType': 'document',
              'originalName': 'clinic_medical_report.pdf',
              'mimeType': 'application/pdf',
              'sizeBytes': 420000,
              'description': 'Medical report from Green Valley Clinic',
              'uploadedAt': '2026-03-06T14:20:00.000Z',
            },
            {
              '_id': 'ev-006',
              'fileType': 'audio',
              'originalName': 'voice_note_timeline.m4a',
              'mimeType': 'audio/mp4',
              'sizeBytes': 950000,
              'description': 'Reporter voice note describing the sequence of events',
              'uploadedAt': '2026-03-06T15:01:00.000Z',
            },
          ],
          'timeline': [
            {
              'status': 'submitted',
              'note': 'Case submitted',
              'createdAt': '2026-03-06T14:10:00.000Z',
            },
            {
              'status': 'under_review',
              'note': 'Assigned to Case Officer for preliminary review',
              'createdAt': '2026-03-07T09:00:00.000Z',
            },
          ],
          'publicUpdates': <Map<String, dynamic>>[],
          'internalNotes': <Map<String, dynamic>>[],
          'adminFeedback': null,
          'userFeedback': null,
        },
        {
          '_id': 'off-case-003',
          'referenceNumber': 'JN-2026-00029',
          'title': 'Forced disappearance of community organizer',
          'description':
              'A local community organizer went missing after being approached by unidentified individuals in plain clothes outside their residence. Family members have not been able to locate them for 9 days. Last confirmed sighting was near the bus depot.',
          'category': 'forced_disappearance',
          'incidentDate': '2026-02-28T00:00:00.000Z',
          'location': {
            'address': 'Near Central Bus Depot',
            'city': 'Jaffna',
            'state': 'Northern',
            'country': 'Sri Lanka',
          },
          'status': 'evidence_requested',
          'priority': 'critical',
          'isAnonymous': true,
          'reportedByAlias': 'User_B3D9E2',
          'submittedAt': '2026-03-01T11:45:00.000Z',
          'evidence': [
            {
              '_id': 'ev-007',
              'fileType': 'image',
              'originalName': 'last_known_photo.jpg',
              'mimeType': 'image/jpeg',
              'sizeBytes': 1900000,
              'description': 'Most recent photo of the missing person',
              'uploadedAt': '2026-03-01T11:50:00.000Z',
            },
          ],
          'timeline': [
            {
              'status': 'submitted',
              'note': 'Case submitted by anonymous reporter',
              'createdAt': '2026-03-01T11:45:00.000Z',
            },
            {
              'status': 'under_review',
              'note': 'Initial triage completed',
              'createdAt': '2026-03-02T10:00:00.000Z',
            },
            {
              'status': 'evidence_requested',
              'note': 'Requested CCTV stills and additional witness contacts',
              'createdAt': '2026-03-04T16:30:00.000Z',
            },
          ],
          'publicUpdates': [
            {
              'message':
                  'We have received your report. Additional evidence has been requested to proceed with investigation. Please upload any CCTV stills or witness contacts if available.',
              'createdAt': '2026-03-04T16:30:00.000Z',
            },
          ],
          'internalNotes': [
            {
              'note': 'Evidence insufficient — only one photo. Need location corroboration.',
              'createdAt': '2026-03-04T16:28:00.000Z',
            },
          ],
          'adminFeedback': null,
          'userFeedback': null,
        },
        {
          '_id': 'off-case-004',
          'referenceNumber': 'JN-2026-00022',
          'title': 'Discrimination in public employment recruitment',
          'description':
              'The reporter claims systematic exclusion from a public-sector recruitment process based on ethnicity and place of origin, despite meeting all published eligibility criteria. Multiple similarly qualified applicants from the same community were also rejected without written reasons.',
          'category': 'discrimination',
          'incidentDate': '2026-02-10T00:00:00.000Z',
          'location': {
            'address': 'Ministry Recruitment Centre',
            'city': 'Colombo',
            'state': 'Western',
            'country': 'Sri Lanka',
          },
          'status': 'investigating',
          'priority': 'medium',
          'isAnonymous': false,
          'reportedByAlias': 'reporter.hr@mail.com',
          'submittedAt': '2026-02-15T09:30:00.000Z',
          'evidence': [
            {
              '_id': 'ev-008',
              'fileType': 'document',
              'originalName': 'rejection_letter.pdf',
              'mimeType': 'application/pdf',
              'sizeBytes': 95000,
              'description': 'Official rejection letter with no stated reason',
              'uploadedAt': '2026-02-15T09:35:00.000Z',
            },
            {
              '_id': 'ev-009',
              'fileType': 'document',
              'originalName': 'eligibility_certificates.zip',
              'mimeType': 'application/zip',
              'sizeBytes': 1200000,
              'description': 'Scanned certificates and eligibility documents',
              'uploadedAt': '2026-02-15T09:40:00.000Z',
            },
            {
              '_id': 'ev-010',
              'fileType': 'document',
              'originalName': 'vacancy_notice.pdf',
              'mimeType': 'application/pdf',
              'sizeBytes': 210000,
              'description': 'Published vacancy notice and criteria',
              'uploadedAt': '2026-02-15T09:42:00.000Z',
            },
          ],
          'timeline': [
            {
              'status': 'submitted',
              'note': 'Case submitted',
              'createdAt': '2026-02-15T09:30:00.000Z',
            },
            {
              'status': 'under_review',
              'note': 'Documents verified as authentic',
              'createdAt': '2026-02-18T11:00:00.000Z',
            },
            {
              'status': 'investigating',
              'note': 'Investigation opened — contacting recruitment board',
              'createdAt': '2026-02-22T14:00:00.000Z',
            },
          ],
          'publicUpdates': [
            {
              'message':
                  'Your case is under active investigation. We are reviewing the recruitment process documentation.',
              'createdAt': '2026-02-22T14:05:00.000Z',
            },
          ],
          'internalNotes': [
            {
              'note': 'Evidence package is solid. Proceeding to formal inquiry with the board.',
              'createdAt': '2026-02-22T13:55:00.000Z',
            },
          ],
          'adminFeedback': null,
          'userFeedback': null,
        },
        {
          '_id': 'off-case-005',
          'referenceNumber': 'JN-2026-00015',
          'title': 'Freedom of expression — journalist intimidation',
          'description':
              'An independent journalist received repeated anonymous threats after publishing an investigative piece on local land acquisition. Threats arrived via phone and social media over a two-week period.',
          'category': 'freedom_of_expression',
          'incidentDate': '2026-01-20T00:00:00.000Z',
          'location': {
            'address': null,
            'city': 'Galle',
            'state': 'Southern',
            'country': 'Sri Lanka',
          },
          'status': 'resolved',
          'priority': 'high',
          'isAnonymous': true,
          'reportedByAlias': 'User_C7A1F4',
          'submittedAt': '2026-01-25T17:00:00.000Z',
          'evidence': [
            {
              '_id': 'ev-011',
              'fileType': 'image',
              'originalName': 'threat_screenshots.png',
              'mimeType': 'image/png',
              'sizeBytes': 870000,
              'description': 'Screenshots of threatening messages',
              'uploadedAt': '2026-01-25T17:05:00.000Z',
            },
            {
              '_id': 'ev-012',
              'fileType': 'audio',
              'originalName': 'threat_call_recording.mp3',
              'mimeType': 'audio/mpeg',
              'sizeBytes': 1500000,
              'description': 'Recording of threatening phone call',
              'uploadedAt': '2026-01-25T17:10:00.000Z',
            },
          ],
          'timeline': [
            {
              'status': 'submitted',
              'note': 'Case submitted',
              'createdAt': '2026-01-25T17:00:00.000Z',
            },
            {
              'status': 'investigating',
              'note': 'Investigation started',
              'createdAt': '2026-01-28T10:00:00.000Z',
            },
            {
              'status': 'resolved',
              'note': 'Protective measures coordinated; threats ceased after intervention',
              'createdAt': '2026-02-20T12:00:00.000Z',
            },
          ],
          'publicUpdates': [
            {
              'message':
                  'Protective measures have been arranged with partner organizations. Please contact us if threats resume.',
              'createdAt': '2026-02-20T12:05:00.000Z',
            },
          ],
          'internalNotes': [
            {
              'note': 'Case closed successfully. Admin: escalate pattern monitoring in Southern province.',
              'createdAt': '2026-02-20T11:50:00.000Z',
            },
          ],
          'adminFeedback':
              'Pattern of intimidation against journalists in Southern province. Recommend regional monitoring.',
          'userFeedback':
              'Your case has been resolved. Protective measures are in place. Contact us if the situation changes.',
        },
      ];
}
