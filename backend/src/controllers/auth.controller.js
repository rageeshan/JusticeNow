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
 * Register a citizen with email/password
 */
const register = async (req, res, next) => {
  try {
    const { email, password } = req.body;
    const { user, token } = await authService.registerCitizen({ email, password });
    return sendCreated(res, { user, token }, 'Registration successful');
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

module.exports = { anonymousLogin, register, login, firebaseAuth, getMe };
