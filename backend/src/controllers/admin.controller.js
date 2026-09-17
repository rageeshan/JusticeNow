const User = require('../models/User.model');
const AuditLog = require('../models/AuditLog.model');
const { sendSuccess, sendNotFound, sendError } = require('../utils/response.util');

/**
 * GET /api/admin/users
 * Fetch users with optional filters by approvalStatus and role
 */
const getUsers = async (req, res, next) => {
  try {
    const { approvalStatus, role, search, page = 1, limit = 20 } = req.query;
    const query = {};

    if (approvalStatus && approvalStatus !== 'all') {
      query.approvalStatus = approvalStatus;
    }

    if (role && role !== 'all') {
      query.role = role;
    }

    if (search) {
      query.$or = [
        { email: { $regex: search, $options: 'i' } },
        { 'profile.fullName': { $regex: search, $options: 'i' } },
        { 'profile.policeId': { $regex: search, $options: 'i' } },
        { 'profile.lawyerId': { $regex: search, $options: 'i' } },
      ];
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [users, total] = await Promise.all([
      User.find(query)
        .select('-passwordHash')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit)),
      User.countDocuments(query),
    ]);

    return sendSuccess(
      res,
      {
        users,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / parseInt(limit)),
        },
      },
      'Users retrieved successfully'
    );
  } catch (err) {
    next(err);
  }
};

/**
 * PATCH /api/admin/users/:id/status
 * Approve or reject a user account (e.g. police officer or lawyer)
 */
const updateUserApprovalStatus = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status, reason } = req.body;

    const user = await User.findById(id);
    if (!user) {
      return sendNotFound(res, 'User not found');
    }

    const previousStatus = user.approvalStatus;
    user.approvalStatus = status;
    user.isVerified = status === 'approved';

    await user.save();

    await AuditLog.create({
      action: status === 'approved' ? 'user.approved' : 'user.rejected',
      performedBy: req.user._id,
      targetResource: 'User',
      targetId: user._id,
      metadata: {
        previousStatus,
        newStatus: status,
        role: user.role,
        reason: reason || null,
      },
      ipAddress: req.ip,
      userAgent: req.headers['user-agent'],
    });

    return sendSuccess(
      res,
      { user: user.toJSON() },
      `User account ${status} successfully`
    );
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getUsers,
  updateUserApprovalStatus,
};
