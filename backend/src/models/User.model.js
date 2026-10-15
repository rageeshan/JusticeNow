const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    // For anonymous citizens — auto-generated alias
    alias: {
      type: String,
      default: null,
    },

    // For registered users (NGOs/Officers/Admins)
    email: {
      type: String,
      lowercase: true,
      trim: true,
      default: null,
    },

    // Firebase UID for authenticated staff accounts
    firebaseUid: {
      type: String,
      default: null,
    },

    role: {
      type: String,
      enum: [
        'anonymous',
        'citizen',
        'lawyer',
        'police_officer',
        'admin',
      ],
      default: 'anonymous',
    },

    // For citizen accounts who choose to register
    passwordHash: {
      type: String,
      default: null,
    },

    profile: {
      // Common profile fields
      fullName: { type: String, default: null, trim: true },
      phone: { type: String, default: null, trim: true },
      nic: { type: String, default: null, trim: true },
      gender: { type: String, enum: ['Male', 'Female', 'Other', null], default: null },
      age: { type: Number, default: null },
      dob: { type: Date, default: null },
      province: { type: String, default: null, trim: true },
      district: { type: String, default: null, trim: true },

      // Role-specific fields: Lawyer
      courtNumber: { type: String, default: null, trim: true },
      lawyerId: { type: String, default: null, trim: true },
      certificateUrl: { type: String, default: null }, // Supreme Court Certificate photo or PDF

      // Role-specific fields: Police Officer
      policeId: { type: String, default: null, trim: true },

      // Role-specific fields: Professional details (Lawyer & Police Officer)
      aboutMe: { type: String, default: null, trim: true },
      preferredLanguage: {
        type: String,
        enum: ['Sinhala', 'Tamil', 'English', null],
        default: null,
      },

      // Existing/organization fields
      organization: { type: String, default: null },
      avatarUrl: { type: String, default: null },

      // Lawyer availability schedule (weekly slots)
      availability: {
        type: mongoose.Schema.Types.Mixed,
        default: null,
      },
    },

    approvalStatus: {
      type: String,
      enum: ['pending', 'approved', 'rejected'],
      default: function () {
        return ['police_officer', 'lawyer'].includes(this.role) ? 'pending' : 'approved';
      },
    },

    rejectionReason: {
      type: String,
      default: null,
      trim: true,
    },

    reviewedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },

    reviewedAt: {
      type: Date,
      default: null,
    },

    isVerified: {
      type: Boolean,
      default: false,
    },

    isAnonymous: {
      type: Boolean,
      default: false,
    },

    // Explicit approval lifecycle tracking
    verificationStatus: {
      type: String,
      enum: ['pending', 'approved', 'rejected'],
      default: 'pending',
    },

    isActive: {
      type: Boolean,
      default: true,
    },

    lastLogin: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Hash password before saving
userSchema.pre('save', async function () {
  if (!this.isModified('passwordHash') || !this.passwordHash) return;
  this.passwordHash = await bcrypt.hash(this.passwordHash, 12);
});

// Compare password
userSchema.methods.comparePassword = async function (candidatePassword) {
  return bcrypt.compare(candidatePassword, this.passwordHash);
};

// Never expose password hash
userSchema.methods.toJSON = function () {
  const obj = this.toObject();
  delete obj.passwordHash;
  return obj;
};

module.exports = mongoose.model('User', userSchema);