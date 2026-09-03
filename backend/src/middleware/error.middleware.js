const { sendError } = require('../utils/response.util');

/**
 * Global error handling middleware
 * Must be the last middleware registered in app.js
 */
const errorHandler = (err, req, res, next) => {
  console.error('❌ Unhandled Error:', err);

  // Mongoose validation error
  if (err.name === 'ValidationError') {
    const errors = Object.values(err.errors).map((e) => ({
      field: e.path,
      message: e.message,
    }));
    return sendError(res, 'Validation failed', 422, errors);
  }

  // Mongoose duplicate key error
  if (err.code === 11000) {
    const field = Object.keys(err.keyValue)[0];
    return sendError(res, `${field} already exists`, 409);
  }

  // Mongoose cast error (invalid ObjectId)
  if (err.name === 'CastError') {
    return sendError(res, `Invalid ${err.path}: ${err.value}`, 400);
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    return sendError(res, 'Invalid token', 401);
  }
  if (err.name === 'TokenExpiredError') {
    return sendError(res, 'Token expired', 401);
  }

  // Multer file size error
  if (err.code === 'LIMIT_FILE_SIZE') {
    return sendError(
      res,
      `File too large. Max size: ${process.env.MAX_FILE_SIZE_MB || 50}MB`,
      413
    );
  }

  // Generic server error
  const statusCode = err.statusCode || 500;
  const message =
    process.env.NODE_ENV === 'production' ? 'Internal server error' : err.message;

  return sendError(res, message, statusCode);
};

/**
 * 404 handler for unmatched routes
 */
const notFound = (req, res, next) => {
  sendError(res, `Route not found: ${req.method} ${req.originalUrl}`, 404);
};

module.exports = { errorHandler, notFound };
