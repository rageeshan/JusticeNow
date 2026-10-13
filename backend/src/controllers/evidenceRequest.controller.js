const evidenceRequestService = require('../services/evidenceRequest.service');
const { sendSuccess, sendCreated, sendNotFound, sendError } = require('../utils/response.util');

const createRequest = async (req, res, next) => {
  try {
    const { id: caseId } = req.params;
    const request = await evidenceRequestService.createEvidenceRequest(caseId, req.body, req.user);
    return sendCreated(res, { evidenceRequest: request }, 'Evidence request sent to reporter');
  } catch (err) {
    next(err);
  }
};

const getRequestsByCase = async (req, res, next) => {
  try {
    const { id: caseId } = req.params;
    const requests = await evidenceRequestService.getRequestsByCase(caseId);
    return sendSuccess(res, { evidenceRequests: requests }, 'Evidence requests retrieved');
  } catch (err) {
    next(err);
  }
};

const getOfficerRequests = async (req, res, next) => {
  try {
    const { status, page, limit } = req.query;
    const officerId = req.user.role === 'admin' ? null : req.user._id;
    const result = await evidenceRequestService.getOfficerRequests(officerId, {
      status,
      page: parseInt(page) || 1,
      limit: parseInt(limit) || 20,
    });
    return sendSuccess(res, result, 'Evidence requests retrieved');
  } catch (err) {
    next(err);
  }
};

const updateRequestStatus = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status, reviewNotes } = req.body;
    if (!status) {
      return sendError(res, 'Status is required', 400);
    }
    const updated = await evidenceRequestService.updateRequestStatus(
      id,
      { status, reviewNotes },
      req.user
    );
    return sendSuccess(res, { evidenceRequest: updated }, 'Evidence request status updated');
  } catch (err) {
    next(err);
  }
};

module.exports = {
  createRequest,
  getRequestsByCase,
  getOfficerRequests,
  updateRequestStatus,
};
