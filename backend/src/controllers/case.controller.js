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
} = require('../utils/response.util');

/**
 * POST /api/cases
 * Submit a new case report
 */
const createCase = async (req, res, next) => {
  try {
    const caseDoc = await caseService.createCase(req.body, req.user);
    return sendCreated(res, { case: caseDoc }, 'Case submitted successfully');
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/cases
 * Get paginated case list (officers/admins only)
 */
const getCases = async (req, res, next) => {
  try {
    const { page, limit, status, category, priority, search } = req.query;
    const result = await caseService.getCases({
      page: parseInt(page) || 1,
      limit: parseInt(limit) || 20,
      status,
      category,
      priority,
      search,
    });
    return sendSuccess(res, result, 'Cases retrieved');
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/cases/my
 * Get cases reported by the current user
 */
const getMyCases = async (req, res, next) => {
  try {
    const { page, limit } = req.query;
    const result = await caseService.getCasesByReporter(req.user._id, {
      page: parseInt(page) || 1,
      limit: parseInt(limit) || 20,
    });
    return sendSuccess(res, result, 'Your cases retrieved');
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/cases/:id
 * Get a single case by ID
 */
const getCaseById = async (req, res, next) => {
  try {
    const caseDoc = await caseService.getCaseById(req.params.id);
    if (!caseDoc) return sendNotFound(res, 'Case not found');

    // Anonymous reporters can only see their own cases (without internal notes)
    const isOwner = caseDoc.reportedBy._id.toString() === req.user._id.toString();
    const isStaff = ['officer', 'admin'].includes(req.user.role);

    if (!isOwner && !isStaff) {
      return sendForbidden(res, 'You do not have access to this case');
    }

    // Strip internal notes for non-staff
    const data = caseDoc.toObject();
    if (!isStaff) delete data.internalNotes;

    return sendSuccess(res, { case: data }, 'Case retrieved');
  } catch (err) {
    next(err);
  }
};

/**
 * PATCH /api/cases/:id/status
 * Update case status (officers/admins only)
 */
const updateCaseStatus = async (req, res, next) => {
  try {
    const caseDoc = await caseService.updateCaseStatus(req.params.id, req.body, req.user);
    return sendSuccess(res, { case: caseDoc }, 'Case status updated');
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/cases/:id/evidence
 * Upload evidence file(s) for a case
 */
const uploadEvidence = async (req, res, next) => {
  try {
    if (!req.files || req.files.length === 0) {
      return sendNotFound(res, 'No files uploaded');
    }

    const caseDoc = await caseService.getCaseById(req.params.id);
    if (!caseDoc) return sendNotFound(res, 'Case not found');

    const evidenceDocs = await Promise.all(
      req.files.map(async (file) => {
        // Compute SHA-256 hash for integrity
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
              note: 'Initial upload',
            },
          ],
        });
      })
    );

    // Link evidence to case
    caseDoc.evidence.push(...evidenceDocs.map((e) => e._id));
    await caseDoc.save();

    await AuditLog.create({
      action: 'evidence.uploaded',
      performedBy: req.user._id,
      targetResource: 'Evidence',
      targetId: caseDoc._id,
      metadata: { files: evidenceDocs.map((e) => e.originalName) },
    });

    return sendCreated(res, { evidence: evidenceDocs }, 'Evidence uploaded successfully');
  } catch (err) {
    next(err);
  }
};

module.exports = { createCase, getCases, getMyCases, getCaseById, updateCaseStatus, uploadEvidence };
