/**
 * Unit tests for Notification model
 */

require('../setup');
const mongoose = require('mongoose');
const Notification = require('../../src/models/Notification.model');
const User = require('../../src/models/User.model');

describe('Notification Model', () => {
  let user;

  beforeEach(async () => {
    user = await User.create({
      alias: 'Citizen-NOTIF',
      role: 'citizen',
    });
  });

  it('should create a notification with required fields', async () => {
    const notif = await Notification.create({
      recipient: user._id,
      title: 'Case Update',
      message: 'Your case has been approved.',
      type: 'general',
    });

    expect(notif.recipient.toString()).toBe(user._id.toString());
    expect(notif.title).toBe('Case Update');
    expect(notif.isRead).toBe(false);
    expect(notif.case).toBeNull();
    expect(notif.actionRoute).toBeNull();
  });

  it('should reject notification without recipient', async () => {
    await expect(
      Notification.create({
        title: 'No Recipient',
        message: 'Missing recipient.',
      })
    ).rejects.toThrow();
  });

  it('should reject notification without title', async () => {
    await expect(
      Notification.create({
        recipient: user._id,
        message: 'Missing title.',
      })
    ).rejects.toThrow();
  });

  it('should reject notification without message', async () => {
    await expect(
      Notification.create({
        recipient: user._id,
        title: 'Missing Message',
      })
    ).rejects.toThrow();
  });

  it('should reject invalid notification type', async () => {
    await expect(
      Notification.create({
        recipient: user._id,
        title: 'Bad Type',
        message: 'Invalid type.',
        type: 'invalid_type',
      })
    ).rejects.toThrow();
  });

  it('should accept all valid notification types', async () => {
    const types = [
      'awaiting_lawyer_selection',
      'waiting_for_lawyer_approval',
      'new_case_request',
      'case_approved_scheduled',
      'lawyer_declined',
      'case_rejected',
      'case_assigned_police',
      'case_assigned_officer',
      'case_forwarded_police',
      'case_declined_reassign',
      'officer_declined',
      'general',
    ];

    for (const type of types) {
      const notif = await Notification.create({
        recipient: user._id,
        title: `Type ${type}`,
        message: 'Test message.',
        type,
      });
      expect(notif.type).toBe(type);
    }
  });

  it('should default isRead to false', async () => {
    const notif = await Notification.create({
      recipient: user._id,
      title: 'Unread',
      message: 'Should be unread.',
    });

    expect(notif.isRead).toBe(false);
  });

  it('should allow marking as read', async () => {
    const notif = await Notification.create({
      recipient: user._id,
      title: 'Mark Read',
      message: 'Will be read.',
    });

    notif.isRead = true;
    await notif.save();

    const fetched = await Notification.findById(notif._id);
    expect(fetched.isRead).toBe(true);
  });
});
