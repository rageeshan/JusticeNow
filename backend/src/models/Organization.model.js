const mongoose = require('mongoose');

const organizationSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Organization name is required'],
      trim: true,
    },

    type: {
      type: String,
      enum: ['ngo', 'legal_firm', 'law_clinic', 'government_body', 'other'],
      required: true,
    },

    description: {
      type: String,
      maxlength: 2000,
      default: '',
    },

    specializations: [
      {
        type: String,
        enum: [
          'arbitrary_detention',
          'torture',
          'forced_disappearance',
          'extrajudicial_killing',
          'discrimination',
          'freedom_of_expression',
          'freedom_of_assembly',
          'right_to_fair_trial',
          'other',
        ],
      },
    ],

    contact: {
      email: { type: String, default: null },
      phone: { type: String, default: null },
      website: { type: String, default: null },
      address: { type: String, default: null },
    },

    location: {
      city: { type: String, default: null },
      state: { type: String, default: null },
      country: { type: String, default: null },
    },

    // Verified by admin
    isVerified: {
      type: Boolean,
      default: false,
    },

    isActive: {
      type: Boolean,
      default: true,
    },

    logoUrl: {
      type: String,
      default: null,
    },

    // Staff members linked to this org
    members: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
    ],

    casesHandled: {
      type: Number,
      default: 0,
    },
  },
  {
    timestamps: true,
  }
);

// Text search
organizationSchema.index({ name: 'text', description: 'text' });

module.exports = mongoose.model('Organization', organizationSchema);
