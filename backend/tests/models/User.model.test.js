/**
 * Unit tests for User model
 * Tests schema validation, password hashing, password comparison, and toJSON sanitisation
 */

require('../setup');
const mongoose = require('mongoose');
const User = require('../../src/models/User.model');

describe('User Model', () => {
  // ─── Schema & Defaults ─────────────────────────────────────────────────────

  describe('Schema defaults', () => {
    it('should create a minimal anonymous user with defaults', async () => {
      const user = await User.create({
        alias: 'Citizen-A1B2C3',
        role: 'citizen',
      });

      expect(user.alias).toBe('Citizen-A1B2C3');
      expect(user.role).toBe('citizen');
      expect(user.isActive).toBe(true);
      expect(user.isVerified).toBe(false);
      expect(user.email).toBeNull();
      expect(user.firebaseUid).toBeNull();
      expect(user.lastLogin).toBeNull();
      expect(user.createdAt).toBeDefined();
      expect(user.updatedAt).toBeDefined();
    });

    it('should default approvalStatus to pending for police_officer role', async () => {
      const user = await User.create({
        email: 'officer@test.com',
        role: 'police_officer',
        passwordHash: 'testpassword123',
      });

      expect(user.approvalStatus).toBe('pending');
    });

    it('should default approvalStatus to pending for lawyer role', async () => {
      const user = await User.create({
        email: 'lawyer@test.com',
        role: 'lawyer',
        passwordHash: 'testpassword123',
      });

      expect(user.approvalStatus).toBe('pending');
    });

    it('should default approvalStatus to approved for citizen role', async () => {
      const user = await User.create({
        email: 'citizen@test.com',
        role: 'citizen',
        passwordHash: 'testpassword123',
      });

      expect(user.approvalStatus).toBe('approved');
    });
  });

  // ─── Validation ─────────────────────────────────────────────────────────────

  describe('Validation', () => {
    it('should reject an invalid role', async () => {
      await expect(
        User.create({
          email: 'bad@test.com',
          role: 'superadmin',
        })
      ).rejects.toThrow();
    });

    it('should reject invalid gender value', async () => {
      await expect(
        User.create({
          email: 'gender@test.com',
          role: 'citizen',
          profile: { gender: 'Unknown' },
        })
      ).rejects.toThrow();
    });

    it('should accept valid gender values', async () => {
      for (const gender of ['Male', 'Female', 'Other']) {
        const user = await User.create({
          email: `${gender.toLowerCase()}@test.com`,
          role: 'citizen',
          profile: { gender },
        });
        expect(user.profile.gender).toBe(gender);
      }
    });

    it('should lowercase email on save', async () => {
      const user = await User.create({
        email: 'UPPER@TEST.COM',
        role: 'citizen',
      });

      expect(user.email).toBe('upper@test.com');
    });

    it('should trim email whitespace', async () => {
      const user = await User.create({
        email: '  spacey@test.com  ',
        role: 'citizen',
      });

      expect(user.email).toBe('spacey@test.com');
    });
  });

  // ─── Password Hashing ──────────────────────────────────────────────────────

  describe('Password hashing', () => {
    it('should hash passwordHash on creation', async () => {
      const plainPassword = 'SecurePassword123!';
      const user = await User.create({
        email: 'hash@test.com',
        role: 'citizen',
        passwordHash: plainPassword,
      });

      expect(user.passwordHash).not.toBe(plainPassword);
      expect(user.passwordHash).toMatch(/^\$2[aby]\$/); // bcrypt hash prefix
    });

    it('should re-hash when passwordHash is modified', async () => {
      const user = await User.create({
        email: 'rehash@test.com',
        role: 'citizen',
        passwordHash: 'OldPassword123!',
      });

      const firstHash = user.passwordHash;
      user.passwordHash = 'NewPassword456!';
      await user.save();

      expect(user.passwordHash).not.toBe(firstHash);
      expect(user.passwordHash).not.toBe('NewPassword456!');
    });

    it('should NOT re-hash when other fields are modified', async () => {
      const user = await User.create({
        email: 'noreash@test.com',
        role: 'citizen',
        passwordHash: 'SamePassword123!',
      });

      const hashAfterCreate = user.passwordHash;
      user.profile = { fullName: 'John Doe' };
      await user.save();

      expect(user.passwordHash).toBe(hashAfterCreate);
    });
  });

  // ─── comparePassword ───────────────────────────────────────────────────────

  describe('comparePassword', () => {
    it('should return true for correct password', async () => {
      const user = await User.create({
        email: 'compare@test.com',
        role: 'citizen',
        passwordHash: 'CorrectPassword123!',
      });

      const isMatch = await user.comparePassword('CorrectPassword123!');
      expect(isMatch).toBe(true);
    });

    it('should return false for incorrect password', async () => {
      const user = await User.create({
        email: 'wrong@test.com',
        role: 'citizen',
        passwordHash: 'RightPassword!',
      });

      const isMatch = await user.comparePassword('WrongPassword!');
      expect(isMatch).toBe(false);
    });
  });

  // ─── toJSON Sanitisation ───────────────────────────────────────────────────

  describe('toJSON', () => {
    it('should strip passwordHash from JSON output', async () => {
      const user = await User.create({
        email: 'json@test.com',
        role: 'citizen',
        passwordHash: 'HiddenPassword!',
      });

      const json = user.toJSON();
      expect(json.passwordHash).toBeUndefined();
      expect(json.email).toBe('json@test.com');
    });
  });

  // ─── Profile Fields ────────────────────────────────────────────────────────

  describe('Profile fields', () => {
    it('should store lawyer-specific profile fields', async () => {
      const user = await User.create({
        email: 'lawyer.profile@test.com',
        role: 'lawyer',
        passwordHash: 'Password123!',
        profile: {
          fullName: 'Jane Lawyer',
          courtNumber: 'CT-2024-001',
          lawyerId: 'LW-5678',
          certificateUrl: 'https://example.com/cert.pdf',
          aboutMe: 'Experienced human rights lawyer',
          preferredLanguage: 'English',
        },
      });

      expect(user.profile.courtNumber).toBe('CT-2024-001');
      expect(user.profile.lawyerId).toBe('LW-5678');
      expect(user.profile.certificateUrl).toBe('https://example.com/cert.pdf');
      expect(user.profile.preferredLanguage).toBe('English');
    });

    it('should store police officer profile fields', async () => {
      const user = await User.create({
        email: 'officer.profile@test.com',
        role: 'police_officer',
        passwordHash: 'Password123!',
        profile: {
          fullName: 'John Officer',
          policeId: 'PO-1234',
          district: 'Colombo',
          province: 'Western',
        },
      });

      expect(user.profile.policeId).toBe('PO-1234');
      expect(user.profile.district).toBe('Colombo');
    });

    it('should reject invalid preferredLanguage', async () => {
      await expect(
        User.create({
          email: 'badlang@test.com',
          role: 'citizen',
          profile: { preferredLanguage: 'French' },
        })
      ).rejects.toThrow();
    });
  });
});
