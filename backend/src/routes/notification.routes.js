const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notification.controller');
const { authenticate } = require('../middleware/auth.middleware');

router.use(authenticate);

// GET   /api/notifications         — List user's notifications & unread count
router.get('/', notificationController.getMyNotifications);

// PATCH /api/notifications/read-all — Mark all as read
router.patch('/read-all', notificationController.markAllAsRead);

// PATCH /api/notifications/:id/read — Mark single notification as read
router.patch('/:id/read', notificationController.markAsRead);

module.exports = router;
