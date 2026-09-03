const express = require('express');
const router = express.Router();
const analyticsController = require('../controllers/analytics.controller');
const { authenticate, authorize } = require('../middleware/auth.middleware');

// All analytics routes — officers and admins only
router.use(authenticate, authorize('officer', 'admin'));

// GET /api/analytics/summary
router.get('/summary', analyticsController.getSummary);

// GET /api/analytics/hotspots
router.get('/hotspots', analyticsController.getHotspots);

// GET /api/analytics/trends
router.get('/trends', analyticsController.getTrends);

module.exports = router;
