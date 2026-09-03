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
router.get('/', authorize('officer', 'admin'), caseController.getCases);

// GET  /api/cases/my         — Self-tracking for reporters
router.get('/my', caseController.getMyCases);

// GET  /api/cases/:id        — Owner or staff
router.get('/:id', caseController.getCaseById);

// PATCH /api/cases/:id/status — Officers and admins only
router.patch(
  '/:id/status',
  authorize('officer', 'admin'),
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
