/**
 * Unit tests for EvidenceRequest service
 */

require('../setup');
const mongoose = require('mongoose');
const User = require('../../src/models/User.model');
const Case = require('../../src/models/Case.model');
const EvidenceRequest = require('../../src/models/EvidenceRequest.model');
const AuditLog = require('../../src/models/AuditLog.model');
const evidenceRequestService = require('../../src/services/evidenceRequest.service');

describe('EvidenceRequest Service', () => {
  let officer, citizen, testCase;

  beforeEach(async () => {
    citizen = await User.create({
      alias: 'Citizen-ER01',
      role: 'citizen',
      isVerified: true,
      approvalStatus: 'approved',
    });

    officer = await User.create({
      email: 'officer.er@test.com',
      role: 'police_officer',
      isVerified: true,
      approvalStatus: 'approved',
      profile: { fullName: 'Officer ER' },
    });

    testCase = await Case.create({
      referenceNumber: 'JN-2026-ER001',
      title: 'Evidence Request Case',
      description: 'Case for evidence request testing.',
      category: 'other',
      incidentDate: new Date(),
      reportedBy: citizen._id,
      status: 'investigating',
    });
  });

  // ─── createEvidenceRequest ─────────────────────────────────────────────────

  describe('createEvidenceRequest', () => {
    it('should create an evidence request', async () => {
      const request = await evidenceRequestService.createEvidenceRequest(
        testCase._id,
        {
          description: 'Please provide witness statement',
          reason: 'Need corroboration',
          instructions: 'Upload a signed PDF',
        },
        officer
      );

      expect(request.description).toBe('Please provide witness statement');
      expect(request.status).toBe('pending');
      expect(request.requestedBy.toString()).toBe(officer._id.toString());
    });

    it('should update the case status to evidence_requested', async () => {
      await evidenceRequestService.createEvidenceRequest(
        testCase._id,
        { description: 'Need photos' },
        officer
      );

      const updatedCase = await Case.findById(testCase._id);
      expect(updatedCase.status).toBe('evidence_requested');
    });

    it('should add timeline entry to the case', async () => {
      await evidenceRequestService.createEvidenceRequest(
        testCase._id,
        { description: 'Need documents', reason: 'Investigation requires more info' },
        officer
      );

      const updatedCase = await Case.findById(testCase._id);
      const lastEvent = updatedCase.timeline[updatedCase.timeline.length - 1];
      expect(lastEvent.status).toBe('evidence_requested');
    });

    it('should add public update to the case', async () => {
      await evidenceRequestService.createEvidenceRequest(
        testCase._id,
        { description: 'Upload video evidence' },
        officer
      );

      const updatedCase = await Case.findById(testCase._id);
      expect(updatedCase.publicUpdates).toHaveLength(1);
    });

    it('should add internal note when provided', async () => {
      await evidenceRequestService.createEvidenceRequest(
        testCase._id,
        { description: 'Need alibi details', internalNote: 'Officer noted suspect inconsistencies' },
        officer
      );

      const updatedCase = await Case.findById(testCase._id);
      expect(updatedCase.internalNotes).toHaveLength(1);
      expect(updatedCase.internalNotes[0].note).toContain('inconsistencies');
    });

    it('should create an audit log entry', async () => {
      await evidenceRequestService.createEvidenceRequest(
        testCase._id,
        { description: 'Audit test' },
        officer
      );

      const logs = await AuditLog.find({ action: 'evidence_request.created' });
      expect(logs).toHaveLength(1);
    });

    it('should throw 404 for non-existent case', async () => {
      const fakeId = new mongoose.Types.ObjectId();

      try {
        await evidenceRequestService.createEvidenceRequest(
          fakeId,
          { description: 'No case' },
          officer
        );
        fail('Should have thrown');
      } catch (err) {
        expect(err.statusCode).toBe(404);
      }
    });
  });

  // ─── getRequestsByCase ─────────────────────────────────────────────────────

  describe('getRequestsByCase', () => {
    it('should return all requests for a case', async () => {
      await EvidenceRequest.create({
        case: testCase._id,
        requestedBy: officer._id,
        description: 'Request 1',
        status: 'pending',
      });
      await EvidenceRequest.create({
        case: testCase._id,
        requestedBy: officer._id,
        description: 'Request 2',
        status: 'fulfilled',
      });

      const requests = await evidenceRequestService.getRequestsByCase(testCase._id);
      expect(requests).toHaveLength(2);
    });

    it('should not return soft-deleted requests', async () => {
      await EvidenceRequest.create({
        case: testCase._id,
        requestedBy: officer._id,
        description: 'Visible',
        status: 'pending',
      });
      await EvidenceRequest.create({
        case: testCase._id,
        requestedBy: officer._id,
        description: 'Deleted',
        status: 'pending',
        isDeleted: true,
      });

      const requests = await evidenceRequestService.getRequestsByCase(testCase._id);
      expect(requests).toHaveLength(1);
    });
  });

  // ─── updateRequestStatus ───────────────────────────────────────────────────

  describe('updateRequestStatus', () => {
    it('should update request status', async () => {
      const request = await EvidenceRequest.create({
        case: testCase._id,
        requestedBy: officer._id,
        description: 'Update me',
        status: 'pending',
      });

      const updated = await evidenceRequestService.updateRequestStatus(
        request._id,
        { status: 'fulfilled', reviewNotes: 'Evidence received and verified' },
        officer
      );

      expect(updated.status).toBe('fulfilled');
      expect(updated.reviewNotes).toBe('Evidence received and verified');
      expect(updated.reviewedAt).toBeInstanceOf(Date);
    });

    it('should throw 404 for non-existent request', async () => {
      const fakeId = new mongoose.Types.ObjectId();

      try {
        await evidenceRequestService.updateRequestStatus(
          fakeId,
          { status: 'fulfilled' },
          officer
        );
        fail('Should have thrown');
      } catch (err) {
        expect(err.statusCode).toBe(404);
      }
    });

    it('should create audit log for status update', async () => {
      const request = await EvidenceRequest.create({
        case: testCase._id,
        requestedBy: officer._id,
        description: 'Audit status test',
        status: 'pending',
      });

      await evidenceRequestService.updateRequestStatus(
        request._id,
        { status: 'under_review' },
        officer
      );

      const logs = await AuditLog.find({ action: 'evidence_request.status_updated' });
      expect(logs).toHaveLength(1);
    });
  });

  // ─── getOfficerRequests ────────────────────────────────────────────────────

  describe('getOfficerRequests', () => {
    beforeEach(async () => {
      const otherOfficer = await User.create({
        email: 'other_officer@test.com',
        role: 'police_officer',
        isVerified: true,
        approvalStatus: 'approved',
      });

      await EvidenceRequest.create([
        {
          case: testCase._id,
          requestedBy: officer._id,
          description: 'Request 1',
          status: 'pending',
        },
        {
          case: testCase._id,
          requestedBy: officer._id,
          description: 'Request 2',
          status: 'fulfilled',
        },
        {
          case: testCase._id,
          requestedBy: otherOfficer._id,
          description: 'Request from other officer',
          status: 'pending',
        },
      ]);
    });

    it('should return paginated requests for specific officer', async () => {
      const result = await evidenceRequestService.getOfficerRequests(officer._id, {
        page: 1,
        limit: 10,
      });

      expect(result.requests).toHaveLength(2);
      expect(result.pagination.total).toBe(2);
    });

    it('should return all requests when officerId is null (admin view)', async () => {
      const result = await evidenceRequestService.getOfficerRequests(null);
      expect(result.requests).toHaveLength(3);
      expect(result.pagination.total).toBe(3);
    });

    it('should filter officer requests by status', async () => {
      const result = await evidenceRequestService.getOfficerRequests(officer._id, {
        status: 'fulfilled',
      });

      expect(result.requests).toHaveLength(1);
      expect(result.requests[0].status).toBe('fulfilled');
    });
  });
});

