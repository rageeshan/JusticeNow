const mongoose = require('mongoose');

const advertisementSchema = new mongoose.Schema(
  {
    lawyer: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    lawyerName: {
      type: String,
      default: 'Attorney at Law',
      trim: true,
    },
    lawyerCourtNumber: {
      type: String,
      default: '',
      trim: true,
    },
    lawyerDistrict: {
      type: String,
      default: '',
      trim: true,
    },
    lawyerProvince: {
      type: String,
      default: '',
      trim: true,
    },
    imageUrl: {
      type: String,
      required: [true, 'Post image is required'],
    },
    caption: {
      type: String,
      default: '',
      trim: true,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Advertisement', advertisementSchema);
