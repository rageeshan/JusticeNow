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
      enum: ['anonymous', 'citizen', 'ngo', 'legal_practitioner', 'officer', 'admin'],
      default: 'anonymous',
    },

    // For citizen accounts who choose to register
    passwordHash: {
      type: String,
      default: null,
    },

    profile: {
      fullName: { type: String, default: null },
      phone: { type: String, default: null },
      organization: { type: String, default: null },
      avatarUrl: { type: String, default: null },
    },

    isVerified: {
      type: Boolean,
      default: false,
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
userSchema.pre('save', async function (next) {
  if (!this.isModified('passwordHash') || !this.passwordHash) return next();
  this.passwordHash = await bcrypt.hash(this.passwordHash, 12);
  next();
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
