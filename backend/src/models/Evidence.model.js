const mongoose = require('mongoose');

const evidenceSchema = new mongoose.Schema(
  {
    case: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Case',
      required: true,
    },

    uploadedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },

    fileType: {
      type: String,
      enum: ['image', 'video', 'audio', 'document', 'other'],
      required: true,
    },

    originalName: {
      type: String,
      required: true,
    },

    storedName: {
      type: String,
      required: true,
    },

    mimeType: {
      type: String,
      required: true,
    },

    sizeBytes: {
      type: Number,
      required: true,
    },

    // Path or URL (local or cloud storage)
    storagePath: {
      type: String,
      required: true,
    },

    description: {
      type: String,
      default: '',
      maxlength: 1000,
    },

    // Chain of custody — who handled this evidence
    custodyLog: [
      {
        action: {
          type: String,
          enum: ['uploaded', 'accessed', 'transferred', 'reviewed', 'sealed'],
          required: true,
        },
        performedBy: {
          type: mongoose.Schema.Types.ObjectId,
          ref: 'User',
        },
        performedAt: {
          type: Date,
          default: Date.now,
        },
        note: {
          type: String,
          default: '',
        },
      },
    ],

    // SHA-256 hash for integrity verification
    integrityHash: {
      type: String,
      default: null,
    },

    isSealed: {
      type: Boolean,
      default: false,
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

module.exports = mongoose.model('Evidence', evidenceSchema);
