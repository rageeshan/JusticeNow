const jwt = require('jsonwebtoken');
const { admin } = require('../config/firebase');
const User = require('../models/User.model');
const { sendUnauthorized, sendForbidden } = require('../utils/response.util');

/**
 * Middleware: Authenticate any request (JWT or Firebase token)
 * Attaches req.user on success.
 */
const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return sendUnauthorized(res, 'No token provided');
    }

    const token = authHeader.split(' ')[1];
    let user = null;

    // First, try Firebase token verification (for staff accounts)
    try {
      const decoded = await admin.auth().verifyIdToken(token);
      user = await User.findOne({ firebaseUid: decoded.uid, isActive: true });
      if (user) req.authType = 'firebase';
    } catch {
      // Not a Firebase token — try JWT (anonymous/citizen)
    }

    // Try JWT verification if Firebase didn't return a user
    if (!user) {
      try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        user = await User.findById(decoded.userId).select('-passwordHash');
        if (user && user.isActive) req.authType = 'jwt';
      } catch {
        return sendUnauthorized(res, 'Invalid or expired token');
      }
    }

    if (!user || !user.isActive) {
      return sendUnauthorized(res, 'User account not found or deactivated');
    }

    // Block pending or rejected professional accounts
    if (['police_officer', 'officer', 'lawyer', 'legal_practitioner', 'ngo'].includes(user.role)) {
      if (user.verificationStatus === 'pending') {
        return sendForbidden(res, 'Your account is pending admin approval');
      }
      if (user.verificationStatus === 'rejected') {
        return sendForbidden(res, `Account rejected: ${user.rejectionReason || 'Verification failed'}`);
      }
    }

    req.user = user;
    return next();
  } catch (error) {
    return sendUnauthorized(res, 'Authentication failed');
  }
};

/**
 * Middleware: Authorize by role(s)
 * Usage: authorize('admin', 'police_officer')
 */
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return sendUnauthorized(res);
    }
    if (!roles.includes(req.user.role)) {
      return sendForbidden(res, `Access denied. Required role(s): ${roles.join(', ')}`);
    }
    next();
  };
};

/**
 * Optional auth: Attach user if token present, but don't block if missing
 */
const optionalAuthenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      req.user = null;
      return next();
    }
    await authenticate(req, res, () => next());
  } catch {
    req.user = null;
    next();
  }
};

module.exports = { authenticate, authorize, optionalAuthenticate };