const express = require('express');
const router = express.Router();
const caseController = require('../controllers/case.controller');
const { authenticate, authorize, optionalAuthenticate } = require('../middleware/auth.middleware');
const upload = require('../middleware/upload.middleware');
const { caseValidators } = require('../utils/validators');

// ─────────────────────────────────────────────────────────────────────────────
//  Citizen — Case Reporting & Tracking
// ─────────────────────────────────────────────────────────────────────────────

/**
 * GET /api/cases/ref/:refNum
 * Track a case by its human-readable reference number (e.g. JN-2024-00042)
 * ✅ Works WITHOUT a token — anonymous tracking.
 * Strips all sensitive fields (internalNotes, officer details, contact info).
 *
 * IMPORTANT: must be defined BEFORE /:id to avoid route collision.
 */
router.get('/ref/:refNum', optionalAuthenticate, caseController.getCaseByRef);

/**
 * POST /api/cases
 * Submit a new incident report.
 * Requires a JWT token — get one via POST /api/auth/anonymous or /api/auth/login.
 */
router.post('/', authenticate, caseValidators.create, caseController.createCase);

/**
 * GET /api/cases/my
 * Get all cases submitted by the authenticated user (citizen self-tracking).
 */
router.get('/my', authenticate, caseController.getMyCases);

/**
 * POST /api/cases/:id/evidence
 * Upload evidence files. Owner or staff only.
 */
router.post(
  '/:id/evidence',
  authenticate,
  upload.array('files', 10),
  caseController.uploadEvidence
);

/**
 * GET /api/cases/:id/updates
 * Get public investigator updates and timeline for the citizen's own case.
 * Never exposes internal officer notes.
 */
router.get('/:id/updates', authenticate, caseController.getPublicUpdates);

/**
 * GET /api/cases/:id
 * Get full case by MongoDB ObjectId.
 * Citizens get everything except internalNotes + assigned officer.
 * Staff get everything.
 */
router.get('/:id', authenticate, caseController.getCaseById);

// ─────────────────────────────────────────────────────────────────────────────
//  Staff — Case Management (police_officer / officer / admin only)
// ─────────────────────────────────────────────────────────────────────────────

/**
 * GET /api/cases
 * Paginated list of all cases — officers and admins only.
 */
router.get('/', authenticate, authorize('police_officer', 'officer', 'admin'), caseController.getCases);

/**
 * PATCH /api/cases/:id/status
 * Update case status — officers and admins only.
 */
router.patch(
  '/:id/status',
  authenticate,
  authorize('police_officer', 'officer', 'admin'),
  caseValidators.updateStatus,
  caseController.updateCaseStatus
);

module.exports = router;
