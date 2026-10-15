const mongoose = require('mongoose');

const evidenceRequestSchema = new mongoose.Schema(
  {
    case: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Case',
      required: true,
    },

    requestedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },

    // What evidence/information is being requested
    description: {
      type: String,
      required: [true, 'Evidence request description is required'],
      maxlength: 2000,
    },

    // Why this evidence is needed
    reason: {
      type: String,
      default: '',
      maxlength: 1000,
    },

    // Instructions for the citizen
    instructions: {
      type: String,
      default: '',
      maxlength: 2000,
    },

    // Optional due date
    dueDate: {
      type: Date,
      default: null,
    },

    status: {
      type: String,
      enum: ['pending', 'submitted', 'under_review', 'fulfilled', 'cancelled'],
      default: 'pending',
    },

    // Evidence submitted in response to this request
    responseEvidence: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Evidence',
      },
    ],

    // Review notes by the officer
    reviewNotes: {
      type: String,
      default: '',
      maxlength: 2000,
    },

    reviewedAt: {
      type: Date,
      default: null,
    },

    isDeleted: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

// Index for efficient queries
evidenceRequestSchema.index({ case: 1, status: 1 });
evidenceRequestSchema.index({ requestedBy: 1, status: 1 });

module.exports = mongoose.model('EvidenceRequest', evidenceRequestSchema);
