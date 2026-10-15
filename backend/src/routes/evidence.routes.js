const express = require('express');
const router = express.Router();
const evidenceRequestController = require('../controllers/evidenceRequest.controller');
const { authenticate, authorize } = require('../middleware/auth.middleware');

// All routes require authentication
router.use(authenticate);

/**
 * GET /api/evidence-requests
 * Get evidence requests for the officer (or all for admin)
 */
router.get('/', authorize('police_officer', 'admin'), evidenceRequestController.getOfficerRequests);

/**
 * POST /api/evidence-requests/case/:id
 * Create an evidence request for a case
 */
router.post('/case/:id', authorize('police_officer', 'admin'), evidenceRequestController.createRequest);

/**
 * GET /api/evidence-requests/case/:id
 * Get all evidence requests for a case
 */
router.get('/case/:id', evidenceRequestController.getRequestsByCase);

/**
 * PATCH /api/evidence-requests/:id/status
 * Update an evidence request's status (review, fulfill, cancel)
 */
router.patch('/:id/status', authorize('police_officer', 'admin'), evidenceRequestController.updateRequestStatus);

module.exports = router;
