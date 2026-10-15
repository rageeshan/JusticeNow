/**
 * Unit tests for EvidenceRequest model
 */

require('../setup');
const mongoose = require('mongoose');
const EvidenceRequest = require('../../src/models/EvidenceRequest.model');
const User = require('../../src/models/User.model');
const Case = require('../../src/models/Case.model');

describe('EvidenceRequest Model', () => {
  let officer, testCase;

  beforeEach(async () => {
    officer = await User.create({
      email: 'officer.ermodel@test.com',
      role: 'police_officer',
      isActive: true,
    });

    const citizen = await User.create({
      alias: 'Citizen-ERM',
      role: 'citizen',
    });

    testCase = await Case.create({
      referenceNumber: 'JN-2026-ERM01',
      title: 'ER Model Test Case',
      description: 'For evidence request model testing.',
      category: 'other',
      incidentDate: new Date(),
      reportedBy: citizen._id,
    });
  });

  it('should create an evidence request with required fields', async () => {
    const er = await EvidenceRequest.create({
      case: testCase._id,
      requestedBy: officer._id,
      description: 'Please provide CCTV footage',
    });

    expect(er.description).toBe('Please provide CCTV footage');
    expect(er.status).toBe('pending');
    expect(er.isDeleted).toBe(false);
    expect(er.reason).toBe('');
    expect(er.instructions).toBe('');
  });

  it('should reject without case reference', async () => {
    await expect(
      EvidenceRequest.create({
        requestedBy: officer._id,
        description: 'No case',
      })
    ).rejects.toThrow();
  });

  it('should reject without requestedBy', async () => {
    await expect(
      EvidenceRequest.create({
        case: testCase._id,
        description: 'No requester',
      })
    ).rejects.toThrow();
  });

  it('should reject without description', async () => {
    await expect(
      EvidenceRequest.create({
        case: testCase._id,
        requestedBy: officer._id,
      })
    ).rejects.toThrow();
  });

  it('should reject invalid status', async () => {
    await expect(
      EvidenceRequest.create({
        case: testCase._id,
        requestedBy: officer._id,
        description: 'Bad status',
        status: 'invalid_status',
      })
    ).rejects.toThrow();
  });

  it('should accept all valid status values', async () => {
    const statuses = ['pending', 'submitted', 'under_review', 'fulfilled', 'cancelled'];

    for (const status of statuses) {
      const er = await EvidenceRequest.create({
        case: testCase._id,
        requestedBy: officer._id,
        description: `Status test: ${status}`,
        status,
      });
      expect(er.status).toBe(status);
    }
  });

  it('should store optional fields', async () => {
    const dueDate = new Date('2026-12-31');
    const er = await EvidenceRequest.create({
      case: testCase._id,
      requestedBy: officer._id,
      description: 'Full evidence request',
      reason: 'Need for case corroboration',
      instructions: 'Upload as PDF',
      dueDate,
    });

    expect(er.reason).toBe('Need for case corroboration');
    expect(er.instructions).toBe('Upload as PDF');
    expect(er.dueDate.toISOString()).toBe(dueDate.toISOString());
  });

  it('should store review data', async () => {
    const er = await EvidenceRequest.create({
      case: testCase._id,
      requestedBy: officer._id,
      description: 'Review test',
    });

    er.reviewNotes = 'Evidence looks good';
    er.reviewedAt = new Date();
    er.status = 'fulfilled';
    await er.save();

    const fetched = await EvidenceRequest.findById(er._id);
    expect(fetched.reviewNotes).toBe('Evidence looks good');
    expect(fetched.reviewedAt).toBeInstanceOf(Date);
    expect(fetched.status).toBe('fulfilled');
  });
});
