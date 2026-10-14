const User = require('../models/User.model');
const Case = require('../models/Case.model');
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
        { 'profile.phone': { $regex: search, $options: 'i' } },
        { 'profile.nic': { $regex: search, $options: 'i' } },
        { 'profile.policeId': { $regex: search, $options: 'i' } },
        { 'profile.courtNumber': { $regex: search, $options: 'i' } },
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
 * GET /api/admin/users/:id
 * Retrieve comprehensive details for a specific user (Verification Detail Page)
 */
const getUserById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const user = await User.findById(id)
      .select('-passwordHash')
      .populate('reviewedBy', 'email profile.fullName role');

    if (!user) {
      return sendNotFound(res, 'User not found');
    }

    return sendSuccess(res, { user }, 'User details retrieved successfully');
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
    if (status === 'rejected') {
      user.rejectionReason = reason || 'Application requirements not met';
    } else if (status === 'approved') {
      user.rejectionReason = null;
    }
    user.reviewedBy = req.user._id;
    user.reviewedAt = new Date();

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

/**
 * GET /api/admin/export-cases
 * Retrieve cases for report preview and PDF generation
 */
const getExportCases = async (req, res, next) => {
  try {
    const {
      timeRange = 'all',
      province,
      district,
      status,
      sortBy = 'date_desc',
      search,
    } = req.query;

    const query = { isDeleted: false };

    if (status && status !== 'all' && status !== 'All') {
      query.status = status;
    }

    const now = new Date();
    if (timeRange === 'today') {
      const start = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
      const end = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);
      query.createdAt = { $gte: start, $lte: end };
    } else if (timeRange === 'this_week') {
      const day = now.getDay();
      const diff = now.getDate() - day + (day === 0 ? -6 : 1);
      const start = new Date(now.getFullYear(), now.getMonth(), diff, 0, 0, 0, 0);
      query.createdAt = { $gte: start, $lte: now };
    } else if (timeRange === 'last_week') {
      const day = now.getDay();
      const diff = now.getDate() - day + (day === 0 ? -6 : 1);
      const start = new Date(now.getFullYear(), now.getMonth(), diff - 7, 0, 0, 0, 0);
      const end = new Date(now.getFullYear(), now.getMonth(), diff - 1, 23, 59, 59, 999);
      query.createdAt = { $gte: start, $lte: end };
    } else if (timeRange === 'this_month') {
      const start = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0, 0);
      query.createdAt = { $gte: start, $lte: now };
    } else if (timeRange === 'last_month') {
      const start = new Date(now.getFullYear(), now.getMonth() - 1, 1, 0, 0, 0, 0);
      const end = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59, 999);
      query.createdAt = { $gte: start, $lte: end };
    } else if (timeRange === 'last_3_months') {
      const start = new Date(now.getFullYear(), now.getMonth() - 3, 1, 0, 0, 0, 0);
      query.createdAt = { $gte: start, $lte: now };
    }

    if (search && search.trim().length > 0) {
      const regex = new RegExp(search.trim(), 'i');
      query.$or = [
        { title: regex },
        { description: regex },
        { referenceNumber: regex },
      ];
    }

    const cases = await Case.find(query)
      .populate('reportedBy', 'alias email role profile')
      .populate('assignedOfficer', 'profile.fullName email')
      .lean();

    const helperGetAge = (profile) => {
      if (!profile) return null;
      if (typeof profile.age === 'number' && profile.age > 0) return profile.age;
      if (profile.dob) {
        const diffMs = Date.now() - new Date(profile.dob).getTime();
        const ageDt = new Date(diffMs);
        const age = Math.abs(ageDt.getUTCFullYear() - 1970);
        if (!isNaN(age) && age > 0 && age < 120) return age;
      }
      if (profile.nic && typeof profile.nic === 'string') {
        const nic = profile.nic.trim();
        if (nic.length === 10) {
          const yr = parseInt('19' + nic.substring(0, 2), 10);
          if (!isNaN(yr) && yr > 1920 && yr < new Date().getFullYear()) {
            return new Date().getFullYear() - yr;
          }
        } else if (nic.length === 12) {
          const yr = parseInt(nic.substring(0, 4), 10);
          if (!isNaN(yr) && yr > 1920 && yr < new Date().getFullYear()) {
            return new Date().getFullYear() - yr;
          }
        }
      }
      return null;
    };

    let formatted = cases.map((c) => {
      const rep = c.reportedBy || {};
      const prof = rep.profile || {};
      const loc = c.location || {};

      const prov = (loc.state && loc.state.trim().length > 0)
        ? loc.state.trim()
        : (prof.province && prof.province.trim().length > 0 ? prof.province.trim() : 'Unspecified');

      const dist = (loc.city && loc.city.trim().length > 0)
        ? loc.city.trim()
        : (prof.district && prof.district.trim().length > 0 ? prof.district.trim() : (loc.address || 'Unspecified'));

      const fullLoc = [loc.address, loc.city, loc.state]
        .filter((s) => s && s.trim().length > 0)
        .join(', ') || 'Not specified';

      return {
        id: c._id.toString(),
        referenceNumber: c.referenceNumber || 'N/A',
        title: c.title || 'Untitled Case',
        description: c.description || '',
        category: c.category || 'other',
        status: c.status || 'submitted',
        createdAt: c.createdAt,
        incidentDate: c.incidentDate || c.createdAt,
        personName: prof.fullName || rep.alias || 'Anonymous Citizen',
        personAge: helperGetAge(prof),
        personGender: prof.gender || 'Not specified',
        personNic: prof.nic || 'Not specified',
        province: prov,
        district: dist,
        fullLocation: fullLoc,
        address: loc.address || '',
        city: loc.city || '',
        state: loc.state || '',
      };
    });

    if (province && province !== 'all' && province !== 'All') {
      const pLower = province.toLowerCase();
      formatted = formatted.filter((item) =>
        item.province.toLowerCase().includes(pLower) ||
        item.fullLocation.toLowerCase().includes(pLower)
      );
    }

    if (district && district !== 'all' && district !== 'All') {
      const dLower = district.toLowerCase();
      formatted = formatted.filter((item) =>
        item.district.toLowerCase().includes(dLower) ||
        item.fullLocation.toLowerCase().includes(dLower)
      );
    }

    if (sortBy === 'date_asc') {
      formatted.sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));
    } else if (sortBy === 'location') {
      formatted.sort((a, b) => a.province.localeCompare(b.province) || a.district.localeCompare(b.district));
    } else if (sortBy === 'age_asc') {
      formatted.sort((a, b) => (a.personAge ?? 999) - (b.personAge ?? 999));
    } else if (sortBy === 'age_desc') {
      formatted.sort((a, b) => (b.personAge ?? -1) - (a.personAge ?? -1));
    } else if (sortBy === 'title') {
      formatted.sort((a, b) => a.title.localeCompare(b.title));
    } else {
      formatted.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    }

    return sendSuccess(
      res,
      {
        total: formatted.length,
        cases: formatted,
        filters: {
          timeRange,
          province: province || 'All',
          district: district || 'All',
          status: status || 'all',
          sortBy,
        },
      },
      'Export cases retrieved successfully'
    );
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getUsers,
  getUserById,
  updateUserApprovalStatus,
  getExportCases,
};
