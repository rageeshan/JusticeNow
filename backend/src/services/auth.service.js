const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const User = require('../models/User.model');
const AuditLog = require('../models/AuditLog.model');
const { admin } = require('../config/firebase');

/**
 * Generate a JWT for a given user
 */
const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '30d',
  });
};

/**
 * Create an anonymous session for a citizen who does not want to register
 */
const createAnonymousSession = async () => {
  const alias = `User_${uuidv4().slice(0, 8).toUpperCase()}`;
  const user = await User.create({
    alias,
    role: 'anonymous',
    isVerified: true,
    verificationStatus: 'approved',
  });
  const token = generateToken(user._id);
  return { user, token };
};

/**
 * Register a user with email/password, name and role
 */
const registerCitizen = async ({ email, password, fullName, role }) => {
  const existing = await User.findOne({ email });
  if (existing) {
    const err = new Error('Email already in use');
    err.statusCode = 409;
    throw err;
  }

  const validRoles = [
    'citizen',
    'police_officer',
    'officer',
    'lawyer',
    'legal_practitioner',
    'ngo',
    'admin',
  ];
  const userRole = validRoles.includes(role) ? role : 'citizen';

  // Determine if role requires manual admin verification
  const requiresApproval = [
    'police_officer',
    'officer',
    'lawyer',
    'legal_practitioner',
    'ngo',
  ].includes(userRole);

  const user = await User.create({
    email,
    passwordHash: password, // Pre-save hook handles hashing
    role: userRole,
    profile: { fullName: fullName || null },
    isVerified: !requiresApproval,
    verificationStatus: requiresApproval ? 'pending' : 'approved',
  });

  const token = generateToken(user._id);

  await AuditLog.create({
    action: 'user.registered',
    performedBy: user._id,
    targetResource: 'User',
    targetId: user._id,
  });

  return { user, token };
};

/**
 * Login user with email/password
 */
const loginCitizen = async ({ email, password }) => {
  const user = await User.findOne({ email });
  if (!user || !(await user.comparePassword(password))) {
    const err = new Error('Invalid email or password');
    err.statusCode = 401;
    throw err;
  }

  if (!user.isActive) {
    const err = new Error('Account deactivated');
    err.statusCode = 403;
    throw err;
  }

  // Block unapproved professional accounts at login
  if (['police_officer', 'officer', 'lawyer', 'legal_practitioner', 'ngo'].includes(user.role)) {
    if (user.verificationStatus === 'pending') {
      const err = new Error('Your account is pending admin approval');
      err.statusCode = 403;
      throw err;
    }
    if (user.verificationStatus === 'rejected') {
      const err = new Error(`Account rejected: ${user.rejectionReason || 'Verification failed'}`);
      err.statusCode = 403;
      throw err;
    }
  }

  user.lastLogin = new Date();
  await user.save();
  const token = generateToken(user._id);

  return { user, token };
};

/**
 * Verify Firebase token and upsert staff user
 */
const verifyFirebaseAndGetUser = async (firebaseToken) => {
  const decoded = await admin.auth().verifyIdToken(firebaseToken);
  let user = await User.findOne({ firebaseUid: decoded.uid });

  if (!user) {
    // First login — create pending staff account
    user = await User.create({
      email: decoded.email,
      firebaseUid: decoded.uid,
      role: 'lawyer',
      isVerified: false,
      verificationStatus: 'pending',
      profile: {
        fullName: decoded.name || null,
        avatarUrl: decoded.picture || null,
      },
    });

    await AuditLog.create({
      action: 'user.registered_firebase',
      performedBy: user._id,
      targetResource: 'User',
      targetId: user._id,
    });
  }

  if (!user.isActive) {
    const err = new Error('Account deactivated');
    err.statusCode = 403;
    throw err;
  }

  user.lastLogin = new Date();
  await user.save();
  const token = generateToken(user._id);

  return { user, token };
};

module.exports = {
  generateToken,
  createAnonymousSession,
  registerCitizen,
  loginCitizen,
  verifyFirebaseAndGetUser,
};