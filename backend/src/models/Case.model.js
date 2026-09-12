const mongoose = require('mongoose');

const timelineEventSchema = new mongoose.Schema(
  {
    status: {
      type: String,
      required: true,
    },
    note: {
      type: String,
      default: '',
    },
    updatedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
  },
  { timestamps: true }
);

const caseSchema = new mongoose.Schema(
  {
    // Auto-generated public reference (e.g., CASE-2026-8942)
    referenceNumber: {
      type: String,
      unique: true,
      required: true,
    },

    title: {
      type: String,
      required: [true, 'Case title is required'],
      trim: true,
      maxlength: 200,
    },

    description: {
      type: String,
      required: [true, 'Case description is required'],
      maxlength: 5000,
    },

    category: {
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
      required: true,
    },

    incidentDate: {
      type: Date,
      default: Date.now,
    },

    location: {
      address: { type: String, default: null },
      city: { type: String, default: null },
      state: { type: String, default: null },
      country: { type: String, default: null },
      coordinates: {
        type: { type: String, enum: ['Point'], default: 'Point' },
        coordinates: { type: [Number], default: [0, 0] }, // [lng, lat]
      },
    },

    status: {
      type: String,
      enum: [
        'submitted',
        'under_review',
        'investigating',
        'evidence_requested',
        'referred_to_ngo',
        'legal_action_initiated',
        'resolved',
        'closed',
        'rejected',
      ],
      default: 'submitted',
    },

    priority: {
      type: String,
      enum: ['low', 'medium', 'high', 'critical'],
      default: 'medium',
    },

    // Reporter — can be anonymous or registered user
    reportedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    isAnonymous: {
      type: Boolean,
      default: true,
    },

    assignedOfficer: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },

    assignedOrganization: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Organization',
      default: null,
    },

    evidence: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Evidence',
      },
    ],

    timeline: [timelineEventSchema],

    internalNotes: [
      {
        note: String,
        addedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
        addedAt: { type: Date, default: Date.now },
      },
    ],

    publicUpdates: [
      {
        message: String,
        sentAt: { type: Date, default: Date.now },
      },
    ],

    isDeleted: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

// Auto-generate unique Reference Number before validation
caseSchema.pre('validate', function (next) {
  if (!this.referenceNumber) {
    const randomSuffix = Math.floor(1000 + Math.random() * 9000);
    const year = new Date().getFullYear();
    this.referenceNumber = `CASE-${year}-${randomSuffix}`;
  }
  next();
});

// Indexes
caseSchema.index({ 'location.coordinates': '2dsphere' });
caseSchema.index({ title: 'text', description: 'text' });

module.exports = mongoose.model('Case', caseSchema);