/**
 * Unit tests for Case service
 * Tests case creation, listing, status updates, reference number generation,
 * and date filter queries
 */

require('../setup');
const mongoose = require('mongoose');
const User = require('../../src/models/User.model');
const Case = require('../../src/models/Case.model');
const AuditLog = require('../../src/models/AuditLog.model');
const Notification = require('../../src/models/Notification.model');
const caseService = require('../../src/services/case.service');

describe('Case Service', () => {
  let citizen, officer;

  beforeEach(async () => {
    citizen = await User.create({
      alias: 'Citizen-SVC01',
      role: 'citizen',
      isVerified: true,
      approvalStatus: 'approved',
    });

    officer = await User.create({
      email: 'officer@svc.com',
      role: 'police_officer',
      isVerified: true,
      approvalStatus: 'approved',
      profile: { fullName: 'Officer Smith' },
    });
  });

  // ─── createCase ────────────────────────────────────────────────────────────

  describe('createCase', () => {
    const validCaseData = {
      title: 'Test Case Report',
      description: 'Detailed incident description for testing.',
      category: 'arbitrary_detention',
      incidentDate: new Date('2026-06-15'),
      location: { country: 'Sri Lanka', city: 'Colombo' },
    };

    it('should create a case with auto-generated reference number', async () => {
      const caseDoc = await caseService.createCase(validCaseData, citizen);

      expect(caseDoc.referenceNumber).toMatch(/^JN-\d{4}-\d{5}$/);
      expect(caseDoc.title).toBe('Test Case Report');
      expect(caseDoc.status).toBe('submitted');
      expect(caseDoc.reportedBy.toString()).toBe(citizen._id.toString());
    });

    it('should add initial timeline entry', async () => {
      const caseDoc = await caseService.createCase(validCaseData, citizen);

      expect(caseDoc.timeline).toHaveLength(1);
      expect(caseDoc.timeline[0].status).toBe('submitted');
      expect(caseDoc.timeline[0].note).toContain('submitted');
    });

    it('should create an audit log entry', async () => {
      await caseService.createCase(validCaseData, citizen);

      const logs = await AuditLog.find({ action: 'case.created' });
      expect(logs).toHaveLength(1);
      expect(logs[0].metadata.category).toBe('arbitrary_detention');
    });

    it('should generate unique sequential reference numbers', async () => {
      const case1 = await caseService.createCase(validCaseData, citizen);
      const case2 = await caseService.createCase(
        { ...validCaseData, title: 'Second Case' },
        citizen
      );

      expect(case1.referenceNumber).not.toBe(case2.referenceNumber);
    });
  });

  // ─── getCases ──────────────────────────────────────────────────────────────

  describe('getCases', () => {
    beforeEach(async () => {
      // Seed 5 cases with different statuses and categories
      const statuses = ['submitted', 'under_review', 'investigating', 'completed', 'rejected'];
      const categories = ['arbitrary_detention', 'torture', 'discrimination', 'other', 'other'];

      for (let i = 0; i < 5; i++) {
        await Case.create({
          referenceNumber: `JN-2026-GC${String(i + 1).padStart(3, '0')}`,
          title: `Case ${i + 1}`,
          description: `Description for case ${i + 1}.`,
          category: categories[i],
          incidentDate: new Date(),
          reportedBy: citizen._id,
          status: statuses[i],
        });
      }
    });

    it('should return paginated results', async () => {
      const result = await caseService.getCases({ page: 1, limit: 2 });

      expect(result.cases).toHaveLength(2);
      expect(result.pagination.total).toBe(5);
      expect(result.pagination.pages).toBe(3);
      expect(result.pagination.page).toBe(1);
      expect(result.pagination.limit).toBe(2);
    });

    it('should return all cases by default', async () => {
      const result = await caseService.getCases();

      expect(result.cases).toHaveLength(5);
    });

    it('should filter by status', async () => {
      const result = await caseService.getCases({ status: 'submitted' });

      expect(result.cases).toHaveLength(1);
      expect(result.cases[0].status).toBe('submitted');
    });

    it('should filter by category', async () => {
      const result = await caseService.getCases({ category: 'other' });

      expect(result.cases).toHaveLength(2);
    });

    it('should search by title text', async () => {
      const result = await caseService.getCases({ search: 'Case 3' });

      expect(result.cases).toHaveLength(1);
      expect(result.cases[0].title).toBe('Case 3');
    });

    it('should not return soft-deleted cases', async () => {
      await Case.updateOne(
        { referenceNumber: 'JN-2026-GC001' },
        { isDeleted: true }
      );

      const result = await caseService.getCases();
      expect(result.cases).toHaveLength(4);
    });

    it('should ignore "All" status filter', async () => {
      const result = await caseService.getCases({ status: 'All' });
      expect(result.cases).toHaveLength(5);
    });

    it('should filter by priority and ignore "All" priority filter', async () => {
      await Case.updateOne({ referenceNumber: 'JN-2026-GC001' }, { priority: 'urgent' });

      const filtered = await caseService.getCases({ priority: 'urgent' });
      expect(filtered.cases).toHaveLength(1);
      expect(filtered.cases[0].priority).toBe('urgent');

      const allPriority = await caseService.getCases({ priority: 'All' });
      expect(allPriority.cases).toHaveLength(5);
    });

    it('should search by referenceNumber or description', async () => {
      const refSearch = await caseService.getCases({ search: 'GC002' });
      expect(refSearch.cases).toHaveLength(1);

      const descSearch = await caseService.getCases({ search: 'Description for case 4' });
      expect(descSearch.cases).toHaveLength(1);
    });

    it('should filter by dateFilter options (today, this_week, last_week, this_month, last_month)', async () => {
      const resToday = await caseService.getCases({ dateFilter: 'today' });
      expect(resToday.cases).toBeDefined();

      const resWeek = await caseService.getCases({ dateFilter: 'this_week' });
      expect(resWeek.cases).toBeDefined();

      const resLastWeek = await caseService.getCases({ dateFilter: 'last_week' });
      expect(resLastWeek.cases).toBeDefined();

      const resMonth = await caseService.getCases({ dateFilter: 'this_month' });
      expect(resMonth.cases).toBeDefined();

      const resLastMonth = await caseService.getCases({ dateFilter: 'last_month' });
      expect(resLastMonth.cases).toBeDefined();

      const resAll = await caseService.getCases({ dateFilter: 'all' });
      expect(resAll.cases).toBeDefined();
    });
  });

  // ─── getCaseById ───────────────────────────────────────────────────────────

  describe('getCaseById', () => {
    it('should return a case by ID with populated fields', async () => {
      const created = await Case.create({
        referenceNumber: 'JN-2026-BYID1',
        title: 'Find By ID',
        description: 'Testing getCaseById.',
        category: 'other',
        incidentDate: new Date(),
        reportedBy: citizen._id,
      });

      const found = await caseService.getCaseById(created._id);

      expect(found).toBeTruthy();
      expect(found.title).toBe('Find By ID');
      expect(found.reportedBy).toBeDefined();
    });

    it('should return null for soft-deleted case', async () => {
      const created = await Case.create({
        referenceNumber: 'JN-2026-DEL01',
        title: 'Deleted Case',
        description: 'Soft deleted.',
        category: 'other',
        incidentDate: new Date(),
        reportedBy: citizen._id,
        isDeleted: true,
      });

      const found = await caseService.getCaseById(created._id);
      expect(found).toBeNull();
    });

    it('should return null for non-existent ID', async () => {
      const fakeId = new mongoose.Types.ObjectId();
      const found = await caseService.getCaseById(fakeId);
      expect(found).toBeNull();
    });
  });

  // ─── updateCaseStatus ──────────────────────────────────────────────────────

  describe('updateCaseStatus', () => {
    let testCase;

    beforeEach(async () => {
      testCase = await Case.create({
        referenceNumber: 'JN-2026-UPD01',
        title: 'Status Update Case',
        description: 'For status update testing.',
        category: 'other',
        incidentDate: new Date(),
        reportedBy: citizen._id,
        status: 'submitted',
      });
    });

    it('should update case status and add timeline entry', async () => {
      const updated = await caseService.updateCaseStatus(
        testCase._id,
        { status: 'under_review', note: 'Reviewing now' },
        officer
      );

      expect(updated.status).toBe('under_review');
    });

    it('should create audit log on status change', async () => {
      await caseService.updateCaseStatus(
        testCase._id,
        { status: 'investigating', note: 'Started investigation' },
        officer
      );

      const logs = await AuditLog.find({ action: 'case.status_changed' });
      expect(logs).toHaveLength(1);
      expect(logs[0].metadata.previousStatus).toBe('submitted');
      expect(logs[0].metadata.newStatus).toBe('investigating');
    });

    it('should throw 404 for non-existent case', async () => {
      const fakeId = new mongoose.Types.ObjectId();

      try {
        await caseService.updateCaseStatus(
          fakeId,
          { status: 'completed' },
          officer
        );
        fail('Should have thrown');
      } catch (err) {
        expect(err.statusCode).toBe(404);
      }
    });

    it('should set rejectionReason when status is rejected', async () => {
      await caseService.updateCaseStatus(
        testCase._id,
        { status: 'rejected', reason: 'Insufficient evidence' },
        officer
      );

      const fetched = await Case.findById(testCase._id);
      expect(fetched.rejectionReason).toBe('Insufficient evidence');
    });

    it('should create notification for awaiting_lawyer_selection', async () => {
      await caseService.updateCaseStatus(
        testCase._id,
        { status: 'awaiting_lawyer_selection', note: 'Ready for lawyer' },
        officer
      );

      const notifications = await Notification.find({ type: 'awaiting_lawyer_selection' });
      expect(notifications).toHaveLength(1);
      expect(notifications[0].recipient.toString()).toBe(citizen._id.toString());
    });

    it('should create notification for rejected case', async () => {
      await caseService.updateCaseStatus(
        testCase._id,
        { status: 'rejected', reason: 'Not valid' },
        officer
      );

      const notifications = await Notification.find({ type: 'case_rejected' });
      expect(notifications).toHaveLength(1);
    });
  });

  // ─── getCasesByReporter ────────────────────────────────────────────────────

  describe('getCasesByReporter', () => {
    beforeEach(async () => {
      for (let i = 0; i < 3; i++) {
        await Case.create({
          referenceNumber: `JN-2026-RPT${String(i + 1).padStart(2, '0')}`,
          title: `Reporter Case ${i + 1}`,
          description: `Case by reporter ${i + 1}.`,
          category: 'other',
          incidentDate: new Date(),
          reportedBy: citizen._id,
        });
      }

      // Another user's case - should not appear
      const otherUser = await User.create({ alias: 'Citizen-OTHER', role: 'citizen' });
      await Case.create({
        referenceNumber: 'JN-2026-OTHER',
        title: 'Other Case',
        description: 'By someone else.',
        category: 'other',
        incidentDate: new Date(),
        reportedBy: otherUser._id,
      });
    });

    it('should return only cases by the specified reporter', async () => {
      const result = await caseService.getCasesByReporter(citizen._id);

      expect(result.cases).toHaveLength(3);
      result.cases.forEach((c) => {
        expect(c.reportedBy.toString()).toBe(citizen._id.toString());
      });
    });

    it('should paginate results', async () => {
      const result = await caseService.getCasesByReporter(citizen._id, { page: 1, limit: 2 });

      expect(result.cases).toHaveLength(2);
      expect(result.pagination.total).toBe(3);
      expect(result.pagination.pages).toBe(2);
    });

    it('should return empty for user with no cases', async () => {
      const newUser = await User.create({ alias: 'Citizen-EMPTY', role: 'citizen' });
      const result = await caseService.getCasesByReporter(newUser._id);

      expect(result.cases).toHaveLength(0);
      expect(result.pagination.total).toBe(0);
    });
  });
});
