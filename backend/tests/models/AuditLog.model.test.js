/**
 * Unit tests for AuditLog model
 */

require('../setup');
const mongoose = require('mongoose');
const AuditLog = require('../../src/models/AuditLog.model');
const User = require('../../src/models/User.model');

describe('AuditLog Model', () => {
  let user;

  beforeEach(async () => {
    user = await User.create({
      alias: 'Citizen-AUDIT',
      role: 'citizen',
    });
  });

  it('should create an audit log with required fields', async () => {
    const log = await AuditLog.create({
      action: 'case.created',
      performedBy: user._id,
      targetResource: 'Case',
      targetId: new mongoose.Types.ObjectId(),
    });

    expect(log.action).toBe('case.created');
    expect(log.targetResource).toBe('Case');
    expect(log.createdAt).toBeInstanceOf(Date);
  });

  it('should reject without action', async () => {
    await expect(
      AuditLog.create({
        targetResource: 'Case',
      })
    ).rejects.toThrow();
  });

  it('should reject without targetResource', async () => {
    await expect(
      AuditLog.create({
        action: 'case.created',
      })
    ).rejects.toThrow();
  });

  it('should reject invalid targetResource enum', async () => {
    await expect(
      AuditLog.create({
        action: 'test.action',
        targetResource: 'InvalidResource',
      })
    ).rejects.toThrow();
  });

  it('should accept all valid targetResource values', async () => {
    const resources = ['Case', 'Evidence', 'User', 'Organization', 'System'];

    for (const targetResource of resources) {
      const log = await AuditLog.create({
        action: `test.${targetResource.toLowerCase()}`,
        targetResource,
      });
      expect(log.targetResource).toBe(targetResource);
    }
  });

  it('should store metadata as mixed type', async () => {
    const metadata = {
      previousStatus: 'submitted',
      newStatus: 'under_review',
      reason: 'Reviewed by officer',
    };

    const log = await AuditLog.create({
      action: 'case.status_changed',
      performedBy: user._id,
      targetResource: 'Case',
      metadata,
    });

    expect(log.metadata.previousStatus).toBe('submitted');
    expect(log.metadata.newStatus).toBe('under_review');
  });

  it('should default metadata to empty object', async () => {
    const log = await AuditLog.create({
      action: 'user.login',
      targetResource: 'User',
    });

    expect(log.metadata).toEqual({});
  });

  it('should store IP address and user agent', async () => {
    const log = await AuditLog.create({
      action: 'user.login',
      performedBy: user._id,
      targetResource: 'User',
      ipAddress: '192.168.1.1',
      userAgent: 'Mozilla/5.0 TestAgent',
    });

    expect(log.ipAddress).toBe('192.168.1.1');
    expect(log.userAgent).toBe('Mozilla/5.0 TestAgent');
  });
});
