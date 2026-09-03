const Case = require('../models/Case.model');
const AuditLog = require('../models/AuditLog.model');

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
const getCases = async ({ page = 1, limit = 20, status, category, priority, search } = {}) => {
  const query = { isDeleted: false };

  if (status) query.status = status;
  if (category) query.category = category;
  if (priority) query.priority = priority;
  if (search) query.$text = { $search: search };

  const skip = (page - 1) * limit;
  const [cases, total] = await Promise.all([
    Case.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .populate('assignedOfficer', 'profile.fullName email')
      .populate('assignedOrganization', 'name type'),
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
    .populate('reportedBy', 'alias email role')
    .populate('assignedOfficer', 'profile.fullName email')
    .populate('assignedOrganization', 'name type contact')
    .populate('evidence');
};

/**
 * Update case status with timeline event
 */
const updateCaseStatus = async (id, { status, note }, updatedBy) => {
  const caseDoc = await Case.findOne({ _id: id, isDeleted: false });
  if (!caseDoc) {
    const err = new Error('Case not found');
    err.statusCode = 404;
    throw err;
  }

  caseDoc.status = status;
  caseDoc.timeline.push({ status, note, updatedBy: updatedBy._id });
  await caseDoc.save();

  await AuditLog.create({
    action: 'case.status_changed',
    performedBy: updatedBy._id,
    targetResource: 'Case',
    targetId: caseDoc._id,
    metadata: { previousStatus: caseDoc.status, newStatus: status },
  });

  return caseDoc;
};

/**
 * Get cases reported by a specific user (for self-tracking)
 */
const getCasesByReporter = async (userId, { page = 1, limit = 20 } = {}) => {
  const query = { reportedBy: userId, isDeleted: false };
  const skip = (page - 1) * limit;
  const [cases, total] = await Promise.all([
    Case.find(query).sort({ createdAt: -1 }).skip(skip).limit(limit).select('-internalNotes'),
    Case.countDocuments(query),
  ]);
  return { cases, pagination: { page, limit, total, pages: Math.ceil(total / limit) } };
};

module.exports = { createCase, getCases, getCaseById, updateCaseStatus, getCasesByReporter };
