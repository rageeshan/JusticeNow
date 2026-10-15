const Case = require('../models/Case.model');
const AuditLog = require('../models/AuditLog.model');
const Notification = require('../models/Notification.model');

/**
 * Generate a unique human-readable reference number
 * Format: JN-YYYY-XXXXX
 */
const generateReferenceNumber = async () => {
  const year = new Date().getFullYear();
  const count = await Case.countDocuments();
  const padded = String(count + 1).padStart(5, '0');
  return `JN-${year}-${padded}`;
};

/**
 * Helper to compute date range filter
 */
const getDateFilterQuery = (filter) => {
  const now = new Date();
  if (filter === 'today') {
    const start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const end = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);
    return { $gte: start, $lte: end };
  }
  if (filter === 'this_week') {
    const day = now.getDay();
    const diff = now.getDate() - day + (day === 0 ? -6 : 1); // Monday
    const start = new Date(now.getFullYear(), now.getMonth(), diff, 0, 0, 0, 0);
    return { $gte: start, $lte: now };
  }
  if (filter === 'last_week') {
    const day = now.getDay();
    const diff = now.getDate() - day + (day === 0 ? -6 : 1);
    const start = new Date(now.getFullYear(), now.getMonth(), diff - 7, 0, 0, 0, 0);
    const end = new Date(now.getFullYear(), now.getMonth(), diff - 1, 23, 59, 59, 999);
    return { $gte: start, $lte: end };
  }
  if (filter === 'this_month') {
    const start = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0, 0);
    return { $gte: start, $lte: now };
  }
  if (filter === 'last_month') {
    const start = new Date(now.getFullYear(), now.getMonth() - 1, 1, 0, 0, 0, 0);
    const end = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59, 999);
    return { $gte: start, $lte: end };
  }
  return null;
};

/**
 * Create a new case report
 */
const createCase = async (data, reportedBy) => {
  const referenceNumber = await generateReferenceNumber();

  const newCase = await Case.create({
    ...data,
    referenceNumber,
    reportedBy: reportedBy._id,
    isAnonymous: reportedBy.role === 'anonymous',
    timeline: [
      {
        status: 'submitted',
        note: 'Case submitted by reporter',
        updatedBy: reportedBy._id,
      },
    ],
  });

  await AuditLog.create({
    action: 'case.created',
    performedBy: reportedBy._id,
    targetResource: 'Case',
    targetId: newCase._id,
    metadata: { referenceNumber, category: data.category },
  });

  return newCase;
};

/**
 * Get paginated list of cases (for officers/admins)
 */
const getCases = async ({ page = 1, limit = 20, status, category, priority, search, dateFilter } = {}) => {
  const query = { isDeleted: false };

  if (status && status !== 'All') query.status = status;
  if (category && category !== 'All') query.category = category;
  if (priority && priority !== 'All') query.priority = priority;
  if (search) {
    query.$or = [
      { title: { $regex: search, $options: 'i' } },
      { description: { $regex: search, $options: 'i' } },
      { referenceNumber: { $regex: search, $options: 'i' } },
    ];
  }

  if (dateFilter && dateFilter !== 'all') {
    const dateRange = getDateFilterQuery(dateFilter);
    if (dateRange) {
      query.createdAt = dateRange;
    }
  }

  const skip = (page - 1) * limit;
  const [cases, total] = await Promise.all([
    Case.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .populate('reportedBy', 'alias email role profile')
      .populate('assignedOfficer', 'profile.fullName email')
      .populate('assignedOrganization', 'name type')
      .populate('evidence'),
    Case.countDocuments(query),
  ]);

  return {
    cases,
    pagination: {
      page,
      limit,
      total,
      pages: Math.ceil(total / limit),
    },
  };
};

/**
 * Get a single case by ID
 */
const getCaseById = async (id) => {
  return Case.findOne({ _id: id, isDeleted: false })
    .populate('reportedBy', 'alias email role profile')
    .populate('assignedOfficer', 'profile.fullName profile.phone profile.district email')
    .populate('assignedOrganization', 'name type contact')
    .populate('evidence');
};

/**
 * Update case status with timeline event and notifications
 */
const updateCaseStatus = async (id, { status, note, reason }, updatedBy) => {
  const caseDoc = await Case.findOne({ _id: id, isDeleted: false });
  if (!caseDoc) {
    const err = new Error('Case not found');
    err.statusCode = 404;
    throw err;
  }

  const previousStatus = caseDoc.status;
  caseDoc.status = status;
  if (status === 'rejected') {
    caseDoc.rejectionReason = reason || note || 'Case requirements not met';
  }

  caseDoc.timeline.push({
    status,
    note: note || reason || `Status updated to ${status}`,
    updatedBy: updatedBy._id,
  });
  await caseDoc.save();

  // Create citizen notification for assign to lawyer or rejection
  if (caseDoc.reportedBy) {
    if (status === 'awaiting_lawyer_selection') {
      await Notification.create({
        recipient: caseDoc.reportedBy,
        case: caseDoc._id,
        title: 'Thank you for submitting your report.',
        message:
          'Your case has been reviewed and approved by our admin team. You can now book a lawyer related to your area from here.',
        type: 'awaiting_lawyer_selection',
        actionRoute: '/legal-aid',
        actionText: 'Find a Lawyer',
      });
    } else if (status === 'rejected') {
      await Notification.create({
        recipient: caseDoc.reportedBy,
        case: caseDoc._id,
        title: 'Your report has been reviewed.',
        message: `Unfortunately, it was not approved.\nReason: ${reason || note || 'Case requirements not met'}`,
        type: 'case_rejected',
        actionRoute: null,
        actionText: null,
      });
    }
  }

  await AuditLog.create({
    action: 'case.status_changed',
    performedBy: updatedBy._id,
    targetResource: 'Case',
    targetId: caseDoc._id,
    metadata: { previousStatus, newStatus: status, reason: reason || null },
  });

  const populated = await Case.findById(caseDoc._id)
    .populate('reportedBy', 'alias email role profile')
    .populate('assignedOfficer', 'profile.fullName email')
    .populate('assignedOrganization', 'name type contact')
    .populate('evidence');

  return populated || caseDoc;
};

/**
 * Get cases reported by a specific user (for self-tracking)
 */
const getCasesByReporter = async (userId, { page = 1, limit = 20 } = {}) => {
  const query = { reportedBy: userId, isDeleted: false };
  const skip = (page - 1) * limit;
  const [cases, total] = await Promise.all([
    Case.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .select('-internalNotes')
      .populate('assignedOfficer', 'profile.fullName profile.phone profile.district email')
      .populate('assignedLawyer', 'profile.fullName profile.phone profile.courtNumber profile.district profile.province email')
      .populate('evidence'),
    Case.countDocuments(query),
  ]);
  return { cases, pagination: { page, limit, total, pages: Math.ceil(total / limit) } };
};

module.exports = { createCase, getCases, getCaseById, updateCaseStatus, getCasesByReporter };
