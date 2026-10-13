const express = require('express');
const router = express.Router();
const translateController = require('../controllers/translate.controller');
const { optionalAuthenticate } = require('../middleware/auth.middleware');

// POST /api/translate
router.post('/', optionalAuthenticate, translateController.translate);

module.exports = router;
