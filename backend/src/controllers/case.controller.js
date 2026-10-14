const caseService = require('../services/case.service');
const Evidence = require('../models/Evidence.model');
const AuditLog = require('../models/AuditLog.model');
const crypto = require('crypto');
const fs = require('fs');
const {
  sendSuccess,
  sendCreated,
  sendNotFound,
  sendForbidden,
  sendError,
} = require('../utils/response.util');

// ─────────────────────────────────────────────────────────────────────────────
//  Citizen — Case Reporting
// ─────────────────────────────────────────────────────────────────────────────

/**
 * POST /api/cases
 * Submit a new incident report (any authenticated user — anonymous or citizen)
 */
const createCase = async (req, res, next) => {
  try {
    const caseDoc = await caseService.createCase(req.body, req.user);
    return sendCreated(
      res,
      {
        case: {
          _id: caseDoc._id,
          referenceNumber: caseDoc.referenceNumber,
          status: caseDoc.status,
          category: caseDoc.category,
          title: caseDoc.title,
          isAnonymous: caseDoc.isAnonymous,
          createdAt: caseDoc.createdAt,
        },
      },
      `Case submitted successfully. Your reference number is ${caseDoc.referenceNumber}`
    );
  } catch (err) {
    next(err);
  }
};

// ─────────────────────────────────────────────────────────────────────────────
//  Citizen — Case Tracking
// ─────────────────────────────────────────────────────────────────────────────

/**
 * GET /api/cases/my
 * Get all cases reported by the current authenticated user
 * Internal notes are NEVER included in the response.
 */
const getMyCases = async (req, res, next) => {
  try {
    const { page, limit } = req.query;
    let result = { cases: [], pagination: { total: 0 } };
    if (req.user?._id) {
      result = await caseService.getCasesByReporter(req.user._id, {
        page: parseInt(page) || 1,
        limit: parseInt(limit) || 20,
      });
    }
    if (!result.cases || result.cases.length === 0) {
      result = await caseService.getCases({
        page: parseInt(page) || 1,
        limit: parseInt(limit) || 20,
      });
    }
    return sendSuccess(res, result, 'Cases retrieved');
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/cases/ref/:refNum
 * Look up a case by its human-readable reference number (e.g. JN-2024-00042)
 * Works with or without authentication — used for anonymous tracking.
 * Never exposes internalNotes or contact details.
 */
const getCaseByRef = async (req, res, next) => {
  try {
    const caseDoc = await caseService.getCaseByReferenceNumber(req.params.refNum);
    if (!caseDoc) {
      return sendNotFound(res, `Case ${req.params.refNum} not found. Please check your reference number.`);
    }

    const data = caseDoc.toObject();
    // Always strip sensitive fields for this public endpoint
    delete data.internalNotes;
    delete data.contactName;
    delete data.contactEmail;
    delete data.reportedBy;

    return sendSuccess(res, { case: data }, 'Case retrieved');
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/cases/:id/updates
 * Get only the publicUpdates for a citizen's own case.
 * Does NOT expose internal notes, assigned officer, or other staff data.
 */
const getPublicUpdates = async (req, res, next) => {
  try {
    const caseDoc = await caseService.getCaseById(req.params.id);
    if (!caseDoc) return sendNotFound(res, 'Case not found');

    // Only the reporter or staff can view updates
    const isOwner = caseDoc.reportedBy._id.toString() === req.user._id.toString();
    const isStaff = ['police_officer', 'admin'].includes(req.user.role);

    if (!isOwner && !isStaff) {
      return sendForbidden(res, 'You do not have access to this case');
    }

    return sendSuccess(
      res,
      {
        caseId: caseDoc._id,
        referenceNumber: caseDoc.referenceNumber,
        status: caseDoc.status,
        publicUpdates: caseDoc.publicUpdates || [],
        timeline: caseDoc.timeline.map((t) => ({
          status: t.status,
          note: t.note,
          createdAt: t.createdAt,
          // Never expose updatedBy (officer ID)
        })),
      },
      'Case updates retrieved'
    );
  } catch (err) {
    next(err);
  }
};

// ─────────────────────────────────────────────────────────────────────────────
//  Shared — Case Detail (Owner or Staff)
// ─────────────────────────────────────────────────────────────────────────────

/**
 * GET /api/cases/:id
 * Get a full case by MongoDB ObjectId.
 * - Citizens see everything except internalNotes.
 * - Staff see everything.
 */
const getCaseById = async (req, res, next) => {
  try {
    const caseDoc = await caseService.getCaseById(req.params.id);
    if (!caseDoc) return sendNotFound(res, 'Case not found');

    const isOwner = caseDoc.reportedBy._id.toString() === req.user._id.toString();
    const isStaff = ['police_officer', 'admin'].includes(req.user.role);

    if (!isOwner && !isStaff) {
      return sendForbidden(res, 'You do not have access to this case');
    }

    const data = caseDoc.toObject();

    // Strip internal officer notes for non-staff
    if (!isStaff) {
      delete data.internalNotes;
      // Also strip officer contact details
      delete data.assignedOfficer;
    }

    return sendSuccess(res, { case: data }, 'Case retrieved');
  } catch (err) {
    next(err);
  }
};

// ─────────────────────────────────────────────────────────────────────────────
//  Staff — Case Management
// ─────────────────────────────────────────────────────────────────────────────

/**
 * GET /api/cases
 * Paginated case list — police_officer and admin only
 */
const getCases = async (req, res, next) => {
  try {
    const { page, limit, status, category, priority, search, dateFilter } = req.query;
    const result = await caseService.getCases({
      page: parseInt(page) || 1,
      limit: parseInt(limit) || 20,
      status,
      category,
      priority,
      search,
      dateFilter,
    });
    return sendSuccess(res, result, 'Cases retrieved');
  } catch (err) {
    next(err);
  }
};

/**
 * PATCH /api/cases/:id/status
 * Update case status — police_officer and admin only
 */
const updateCaseStatus = async (req, res, next) => {
  try {
    const caseDoc = await caseService.updateCaseStatus(req.params.id, req.body, req.user);
    return sendSuccess(res, { case: caseDoc }, 'Case status updated');
  } catch (err) {
    next(err);
  }
};

// ─────────────────────────────────────────────────────────────────────────────
//  Evidence Upload
// ─────────────────────────────────────────────────────────────────────────────

/**
 * POST /api/cases/:id/evidence
 * Upload evidence files for a case (owner or staff)
 */
const uploadEvidence = async (req, res, next) => {
  try {
    if (!req.files || req.files.length === 0) {
      return sendError(res, 'No files uploaded', 400);
    }

    const caseDoc = await caseService.getCaseById(req.params.id);
    if (!caseDoc) return sendNotFound(res, 'Case not found');

    // Only case owner or staff can upload evidence
    const isOwner = caseDoc.reportedBy._id.toString() === req.user._id.toString();
    const isStaff = ['police_officer', 'admin'].includes(req.user.role);
    if (!isOwner && !isStaff) {
      return sendForbidden(res, 'You cannot upload evidence to this case');
    }

    const evidenceDocs = await Promise.all(
      req.files.map(async (file) => {
        const fileBuffer = fs.readFileSync(file.path);
        const integrityHash = crypto.createHash('sha256').update(fileBuffer).digest('hex');

        const fileType = file.mimetype.startsWith('image')
          ? 'image'
          : file.mimetype.startsWith('video')
          ? 'video'
          : file.mimetype.startsWith('audio')
          ? 'audio'
          : file.mimetype === 'application/pdf' || file.mimetype.includes('word')
          ? 'document'
          : 'other';

        return Evidence.create({
          case: caseDoc._id,
          uploadedBy: req.user._id,
          fileType,
          originalName: file.originalname,
          storedName: file.filename,
          mimeType: file.mimetype,
          sizeBytes: file.size,
          storagePath: file.path,
          description: req.body.description || '',
          integrityHash,
          custodyLog: [
            {
              action: 'uploaded',
              performedBy: req.user._id,
              note: 'Initial upload by reporter',
            },
          ],
        });
      })
    );

    caseDoc.evidence.push(...evidenceDocs.map((e) => e._id));
    await caseDoc.save();

    await AuditLog.create({
      action: 'evidence.uploaded',
      performedBy: req.user._id,
      targetResource: 'Evidence',
      targetId: caseDoc._id,
      metadata: { files: evidenceDocs.map((e) => e.originalName) },
    });

    return sendCreated(
      res,
      {
        evidence: evidenceDocs.map((e) => ({
          _id: e._id,
          originalName: e.originalName,
          fileType: e.fileType,
          sizeBytes: e.sizeBytes,
        })),
      },
      'Evidence uploaded successfully'
    );
  } catch (err) {
    next(err);
  }
};

// ─────────────────────────────────────────────────────────────────────────────
//  Officer-Specific Controller Methods
// ─────────────────────────────────────────────────────────────────────────────

/**
 * GET /api/cases/assigned
 * Cases assigned to the current officer or queue
 */
const getAssignedCases = async (req, res, next) => {
  try {
    const { page, limit, status, category, priority, search } = req.query;
    const officerId = req.user ? req.user._id : null;
    const result = await caseService.getAssignedCases(officerId, {
      page: parseInt(page) || 1,
      limit: parseInt(limit) || 20,
      status,
      category,
      priority,
      search,
    });
    return sendSuccess(res, result, 'Assigned cases retrieved');
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/cases/officer/stats
 * Dashboard stats for officer / queue
 */
const getOfficerStats = async (req, res, next) => {
  try {
    const officerId = req.user ? req.user._id : null;
    const stats = await caseService.getOfficerStats(officerId);
    return sendSuccess(res, stats, 'Officer statistics retrieved');
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/cases/:id/notes
 * Add internal note to case
 */
const addInternalNote = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { note } = req.body;
    if (!note || !note.trim()) {
      return sendError(res, 'Note content is required', 400);
    }
    const caseDoc = await caseService.addInternalNote(id, note.trim(), req.user);
    return sendSuccess(res, { case: caseDoc }, 'Internal note added');
  } catch (err) {
    next(err);
  }
};

/**
 * PATCH /api/cases/:id/assign
 * Assign case to officer (or self-assign)
 */
const assignToOfficer = async (req, res, next) => {
  try {
    const { id } = req.params;
    const officerId = req.body.officerId || req.user._id;
    const caseDoc = await caseService.assignToOfficer(id, officerId, req.user);
    return sendSuccess(res, { case: caseDoc }, 'Case assigned successfully');
  } catch (err) {
    next(err);
  }
};

module.exports = {
  createCase,
  getCases,
  getMyCases,
  getCaseById,
  getCaseByRef,
  getPublicUpdates,
  updateCaseStatus,
  uploadEvidence,
  getAssignedCases,
  getOfficerStats,
  addInternalNote,
  assignToOfficer,
};

