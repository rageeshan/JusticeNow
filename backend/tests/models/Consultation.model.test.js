/**
 * Unit tests for Consultation model
 */

require('../setup');
const mongoose = require('mongoose');
const Consultation = require('../../src/models/Consultation.model');
const User = require('../../src/models/User.model');

describe('Consultation Model', () => {
  let citizen, lawyer;

  beforeEach(async () => {
    citizen = await User.create({
      alias: 'Citizen-CONS01',
      role: 'citizen',
      isVerified: true,
      approvalStatus: 'approved',
    });

    lawyer = await User.create({
      email: 'counsel@test.com',
      role: 'lawyer',
      isVerified: true,
      approvalStatus: 'approved',
    });
  });

  it('should create consultation with required fields and defaults', async () => {
    const consultation = await Consultation.create({
      citizenName: 'John Doe',
      counselId: lawyer._id,
    });

    expect(consultation._id).toBeDefined();
    expect(consultation.citizenName).toBe('John Doe');
    expect(consultation.counselId.toString()).toBe(lawyer._id.toString());
    expect(consultation.category).toBe('General');
    expect(consultation.preferredContactMethod).toBe('In-app');
    expect(consultation.status).toBe('Waiting for Lawyer Approval');
    expect(consultation.translationLanguage).toBe('EN');
    expect(consultation.requestedDate).toBeDefined();
  });

  it('should reject consultation without citizenName', async () => {
    await expect(
      Consultation.create({
        counselId: lawyer._id,
      })
    ).rejects.toThrow();
  });

  it('should reject consultation without counselId', async () => {
    await expect(
      Consultation.create({
        citizenName: 'Jane Doe',
      })
    ).rejects.toThrow();
  });

  it('should accept all valid status enum values', async () => {
    const validStatuses = [
      'Pending',
      'Waiting for Lawyer Approval',
      'Accepted',
      'Rescheduled',
      'Completed',
      'Rejected',
    ];

    for (const status of validStatuses) {
      const consultation = await Consultation.create({
        citizenName: 'Status Test',
        counselId: lawyer._id,
        status,
      });
      expect(consultation.status).toBe(status);
    }
  });

  it('should reject invalid status value', async () => {
    await expect(
      Consultation.create({
        citizenName: 'Jane Doe',
        counselId: lawyer._id,
        status: 'InvalidStatus',
      })
    ).rejects.toThrow();
  });

  it('should accept all valid preferredContactMethod values and reject invalid', async () => {
    const validMethods = ['Call', 'Email', 'In-app', null];
    for (const method of validMethods) {
      const consultation = await Consultation.create({
        citizenName: 'Contact Test',
        counselId: lawyer._id,
        preferredContactMethod: method,
      });
      expect(consultation.preferredContactMethod).toBe(method);
    }

    await expect(
      Consultation.create({
        citizenName: 'Contact Test',
        counselId: lawyer._id,
        preferredContactMethod: 'CarrierPigeon',
      })
    ).rejects.toThrow();
  });
});
