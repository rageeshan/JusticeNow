const mongoose = require('mongoose');

const consultationSchema = new mongoose.Schema(
  {
    citizenName: { type: String, required: true },
    citizenId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    counselId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    caseId: { type: mongoose.Schema.Types.ObjectId, ref: 'Case' },
    category: { type: String, default: 'General' },
    requestedDate: { type: String, default: () => new Date().toISOString() },
    caseDescription: { type: String, default: '' },
    preferredContactMethod: { type: String, enum: ['Call', 'Email', 'In-app', null], default: 'In-app' },
    shortMessage: { type: String, default: '' },
    status: {
      type: String,
      enum: ['Pending', 'Waiting for Lawyer Approval', 'Accepted', 'Rescheduled', 'Completed', 'Rejected'],
      default: 'Waiting for Lawyer Approval',
    },
    translationLanguage: { type: String, default: 'EN' },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Consultation', consultationSchema);