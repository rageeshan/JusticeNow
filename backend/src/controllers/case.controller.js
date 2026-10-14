const caseService = require('../services/case.service');
const Case = require('../models/Case.model');
const User = require('../models/User.model');
const Notification = require('../models/Notification.model');
const Evidence = require('../models/Evidence.model');
const AuditLog = require('../models/AuditLog.model');
const mongoose = require('mongoose');
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
      if (data.assignedOfficer && typeof data.assignedOfficer === 'object') {
        data.assignedOfficer = {
          _id: data.assignedOfficer._id,
          name: data.assignedOfficer.profile?.fullName || data.assignedOfficer.email || 'Assigned Officer',
          phone: data.assignedOfficer.profile?.phone || '',
          email: data.assignedOfficer.email || '',
          district: data.assignedOfficer.profile?.district || '',
        };
      }
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

/**
 * GET /api/cases/officer/cases
 * Get cases assigned to this police officer by tab (pending, in_progress, completed)
 */
const getOfficerCases = async (req, res, next) => {
  try {
    const { tab = 'pending', search } = req.query;
    const officerId = req.user._id;

    let statusQuery;
    if (tab === 'in_progress') {
      statusQuery = {
        $in: [
          'in_progress',
          'in_progress_police',
          'investigating',
          'suspect_identified',
          'referred_to_court',
        ],
      };
    } else if (tab === 'completed') {
      statusQuery = { $in: ['completed', 'resolved', 'closed'] };
    } else {
      // Pending tab: assigned by admin, waiting for officer to accept
      statusQuery = {
        $in: ['assigned_to_police', 'submitted', 'under_review'],
      };
    }

    const query = {
      assignedOfficer: officerId,
      status: statusQuery,
      isDeleted: false,
    };

    if (search && search.trim().length > 0) {
      const regex = new RegExp(search.trim(), 'i');
      query.$or = [{ title: regex }, { description: regex }, { referenceNumber: regex }];
    }

    const cases = await Case.find(query)
      .sort({ assignedToPoliceAt: -1, updatedAt: -1, createdAt: -1 })
      .populate('reportedBy', 'profile email role alias')
      .populate('evidence')
      .lean();

    return sendSuccess(res, { cases }, 'Officer cases retrieved');
  } catch (err) {
    next(err);
  }
};

/**
 * PATCH /api/cases/officer/cases/:id/accept
 * Officer accepts assigned case and selects investigation start date & time
 */
const acceptOfficerCase = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { startDate, startTime } = req.body;

    if (!startDate || !startTime) {
      return sendError(res, 'Investigation start date and time are required to accept the case', 400);
    }

    const caseDoc = await Case.findOne({ _id: id, isDeleted: false });
    if (!caseDoc) {
      return sendNotFound(res, 'Case not found');
    }

    if (caseDoc.assignedOfficer?.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return sendForbidden(res, 'You are not assigned to this case');
    }

    // Prevent double-booking for the officer on the exact date and time slot
    const parsedDate = new Date(startDate);
    const dayStart = new Date(parsedDate);
    dayStart.setHours(0, 0, 0, 0);
    const dayEnd = new Date(parsedDate);
    dayEnd.setHours(23, 59, 59, 999);

    const conflictingCase = await Case.findOne({
      assignedOfficer: req.user._id,
      _id: { $ne: id },
      status: { $in: ['in_progress_police', 'investigating', 'suspect_identified', 'referred_to_court'] },
      investigationStartDate: { $gte: dayStart, $lte: dayEnd },
      investigationStartTime: startTime,
      isDeleted: false,
    });

    if (conflictingCase) {
      return sendError(
        res,
        `You already have an active investigation scheduled for ${startDate} at ${startTime}. Please choose an open slot to prevent double-booking.`,
        400
      );
    }

    const previousStatus = caseDoc.status;
    caseDoc.status = 'in_progress_police';
    caseDoc.investigationStartDate = new Date(startDate);
    caseDoc.investigationStartTime = startTime;
    if (req.body.notes && req.body.notes.trim()) {
      caseDoc.policeAcceptNotes = req.body.notes.trim();
    }
    const scheduleNote = `Officer accepted case. Investigation scheduled: ${startDate} at ${startTime}${req.body.notes ? '. Notes: ' + req.body.notes.trim() : ''}`;
    caseDoc.timeline.push({
      status: 'in_progress_police',
      note: scheduleNote,
      updatedBy: req.user._id,
    });

    await caseDoc.save();

    // Send notification to the citizen
    if (caseDoc.reportedBy) {
      const officerName = req.user.profile?.fullName || req.user.alias || 'Police Officer';
      const officerDistrict = req.user.profile?.district || 'Assigned District';
      const officerContact = req.user.profile?.phone || req.user.email || '';

      try {
        await Notification.create({
          recipient: caseDoc.reportedBy,
          case: caseDoc._id,
          title: 'Police officer assigned to your case',
          message: `Officer: ${officerName}\nDistrict: ${officerDistrict}\nStart Date: ${startDate} Time: ${startTime}\nYou may be contacted soon.${officerContact ? '\nContact: ' + officerContact : ''}`,
          type: 'case_assigned_police',
          actionRoute: '/my-cases',
          actionText: 'View in History',
        });
      } catch (notifErr) {
        console.error('Failed to create officer acceptance notification:', notifErr);
      }
    }

    await AuditLog.create({
      action: 'case.officer_accepted',
      performedBy: req.user._id,
      targetResource: 'Case',
      targetId: caseDoc._id,
      metadata: { previousStatus, newStatus: caseDoc.status, startDate, startTime },
    });

    const updatedCase = await Case.findById(caseDoc._id)
      .populate('reportedBy', 'profile email role alias')
      .populate('evidence');

    return sendSuccess(res, { case: updatedCase }, 'Case accepted successfully');
  } catch (err) {
    next(err);
  }
};

/**
 * PATCH /api/cases/officer/cases/:id/reject
 * Officer declines assigned case with required reason, returning to admin pool
 */
const rejectOfficerCase = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { reason, reasonType } = req.body;

    const fullReason = (reasonType && reasonType !== 'Other' && !reason?.includes(reasonType))
      ? `${reasonType}: ${reason || ''}`.trim()
      : (reason || reasonType || '').trim();

    if (!fullReason) {
      return sendError(res, 'Decline reason is required', 400);
    }

    const caseDoc = await Case.findOne({ _id: id, isDeleted: false })
      .populate('reportedBy', 'profile alias email');

    if (!caseDoc) {
      return sendNotFound(res, 'Case not found');
    }

    if (caseDoc.assignedOfficer?.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return sendForbidden(res, 'You are not assigned to this case');
    }

    const officerName = req.user.profile?.fullName || req.user.alias || req.user.email || 'Officer';
    const previousStatus = caseDoc.status;
    caseDoc.status = 'pending_reassignment';
    caseDoc.policeDeclineReason = fullReason;
    // Return to admin pool for reassignment
    caseDoc.assignedOfficer = null;
    caseDoc.timeline.push({
      status: 'pending_reassignment',
      note: `Officer ${officerName} declined case. Reason: ${fullReason}`,
      updatedBy: req.user._id,
    });

    await caseDoc.save();

    try {
      // 1. Send notification to Admin users:
      const admins = await User.find({ role: 'admin' });
      for (const admin of admins) {
        await Notification.create({
          recipient: admin._id,
          case: caseDoc._id,
          title: `Officer ${officerName} declined case`,
          message: `Officer ${officerName} declined case "${caseDoc.title}". Reason: ${fullReason}`,
          type: 'officer_declined',
          actionRoute: `/admin/cases/${caseDoc._id}`,
          actionText: 'Reassign Case',
        });
      }

      // 2. Send notification to Citizen:
      if (caseDoc.reportedBy?._id || caseDoc.reportedBy) {
        const citizenId = caseDoc.reportedBy._id || caseDoc.reportedBy;
        await Notification.create({
          recipient: citizenId,
          case: caseDoc._id,
          title: 'Update on your case',
          message: `Officer ${officerName} could not proceed.\nReason: ${fullReason}\nYour case will be reassigned.`,
          type: 'case_declined_reassign',
          actionRoute: '/my-cases',
          actionText: 'View in History',
        });
      }
    } catch (notifErr) {
      console.error('Failed to create decline notifications:', notifErr);
    }

    await AuditLog.create({
      action: 'case.officer_declined',
      performedBy: req.user._id,
      targetResource: 'Case',
      targetId: caseDoc._id,
      metadata: { previousStatus, reason: fullReason },
    });

    return sendSuccess(res, { case: caseDoc }, 'Case declined and returned to admin for reassignment');
  } catch (err) {
    next(err);
  }
};

/**
 * PATCH /api/cases/officer/cases/:id/stage
 * Officer updates stage (investigating, suspect_identified, referred_to_court, closed)
 */
const updateOfficerCaseStage = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { stage, note } = req.body;

    const validStages = ['investigating', 'suspect_identified', 'referred_to_court', 'closed', 'completed'];
    if (!validStages.includes(stage)) {
      return sendError(res, `Invalid stage. Must be one of: ${validStages.join(', ')}`, 400);
    }

    const caseDoc = await Case.findOne({ _id: id, isDeleted: false });
    if (!caseDoc) {
      return sendNotFound(res, 'Case not found');
    }

    const previousStatus = caseDoc.status;
    caseDoc.status = stage;
    if (stage === 'completed' || stage === 'closed') {
      caseDoc.completedAt = new Date();
    }

    const stageNote = note || `Investigation stage updated to: ${stage.replace(/_/g, ' ')}`;
    caseDoc.timeline.push({
      status: stage,
      note: stageNote,
      updatedBy: req.user._id,
    });

    await caseDoc.save();

    if (caseDoc.reportedBy) {
      await Notification.create({
        recipient: caseDoc.reportedBy,
        case: caseDoc._id,
        title: 'Case Investigation Update',
        message: `Your case "${caseDoc.title}" status has been updated: ${stage.replace(/_/g, ' ').toUpperCase()}`,
        type: 'general',
        actionRoute: '/my-cases',
        actionText: 'View Case History',
      });
    }

    return sendSuccess(res, { case: caseDoc }, 'Case stage updated');
  } catch (err) {
    next(err);
  }
};

/**
 * PATCH /api/cases/officer/cases/:id/complete
 * Mark case as completed by officer
 */
const completeOfficerCase = async (req, res, next) => {
  try {
    const { id } = req.params;
    const caseDoc = await Case.findOne({ _id: id, isDeleted: false });
    if (!caseDoc) {
      return sendNotFound(res, 'Case not found');
    }

    caseDoc.status = 'completed';
    caseDoc.completedAt = new Date();
    caseDoc.timeline.push({
      status: 'completed',
      note: 'Case marked as completed by officer',
      updatedBy: req.user._id,
    });
    await caseDoc.save();

    if (caseDoc.reportedBy) {
      await Notification.create({
        recipient: caseDoc.reportedBy,
        case: caseDoc._id,
        title: 'Case Completed',
        message: `Your case "${caseDoc.title}" has been completed by the investigating officer.`,
        type: 'general',
        actionRoute: '/my-cases',
        actionText: 'View Case History',
      });
    }

    return sendSuccess(res, { case: caseDoc }, 'Case marked as completed');
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/cases/officer/availability
 * Get officer's saved weekly availability duty slots
 */
const getOfficerAvailability = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id).select('profile.availability');
    const defaultAvailability = {
      Monday: { isUnavailable: false, slots: [{ startTime: '08:00 AM', endTime: '12:00 PM' }, { startTime: '01:00 PM', endTime: '05:00 PM' }] },
      Tuesday: { isUnavailable: false, slots: [{ startTime: '08:00 AM', endTime: '12:00 PM' }, { startTime: '01:00 PM', endTime: '05:00 PM' }] },
      Wednesday: { isUnavailable: false, slots: [{ startTime: '08:00 AM', endTime: '12:00 PM' }, { startTime: '01:00 PM', endTime: '05:00 PM' }] },
      Thursday: { isUnavailable: false, slots: [{ startTime: '08:00 AM', endTime: '12:00 PM' }, { startTime: '01:00 PM', endTime: '05:00 PM' }] },
      Friday: { isUnavailable: false, slots: [{ startTime: '08:00 AM', endTime: '12:00 PM' }, { startTime: '01:00 PM', endTime: '05:00 PM' }] },
      Saturday: { isUnavailable: true, slots: [] },
      Sunday: { isUnavailable: true, slots: [] },
    };
    const availability = user?.profile?.availability || defaultAvailability;
    return sendSuccess(res, { availability }, 'Officer availability retrieved');
  } catch (err) {
    next(err);
  }
};

/**
 * PUT /api/cases/officer/availability
 * Update officer weekly availability
 */
const updateOfficerAvailability = async (req, res, next) => {
  try {
    const { availability } = req.body;
    if (!availability || typeof availability !== 'object') {
      return sendError(res, 'Invalid availability format', 400);
    }
    const user = await User.findById(req.user._id);
    if (!user) return sendNotFound(res, 'User not found');
    if (!user.profile) user.profile = {};
    user.profile.availability = availability;
    await user.save();
    return sendSuccess(res, { availability: user.profile.availability }, 'Availability updated successfully');
  } catch (err) {
    next(err);
  }
};

/**
 * Helper to format availability schedule into a human-readable summary
 */
function formatAvailabilitySummary(avail) {
  if (!avail || typeof avail !== 'object') return 'Mon–Fri, 08:00 AM – 04:00 PM';
  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  const shortDays = { Monday: 'Mon', Tuesday: 'Tue', Wednesday: 'Wed', Thursday: 'Thu', Friday: 'Fri', Saturday: 'Sat', Sunday: 'Sun' };
  const availableDays = [];
  let commonSlot = null;

  for (const day of days) {
    const dayData = avail[day];
    if (dayData && !dayData.isUnavailable && Array.isArray(dayData.slots) && dayData.slots.length > 0) {
      availableDays.push(shortDays[day] || day);
      if (!commonSlot) {
        const s = dayData.slots[0];
        if (s && s.startTime && s.endTime) {
          commonSlot = `${s.startTime} – ${s.endTime}`;
        }
      }
    }
  }

  if (availableDays.length === 0) return 'Unavailable';
  if (availableDays.length === 5 && availableDays[0] === 'Mon' && availableDays[4] === 'Fri') {
    return `Mon–Fri, ${commonSlot || '08:00 AM – 04:00 PM'}`;
  }
  if (availableDays.length === 7) {
    return `Mon–Sun, ${commonSlot || '08:00 AM – 04:00 PM'}`;
  }
  return `${availableDays.join(', ')}${commonSlot ? ', ' + commonSlot : ''}`;
}

/**
 * Helper to calculate age from Date of Birth
 */
function calculateAge(dob) {
  if (!dob) return null;
  const birthDate = new Date(dob);
  const diff = Date.now() - birthDate.getTime();
  const ageDate = new Date(diff);
  return Math.abs(ageDate.getUTCFullYear() - 1970);
}

/**
 * GET /api/cases/:id/officers-available
 * Admin endpoint: List approved police officers auto-filtered by case location (Province & District)
 * Supports sorting: fewest_cases (default), name, age, most_available
 */
const getAvailableOfficersForCase = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { sortBy = 'fewest_cases', province: overrideProvince, district: overrideDistrict } = req.query;

    const caseDoc = await Case.findOne({
      $or: [
        ...(mongoose.isValidObjectId(id) ? [{ _id: id }] : []),
        { referenceNumber: id },
      ],
      isDeleted: false,
    }).populate('reportedBy', 'profile alias email');

    if (!caseDoc) {
      return sendNotFound(res, 'Case not found');
    }

    const citizenProfile = caseDoc.reportedBy?.profile || {};
    const targetProvince = overrideProvince || citizenProfile.province || caseDoc.location?.state || null;
    const targetDistrict = overrideDistrict || citizenProfile.district || caseDoc.location?.city || null;

    const officers = await User.find({
      role: 'police_officer',
      approvalStatus: 'approved',
    }).select('profile email alias role createdAt');

    const enrichedOfficers = await Promise.all(
      officers.map(async (officer) => {
        const p = officer.profile || {};
        const officerProvince = p.province || '';
        const officerDistrict = p.district || '';

        const provinceMatch = targetProvince
          ? officerProvince.trim().toLowerCase() === targetProvince.trim().toLowerCase()
          : true;
        const districtMatch = targetDistrict
          ? officerDistrict.trim().toLowerCase() === targetDistrict.trim().toLowerCase()
          : true;
        const isExactMatch = provinceMatch && districtMatch;

        const pendingCasesCount = await Case.countDocuments({
          assignedOfficer: officer._id,
          status: { $in: ['assigned_to_police', 'in_progress_police', 'investigating', 'suspect_identified'] },
          isDeleted: false,
        });

        let age = p.age || null;
        if (!age && p.dob) {
          age = calculateAge(p.dob);
        }

        const availabilitySummary = formatAvailabilitySummary(p.availability);
        let openSlotsCount = 0;
        if (p.availability && typeof p.availability === 'object') {
          for (const k of Object.keys(p.availability)) {
            const dayObj = p.availability[k];
            if (dayObj && !dayObj.isUnavailable && Array.isArray(dayObj.slots)) {
              openSlotsCount += dayObj.slots.length;
            }
          }
        }

        return {
          _id: officer._id,
          name: p.fullName || officer.alias || officer.email?.split('@')[0] || 'Police Officer',
          email: officer.email,
          phone: p.phone || 'N/A',
          gender: p.gender || null,
          age: age || 34,
          aboutMe: p.aboutMe || 'Dedicated police officer committed to public service and community safety.',
          policeId: p.policeId || 'PO-OFFICER',
          province: officerProvince || 'Western',
          district: officerDistrict || 'Colombo',
          availability: availabilitySummary,
          availabilityRaw: p.availability,
          openSlotsCount,
          pendingCasesCount,
          isExactMatch,
        };
      })
    );

    let filtered = enrichedOfficers.filter((o) => o.isExactMatch);
    if (filtered.length === 0 && targetProvince) {
      filtered = enrichedOfficers.filter(
        (o) => o.province.trim().toLowerCase() === targetProvince.trim().toLowerCase()
      );
    }
    if (filtered.length === 0) {
      filtered = enrichedOfficers;
    }

    if (sortBy === 'fewest_cases') {
      filtered.sort((a, b) => a.pendingCasesCount - b.pendingCasesCount);
    } else if (sortBy === 'name') {
      filtered.sort((a, b) => a.name.localeCompare(b.name));
    } else if (sortBy === 'age') {
      filtered.sort((a, b) => (a.age || 0) - (b.age || 0));
    } else if (sortBy === 'most_available') {
      filtered.sort((a, b) => b.openSlotsCount - a.openSlotsCount);
    }

    return sendSuccess(
      res,
      {
        officers: filtered,
        targetProvince,
        targetDistrict,
        totalOfficers: filtered.length,
      },
      'Available police officers retrieved'
    );
  } catch (err) {
    next(err);
  }
};

/**
 * PATCH /api/cases/:id/assign-officer
 * Admin assigns a case to a specific approved police officer
 */
const assignOfficerToCase = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { officerId } = req.body;

    if (!officerId) {
      return sendError(res, 'Police officer ID is required', 400);
    }

    const caseDoc = await Case.findOne({
      $or: [
        ...(mongoose.isValidObjectId(id) ? [{ _id: id }] : []),
        { referenceNumber: id },
      ],
      isDeleted: false,
    }).populate('reportedBy', 'profile alias email');

    if (!caseDoc) {
      return sendNotFound(res, 'Case not found');
    }

    const officer = await User.findOne({
      _id: officerId,
      role: 'police_officer',
      approvalStatus: 'approved',
    });

    if (!officer) {
      return sendNotFound(res, 'Approved police officer not found');
    }

    const officerName = officer.profile?.fullName || officer.alias || officer.email || 'Officer';
    const citizenProfile = caseDoc.reportedBy?.profile || {};
    const citizenName = citizenProfile.fullName || caseDoc.reportedBy?.alias || 'Citizen';
    const citizenDistrict = citizenProfile.district || caseDoc.location?.city || 'District';

    caseDoc.assignedOfficer = officer._id;
    caseDoc.status = 'assigned_to_police';
    caseDoc.assignedToPoliceAt = new Date();
    caseDoc.timeline.push({
      status: 'assigned_to_police',
      note: `Assigned to police officer ${officerName} by Admin`,
      updatedBy: req.user._id,
    });

    await caseDoc.save();

    // 1. Notify Officer & 2. Notify Citizen
    try {
      await Notification.create({
        recipient: officer._id,
        case: caseDoc._id,
        title: `New case assigned to you: ${caseDoc.title}`,
        message: `From: ${citizenName} – ${citizenDistrict}`,
        type: 'case_assigned_officer',
        actionRoute: `/officer/cases/${caseDoc._id}`,
        actionText: 'View Case',
      });

      if (caseDoc.reportedBy?._id || caseDoc.reportedBy) {
        const citizenId = caseDoc.reportedBy._id || caseDoc.reportedBy;
        await Notification.create({
          recipient: citizenId,
          case: caseDoc._id,
          title: 'Your case is being reviewed by police',
          message: `Case "${caseDoc.title}" has been forwarded to the police department.`,
          type: 'case_forwarded_police',
          actionRoute: '/my-cases',
          actionText: 'View in History',
        });
      }
    } catch (notifErr) {
      console.error('Failed to create assignment notification:', notifErr);
    }

    await AuditLog.create({
      action: 'case.assigned_to_police',
      performedBy: req.user._id,
      targetResource: 'Case',
      targetId: caseDoc._id,
      metadata: { officerId: officer._id, officerName },
    });

    const updatedCase = await Case.findById(caseDoc._id)
      .populate('reportedBy', 'profile alias email')
      .populate('assignedOfficer', 'profile email')
      .populate('evidence');

    return sendSuccess(res, { case: updatedCase }, `Case successfully assigned to Officer ${officerName}`);
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
  assignToOfficer: assignOfficerToCase,
  assignOfficerToCase,
  getAvailableOfficersForCase,
  getOfficerCases,
  acceptOfficerCase,
  rejectOfficerCase,
  updateOfficerCaseStage,
  completeOfficerCase,
  getOfficerAvailability,
  updateOfficerAvailability,
};

