const mongoose = require('mongoose');
const Case = require('../models/Case.model');
const AuditLog = require('../models/AuditLog.model');

// ─────────────────────────────────────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Generate a unique human-readable reference number
 * Format: JN-YYYY-XXXXX  e.g. JN-2026-00042
 */
const generateReferenceNumber = async () => {
  const year = new Date().getFullYear();
  const count = await Case.countDocuments();
  const padded = String(count + 1).padStart(5, '0');
  return `JN-${year}-${padded}`;
};

// Citizen-safe projection — strips internal officer notes
const CITIZEN_PROJECTION = '-internalNotes';

// ─────────────────────────────────────────────────────────────────────────────
//  Create
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Create a new case report
 * @param {Object} data   - Request body (title, description, category, etc.)
 * @param {Object} user   - Authenticated user (req.user)
 */
const createCase = async (data, user) => {
  const referenceNumber = await generateReferenceNumber();
  const isAnonymous = user.role === 'anonymous';

  const newCase = await Case.create({
    title: data.title,
    description: data.description,
    category: data.category,
    incidentDate: data.incidentDate,
    location: data.location || {},
    referenceNumber,
    reportedBy: user._id,
    isAnonymous,
    // Only persist contact details for non-anonymous reporters
    contactName: !isAnonymous ? (data.contactName || null) : null,
    contactEmail: !isAnonymous ? (data.contactEmail || null) : null,
    timeline: [
      {
        status: 'submitted',
        note: 'Case submitted by reporter',
        updatedBy: user._id,
      },
    ],
  });

  await AuditLog.create({
    action: 'case.created',
    performedBy: user._id,
    targetResource: 'Case',
    targetId: newCase._id,
    metadata: { referenceNumber, category: data.category, isAnonymous },
  });

  return newCase;
};

// ─────────────────────────────────────────────────────────────────────────────
//  Read — Officer / Admin
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Get paginated list of ALL cases (officers/admins only)
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
    pagination: { page, limit, total, pages: Math.ceil(total / limit) },
  };
};

// ─────────────────────────────────────────────────────────────────────────────
//  Read — Citizen
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Get cases reported by a specific user (citizen self-tracking)
 * Internal notes are NEVER sent to the citizen.
 */
const getCasesByReporter = async (userId, { page = 1, limit = 20 } = {}) => {
  const query = { reportedBy: userId, isDeleted: false };
  const skip = (page - 1) * limit;
  const [cases, total] = await Promise.all([
    Case.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .select(CITIZEN_PROJECTION),
    Case.countDocuments(query),
  ]);
  return { cases, pagination: { page, limit, total, pages: Math.ceil(total / limit) } };
};

/**
 * Get a single case by MongoDB ObjectId
 */
const getCaseById = async (id) => {
  return Case.findOne({ _id: id, isDeleted: false })
    .populate('reportedBy', 'alias email role')
    .populate('assignedOfficer', 'profile.fullName email')
    .populate('assignedOrganization', 'name type contact')
    .populate('evidence');
};

/**
 * Get a single case by its human-readable reference number
 * e.g. JN-2024-0042 — used by citizens tracking from the mobile app.
 * Internal notes are stripped; only publicUpdates are returned.
 */
const getCaseByReferenceNumber = async (refNum) => {
  return Case.findOne({ referenceNumber: refNum.toUpperCase(), isDeleted: false })
    .select(CITIZEN_PROJECTION)
    .populate('evidence', 'originalName fileType sizeBytes createdAt');
};

// ─────────────────────────────────────────────────────────────────────────────
//  Update — Officer / Admin
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Update case status with a timeline entry (officer/admin only)
 */
const updateCaseStatus = async (id, { status, note }, updatedBy) => {
  const query = mongoose.Types.ObjectId.isValid(id)
    ? { _id: id, isDeleted: false }
    : { referenceNumber: id, isDeleted: false };
  const caseDoc = await Case.findOne(query);
  if (!caseDoc) {
    const err = new Error('Case not found');
    err.statusCode = 404;
    throw err;
  }

  const prevStatus = caseDoc.status;
  caseDoc.status = status;
  const updaterId = updatedBy?._id || null;
  caseDoc.timeline.push({ status, note: note || '', updatedBy: updaterId });
  await caseDoc.save();

  if (updaterId) {
    await AuditLog.create({
      action: 'case.status_changed',
      performedBy: updaterId,
      targetResource: 'Case',
      targetId: caseDoc._id,
      metadata: { previousStatus: prevStatus, newStatus: status, note },
    });
  }

  return caseDoc;
};

// ─────────────────────────────────────────────────────────────────────────────
//  Officer-Specific Methods
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Get cases assigned to a specific officer with filters
 */
const getAssignedCases = async (officerId, { page = 1, limit = 20, status, category, priority, search } = {}) => {
  const query = { isDeleted: false };
  if (officerId) {
    query.$or = [{ assignedOfficer: officerId }, { assignedOfficer: null }];
  }

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
      .populate('reportedBy', 'alias email role')
      .populate('evidence', 'originalName fileType sizeBytes createdAt'),
    Case.countDocuments(query),
  ]);

  return {
    cases,
    pagination: { page, limit, total, pages: Math.ceil(total / limit) },
  };
};

/**
 * Get dashboard statistics for an officer
 */
const getOfficerStats = async (officerId) => {
  const baseQuery = { isDeleted: false };
  if (officerId) {
    baseQuery.$or = [{ assignedOfficer: officerId }, { assignedOfficer: null }];
  }

  const [totalAssigned, byStatus, byPriority, recentlyUpdated, critical] = await Promise.all([
    Case.countDocuments(baseQuery),

    Case.aggregate([
      { $match: baseQuery },
      { $group: { _id: '$status', count: { $sum: 1 } } },
    ]),

    Case.aggregate([
      { $match: baseQuery },
      { $group: { _id: '$priority', count: { $sum: 1 } } },
    ]),

    Case.find(baseQuery)
      .sort({ updatedAt: -1 })
      .limit(5)
      .select('referenceNumber title status priority category updatedAt')
      .lean(),

    Case.countDocuments({ ...baseQuery, priority: 'critical' }),
  ]);

  // Compute convenience counts
  const statusMap = {};
  byStatus.forEach((s) => { statusMap[s._id] = s.count; });

  return {
    totalAssigned,
    awaitingReview: (statusMap['submitted'] || 0) + (statusMap['under_review'] || 0),
    activeInvestigations: (statusMap['investigating'] || 0) + (statusMap['legal_action_initiated'] || 0),
    evidenceRequested: statusMap['evidence_requested'] || 0,
    resolved: (statusMap['resolved'] || 0) + (statusMap['closed'] || 0),
    critical,
    byStatus,
    byPriority,
    recentlyUpdated,
  };
};

/**
 * Add an internal note to a case (officer/admin only)
 */
const addInternalNote = async (caseId, noteText, officer) => {
  const query = mongoose.Types.ObjectId.isValid(caseId)
    ? { _id: caseId, isDeleted: false }
    : { referenceNumber: caseId, isDeleted: false };
  const caseDoc = await Case.findOne(query);
  if (!caseDoc) {
    const err = new Error('Case not found');
    err.statusCode = 404;
    throw err;
  }

  const officerId = officer?._id || null;
  caseDoc.internalNotes.push({
    note: noteText,
    addedBy: officerId,
    addedAt: new Date(),
  });
  await caseDoc.save();

  if (officerId) {
    await AuditLog.create({
      action: 'case.note_added',
      performedBy: officerId,
      targetResource: 'Case',
      targetId: caseDoc._id,
      metadata: { notePreview: noteText.substring(0, 100) },
    });
  }

  return caseDoc;
};

/**
 * Assign case to an officer (or self-assign)
 */
const assignToOfficer = async (caseId, officerId, assignedBy) => {
  const caseDoc = await Case.findOne({ _id: caseId, isDeleted: false });
  if (!caseDoc) {
    const err = new Error('Case not found');
    err.statusCode = 404;
    throw err;
  }

  caseDoc.assignedOfficer = officerId;

  // If the case is still 'submitted', move to 'under_review'
  if (caseDoc.status === 'submitted') {
    caseDoc.status = 'under_review';
    caseDoc.timeline.push({
      status: 'under_review',
      note: 'Case assigned to officer for review',
      updatedBy: assignedBy._id,
    });
  }

  await caseDoc.save();

  await AuditLog.create({
    action: 'case.assigned',
    performedBy: assignedBy._id,
    targetResource: 'Case',
    targetId: caseDoc._id,
    metadata: { assignedOfficer: officerId },
  });

  return caseDoc;
};

module.exports = {
  createCase,
  getCases,
  getCaseById,
  getCaseByReferenceNumber,
  getCasesByReporter,
  updateCaseStatus,
  getAssignedCases,
  getOfficerStats,
  addInternalNote,
  assignToOfficer,
};

