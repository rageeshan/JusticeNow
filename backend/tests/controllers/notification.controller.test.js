/**
 * Unit tests for Notification Controller
 */

require('../setup');
const mongoose = require('mongoose');
const Notification = require('../../src/models/Notification.model');
const User = require('../../src/models/User.model');
const Case = require('../../src/models/Case.model');
const {
  getMyNotifications,
  markAsRead,
  markAllAsRead,
} = require('../../src/controllers/notification.controller');

describe('Notification Controller', () => {
  let user, otherUser, testCase, req, res, next;

  beforeEach(async () => {
    user = await User.create({
      alias: 'Citizen-NOTIF01',
      role: 'citizen',
      isVerified: true,
      approvalStatus: 'approved',
    });

    otherUser = await User.create({
      alias: 'Citizen-NOTIF02',
      role: 'citizen',
      isVerified: true,
      approvalStatus: 'approved',
    });

    testCase = await Case.create({
      referenceNumber: 'JN-2026-N001',
      title: 'Notif Case',
      description: 'Incident for notification test',
      category: 'other',
      incidentDate: new Date(),
      reportedBy: user._id,
    });

    req = {
      user: { _id: user._id },
      params: {},
    };

    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    };

    next = jest.fn();
  });

  describe('getMyNotifications', () => {
    it('should return user notifications and unreadCount', async () => {
      await Notification.create([
        {
          recipient: user._id,
          title: 'Notif 1',
          message: 'Message 1',
          type: 'awaiting_lawyer_selection',
          case: testCase._id,
          isRead: false,
        },
        {
          recipient: user._id,
          title: 'Notif 2',
          message: 'Message 2',
          type: 'general',
          isRead: true,
        },
        {
          recipient: otherUser._id,
          title: 'Other User Notif',
          message: 'Should not appear',
          type: 'general',
        },
      ]);

      await getMyNotifications(req, res, next);

      expect(res.status).toHaveBeenCalledWith(200);
      const data = res.json.mock.calls[0][0].data;
      expect(data.notifications).toHaveLength(2);
      expect(data.unreadCount).toBe(1);
    });

    it('should pass errors to next()', async () => {
      req.user = null; // will cause TypeError when reading req.user._id
      await getMyNotifications(req, res, next);
      expect(next).toHaveBeenCalled();
    });
  });

  describe('markAsRead', () => {
    it('should mark a notification as read', async () => {
      const notif = await Notification.create({
        recipient: user._id,
        title: 'Unread',
        message: 'Unread message',
        type: 'general',
        isRead: false,
      });

      req.params.id = notif._id;
      await markAsRead(req, res, next);

      expect(res.status).toHaveBeenCalledWith(200);
      const updated = await Notification.findById(notif._id);
      expect(updated.isRead).toBe(true);
    });

    it('should return 404 if notification not found or belongs to another user', async () => {
      const otherNotif = await Notification.create({
        recipient: otherUser._id,
        title: 'Other Unread',
        message: 'Unread message',
        type: 'general',
        isRead: false,
      });

      req.params.id = otherNotif._id;
      await markAsRead(req, res, next);

      expect(res.status).toHaveBeenCalledWith(404);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: 'Notification not found',
        })
      );
    });
  });

  describe('markAllAsRead', () => {
    it('should mark all unread notifications of the user as read', async () => {
      await Notification.create([
        { recipient: user._id, title: 'N1', message: 'M1', type: 'general', isRead: false },
        { recipient: user._id, title: 'N2', message: 'M2', type: 'general', isRead: false },
        { recipient: otherUser._id, title: 'N3', message: 'M3', type: 'general', isRead: false },
      ]);

      await markAllAsRead(req, res, next);

      expect(res.status).toHaveBeenCalledWith(200);

      const userUnread = await Notification.countDocuments({ recipient: user._id, isRead: false });
      expect(userUnread).toBe(0);

      const otherUnread = await Notification.countDocuments({ recipient: otherUser._id, isRead: false });
      expect(otherUnread).toBe(1);
    });
  });
});
