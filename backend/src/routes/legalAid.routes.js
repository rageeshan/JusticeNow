const express = require('express');
const router = express.Router();
const legalAidController = require('../controllers/legalAid.controller');
const { authenticate, authorize } = require('../middleware/auth.middleware');

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
