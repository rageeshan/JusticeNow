/**
 * Unit tests for auth middleware
 * Tests authenticate, authorize, and optionalAuthenticate
 */

require('../setup');
const jwt = require('jsonwebtoken');
const User = require('../../src/models/User.model');

// Mock Firebase admin
jest.mock('../../src/config/firebase', () => ({
  admin: {
    auth: () => ({
      verifyIdToken: jest.fn().mockRejectedValue(new Error('Not a Firebase token')),
    }),
  },
  initFirebase: jest.fn(),
}));

const { authenticate, authorize, optionalAuthenticate } = require('../../src/middleware/auth.middleware');

// Helper to create mock req/res/next
const createMockReq = (headers = {}, user = null) => ({
  headers,
  user,
});

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

describe('Auth Middleware', () => {
  // ─── authenticate ──────────────────────────────────────────────────────────

  describe('authenticate', () => {
    it('should return 401 when no Authorization header', async () => {
      const req = createMockReq({});
      const res = createMockRes();
      const next = jest.fn();

      await authenticate(req, res, next);

      expect(res.statusCode).toBe(401);
      expect(res.body.message).toBe('No token provided');
      expect(next).not.toHaveBeenCalled();
    });

    it('should return 401 when Authorization header missing Bearer prefix', async () => {
      const req = createMockReq({ authorization: 'Token abc123' });
      const res = createMockRes();
      const next = jest.fn();

      await authenticate(req, res, next);

      expect(res.statusCode).toBe(401);
    });

    it('should return 401 for invalid JWT', async () => {
      const req = createMockReq({ authorization: 'Bearer invalid.token.here' });
      const res = createMockRes();
      const next = jest.fn();

      await authenticate(req, res, next);

      expect(res.statusCode).toBe(401);
      expect(next).not.toHaveBeenCalled();
    });

    it('should authenticate with valid JWT and active user', async () => {
      const user = await User.create({
        email: 'auth.mw@test.com',
        role: 'citizen',
        isActive: true,
        approvalStatus: 'approved',
      });

      const token = jwt.sign(
        { userId: user._id.toString(), id: user._id.toString() },
        process.env.JWT_SECRET,
        { expiresIn: '1d' }
      );

      const req = createMockReq({ authorization: `Bearer ${token}` });
      const res = createMockRes();
      const next = jest.fn();

      await authenticate(req, res, next);

      expect(next).toHaveBeenCalled();
      expect(req.user).toBeTruthy();
      expect(req.user.email).toBe('auth.mw@test.com');
      expect(req.authType).toBe('jwt');
    });

    it('should return 401 for deactivated user', async () => {
      const user = await User.create({
        email: 'inactive.mw@test.com',
        role: 'citizen',
        isActive: false,
      });

      const token = jwt.sign(
        { userId: user._id.toString() },
        process.env.JWT_SECRET,
        { expiresIn: '1d' }
      );

      const req = createMockReq({ authorization: `Bearer ${token}` });
      const res = createMockRes();
      const next = jest.fn();

      await authenticate(req, res, next);

      expect(res.statusCode).toBe(401);
      expect(next).not.toHaveBeenCalled();
    });

    it('should return 403 for pending police_officer', async () => {
      const user = await User.create({
        email: 'pending.officer@test.com',
        role: 'police_officer',
        isActive: true,
        approvalStatus: 'pending',
      });

      const token = jwt.sign(
        { userId: user._id.toString(), id: user._id.toString() },
        process.env.JWT_SECRET,
        { expiresIn: '1d' }
      );

      const req = createMockReq({ authorization: `Bearer ${token}` });
      const res = createMockRes();
      const next = jest.fn();

      await authenticate(req, res, next);

      expect(res.statusCode).toBe(403);
      expect(res.body.message).toContain('pending admin approval');
    });

    it('should return 403 for rejected lawyer', async () => {
      const user = await User.create({
        email: 'rejected.lawyer@test.com',
        role: 'lawyer',
        isActive: true,
        approvalStatus: 'rejected',
        rejectionReason: 'Invalid certificate',
      });

      const token = jwt.sign(
        { userId: user._id.toString(), id: user._id.toString() },
        process.env.JWT_SECRET,
        { expiresIn: '1d' }
      );

      const req = createMockReq({ authorization: `Bearer ${token}` });
      const res = createMockRes();
      const next = jest.fn();

      await authenticate(req, res, next);

      expect(res.statusCode).toBe(403);
      expect(res.body.message).toContain('rejected');
    });

    it('should return 401 for expired JWT', async () => {
      const token = jwt.sign(
        { userId: 'test' },
        process.env.JWT_SECRET,
        { expiresIn: '-1s' } // already expired
      );

      const req = createMockReq({ authorization: `Bearer ${token}` });
      const res = createMockRes();
      const next = jest.fn();

      await authenticate(req, res, next);

      expect(res.statusCode).toBe(401);
    });
  });

  // ─── authorize ─────────────────────────────────────────────────────────────

  describe('authorize', () => {
    it('should return 401 when no user on request', () => {
      const middleware = authorize('admin');
      const req = createMockReq({}, null);
      const res = createMockRes();
      const next = jest.fn();

      middleware(req, res, next);

      expect(res.statusCode).toBe(401);
    });

    it('should return 403 when user role not in allowed roles', () => {
      const middleware = authorize('admin', 'police_officer');
      const req = { user: { role: 'citizen' } };
      const res = createMockRes();
      const next = jest.fn();

      middleware(req, res, next);

      expect(res.statusCode).toBe(403);
      expect(res.body.message).toContain('admin, police_officer');
    });

    it('should call next when user has matching role', () => {
      const middleware = authorize('admin', 'police_officer');
      const req = { user: { role: 'admin' } };
      const res = createMockRes();
      const next = jest.fn();

      middleware(req, res, next);

      expect(next).toHaveBeenCalled();
    });

    it('should handle single role', () => {
      const middleware = authorize('citizen');
      const req = { user: { role: 'citizen' } };
      const res = createMockRes();
      const next = jest.fn();

      middleware(req, res, next);

      expect(next).toHaveBeenCalled();
    });
  });

  // ─── optionalAuthenticate ──────────────────────────────────────────────────

  describe('optionalAuthenticate', () => {
    it('should set req.user to null when no auth header and call next', async () => {
      const req = createMockReq({});
      const res = createMockRes();
      const next = jest.fn();

      await optionalAuthenticate(req, res, next);

      expect(req.user).toBeNull();
      expect(next).toHaveBeenCalled();
    });

    it('should set req.user to null when empty Bearer token', async () => {
      const req = createMockReq({ authorization: '' });
      const res = createMockRes();
      const next = jest.fn();

      await optionalAuthenticate(req, res, next);

      expect(req.user).toBeNull();
      expect(next).toHaveBeenCalled();
    });

    it('should authenticate when valid token is provided', async () => {
      const user = await User.create({
        email: 'optional.auth@test.com',
        role: 'citizen',
        isActive: true,
        approvalStatus: 'approved',
      });

      const token = jwt.sign(
        { userId: user._id.toString(), id: user._id.toString() },
        process.env.JWT_SECRET,
        { expiresIn: '1d' }
      );

      const req = createMockReq({ authorization: `Bearer ${token}` });
      const res = createMockRes();
      const next = jest.fn();

      await optionalAuthenticate(req, res, next);

      expect(next).toHaveBeenCalled();
      expect(req.user).toBeTruthy();
      expect(req.user.email).toBe('optional.auth@test.com');
    });
  });
});
