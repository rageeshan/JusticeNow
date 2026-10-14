const path = require('path');
const authService = require('../services/auth.service');
const { sendSuccess, sendCreated, sendError } = require('../utils/response.util');

/**
 * POST /api/auth/anonymous
 * Create an anonymous session (no registration required)
 */
const anonymousLogin = async (req, res, next) => {
  try {
    const { user, token } = await authService.createAnonymousSession();
    return sendCreated(res, { user, token }, 'Anonymous session created');
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/auth/register
 * Register a citizen, lawyer, or police officer
 */
const register = async (req, res, next) => {
  try {
    const {
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
    } = req.body;
    const result = await authService.registerCitizen({
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
    });
    return sendCreated(
      res,
      { user: result.user, token: result.token, isPending: result.isPending },
      result.message || 'Registration successful'
    );
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/auth/upload-certificate
 * Upload lawyer certificate / professional verification document
 */
const uploadCertificate = async (req, res, next) => {
  try {
    if (!req.file) {
      return sendError(res, 'No file uploaded. Please provide a photo or PDF certificate.', 400);
    }
    const relativePath = path
      .relative(path.resolve(process.env.UPLOAD_DIR || 'uploads'), req.file.path)
      .replace(/\\/g, '/');
    const fileUrl = `/uploads/${relativePath}`;

    return sendCreated(
      res,
      {
        fileUrl,
        filename: req.file.filename,
        originalName: req.file.originalname,
        mimetype: req.file.mimetype,
        size: req.file.size,
      },
      'Certificate uploaded successfully'
    );
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/auth/login
 * Login a citizen with email/password
 */
const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;
    const { user, token } = await authService.loginCitizen({ email, password });
    return sendSuccess(res, { user, token }, 'Login successful');
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/auth/firebase
 * Verify Firebase token (for NGO/Officer/Admin logins)
 * Body: { idToken: <firebase_id_token> }
 */
const firebaseAuth = async (req, res, next) => {
  try {
    const { idToken } = req.body;
    if (!idToken) {
      return sendError(res, 'Firebase ID token is required', 400);
    }
    const { user, token } = await authService.verifyFirebaseAndGetUser(idToken);
    return sendSuccess(res, { user, token }, 'Firebase authentication successful');
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/auth/me
 * Get current authenticated user's profile
 */
const getMe = async (req, res) => {
  return sendSuccess(res, { user: req.user }, 'Profile retrieved');
};

/**
 * PATCH /api/auth/profile
 * Update current authenticated user's profile details
 */
const updateProfile = async (req, res, next) => {
  try {
    const User = require('../models/User.model');
    const { fullName, phone, aboutMe, preferredLanguage, district, province, courtNumber } = req.body;
    const user = await User.findById(req.user._id);
    if (!user) {
      return sendError(res, 'User not found', 404);
    }

    if (!user.profile) user.profile = {};
    if (fullName !== undefined) user.profile.fullName = fullName;
    if (phone !== undefined) user.profile.phone = phone;
    if (aboutMe !== undefined) user.profile.aboutMe = aboutMe;
    if (preferredLanguage !== undefined) user.profile.preferredLanguage = preferredLanguage;
    if (district !== undefined) user.profile.district = district;
    if (province !== undefined) user.profile.province = province;
    if (courtNumber !== undefined) user.profile.courtNumber = courtNumber;

    await user.save();
    return sendSuccess(res, { user }, 'Profile updated successfully');
  } catch (err) {
    next(err);
  }
};

module.exports = { anonymousLogin, register, login, firebaseAuth, getMe, updateProfile, uploadCertificate };

