const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const { authenticate } = require('../middleware/auth.middleware');
const { authValidators } = require('../utils/validators');

// POST /api/auth/anonymous   — No auth required
router.post('/anonymous', authController.anonymousLogin);

// POST /api/auth/register    — No auth required
router.post('/register', authValidators.register, authController.register);

// POST /api/auth/login       — No auth required
router.post('/login', authValidators.login, authController.login);

// POST /api/auth/firebase    — No auth required (provides Firebase ID token)
router.post('/firebase', authController.firebaseAuth);

// GET  /api/auth/me          — Requires auth
router.get('/me', authenticate, authController.getMe);

module.exports = router;
