const { body, param, validationResult } = require('express-validator');
const { sendValidationError } = require('./response.util');

/**
 * Middleware to handle express-validator results
 */
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return sendValidationError(res, errors.array());
  }
  next();
};

/**
 * Common validation chains
 */
const caseValidators = {
  create: [
    body('title').trim().notEmpty().withMessage('Title is required').isLength({ max: 200 }),
    body('description').trim().notEmpty().withMessage('Description is required').isLength({ max: 5000 }),
    body('category').notEmpty().withMessage('Category is required'),
    body('incidentDate').isISO8601().withMessage('Incident date must be a valid date'),
    body('location.country').optional().isString(),
    validate,
  ],
  updateStatus: [
    param('id').isMongoId().withMessage('Invalid case ID'),
    body('status').notEmpty().withMessage('Status is required'),
    body('note').optional().isString(),
    validate,
  ],
};

const authValidators = {
  register: [
    body('email').isEmail().withMessage('Valid email is required').normalizeEmail(),
    body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
    body('province')
      .if(body('role').custom((val) => !val || val === 'citizen'))
      .trim()
      .notEmpty()
      .withMessage('Province is required for citizen registration'),
    body('district')
      .if(body('role').custom((val) => !val || val === 'citizen'))
      .trim()
      .notEmpty()
      .withMessage('District is required for citizen registration'),
    body('policeId')
      .if(body('role').equals('police_officer'))
      .trim()
      .notEmpty()
      .withMessage('Police ID is required for police officer registration'),
    body('lawyerId')
      .if(body('role').equals('lawyer'))
      .trim()
      .notEmpty()
      .withMessage('Lawyer ID is required for lawyer registration'),
    validate,
  ],
  login: [
    body('email').isEmail().withMessage('Valid email is required').normalizeEmail(),
    body('password').notEmpty().withMessage('Password is required'),
    validate,
  ],
};

const adminValidators = {
  updateStatus: [
    param('id').isMongoId().withMessage('Invalid user ID'),
    body('status')
      .isIn(['approved', 'rejected'])
      .withMessage('Status must be either approved or rejected'),
    validate,
  ],
};

module.exports = { validate, caseValidators, authValidators, adminValidators };
