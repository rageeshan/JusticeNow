/**
 * Unit tests for Auth service
 * Tests JWT generation, anonymous sessions, registration, login,
 * and edge cases like duplicate emails and deactivated accounts
 */

require('../setup');
const jwt = require('jsonwebtoken');
const User = require('../../src/models/User.model');
const AuditLog = require('../../src/models/AuditLog.model');

// Mock Firebase admin so the module can be required without credentials
const mockVerifyIdToken = jest.fn();
jest.mock('../../src/config/firebase', () => ({
  admin: {
    auth: () => ({
      verifyIdToken: mockVerifyIdToken,
    }),
  },
  initFirebase: jest.fn(),
}));

const authService = require('../../src/services/auth.service');

describe('Auth Service', () => {
  // ─── generateToken ─────────────────────────────────────────────────────────

  describe('generateToken', () => {
    it('should return a valid JWT containing userId', () => {
      const token = authService.generateToken('abc123');
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      expect(decoded.userId).toBe('abc123');
      expect(decoded.id).toBe('abc123');
      expect(decoded.exp).toBeDefined();
    });

    it('should set expiry from env variable', () => {
      process.env.JWT_EXPIRES_IN = '7d';
      const token = authService.generateToken('test');
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      // JWT exp is in seconds, 7 days = 604800 seconds
      const expectedExpiry = Math.floor(Date.now() / 1000) + 604800;
      expect(decoded.exp).toBeCloseTo(expectedExpiry, -1);
    });
  });

  // ─── createAnonymousSession ────────────────────────────────────────────────

  describe('createAnonymousSession', () => {
    it('should create an anonymous user with auto-generated alias', async () => {
      const { user, token } = await authService.createAnonymousSession();

      expect(user.alias).toMatch(/^Citizen-[A-F0-9]{6}$/);
      expect(user.role).toBe('citizen');
      expect(user.isAnonymous).toBe(true);
      expect(user.isVerified).toBe(true);
      expect(user.approvalStatus).toBe('approved');
      expect(token).toBeDefined();
    });

    it('should create an audit log entry', async () => {
      await authService.createAnonymousSession();

      const logs = await AuditLog.find({ action: 'user.anonymous_created' });
      expect(logs).toHaveLength(1);
      expect(logs[0].targetResource).toBe('User');
    });

    it('should return a valid JWT for the anonymous user', async () => {
      const { user, token } = await authService.createAnonymousSession();
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      expect(decoded.userId).toBe(user._id.toString());
    });
  });

  // ─── registerCitizen ───────────────────────────────────────────────────────

  describe('registerCitizen', () => {
    const validCitizenData = {
      email: 'newcitizen@test.com',
      password: 'StrongPassword123!',
      fullName: 'Test Citizen',
      role: 'citizen',
    };

    it('should register a citizen successfully', async () => {
      const result = await authService.registerCitizen(validCitizenData);

      expect(result.user.email).toBe('newcitizen@test.com');
      expect(result.user.role).toBe('citizen');
      expect(result.token).toBeDefined();
      expect(result.isPending).toBe(false);
      expect(result.message).toBe('Registration successful');
    });

    it('should hash the password', async () => {
      const result = await authService.registerCitizen(validCitizenData);
      const savedUser = await User.findById(result.user._id);

      expect(savedUser.passwordHash).not.toBe(validCitizenData.password);
      expect(savedUser.passwordHash).toMatch(/^\$2[aby]\$/);
    });

    it('should throw 409 for duplicate email', async () => {
      await authService.registerCitizen(validCitizenData);

      try {
        await authService.registerCitizen(validCitizenData);
        fail('Should have thrown');
      } catch (err) {
        expect(err.statusCode).toBe(409);
        expect(err.message).toContain('Email already in use');
      }
    });

    it('should register a police_officer as pending', async () => {
      const result = await authService.registerCitizen({
        email: 'officer@test.com',
        password: 'OfficerPass123!',
        fullName: 'Officer Test',
        role: 'police_officer',
        policeId: 'PO-1234',
      });

      expect(result.isPending).toBe(true);
      expect(result.token).toBeNull();
      expect(result.user.approvalStatus).toBe('pending');
      expect(result.user.isVerified).toBe(false);
    });

    it('should register a lawyer as pending', async () => {
      const result = await authService.registerCitizen({
        email: 'lawyer@test.com',
        password: 'LawyerPass123!',
        fullName: 'Lawyer Test',
        role: 'lawyer',
        courtNumber: 'CT-5678',
      });

      expect(result.isPending).toBe(true);
      expect(result.token).toBeNull();
    });

    it('should default to citizen role for invalid role', async () => {
      const result = await authService.registerCitizen({
        email: 'invalid.role@test.com',
        password: 'Pass123!',
        role: 'superhero',
      });

      expect(result.user.role).toBe('citizen');
    });

    it('should store profile data', async () => {
      const result = await authService.registerCitizen({
        email: 'profile@test.com',
        password: 'Pass123!',
        fullName: 'Full Name',
        role: 'citizen',
        phone: '+94771234567',
        nic: '200012345678',
        gender: 'Male',
        province: 'Western',
        district: 'Colombo',
        preferredLanguage: 'Sinhala',
      });

      expect(result.user.profile.fullName).toBe('Full Name');
      expect(result.user.profile.phone).toBe('+94771234567');
      expect(result.user.profile.nic).toBe('200012345678');
      expect(result.user.profile.preferredLanguage).toBe('Sinhala');
    });

    it('should create an audit log for registration', async () => {
      await authService.registerCitizen(validCitizenData);

      const logs = await AuditLog.find({ action: 'user.registered' });
      expect(logs).toHaveLength(1);
    });
  });

  // ─── loginCitizen ──────────────────────────────────────────────────────────

  describe('loginCitizen', () => {
    beforeEach(async () => {
      await authService.registerCitizen({
        email: 'login@test.com',
        password: 'LoginPassword123!',
        fullName: 'Login User',
        role: 'citizen',
      });
    });

    it('should login with correct credentials', async () => {
      const { user, token } = await authService.loginCitizen({
        email: 'login@test.com',
        password: 'LoginPassword123!',
      });

      expect(user.email).toBe('login@test.com');
      expect(token).toBeDefined();
    });

    it('should update lastLogin on successful login', async () => {
      const { user } = await authService.loginCitizen({
        email: 'login@test.com',
        password: 'LoginPassword123!',
      });

      const fresh = await User.findById(user._id);
      expect(fresh.lastLogin).toBeInstanceOf(Date);
    });

    it('should throw 401 for wrong password', async () => {
      try {
        await authService.loginCitizen({
          email: 'login@test.com',
          password: 'WrongPassword!',
        });
        fail('Should have thrown');
      } catch (err) {
        expect(err.statusCode).toBe(401);
      }
    });

    it('should throw 401 for non-existent email', async () => {
      try {
        await authService.loginCitizen({
          email: 'doesnotexist@test.com',
          password: 'AnyPassword!',
        });
        fail('Should have thrown');
      } catch (err) {
        expect(err.statusCode).toBe(401);
      }
    });

    it('should throw 403 for deactivated account', async () => {
      await User.updateOne({ email: 'login@test.com' }, { isActive: false });

      try {
        await authService.loginCitizen({
          email: 'login@test.com',
          password: 'LoginPassword123!',
        });
        fail('Should have thrown');
      } catch (err) {
        expect(err.statusCode).toBe(403);
        expect(err.message).toContain('deactivated');
      }
    });

    it('should throw 403 for pending approval account', async () => {
      await User.updateOne({ email: 'login@test.com' }, { approvalStatus: 'pending' });

      try {
        await authService.loginCitizen({
          email: 'login@test.com',
          password: 'LoginPassword123!',
        });
        fail('Should have thrown');
      } catch (err) {
        expect(err.statusCode).toBe(403);
        expect(err.code).toBe('ACCOUNT_PENDING');
        expect(err.data.approvalStatus).toBe('pending');
      }
    });

    it('should throw 403 for rejected account with reason', async () => {
      await User.updateOne(
        { email: 'login@test.com' },
        { approvalStatus: 'rejected', rejectionReason: 'Invalid credentials submitted' }
      );

      try {
        await authService.loginCitizen({
          email: 'login@test.com',
          password: 'LoginPassword123!',
        });
        fail('Should have thrown');
      } catch (err) {
        expect(err.statusCode).toBe(403);
        expect(err.code).toBe('ACCOUNT_REJECTED');
        expect(err.message).toContain('Invalid credentials submitted');
      }
    });
  });

  // ─── verifyFirebaseAndGetUser ───────────────────────────────────────────────

  describe('verifyFirebaseAndGetUser', () => {
    it('should create a new pending lawyer account on first Firebase login', async () => {
      mockVerifyIdToken.mockResolvedValue({
        uid: 'firebase-uid-new',
        email: 'firebasetest@law.com',
        name: 'Firebase Lawyer',
        picture: 'https://example.com/pic.jpg',
      });

      const { user, token } = await authService.verifyFirebaseAndGetUser('valid-token');

      expect(user).toBeDefined();
      expect(user.firebaseUid).toBe('firebase-uid-new');
      expect(user.email).toBe('firebasetest@law.com');
      expect(user.role).toBe('lawyer');
      expect(user.approvalStatus).toBe('pending');
      expect(user.isVerified).toBe(false);
      expect(token).toBeDefined();

      const audit = await AuditLog.findOne({ action: 'user.registered_firebase' });
      expect(audit).toBeTruthy();
      expect(audit.performedBy.toString()).toBe(user._id.toString());
    });

    it('should log in existing Firebase user and update lastLogin', async () => {
      const existingUser = await User.create({
        email: 'existing.firebase@law.com',
        firebaseUid: 'firebase-uid-existing',
        role: 'lawyer',
        approvalStatus: 'approved',
        isVerified: true,
      });

      mockVerifyIdToken.mockResolvedValue({
        uid: 'firebase-uid-existing',
        email: 'existing.firebase@law.com',
      });

      const { user, token } = await authService.verifyFirebaseAndGetUser('valid-token');

      expect(user._id.toString()).toBe(existingUser._id.toString());
      expect(user.lastLogin).toBeDefined();
      expect(token).toBeDefined();
    });

    it('should throw 403 if user account is deactivated', async () => {
      await User.create({
        email: 'deactivated.firebase@law.com',
        firebaseUid: 'firebase-uid-deactivated',
        role: 'lawyer',
        isActive: false,
      });

      mockVerifyIdToken.mockResolvedValue({
        uid: 'firebase-uid-deactivated',
      });

      await expect(
        authService.verifyFirebaseAndGetUser('token')
      ).rejects.toMatchObject({
        statusCode: 403,
        message: 'Account deactivated',
      });
    });
  });
});

