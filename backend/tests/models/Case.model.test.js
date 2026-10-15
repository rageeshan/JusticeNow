/**
 * Unit tests for Case model
 * Tests schema validation, defaults, indexes, and embedded subdocuments
 */

require('../setup');
const mongoose = require('mongoose');
const Case = require('../../src/models/Case.model');
const User = require('../../src/models/User.model');

describe('Case Model', () => {
  let reporter;

  beforeEach(async () => {
    reporter = await User.create({
      alias: 'Citizen-TEST01',
      role: 'citizen',
      isVerified: true,
      approvalStatus: 'approved',
    });
  });

  // ─── Schema & Defaults ─────────────────────────────────────────────────────

  describe('Schema defaults', () => {
    it('should create a valid case with required fields', async () => {
      const caseDoc = await Case.create({
        referenceNumber: 'JN-2026-00001',
        title: 'Test Incident Report',
        description: 'A detailed description of the incident.',
        category: 'arbitrary_detention',
        incidentDate: new Date('2026-01-15'),
        reportedBy: reporter._id,
      });

      expect(caseDoc.referenceNumber).toBe('JN-2026-00001');
      expect(caseDoc.status).toBe('submitted');
      expect(caseDoc.priority).toBe('medium');
      expect(caseDoc.isAnonymous).toBe(true);
      expect(caseDoc.isDeleted).toBe(false);
      expect(caseDoc.evidence).toHaveLength(0);
      expect(caseDoc.timeline).toHaveLength(0);
      expect(caseDoc.internalNotes).toHaveLength(0);
      expect(caseDoc.publicUpdates).toHaveLength(0);
    });

    it('should set timestamps on create', async () => {
      const caseDoc = await Case.create({
        referenceNumber: 'JN-2026-00002',
        title: 'Timestamp Test',
        description: 'Testing timestamps.',
        category: 'torture',
        incidentDate: new Date(),
        reportedBy: reporter._id,
      });

      expect(caseDoc.createdAt).toBeInstanceOf(Date);
      expect(caseDoc.updatedAt).toBeInstanceOf(Date);
    });
  });

  // ─── Validation ─────────────────────────────────────────────────────────────

  describe('Validation', () => {
    it('should reject case without required title', async () => {
      await expect(
        Case.create({
          referenceNumber: 'JN-2026-00003',
          description: 'No title.',
          category: 'other',
          incidentDate: new Date(),
          reportedBy: reporter._id,
        })
      ).rejects.toThrow(/title/i);
    });

    it('should reject case without required description', async () => {
      await expect(
        Case.create({
          referenceNumber: 'JN-2026-00004',
          title: 'No Description',
          category: 'other',
          incidentDate: new Date(),
          reportedBy: reporter._id,
        })
      ).rejects.toThrow(/description/i);
    });

    it('should reject case without required category', async () => {
      await expect(
        Case.create({
          referenceNumber: 'JN-2026-00005',
          title: 'No Category',
          description: 'Missing category.',
          incidentDate: new Date(),
          reportedBy: reporter._id,
        })
      ).rejects.toThrow();
    });

    it('should reject invalid category enum value', async () => {
      await expect(
        Case.create({
          referenceNumber: 'JN-2026-00006',
          title: 'Bad Category',
          description: 'Invalid category.',
          category: 'not_a_valid_category',
          incidentDate: new Date(),
          reportedBy: reporter._id,
        })
      ).rejects.toThrow();
    });

    it('should reject case without incidentDate', async () => {
      await expect(
        Case.create({
          referenceNumber: 'JN-2026-00007',
          title: 'No Date',
          description: 'Missing date.',
          category: 'discrimination',
          reportedBy: reporter._id,
        })
      ).rejects.toThrow();
    });

    it('should reject case without reportedBy', async () => {
      await expect(
        Case.create({
          referenceNumber: 'JN-2026-00008',
          title: 'No Reporter',
          description: 'Missing reporter.',
          category: 'discrimination',
          incidentDate: new Date(),
        })
      ).rejects.toThrow();
    });

    it('should enforce unique referenceNumber', async () => {
      await Case.create({
        referenceNumber: 'JN-2026-DUPE1',
        title: 'First',
        description: 'First case.',
        category: 'other',
        incidentDate: new Date(),
        reportedBy: reporter._id,
      });

      await expect(
        Case.create({
          referenceNumber: 'JN-2026-DUPE1',
          title: 'Second',
          description: 'Duplicate refnum.',
          category: 'other',
          incidentDate: new Date(),
          reportedBy: reporter._id,
        })
      ).rejects.toThrow();
    });

    it('should enforce title maxlength of 200', async () => {
      await expect(
        Case.create({
          referenceNumber: 'JN-2026-00009',
          title: 'A'.repeat(201),
          description: 'Long title.',
          category: 'other',
          incidentDate: new Date(),
          reportedBy: reporter._id,
        })
      ).rejects.toThrow();
    });

    it('should accept all valid status values', async () => {
      const validStatuses = [
        'submitted', 'under_review', 'investigating', 'evidence_requested',
        'referred_to_ngo', 'legal_action_initiated', 'awaiting_lawyer_selection',
        'in_progress', 'in_progress_police', 'assigned_to_police',
        'completed', 'resolved', 'closed', 'rejected',
      ];

      for (let i = 0; i < validStatuses.length; i++) {
        const status = validStatuses[i];
        const caseDoc = await Case.create({
          referenceNumber: `JN-S-${i}-${status.substring(0, 8)}`,
          title: `Status test ${status}`,
          description: 'Status validation.',
          category: 'other',
          incidentDate: new Date(),
          reportedBy: reporter._id,
          status,
        });
        expect(caseDoc.status).toBe(status);
      }
    });

    it('should reject invalid priority', async () => {
      await expect(
        Case.create({
          referenceNumber: 'JN-2026-00010',
          title: 'Bad Priority',
          description: 'Invalid priority.',
          category: 'other',
          incidentDate: new Date(),
          reportedBy: reporter._id,
          priority: 'urgent', // not in enum
        })
      ).rejects.toThrow();
    });
  });

  // ─── Embedded Subdocuments ─────────────────────────────────────────────────

  describe('Timeline events', () => {
    it('should add timeline entries', async () => {
      const caseDoc = await Case.create({
        referenceNumber: 'JN-2026-TL001',
        title: 'Timeline Test',
        description: 'Testing timeline.',
        category: 'other',
        incidentDate: new Date(),
        reportedBy: reporter._id,
        timeline: [
          { status: 'submitted', note: 'Case submitted', updatedBy: reporter._id },
        ],
      });

      expect(caseDoc.timeline).toHaveLength(1);
      expect(caseDoc.timeline[0].status).toBe('submitted');
      expect(caseDoc.timeline[0].note).toBe('Case submitted');
    });

    it('should append to timeline on update', async () => {
      const caseDoc = await Case.create({
        referenceNumber: 'JN-2026-TL002',
        title: 'Append Timeline',
        description: 'Testing timeline append.',
        category: 'other',
        incidentDate: new Date(),
        reportedBy: reporter._id,
        timeline: [{ status: 'submitted', note: 'Initial' }],
      });

      caseDoc.timeline.push({ status: 'under_review', note: 'Now reviewing' });
      await caseDoc.save();

      const updated = await Case.findById(caseDoc._id);
      expect(updated.timeline).toHaveLength(2);
      expect(updated.timeline[1].status).toBe('under_review');
    });
  });

  describe('Location', () => {
    it('should store location data', async () => {
      const caseDoc = await Case.create({
        referenceNumber: 'JN-2026-LOC01',
        title: 'Location Test',
        description: 'Testing location.',
        category: 'other',
        incidentDate: new Date(),
        reportedBy: reporter._id,
        location: {
          address: '123 Main St',
          city: 'Colombo',
          country: 'Sri Lanka',
          coordinates: {
            type: 'Point',
            coordinates: [79.8612, 6.9271],
          },
        },
      });

      expect(caseDoc.location.city).toBe('Colombo');
      expect(caseDoc.location.coordinates.coordinates).toEqual([79.8612, 6.9271]);
    });
  });

  describe('Internal notes and public updates', () => {
    it('should store internal notes', async () => {
      const caseDoc = await Case.create({
        referenceNumber: 'JN-2026-NOTE1',
        title: 'Notes Test',
        description: 'Testing notes.',
        category: 'other',
        incidentDate: new Date(),
        reportedBy: reporter._id,
      });

      caseDoc.internalNotes.push({
        note: 'Sensitive officer note',
        addedBy: reporter._id,
      });
      await caseDoc.save();

      const fetched = await Case.findById(caseDoc._id);
      expect(fetched.internalNotes).toHaveLength(1);
      expect(fetched.internalNotes[0].note).toBe('Sensitive officer note');
    });

    it('should store public updates', async () => {
      const caseDoc = await Case.create({
        referenceNumber: 'JN-2026-PUB01',
        title: 'Public Update Test',
        description: 'Testing public updates.',
        category: 'other',
        incidentDate: new Date(),
        reportedBy: reporter._id,
      });

      caseDoc.publicUpdates.push({ message: 'Your case is being reviewed' });
      await caseDoc.save();

      const fetched = await Case.findById(caseDoc._id);
      expect(fetched.publicUpdates).toHaveLength(1);
    });
  });
});
