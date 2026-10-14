const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { admin } = require('../config/firebase');
const User = require('../models/User.model');
const AuditLog = require('../models/AuditLog.model');

/**
 * Generate a JWT for an authenticated user
 */
const generateToken = (userId) => {
  return jwt.sign({ userId, id: userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '30d',
  });
};

/**
 * Create an anonymous session for a citizen
 */
const createAnonymousSession = async () => {
  const alias = `Citizen-${crypto.randomBytes(3).toString('hex').toUpperCase()}`;
  const user = await User.create({
    alias,
    role: 'citizen',
    isAnonymous: true,
    isVerified: true,
    approvalStatus: 'approved',
  });

  await AuditLog.create({
    action: 'user.anonymous_created',
    performedBy: user._id,
    targetResource: 'User',
    targetId: user._id,
  });

  const token = generateToken(user._id);
  return { user, token };
};

/**
 * Register a user with email/password, name, role, and role-specific details
 */
const registerCitizen = async ({
  email,
  password,
  fullName,
  role,
  phone,
  nic,
  gender,
  province,
  district,
  policeId,
  lawyerId,
  courtNumber,
  certificateUrl,
  aboutMe,
  preferredLanguage,
}) => {
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

  const isPendingRole = ['police_officer', 'officer', 'lawyer', 'legal_practitioner', 'ngo'].includes(userRole);
  const approvalStatus = isPendingRole ? 'pending' : 'approved';
  const isVerified = !isPendingRole;

  const user = await User.create({
    email,
    passwordHash: password, // Pre-save hook handles hashing
    role: userRole,
    approvalStatus,
    isVerified,
    profile: {
      fullName: fullName || null,
      phone: phone || null,
      nic: nic || null,
      gender: gender || null,
      province: province || null,
      district: district || null,
      policeId: policeId || null,
      courtNumber: courtNumber || null,
      lawyerId: lawyerId || courtNumber || null,
      certificateUrl: certificateUrl || null,
      aboutMe: aboutMe || null,
      preferredLanguage: preferredLanguage || null,
    },
  });

  await AuditLog.create({
    action: 'user.registered',
    performedBy: user._id,
    targetResource: 'User',
    targetId: user._id,
  });

  // Police officers and lawyers require admin approval before accessing the platform
  if (isPendingRole) {
    return {
      user,
      token: null,
      isPending: true,
      message: 'Registration submitted successfully. Your account is pending administrator verification.',
    };
  }

  const token = generateToken(user._id);
  return { user, token, isPending: false, message: 'Registration successful' };
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

  if (user.approvalStatus === 'pending') {
    const err = new Error('Your account is under review. An administrator must verify your account before you can log in.');
    err.statusCode = 403;
    err.code = 'ACCOUNT_PENDING';
    err.data = {
      approvalStatus: 'pending',
      role: user.role,
      email: user.email,
    };
    throw err;
  }
  if (user.approvalStatus === 'rejected') {
    const err = new Error(user.rejectionReason ? `Account registration rejected: ${user.rejectionReason}` : 'Your account registration was rejected by an administrator.');
    err.statusCode = 403;
    err.code = 'ACCOUNT_REJECTED';
    err.data = {
      approvalStatus: 'rejected',
      role: user.role,
      email: user.email,
      rejectionReason: user.rejectionReason || null,
    };
    throw err;
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
      approvalStatus: 'pending',
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