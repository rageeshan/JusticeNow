const User = require('../models/User.model');
const Consultation = require('../models/Consultation.model');
const { generateToken } = require('../services/auth.service');
const AuditLog = require('../models/AuditLog.model');

// ─────────────────────────────────────────────────────────────
// 1. Lawyer / Legal Aid Registration
// ─────────────────────────────────────────────────────────────
exports.registerCounsel = async (req, res) => {
  try {
    const { fullName, email, password, organization, phone } = req.body;

    // Check for duplicate email
    const existing = await User.findOne({ email });
    if (existing) {
      return res.status(409).json({ success: false, message: 'Email address already registered' });
    }

    // Use 'legal_practitioner' — the correct enum value in the User model
    const user = new User({
      email,
      passwordHash: password, // pre-save hook in User.model.js will bcrypt-hash this
      role: 'legal_practitioner',
      isVerified: false,
      profile: {
        fullName: fullName || null,
        phone: phone || null,
        organization: organization || null,
      },
    });

    await user.save();

    await AuditLog.create({
      action: 'user.registered',
      performedBy: user._id,
      targetResource: 'User',
      targetId: user._id,
    });

    const token = generateToken(user._id);

    res.status(201).json({
      success: true,
      message: 'Counsel registered successfully. Pending admin verification.',
      data: { user, token },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ─────────────────────────────────────────────────────────────
// 2. Counsel Login
// ─────────────────────────────────────────────────────────────
exports.loginCounsel = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find by email for legal_practitioner accounts
    const user = await User.findOne({ email, role: 'legal_practitioner' });

    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    if (!user.passwordHash) {
      return res.status(401).json({ success: false, message: 'No password set for this account' });
    }

    // Use bcrypt comparePassword method defined on the User model
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    if (!user.isActive) {
      return res.status(403).json({ success: false, message: 'Account deactivated' });
    }

    user.lastLogin = new Date();
    await user.save();

    const token = generateToken(user._id);

    res.status(200).json({ success: true, message: 'Login successful', data: { user, token } });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ─────────────────────────────────────────────────────────────
// 3. Get Dashboard Stats & Consultation Requests
// ─────────────────────────────────────────────────────────────
exports.getConsultationRequests = async (req, res) => {
  try {
    const requests = await Consultation.find()
      .sort({ createdAt: -1 })
      .populate('counselId', 'profile.fullName email');

    const pendingCount = await Consultation.countDocuments({ status: 'Pending' });
    const acceptedCount = await Consultation.countDocuments({ status: 'Accepted' });

    res.status(200).json({
      success: true,
      stats: { pendingCount, acceptedCount },
      data: requests,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ─────────────────────────────────────────────────────────────
// 4. Update Consultation Request Status (Accept, Reject, Reschedule)
// ─────────────────────────────────────────────────────────────
exports.updateConsultationStatus = async (req, res) => {
  try {
    const { requestId } = req.params;
    const { status } = req.body;

    const consultation = await Consultation.findByIdAndUpdate(
      requestId,
      { status },
      { new: true, runValidators: true }
    );

    if (!consultation) {
      return res.status(404).json({ success: false, message: 'Consultation request not found' });
    }

    res.status(200).json({
      success: true,
      message: `Status updated to ${status}`,
      data: consultation,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ─────────────────────────────────────────────────────────────
// 5. Update Profile (fullName, phone, organization)
//    Note: availabilityDays and activeTimeSlots are not in the
//    User schema — store them in profile.organization or extend
//    the schema separately if needed.
// ─────────────────────────────────────────────────────────────
exports.updateAvailability = async (req, res) => {
  try {
    const { userId, fullName, phone, organization } = req.body;

    // Only update profile sub-fields that exist in the User schema
    const user = await User.findByIdAndUpdate(
      userId,
      {
        'profile.fullName': fullName,
        'profile.phone': phone,
        'profile.organization': organization,
      },
      { new: true, runValidators: true }
    );

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    res.status(200).json({ success: true, message: 'Profile updated successfully', data: user });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};