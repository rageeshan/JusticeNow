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
    body('reason').optional().isString(),
    validate,
  ],
};

const authValidators = {
  register: [
    body('email').isEmail().withMessage('Valid email is required').normalizeEmail(),
    body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
    body('fullName').optional().trim(),
    body('role')
      .optional()
      .isIn(['citizen', 'police_officer', 'lawyer', 'admin'])
      .withMessage('Invalid role specified'),
    body('phone').optional().trim(),
    body('nic').optional().trim(),
    body('gender')
      .optional()
      .isIn(['Male', 'Female', 'Other'])
      .withMessage('Gender must be Male, Female, or Other'),
    body('province').optional().trim(),
    body('district').optional().trim(),
    body('policeId').optional().trim(),
    body('courtNumber').optional().trim(),
    body('lawyerId').optional().trim(),
    body('certificateUrl').optional().trim(),
    body('aboutMe').optional().trim(),
    body('preferredLanguage')
      .optional()
      .isIn(['Sinhala', 'Tamil', 'English'])
      .withMessage('Preferred Language must be Sinhala, Tamil, or English'),
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
    body('reason').optional().trim(),
    validate,
  ],
};

module.exports = { validate, caseValidators, authValidators, adminValidators };
