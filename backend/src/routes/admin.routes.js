const express = require('express');
const router = express.Router();
const adminController = require('../controllers/admin.controller');
const { authenticate, authorize } = require('../middleware/auth.middleware');
const { adminValidators } = require('../utils/validators');

// All admin routes require authentication and admin role
router.use(authenticate, authorize('admin'));

// GET   /api/admin/users            — List users with optional status/role filters
router.get('/users', adminController.getUsers);

// GET   /api/admin/users/:id        — Get single user details for verification
router.get('/users/:id', adminController.getUserById);

// PATCH /api/admin/users/:id/status — Approve or reject user registration
router.patch('/users/:id/status', adminValidators.updateStatus, adminController.updateUserApprovalStatus);

module.exports = router;
