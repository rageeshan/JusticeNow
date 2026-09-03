const Organization = require('../models/Organization.model');
const { sendSuccess, sendCreated, sendNotFound } = require('../utils/response.util');

/**
 * GET /api/legal-aid/organizations
 * List verified NGOs and legal practitioners
 */
const getOrganizations = async (req, res, next) => {
  try {
    const { type, specialization, country, search, page = 1, limit = 20 } = req.query;
    const query = { isActive: true, isVerified: true };

    if (type) query.type = type;
    if (specialization) query.specializations = specialization;
    if (country) query['location.country'] = country;
    if (search) query.$text = { $search: search };

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [orgs, total] = await Promise.all([
      Organization.find(query)
        .sort({ casesHandled: -1, name: 1 })
        .skip(skip)
        .limit(parseInt(limit))
        .select('-members'),
      Organization.countDocuments(query),
    ]);

    return sendSuccess(
      res,
      {
        organizations: orgs,
        pagination: { page: parseInt(page), limit: parseInt(limit), total, pages: Math.ceil(total / parseInt(limit)) },
      },
      'Organizations retrieved'
    );
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/legal-aid/organizations/:id
 * Get a single organization's details
 */
const getOrganizationById = async (req, res, next) => {
  try {
    const org = await Organization.findOne({
      _id: req.params.id,
      isActive: true,
      isVerified: true,
    });
    if (!org) return sendNotFound(res, 'Organization not found');
    return sendSuccess(res, { organization: org }, 'Organization retrieved');
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/legal-aid/organizations
 * Register a new organization (admin only)
 */
const createOrganization = async (req, res, next) => {
  try {
    const org = await Organization.create(req.body);
    return sendCreated(res, { organization: org }, 'Organization registered');
  } catch (err) {
    next(err);
  }
};

module.exports = { getOrganizations, getOrganizationById, createOrganization };
