/**
 * Unit tests for EvidenceRequest Controller
 */

const {
  createRequest,
  getRequestsByCase,
  getOfficerRequests,
  updateRequestStatus,
} = require('../../src/controllers/evidenceRequest.controller');
const evidenceRequestService = require('../../src/services/evidenceRequest.service');

jest.mock('../../src/services/evidenceRequest.service');

describe('EvidenceRequest Controller', () => {
  let req, res, next;

  beforeEach(() => {
    req = {
      params: {},
      query: {},
      body: {},
      user: { _id: 'user123', role: 'police_officer' },
    };
    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    };
    next = jest.fn();
    jest.clearAllMocks();
  });

  describe('createRequest', () => {
    it('should create an evidence request and return 201', async () => {
      req.params.id = 'case123';
      req.body = { description: 'Provide CCTV footage' };

      const mockCreated = { _id: 'req123', description: 'Provide CCTV footage' };
      evidenceRequestService.createEvidenceRequest.mockResolvedValue(mockCreated);

      await createRequest(req, res, next);

      expect(evidenceRequestService.createEvidenceRequest).toHaveBeenCalledWith(
        'case123',
        req.body,
        req.user
      );
      expect(res.status).toHaveBeenCalledWith(201);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          message: 'Evidence request sent to reporter',
          data: { evidenceRequest: mockCreated },
        })
      );
    });

    it('should forward errors to next()', async () => {
      req.params.id = 'case123';
      const err = new Error('Case not found');
      evidenceRequestService.createEvidenceRequest.mockRejectedValue(err);

      await createRequest(req, res, next);

      expect(next).toHaveBeenCalledWith(err);
    });
  });

  describe('getRequestsByCase', () => {
    it('should return evidence requests for a case', async () => {
      req.params.id = 'case123';
      const mockList = [{ _id: 'req1' }, { _id: 'req2' }];
      evidenceRequestService.getRequestsByCase.mockResolvedValue(mockList);

      await getRequestsByCase(req, res, next);

      expect(evidenceRequestService.getRequestsByCase).toHaveBeenCalledWith('case123');
      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith({
        success: true,
        message: 'Evidence requests retrieved',
        data: { evidenceRequests: mockList },
      });
    });
  });

  describe('getOfficerRequests', () => {
    it('should get requests for the logged-in officer', async () => {
      req.user = { _id: 'officer1', role: 'police_officer' };
      req.query = { status: 'pending', page: '2', limit: '10' };

      const mockResult = { requests: [], pagination: { total: 0 } };
      evidenceRequestService.getOfficerRequests.mockResolvedValue(mockResult);

      await getOfficerRequests(req, res, next);

      expect(evidenceRequestService.getOfficerRequests).toHaveBeenCalledWith('officer1', {
        status: 'pending',
        page: 2,
        limit: 10,
      });
      expect(res.status).toHaveBeenCalledWith(200);
    });

    it('should pass null officerId for admin user to view all requests', async () => {
      req.user = { _id: 'admin1', role: 'admin' };
      req.query = {};

      const mockResult = { requests: [], pagination: { total: 0 } };
      evidenceRequestService.getOfficerRequests.mockResolvedValue(mockResult);

      await getOfficerRequests(req, res, next);

      expect(evidenceRequestService.getOfficerRequests).toHaveBeenCalledWith(null, {
        status: undefined,
        page: 1,
        limit: 20,
      });
      expect(res.status).toHaveBeenCalledWith(200);
    });
  });

  describe('updateRequestStatus', () => {
    it('should return 400 if status is not provided', async () => {
      req.params.id = 'req123';
      req.body = {};

      await updateRequestStatus(req, res, next);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: 'Status is required',
        })
      );
    });

    it('should update request status successfully', async () => {
      req.params.id = 'req123';
      req.body = { status: 'fulfilled', reviewNotes: 'Approved' };

      const mockUpdated = { _id: 'req123', status: 'fulfilled' };
      evidenceRequestService.updateRequestStatus.mockResolvedValue(mockUpdated);

      await updateRequestStatus(req, res, next);

      expect(evidenceRequestService.updateRequestStatus).toHaveBeenCalledWith(
        'req123',
        { status: 'fulfilled', reviewNotes: 'Approved' },
        req.user
      );
      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          message: 'Evidence request status updated',
          data: { evidenceRequest: mockUpdated },
        })
      );
    });
  });
});
