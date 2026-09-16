const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../../middleware/auth.middleware');
const {
  getPendingUsers,
  approveUser,
  rejectUser,
} = require('../../controllers/admin/userApproval.controller');

// Protect all routes: User must be authenticated AND have the 'admin' role
router.use(authenticate, authorize('admin'));

// Admin user verification endpoints
router.get('/pending-users', getPendingUsers);
router.patch('/users/:userId/approve', approveUser);
router.patch('/users/:userId/reject', rejectUser);

module.exports = router;