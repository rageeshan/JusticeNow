const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    recipient: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    case: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Case',
      default: null,
    },
    title: {
      type: String,
      required: true,
      trim: true,
    },
    message: {
      type: String,
      required: true,
      trim: true,
    },
    type: {
      type: String,
      enum: [
        'awaiting_lawyer_selection',
        'waiting_for_lawyer_approval',
        'new_case_request',
        'case_approved_scheduled',
        'lawyer_declined',
        'case_rejected',
        'general',
      ],
      default: 'general',
    },
    actionRoute: {
      type: String,
      default: null,
    },
    actionText: {
      type: String,
      default: null,
    },
    isRead: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Notification', notificationSchema);
