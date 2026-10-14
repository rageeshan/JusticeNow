const express = require('express');
const router = express.Router();
const legalAidController = require('../controllers/legalAid.controller');
const { authenticate, authorize, optionalAuthenticate } = require('../middleware/auth.middleware');

// ── Lawyer Discovery & Booking ──
// GET  /api/legal-aid/lawyers         — Public / Citizen
router.get('/lawyers', optionalAuthenticate, legalAidController.getLawyers);

// GET  /api/legal-aid/lawyers/:id     — Public / Citizen
router.get('/lawyers/:id', optionalAuthenticate, legalAidController.getLawyerById);

// POST /api/legal-aid/book            — Authenticated Citizen
router.post('/book', authenticate, legalAidController.bookLawyer);

// GET  /api/legal-aid/lawyer/cases          — Authenticated Lawyer (lists pending, in_progress, completed)
router.get('/lawyer/cases', authenticate, legalAidController.getLawyerCases);

// GET  /api/legal-aid/lawyer/cases/:caseId   — Authenticated Lawyer / Staff / Citizen
router.get('/lawyer/cases/:caseId', authenticate, legalAidController.getLawyerCase);

// PATCH /api/legal-aid/lawyer/cases/:caseId/approve — Authenticated Lawyer
router.patch('/lawyer/cases/:caseId/approve', authenticate, legalAidController.approveLawyerCase);

// PATCH /api/legal-aid/lawyer/cases/:caseId/reject  — Authenticated Lawyer
router.patch('/lawyer/cases/:caseId/reject', authenticate, legalAidController.rejectLawyerCase);

// PATCH /api/legal-aid/lawyer/cases/:caseId/complete — Authenticated Lawyer
router.patch('/lawyer/cases/:caseId/complete', authenticate, legalAidController.completeLawyerCase);

const upload = require('../middleware/upload.middleware');

// GET  /api/legal-aid/advertisements          — Public / Citizen (Get legal awareness ads)
router.get('/advertisements', legalAidController.getAdvertisements);

// GET  /api/legal-aid/lawyer/availability    — Authenticated Lawyer
router.get('/lawyer/availability', authenticate, legalAidController.getLawyerAvailability);

// PUT  /api/legal-aid/lawyer/availability    — Authenticated Lawyer
router.put('/lawyer/availability', authenticate, legalAidController.updateLawyerAvailability);

// POST /api/legal-aid/lawyer/advertisement   — Authenticated Lawyer
router.post('/lawyer/advertisement', authenticate, upload.single('photo'), legalAidController.submitLawyerAd);

// ── Organization & Legal Aid Clinics ──
// GET  /api/legal-aid/organizations   — Public (optional auth)
router.get('/organizations', legalAidController.getOrganizations);

// GET  /api/legal-aid/organizations/:id — Public
router.get('/organizations/:id', legalAidController.getOrganizationById);

// POST /api/legal-aid/organizations   — Admin only
router.post(
  '/organizations',
  authenticate,
  authorize('admin'),
  legalAidController.createOrganization
);

module.exports = router;
