const mongoose = require('mongoose');

const auditLogSchema = new mongoose.Schema(
  {
    action: {
      type: String,
      required: true,
      // e.g. 'case.created', 'case.status_changed', 'evidence.uploaded', 'user.login'
    },

    performedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },

    targetResource: {
      type: String,
      enum: ['Case', 'Evidence', 'User', 'Organization', 'System'],
      required: true,
    },

    targetId: {
      type: mongoose.Schema.Types.ObjectId,
      default: null,
    },

    // Snapshot of changes (before/after)
    metadata: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },

    ipAddress: {
      type: String,
      default: null,
    },

    userAgent: {
      type: String,
      default: null,
    },
  },
  {
    timestamps: true,
    // Audit logs are immutable — disable updates
    versionKey: false,
  }
);

// TTL: Keep audit logs for 5 years (157680000 seconds)
auditLogSchema.index({ createdAt: 1 }, { expireAfterSeconds: 157680000 });

module.exports = mongoose.model('AuditLog', auditLogSchema);
