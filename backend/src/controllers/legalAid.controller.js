const User = require('../models/User.model');
const Consultation = require('../models/Consultation.model');

// 1. Lawyer / Legal Aid Registration
exports.registerCounsel = async (req, res) => {
  try {
    const { fullName, email, specialization, district, barId, password } = req.body;
    
    let user = await User.findOne({ email });
    if (user) {
      return res.status(400).json({ success: false, message: 'Email address already registered' });
    }

    user = new User({
      fullName,
      email,
      password, // Note: Production වලදී bcrypt මඟින් hash කළ යුතුය
      role: 'lawyer',
      specialization,
      district,
      barId,
      isVerified: false
    });

    await user.save();
    res.status(201).json({ success: true, message: 'Counsel registered successfully for verification', data: user });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// 2. Counsel Login
exports.loginCounsel = async (req, res) => {
  try {
    const { emailOrBarId, password } = req.body;
    
    const user = await User.findOne({
      $or: [{ email: emailOrBarId }, { barId: emailOrBarId }]
    });

    if (!user || user.password !== password) {
      return res.status(401).json({ success: false, message: 'Invalid Credentials' });
    }

    res.status(200).json({ success: true, message: 'Login successful', data: user });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// 3. Get Dashboard Stats & Consultation Requests
exports.getConsultationRequests = async (req, res) => {
  try {
    const requests = await Consultation.find().sort({ createdAt: -1 });
    const pendingCount = await Consultation.countDocuments({ status: 'Pending' });
    const acceptedCount = await Consultation.countDocuments({ status: 'Accepted' });

    res.status(200).json({
      success: true,
      stats: { pendingCount, acceptedCount },
      data: requests
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// 4. Update Consultation Request Status (Accept, Reject, Reschedule)
exports.updateConsultationStatus = async (req, res) => {
  try {
    const { requestId } = req.params;
    const { status } = req.body;

    const consultation = await Consultation.findByIdAndUpdate(
      requestId,
      { status },
      { new: true }
    );

    res.status(200).json({ success: true, message: `Status updated to ${status}`, data: consultation });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// 5. Update Profile & Availability Slots
exports.updateAvailability = async (req, res) => {
  try {
    const { userId, availabilityDays, activeTimeSlots } = req.body;

    const user = await User.findByIdAndUpdate(
      userId,
      { availabilityDays, activeTimeSlots },
      { new: true }
    );

    res.status(200).json({ success: true, message: 'Availability updated successfully', data: user });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};