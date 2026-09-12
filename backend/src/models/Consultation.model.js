const mongoose = require('mongoose');

const consultationSchema = new mongoose.Schema({
  citizenName: { type: String, required: true },
  counselId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  category: { type: String, required: true },
  requestedDate: { type: String, required: true },
  caseDescription: { type: String, required: true },
  status: { 
    type: String, 
    enum: ['Pending', 'Accepted', 'Rescheduled', 'Completed', 'Rejected'], 
    default: 'Pending' 
  },
  translationLanguage: { type: String, default: 'EN' }
}, { timestamps: true });

module.exports = mongoose.model('Consultation', consultationSchema);