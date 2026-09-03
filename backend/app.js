require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

const { initFirebase } = require('./src/config/firebase');
const authRoutes = require('./src/routes/auth.routes');
const caseRoutes = require('./src/routes/case.routes');
const legalAidRoutes = require('./src/routes/legalAid.routes');
const analyticsRoutes = require('./src/routes/analytics.routes');
const { errorHandler, notFound } = require('./src/middleware/error.middleware');

// Initialize Firebase Admin
initFirebase();

const app = express();

// ──────────────────────────────────────────────
// Security Middleware
// ──────────────────────────────────────────────
app.use(helmet());
app.use(
  cors({
    origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  })
);

// Global rate limiter: 100 requests per 15 minutes
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'Too many requests, please try again later.' },
});
app.use(limiter);

// ──────────────────────────────────────────────
// Request Parsing
// ──────────────────────────────────────────────
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// ──────────────────────────────────────────────
// Logging
// ──────────────────────────────────────────────
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

// ──────────────────────────────────────────────
// Static file serving (uploaded evidence)
// ──────────────────────────────────────────────
app.use('/uploads', express.static(process.env.UPLOAD_DIR || 'uploads'));

// ──────────────────────────────────────────────
// Health Check
// ──────────────────────────────────────────────
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    status: 'ok',
    environment: process.env.NODE_ENV,
    timestamp: new Date().toISOString(),
  });
});

// ──────────────────────────────────────────────
// API Routes
// ──────────────────────────────────────────────
app.use('/api/auth', authRoutes);
app.use('/api/cases', caseRoutes);
app.use('/api/legal-aid', legalAidRoutes);
app.use('/api/analytics', analyticsRoutes);

// ──────────────────────────────────────────────
// Error Handling (must be last)
// ──────────────────────────────────────────────
app.use(notFound);
app.use(errorHandler);

module.exports = app;
