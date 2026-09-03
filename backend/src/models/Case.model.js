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
    // Auto-generated public reference (e.g., JN-2026-00123)
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
      required: true,
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

    // Reporter — can be anonymous
    reportedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    isAnonymous: {
      type: Boolean,
      default: true,
    },

    // Assigned case officer
    assignedOfficer: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },

    // Linked NGO/organization
    assignedOrganization: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Organization',
      default: null,
    },

    // Evidence files
    evidence: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Evidence',
      },
    ],

    // Status history
    timeline: [timelineEventSchema],

    // Internal notes by officers (not visible to reporter)
    internalNotes: [
      {
        note: String,
        addedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
        addedAt: { type: Date, default: Date.now },
      },
    ],

    // Feedback visible to reporter
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

// Geospatial index for hotspot mapping
caseSchema.index({ 'location.coordinates': '2dsphere' });
// Text index for search
caseSchema.index({ title: 'text', description: 'text' });

module.exports = mongoose.model('Case', caseSchema);
