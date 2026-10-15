/**
 * Unit tests for response utility helpers
 * Tests all standardized API response functions
 */

const {
  sendSuccess,
  sendCreated,
  sendError,
  sendNotFound,
  sendUnauthorized,
  sendForbidden,
  sendValidationError,
} = require('../../src/utils/response.util');

// Mock Express response object
const createMockRes = () => {
  const res = {
    statusCode: null,
    body: null,
    status(code) {
      res.statusCode = code;
      return res;
    },
    json(data) {
      res.body = data;
      return res;
    },
  };
  return res;
};

describe('Response Utility', () => {
  describe('sendSuccess', () => {
    it('should return 200 with default message', () => {
      const res = createMockRes();
      sendSuccess(res, { id: 1 });

      expect(res.statusCode).toBe(200);
      expect(res.body).toEqual({
        success: true,
        message: 'Success',
        data: { id: 1 },
      });
    });

    it('should return custom status code and message', () => {
      const res = createMockRes();
      sendSuccess(res, { items: [] }, 'Items fetched', 200);

      expect(res.statusCode).toBe(200);
      expect(res.body.message).toBe('Items fetched');
    });

    it('should return empty data by default', () => {
      const res = createMockRes();
      sendSuccess(res);

      expect(res.body.data).toEqual({});
    });
  });

  describe('sendCreated', () => {
    it('should return 201 with resource created message', () => {
      const res = createMockRes();
      sendCreated(res, { id: 'abc123' });

      expect(res.statusCode).toBe(201);
      expect(res.body).toEqual({
        success: true,
        message: 'Resource created successfully',
        data: { id: 'abc123' },
      });
    });

    it('should accept custom creation message', () => {
      const res = createMockRes();
      sendCreated(res, {}, 'Case created');

      expect(res.body.message).toBe('Case created');
    });
  });

  describe('sendError', () => {
    it('should return 500 by default', () => {
      const res = createMockRes();
      sendError(res);

      expect(res.statusCode).toBe(500);
      expect(res.body).toEqual({
        success: false,
        message: 'An error occurred',
      });
    });

    it('should include errors array when provided', () => {
      const res = createMockRes();
      const errors = [{ field: 'email', message: 'Invalid' }];
      sendError(res, 'Validation failed', 422, errors);

      expect(res.statusCode).toBe(422);
      expect(res.body.errors).toEqual(errors);
    });

    it('should include data when provided', () => {
      const res = createMockRes();
      sendError(res, 'Error', 400, null, { debug: true });

      expect(res.body.data).toEqual({ debug: true });
    });

    it('should not include errors or data when null', () => {
      const res = createMockRes();
      sendError(res, 'Fail', 400);

      expect(res.body.errors).toBeUndefined();
      expect(res.body.data).toBeUndefined();
    });
  });

  describe('sendNotFound', () => {
    it('should return 404 with default message', () => {
      const res = createMockRes();
      sendNotFound(res);

      expect(res.statusCode).toBe(404);
      expect(res.body.message).toBe('Resource not found');
    });

    it('should return 404 with custom message', () => {
      const res = createMockRes();
      sendNotFound(res, 'Case not found');

      expect(res.body.message).toBe('Case not found');
    });
  });

  describe('sendUnauthorized', () => {
    it('should return 401', () => {
      const res = createMockRes();
      sendUnauthorized(res);

      expect(res.statusCode).toBe(401);
      expect(res.body.message).toBe('Unauthorized');
    });
  });

  describe('sendForbidden', () => {
    it('should return 403', () => {
      const res = createMockRes();
      sendForbidden(res);

      expect(res.statusCode).toBe(403);
      expect(res.body.message).toBe('Forbidden');
    });

    it('should accept custom forbidden message', () => {
      const res = createMockRes();
      sendForbidden(res, 'Admin only');

      expect(res.body.message).toBe('Admin only');
    });
  });

  describe('sendValidationError', () => {
    it('should return 422 with validation errors', () => {
      const res = createMockRes();
      const errors = [
        { field: 'title', message: 'Required' },
        { field: 'email', message: 'Invalid format' },
      ];
      sendValidationError(res, errors);

      expect(res.statusCode).toBe(422);
      expect(res.body.message).toBe('Validation failed');
      expect(res.body.errors).toEqual(errors);
    });
  });

  describe('sendBadRequest', () => {
    const { sendBadRequest } = require('../../src/utils/response.util');

    it('should return 400 with default and custom message', () => {
      const res1 = createMockRes();
      sendBadRequest(res1);
      expect(res1.statusCode).toBe(400);
      expect(res1.body.message).toBe('Bad request');

      const res2 = createMockRes();
      sendBadRequest(res2, 'Invalid input', [{ field: 'x' }], { extra: 1 });
      expect(res2.statusCode).toBe(400);
      expect(res2.body.message).toBe('Invalid input');
      expect(res2.body.errors).toEqual([{ field: 'x' }]);
      expect(res2.body.data).toEqual({ extra: 1 });
    });
  });
});

