/**
 * Unit tests for error handling middleware
 * Tests errorHandler and notFound middleware
 */

const { errorHandler, notFound } = require('../../src/middleware/error.middleware');

// Mock Express req/res/next
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

describe('Error Middleware', () => {
  let consoleSpy;

  beforeEach(() => {
    consoleSpy = jest.spyOn(console, 'error').mockImplementation();
  });

  afterEach(() => {
    consoleSpy.mockRestore();
  });

  // ─── errorHandler ──────────────────────────────────────────────────────────

  describe('errorHandler', () => {
    it('should handle Mongoose ValidationError', () => {
      const err = {
        name: 'ValidationError',
        errors: {
          title: { path: 'title', message: 'Title is required' },
          category: { path: 'category', message: 'Category is required' },
        },
      };

      const res = createMockRes();
      errorHandler(err, {}, res, jest.fn());

      expect(res.statusCode).toBe(422);
      expect(res.body.message).toBe('Validation failed');
      expect(res.body.errors).toHaveLength(2);
      expect(res.body.errors[0]).toHaveProperty('field');
      expect(res.body.errors[0]).toHaveProperty('message');
    });

    it('should handle Mongoose duplicate key error (11000)', () => {
      const err = {
        code: 11000,
        keyValue: { email: 'test@test.com' },
      };

      const res = createMockRes();
      errorHandler(err, {}, res, jest.fn());

      expect(res.statusCode).toBe(409);
      expect(res.body.message).toContain('email already exists');
    });

    it('should handle Mongoose CastError', () => {
      const err = {
        name: 'CastError',
        path: '_id',
        value: 'not-a-valid-id',
      };

      const res = createMockRes();
      errorHandler(err, {}, res, jest.fn());

      expect(res.statusCode).toBe(400);
      expect(res.body.message).toContain('Invalid _id');
      expect(res.body.message).toContain('not-a-valid-id');
    });

    it('should handle JsonWebTokenError', () => {
      const err = { name: 'JsonWebTokenError', message: 'jwt malformed' };

      const res = createMockRes();
      errorHandler(err, {}, res, jest.fn());

      expect(res.statusCode).toBe(401);
      expect(res.body.message).toBe('Invalid token');
    });

    it('should handle TokenExpiredError', () => {
      const err = { name: 'TokenExpiredError', message: 'jwt expired' };

      const res = createMockRes();
      errorHandler(err, {}, res, jest.fn());

      expect(res.statusCode).toBe(401);
      expect(res.body.message).toBe('Token expired');
    });

    it('should handle Multer file size error', () => {
      const err = { code: 'LIMIT_FILE_SIZE' };
      process.env.MAX_FILE_SIZE_MB = '25';

      const res = createMockRes();
      errorHandler(err, {}, res, jest.fn());

      expect(res.statusCode).toBe(413);
      expect(res.body.message).toContain('25MB');
    });

    it('should handle generic error with statusCode', () => {
      const err = new Error('Custom error');
      err.statusCode = 418;

      const res = createMockRes();
      errorHandler(err, {}, res, jest.fn());

      expect(res.statusCode).toBe(418);
      expect(res.body.message).toBe('Custom error');
    });

    it('should default to 500 for unknown errors', () => {
      const err = new Error('Unknown error');

      const res = createMockRes();
      errorHandler(err, {}, res, jest.fn());

      expect(res.statusCode).toBe(500);
    });

    it('should hide error details in production for unknown errors', () => {
      const originalEnv = process.env.NODE_ENV;
      process.env.NODE_ENV = 'production';

      const err = new Error('Secret error details');
      // No statusCode set → treated as generic server error
      const res = createMockRes();
      errorHandler(err, {}, res, jest.fn());

      expect(res.body.message).toBe('Internal server error');

      process.env.NODE_ENV = originalEnv;
    });

    it('should include error data if present', () => {
      const err = new Error('Error with data');
      err.statusCode = 400;
      err.data = { fieldErrors: ['invalid email'] };

      const res = createMockRes();
      errorHandler(err, {}, res, jest.fn());

      expect(res.body.data).toEqual({ fieldErrors: ['invalid email'] });
    });
  });

  // ─── notFound ──────────────────────────────────────────────────────────────

  describe('notFound', () => {
    it('should return 404 with method and path info', () => {
      const req = { method: 'GET', originalUrl: '/api/nonexistent' };
      const res = createMockRes();

      notFound(req, res, jest.fn());

      expect(res.statusCode).toBe(404);
      expect(res.body.message).toContain('GET');
      expect(res.body.message).toContain('/api/nonexistent');
    });

    it('should handle POST request', () => {
      const req = { method: 'POST', originalUrl: '/api/missing' };
      const res = createMockRes();

      notFound(req, res, jest.fn());

      expect(res.body.message).toContain('POST');
      expect(res.body.message).toContain('/api/missing');
    });
  });
});
