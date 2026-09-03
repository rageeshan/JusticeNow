const Case = require('../models/Case.model');
const AuditLog = require('../models/AuditLog.model');
const { sendSuccess } = require('../utils/response.util');

/**
 * GET /api/analytics/summary
 * High-level dashboard stats for officers/admins
 */
const getSummary = async (req, res, next) => {
  try {
    const [totalCases, byStatus, byCategory, byPriority, recentActivity] = await Promise.all([
      Case.countDocuments({ isDeleted: false }),

      Case.aggregate([
        { $match: { isDeleted: false } },
        { $group: { _id: '$status', count: { $sum: 1 } } },
      ]),

      Case.aggregate([
        { $match: { isDeleted: false } },
        { $group: { _id: '$category', count: { $sum: 1 } } },
      ]),

      Case.aggregate([
        { $match: { isDeleted: false } },
        { $group: { _id: '$priority', count: { $sum: 1 } } },
      ]),

      AuditLog.find()
        .sort({ createdAt: -1 })
        .limit(20)
        .populate('performedBy', 'alias email role'),
    ]);

    return sendSuccess(
      res,
      { totalCases, byStatus, byCategory, byPriority, recentActivity },
      'Analytics summary retrieved'
    );
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/analytics/hotspots
 * Incident hotspot data for map visualization
 */
const getHotspots = async (req, res, next) => {
  try {
    const hotspots = await Case.aggregate([
      {
        $match: {
          isDeleted: false,
          'location.coordinates.coordinates': { $ne: [0, 0] },
        },
      },
      {
        $group: {
          _id: {
            city: '$location.city',
            country: '$location.country',
          },
          count: { $sum: 1 },
          coordinates: { $first: '$location.coordinates.coordinates' },
          categories: { $addToSet: '$category' },
        },
      },
      { $sort: { count: -1 } },
      { $limit: 100 },
    ]);

    return sendSuccess(res, { hotspots }, 'Hotspot data retrieved');
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/analytics/trends
 * Monthly case trend over the last 12 months
 */
const getTrends = async (req, res, next) => {
  try {
    const twelveMonthsAgo = new Date();
    twelveMonthsAgo.setMonth(twelveMonthsAgo.getMonth() - 12);

    const trends = await Case.aggregate([
      { $match: { isDeleted: false, createdAt: { $gte: twelveMonthsAgo } } },
      {
        $group: {
          _id: {
            year: { $year: '$createdAt' },
            month: { $month: '$createdAt' },
          },
          count: { $sum: 1 },
        },
      },
      { $sort: { '_id.year': 1, '_id.month': 1 } },
    ]);

    return sendSuccess(res, { trends }, 'Trend data retrieved');
  } catch (err) {
    next(err);
  }
};

module.exports = { getSummary, getHotspots, getTrends };
