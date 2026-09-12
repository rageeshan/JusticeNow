const express = require('express');
const router = express.Router();
const {
  registerCounsel,
  loginCounsel,
  getConsultationRequests,
  updateConsultationStatus,
  updateAvailability
} = require('../controllers/legalAid.controller');

// Authentication routes
router.post('/register', registerCounsel);
router.post('/login', loginCounsel);

// Consultation & Dashboard routes
router.get('/requests', getConsultationRequests);
router.patch('/requests/:requestId/status', updateConsultationStatus);

// Profile & Availability routes
router.patch('/availability', updateAvailability);

module.exports = router;