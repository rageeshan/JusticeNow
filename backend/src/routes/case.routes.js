const express = require('express');
const router = express.Router();
const caseController = require('../controllers/case.controller');
const { authenticate, authorize } = require('../middleware/auth.middleware');
const upload = require('../middleware/upload.middleware');
const { caseValidators } = require('../utils/validators');

// All case routes require authentication
router.use(authenticate);

// POST /api/cases            — Any authenticated user can report
router.post('/', caseValidators.create, caseController.createCase);

// GET  /api/cases            — Officers and admins only
router.get('/', authorize('police_officer', 'admin'), caseController.getCases);

// GET  /api/cases/my         — Self-tracking for reporters
router.get('/my', caseController.getMyCases);

// ── Police Officer Workflow Routes ──
// GET   /api/cases/officer/cases          — List assigned cases (pending, in_progress, completed)
router.get('/officer/cases', authorize('police_officer', 'admin'), caseController.getOfficerCases);

// PATCH /api/cases/officer/cases/:id/accept — Officer accepts case with scheduled date & time
router.patch('/officer/cases/:id/accept', authorize('police_officer', 'admin'), caseController.acceptOfficerCase);

// PATCH /api/cases/officer/cases/:id/reject — Officer declines case with reason (returns to admin)
router.patch('/officer/cases/:id/reject', authorize('police_officer', 'admin'), caseController.rejectOfficerCase);

// PATCH /api/cases/officer/cases/:id/stage  — Officer updates investigation stage
router.patch('/officer/cases/:id/stage', authorize('police_officer', 'admin'), caseController.updateOfficerCaseStage);

// PATCH /api/cases/officer/cases/:id/complete — Officer marks case as completed
router.patch('/officer/cases/:id/complete', authorize('police_officer', 'admin'), caseController.completeOfficerCase);

// GET   /api/cases/officer/availability   — Get officer availability
router.get('/officer/availability', authorize('police_officer', 'admin'), caseController.getOfficerAvailability);

// PUT   /api/cases/officer/availability   — Update officer availability
router.put('/officer/availability', authorize('police_officer', 'admin'), caseController.updateOfficerAvailability);

// GET  /api/cases/:id        — Owner or staff
router.get('/:id', caseController.getCaseById);

// PATCH /api/cases/:id/status — Officers and admins only
router.patch(
  '/:id/status',
  authorize('police_officer', 'admin'),
  caseValidators.updateStatus,
  caseController.updateCaseStatus
);

// POST /api/cases/:id/evidence — Any authenticated user (owner or staff)
router.post(
  '/:id/evidence',
  upload.array('files', 10), // Up to 10 files per upload
  caseController.uploadEvidence
);

module.exports = router;
