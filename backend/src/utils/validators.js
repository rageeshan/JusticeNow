const { body, param, validationResult } = require('express-validator');
const { sendValidationError } = require('./response.util');

// ─────────────────────────────────────────────────────────────────────────────
//  Middleware: Run express-validator result check
// ─────────────────────────────────────────────────────────────────────────────

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return sendValidationError(res, errors.array());
  }
  next();
};

// ─────────────────────────────────────────────────────────────────────────────
//  Case Validators — Citizen Component
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Valid incident categories — must match Case.model.js enum exactly
 */
const VALID_CATEGORIES = [
  'police_brutality',
  'arbitrary_detention',
  'forced_displacement',
  'freedom_of_expression',
  'gender_based_violence',
  'labor_rights',
  'discrimination',
  'torture',
  'forced_disappearance',
  'extrajudicial_killing',
  'freedom_of_assembly',
  'right_to_fair_trial',
  'other',
];

const caseValidators = {
  /**
   * POST /api/cases — Create a new case report
   */
  create: [
    body('title')
      .trim()
      .notEmpty().withMessage('Incident title is required')
      .isLength({ min: 5, max: 200 }).withMessage('Title must be between 5 and 200 characters'),

    body('description')
      .trim()
      .notEmpty().withMessage('Description is required')
      .isLength({ min: 20, max: 5000 }).withMessage('Description must be at least 20 characters'),

    body('category')
      .notEmpty().withMessage('Incident category is required')
      .isIn(VALID_CATEGORIES).withMessage(`Category must be one of: ${VALID_CATEGORIES.join(', ')}`),

    body('incidentDate')
      .notEmpty().withMessage('Incident date is required')
      .isISO8601().withMessage('Incident date must be a valid ISO 8601 date')
      .custom((value) => {
        if (new Date(value) > new Date()) {
          throw new Error('Incident date cannot be in the future');
        }
        return true;
      }),

    // Location fields — all optional
    body('location.city').optional().trim().isString(),
    body('location.state').optional().trim().isString(),
    body('location.country').optional().trim().isString(),
    body('location.address').optional().trim().isString().isLength({ max: 500 }),

    // Contact info — only relevant for non-anonymous reporters, both optional
    body('contactName')
      .optional()
      .trim()
      .isString()
      .isLength({ max: 200 }).withMessage('Contact name must be under 200 characters'),

    body('contactEmail')
      .optional()
      .trim()
      .isEmail().withMessage('Contact email must be a valid email address')
      .normalizeEmail(),

    validate,
  ],

  /**
   * PATCH /api/cases/:id/status — Update case status (officer/admin)
   */
  updateStatus: [
    param('id').isMongoId().withMessage('Invalid case ID format'),

    body('status')
      .notEmpty().withMessage('Status is required')
      .isIn([
        'submitted',
        'under_review',
        'investigating',
        'evidence_requested',
        'referred_to_ngo',
        'legal_action_initiated',
        'resolved',
        'closed',
        'rejected',
      ]).withMessage('Invalid status value'),

    body('note')
      .optional()
      .trim()
      .isString()
      .isLength({ max: 1000 }).withMessage('Note must be under 1000 characters'),

    validate,
  ],
};

// ─────────────────────────────────────────────────────────────────────────────
//  Auth Validators — Citizen Authentication
// ─────────────────────────────────────────────────────────────────────────────

const authValidators = {
  register: [
    body('email')
      .isEmail().withMessage('A valid email address is required')
      .normalizeEmail(),
    body('password')
      .isLength({ min: 8 }).withMessage('Password must be at least 8 characters long'),
    validate,
  ],
  login: [
    body('email')
      .isEmail().withMessage('A valid email address is required')
      .normalizeEmail(),
    body('password')
      .notEmpty().withMessage('Password is required'),
    validate,
  ],
};

module.exports = { validate, caseValidators, authValidators };
