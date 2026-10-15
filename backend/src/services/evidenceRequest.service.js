const EvidenceRequest = require('../models/EvidenceRequest.model');
const Case = require('../models/Case.model');
const AuditLog = require('../models/AuditLog.model');

/**
 * Create a new evidence request for a case
 */
const createEvidenceRequest = async (caseId, data, officer) => {
  const caseDoc = await Case.findOne({ _id: caseId, isDeleted: false });
  if (!caseDoc) {
    const err = new Error('Case not found');
    err.statusCode = 404;
    throw err;
  }

  const evidenceRequest = await EvidenceRequest.create({
    case: caseDoc._id,
    requestedBy: officer._id,
    description: data.description,
    reason: data.reason || '',
    instructions: data.instructions || '',
    dueDate: data.dueDate || null,
    status: 'pending',
  });

  // Automatically update case status to evidence_requested and add timeline + publicUpdate
  caseDoc.status = 'evidence_requested';
  caseDoc.timeline.push({
    status: 'evidence_requested',
    note: data.reason || 'Additional evidence requested by case officer',
    updatedBy: officer._id,
  });

  caseDoc.publicUpdates.push({
    message: data.description || 'Additional evidence has been requested. Please review and upload supporting files.',
    createdAt: new Date(),
  });

  if (data.internalNote) {
    caseDoc.internalNotes.push({
      note: data.internalNote,
      addedBy: officer._id,
      addedAt: new Date(),
    });
  }

  await caseDoc.save();

  await AuditLog.create({
    action: 'evidence_request.created',
    performedBy: officer._id,
    targetResource: 'Case',
    targetId: caseDoc._id,
    metadata: { evidenceRequestId: evidenceRequest._id, description: data.description },
  });

  return evidenceRequest;
};

/**
 * Get all evidence requests for a specific case
 */
const getRequestsByCase = async (caseId) => {
  return EvidenceRequest.find({ case: caseId, isDeleted: false })
    .populate('requestedBy', 'alias email role')
    .populate('responseEvidence', 'originalName fileType sizeBytes storagePath createdAt')
    .sort({ createdAt: -1 });
};

/**
 * Get all evidence requests requested by an officer (or all pending)
 */
const getOfficerRequests = async (officerId, { status, page = 1, limit = 20 } = {}) => {
  const query = { isDeleted: false };
  if (officerId) {
    query.requestedBy = officerId;
  }
  if (status) {
    query.status = status;
  }

  const skip = (page - 1) * limit;
  const [requests, total] = await Promise.all([
    EvidenceRequest.find(query)
      .populate('case', 'referenceNumber title category status priority')
      .populate('requestedBy', 'alias email')
      .populate('responseEvidence', 'originalName fileType sizeBytes storagePath')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit),
    EvidenceRequest.countDocuments(query),
  ]);

  return {
    requests,
    pagination: { page, limit, total, pages: Math.ceil(total / limit) },
  };
};

/**
 * Update the status of an evidence request (e.g. fulfill, under_review)
 */
const updateRequestStatus = async (requestId, { status, reviewNotes }, officer) => {
  const request = await EvidenceRequest.findOne({ _id: requestId, isDeleted: false });
  if (!request) {
    const err = new Error('Evidence request not found');
    err.statusCode = 404;
    throw err;
  }

  request.status = status;
  if (reviewNotes !== undefined) request.reviewNotes = reviewNotes;
  request.reviewedAt = new Date();
  await request.save();

  await AuditLog.create({
    action: 'evidence_request.status_updated',
    performedBy: officer._id,
    targetResource: 'Evidence',
    targetId: request._id,
    metadata: { status, reviewNotes },
  });

  return request;
};

module.exports = {
  createEvidenceRequest,
  getRequestsByCase,
  getOfficerRequests,
  updateRequestStatus,
};
