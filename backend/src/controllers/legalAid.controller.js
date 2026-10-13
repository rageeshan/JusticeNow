const Organization = require('../models/Organization.model');
const User = require('../models/User.model');
const Case = require('../models/Case.model');
const Consultation = require('../models/Consultation.model');
const Notification = require('../models/Notification.model');
const AuditLog = require('../models/AuditLog.model');
const Advertisement = require('../models/Advertisement.model');
const path = require('path');
const { sendSuccess, sendCreated, sendNotFound, sendBadRequest, sendForbidden } = require('../utils/response.util');

/**
 * Helper to calculate age from birthdate or NIC if not explicitly set
 */
const resolveAge = (user) => {
  if (user.profile?.age) return user.profile.age;
  if (user.profile?.dob) {
    const diff = Date.now() - new Date(user.profile.dob).getTime();
    const ageDate = new Date(diff);
    return Math.abs(ageDate.getUTCFullYear() - 1970);
  }
  // Standard fallback estimation if NIC available
  const nic = user.profile?.nic;
  if (nic && nic.length === 10) {
    const birthYear = 1900 + parseInt(nic.substring(0, 2), 10);
    return new Date().getFullYear() - birthYear;
  } else if (nic && nic.length === 12) {
    const birthYear = parseInt(nic.substring(0, 4), 10);
    return new Date().getFullYear() - birthYear;
  }
  return 35; // reasonable default
};

/**
 * GET /api/legal-aid/lawyers
 * List verified/approved lawyers with filters and sorting
 */
const getLawyers = async (req, res, next) => {
  try {
    const { search, language, province, district, sortBy } = req.query;

    const query = {
      role: 'lawyer',
      approvalStatus: 'approved',
      isActive: true,
    };

    // Filter by Language
    if (language && language !== 'All') {
      query['profile.preferredLanguage'] = language;
    }

    // Filter by Location dropdowns
    if (province && province !== 'All' && province !== 'Default') {
      query['profile.province'] = new RegExp(`^${province.trim()}$`, 'i');
    }
    if (district && district !== 'All' && district !== 'Default') {
      query['profile.district'] = new RegExp(`^${district.trim()}$`, 'i');
    }

    // Search by Name, District, Province, Court Number, Lawyer ID, or About
    if (search && search.trim() !== '') {
      const escaped = search.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      const regex = new RegExp(escaped, 'i');
      query.$or = [
        { 'profile.fullName': regex },
        { 'profile.district': regex },
        { 'profile.province': regex },
        { 'profile.courtNumber': regex },
        { 'profile.lawyerId': regex },
        { 'profile.aboutMe': regex },
        { email: regex },
      ];
    }

    let lawyers = await User.find(query)
      .select('-passwordHash')
      .lean();

    // Map and enrich with calculated age
    lawyers = lawyers.map((l) => ({
      ...l,
      age: resolveAge(l),
      locationText: [l.profile?.district, l.profile?.province]
        .filter(Boolean)
        .join(', ') || 'Sri Lanka',
    }));

    // Sorting
    if (sortBy === 'Age') {
      lawyers.sort((a, b) => (a.age || 0) - (b.age || 0));
    } else if (sortBy === 'Nearest location') {
      // Prioritize same district then same province
      lawyers.sort((a, b) => {
        const aDist = (a.profile?.district || '').toLowerCase();
        const bDist = (b.profile?.district || '').toLowerCase();
        const targetDist = (district || '').toLowerCase();
        if (aDist === targetDist && bDist !== targetDist) return -1;
        if (bDist === targetDist && aDist !== targetDist) return 1;
        return (a.profile?.fullName || '').localeCompare(b.profile?.fullName || '');
      });
    } else {
      // Default: Name (A-Z)
      lawyers.sort((a, b) => (a.profile?.fullName || '').localeCompare(b.profile?.fullName || ''));
    }

    return sendSuccess(res, { lawyers }, 'Lawyers retrieved successfully');
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/legal-aid/lawyers/:id
 * Get single lawyer full profile
 */
const getLawyerById = async (req, res, next) => {
  try {
    const lawyer = await User.findOne({
      _id: req.params.id,
      role: 'lawyer',
      approvalStatus: 'approved',
    })
      .select('-passwordHash')
      .lean();

    if (!lawyer) {
      return sendNotFound(res, 'Lawyer not found');
    }

    const lawyerWithAge = {
      ...lawyer,
      age: resolveAge(lawyer),
      locationText: [lawyer.profile?.district, lawyer.profile?.province]
        .filter(Boolean)
        .join(', ') || 'Sri Lanka',
    };

    return sendSuccess(res, { lawyer: lawyerWithAge }, 'Lawyer details retrieved');
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/legal-aid/book
 * Citizen books an approved case with a specific lawyer
 */
const bookLawyer = async (req, res, next) => {
  try {
    const { caseId, lawyerId, preferredContactMethod, shortMessage } = req.body;

    if (!caseId || !lawyerId) {
      return sendBadRequest(res, 'caseId and lawyerId are required');
    }

    const [caseDoc, lawyer, citizen] = await Promise.all([
      Case.findOne({ _id: caseId, isDeleted: false }).populate('evidence'),
      User.findOne({ _id: lawyerId, role: 'lawyer', approvalStatus: 'approved' }),
      User.findById(req.user._id),
    ]);

    if (!caseDoc) return sendNotFound(res, 'Case not found');
    if (!lawyer) return sendNotFound(res, 'Selected lawyer not found');

    const citizenName =
      citizen.profile?.fullName || citizen.alias || 'Citizen';

    // 1. Update Case
    const previousStatus = caseDoc.status;
    caseDoc.status = 'waiting_for_lawyer_approval';
    caseDoc.assignedLawyer = lawyer._id;
    caseDoc.preferredContactMethod = preferredContactMethod || 'In-app';
    caseDoc.citizenMessageToLawyer = shortMessage || '';
    caseDoc.timeline.push({
      status: 'waiting_for_lawyer_approval',
      note: `Requested legal assistance from Attorney ${lawyer.profile?.fullName || 'Lawyer'}`,
      updatedBy: req.user._id,
    });
    await caseDoc.save();

    // 2. Create Consultation / Booking
    const consultation = await Consultation.create({
      citizenName,
      citizenId: req.user._id,
      counselId: lawyer._id,
      caseId: caseDoc._id,
      category: caseDoc.category || 'Human Rights',
      requestedDate: new Date().toISOString(),
      caseDescription: caseDoc.description || '',
      preferredContactMethod: preferredContactMethod || 'In-app',
      shortMessage: shortMessage || '',
      status: 'Waiting for Lawyer Approval',
    });

    // 3. Notify Lawyer
    await Notification.create({
      recipient: lawyer._id,
      case: caseDoc._id,
      title: `New case request from ${citizenName}`,
      message: `Citizen ${citizenName} has requested your assistance on case "${caseDoc.title}".`,
      type: 'new_case_request',
      actionRoute: `/legal-aid/lawyer-case/${caseDoc._id}`,
      actionText: 'View Case',
    });

    // 4. Notify Citizen
    await Notification.create({
      recipient: req.user._id,
      case: caseDoc._id,
      title: 'Lawyer Request Submitted',
      message: `Your request has been successfully sent to Attorney ${lawyer.profile?.fullName || 'Lawyer'}. Please wait for their approval.`,
      type: 'waiting_for_lawyer_approval',
      actionRoute: '/my-cases',
      actionText: 'Check Case History',
    });

    // 5. Audit Log
    await AuditLog.create({
      action: 'case.lawyer_booked',
      performedBy: req.user._id,
      targetResource: 'Case',
      targetId: caseDoc._id,
      metadata: { previousStatus, newStatus: caseDoc.status, lawyerId: lawyer._id },
    });

    const updatedCase = await Case.findById(caseDoc._id)
      .populate('reportedBy', 'alias email role profile')
      .populate('assignedLawyer', 'profile email')
      .populate('evidence');

    return sendCreated(
      res,
      {
        booking: consultation,
        case: updatedCase,
      },
      'Lawyer booking request submitted successfully'
    );
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/legal-aid/lawyer/cases/:caseId
 * Lawyer side view case page
 */
const getLawyerCase = async (req, res, next) => {
  try {
    const { caseId } = req.params;
    const caseDoc = await Case.findOne({ _id: caseId, isDeleted: false })
      .populate('reportedBy', 'alias email role profile')
      .populate('assignedLawyer', 'profile email')
      .populate('evidence');

    if (!caseDoc) {
      return sendNotFound(res, 'Case not found');
    }

    // Check authorization: must be the assigned lawyer, staff, or owner
    const isAssignedLawyer =
      caseDoc.assignedLawyer &&
      caseDoc.assignedLawyer._id.toString() === req.user._id.toString();
    const isStaff = ['admin', 'officer'].includes(req.user.role);
    const isOwner =
      caseDoc.reportedBy &&
      caseDoc.reportedBy._id.toString() === req.user._id.toString();

    if (!isAssignedLawyer && !isStaff && !isOwner) {
      return sendForbidden(res, 'You do not have permission to view this case');
    }

    return sendSuccess(res, { case: caseDoc }, 'Case details retrieved for lawyer');
  } catch (err) {
    next(err);
  }
};

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

/**
 * GET /api/legal-aid/lawyer/cases
 * Get cases assigned to this lawyer filtered by tab (pending, in_progress, completed)
 */
const getLawyerCases = async (req, res, next) => {
  try {
    const { tab = 'pending' } = req.query;
    const lawyerId = req.user._id;

    let statusQuery;
    if (tab === 'in_progress') {
      statusQuery = { $in: ['approved_scheduled', 'in_progress'] };
    } else if (tab === 'completed') {
      statusQuery = 'completed';
    } else {
      // Default: pending
      statusQuery = 'waiting_for_lawyer_approval';
    }

    const cases = await Case.find({
      assignedLawyer: lawyerId,
      status: statusQuery,
    })
      .sort({ updatedAt: -1, createdAt: -1 })
      .populate('reportedBy', 'profile email role alias')
      .populate('evidence')
      .lean();

    return sendSuccess(res, { cases }, 'Lawyer cases retrieved');
  } catch (err) {
    next(err);
  }
};

/**
 * PATCH /api/legal-aid/lawyer/cases/:caseId/approve
 * Lawyer approves case and schedules meeting date + time
 */
const approveLawyerCase = async (req, res, next) => {
  try {
    const { caseId } = req.params;
    const { scheduledDate, scheduledTime } = req.body;

    if (!scheduledDate || !scheduledTime) {
      return sendBadRequest(res, 'Scheduled date and time are required to approve the case');
    }

    const caseDoc = await Case.findById(caseId);
    if (!caseDoc) {
      return sendNotFound(res, 'Case not found');
    }

    if (caseDoc.assignedLawyer?.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return sendForbidden(res, 'You are not assigned to this case');
    }

    caseDoc.status = 'approved_scheduled';
    caseDoc.scheduledMeetingDate = scheduledDate;
    caseDoc.scheduledMeetingTime = scheduledTime;
    await caseDoc.save();

    // Send notification to the related citizen
    if (caseDoc.reportedBy) {
      await Notification.create({
        recipient: caseDoc.reportedBy,
        case: caseDoc._id,
        title: 'Your lawyer approved your case',
        message: `Case: ${caseDoc.title}\nDate: ${scheduledDate} Time: ${scheduledTime}\nLawyer: ${req.user.profile?.fullName || 'Your Lawyer'}`,
        type: 'case_approved_scheduled',
        actionRoute: '/my-cases',
        actionText: 'View in History',
      });
    }

    return sendSuccess(res, { case: caseDoc }, 'Case approved and scheduled successfully');
  } catch (err) {
    next(err);
  }
};

/**
 * PATCH /api/legal-aid/lawyer/cases/:caseId/reject
 * Lawyer declines case with a required reason
 */
const rejectLawyerCase = async (req, res, next) => {
  try {
    const { caseId } = req.params;
    const { reason } = req.body;

    if (!reason || !reason.trim()) {
      return sendBadRequest(res, 'Rejection reason is required');
    }

    const caseDoc = await Case.findById(caseId);
    if (!caseDoc) {
      return sendNotFound(res, 'Case not found');
    }

    if (caseDoc.assignedLawyer?.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return sendForbidden(res, 'You are not assigned to this case');
    }

    caseDoc.status = 'lawyer_declined';
    caseDoc.lawyerDeclineReason = reason.trim();
    await caseDoc.save();

    // Send notification to the related citizen
    if (caseDoc.reportedBy) {
      await Notification.create({
        recipient: caseDoc.reportedBy,
        case: caseDoc._id,
        title: 'Your case was declined',
        message: `Case: ${caseDoc.title}\n${reason.trim()}`,
        type: 'lawyer_declined',
        actionRoute: `/legal-aid?caseId=${caseDoc._id}`,
        actionText: 'Find another lawyer',
      });
    }

    return sendSuccess(res, { case: caseDoc }, 'Case rejected and citizen notified');
  } catch (err) {
    next(err);
  }
};

/**
 * PATCH /api/legal-aid/lawyer/cases/:caseId/complete
 * Lawyer marks accepted case as completed
 */
const completeLawyerCase = async (req, res, next) => {
  try {
    const { caseId } = req.params;

    const caseDoc = await Case.findById(caseId);
    if (!caseDoc) {
      return sendNotFound(res, 'Case not found');
    }

    if (caseDoc.assignedLawyer?.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return sendForbidden(res, 'You are not assigned to this case');
    }

    caseDoc.status = 'completed';
    caseDoc.completedAt = new Date();
    await caseDoc.save();

    return sendSuccess(res, { case: caseDoc }, 'Case marked as completed');
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/legal-aid/lawyer/availability
 * Get saved weekly availability schedule
 */
const getLawyerAvailability = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id).select('profile.availability');
    const defaultAvailability = {
      Monday: { isUnavailable: false, slots: [{ startTime: '09:00 AM', endTime: '12:00 PM' }, { startTime: '02:00 PM', endTime: '05:00 PM' }] },
      Tuesday: { isUnavailable: false, slots: [{ startTime: '10:00 AM', endTime: '01:00 PM' }] },
      Wednesday: { isUnavailable: true, slots: [] },
      Thursday: { isUnavailable: false, slots: [{ startTime: '09:00 AM', endTime: '12:00 PM' }] },
      Friday: { isUnavailable: false, slots: [{ startTime: '09:00 AM', endTime: '12:00 PM' }] },
      Saturday: { isUnavailable: true, slots: [] },
      Sunday: { isUnavailable: true, slots: [] },
    };

    const availability = user?.profile?.availability || defaultAvailability;
    return sendSuccess(res, { availability }, 'Lawyer availability retrieved');
  } catch (err) {
    next(err);
  }
};

/**
 * PUT /api/legal-aid/lawyer/availability
 * Save lawyer weekly availability schedule
 */
const updateLawyerAvailability = async (req, res, next) => {
  try {
    const { availability } = req.body;
    if (!availability || typeof availability !== 'object') {
      return sendBadRequest(res, 'Invalid availability payload');
    }

    const updatedUser = await User.findByIdAndUpdate(
      req.user._id,
      { $set: { 'profile.availability': availability } },
      { new: true }
    ).select('profile.availability');

    return sendSuccess(res, { availability: updatedUser.profile?.availability }, 'Availability updated successfully');
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/legal-aid/lawyer/advertisement
 * Lawyer submits promotional/service advertisement post with photo
 */
const submitLawyerAd = async (req, res, next) => {
  try {
    let imageUrl = req.body.imageUrl;

    if (req.file) {
      const relativePath = path
        .relative(path.resolve(process.env.UPLOAD_DIR || 'uploads'), req.file.path)
        .replace(/\\/g, '/');
      imageUrl = `/uploads/${relativePath}`;
    }

    if (!imageUrl) {
      return sendBadRequest(res, 'Please upload a photo for your advertisement post');
    }

    const lawyerName = req.user.profile?.fullName || req.user.email || 'Attorney at Law';
    const lawyerCourtNumber = req.user.profile?.courtNumber || req.user.profile?.lawyerId || '';
    const lawyerDistrict = req.user.profile?.district || '';
    const lawyerProvince = req.user.profile?.province || '';
    const caption = req.body.caption || 'Legal Awareness Post';

    const ad = await Advertisement.create({
      lawyer: req.user._id,
      lawyerName,
      lawyerCourtNumber,
      lawyerDistrict,
      lawyerProvince,
      imageUrl,
      caption,
      isActive: true,
    });

    return sendCreated(res, { ad }, 'Advertisement post published successfully');
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/legal-aid/advertisements
 * Get active advertisements for citizen dashboard
 */
const getAdvertisements = async (req, res, next) => {
  try {
    const ads = await Advertisement.find({ isActive: true })
      .sort({ createdAt: -1 })
      .populate('lawyer', 'profile email')
      .lean();

    return sendSuccess(res, { ads }, 'Advertisements retrieved successfully');
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getLawyers,
  getLawyerById,
  bookLawyer,
  getLawyerCase,
  getOrganizations,
  getOrganizationById,
  createOrganization,
  getLawyerCases,
  approveLawyerCase,
  rejectLawyerCase,
  completeLawyerCase,
  getLawyerAvailability,
  updateLawyerAvailability,
  submitLawyerAd,
  getAdvertisements,
};
