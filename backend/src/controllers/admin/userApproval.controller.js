const User = require('../../models/User.model');

// GET /api/admin/pending-users
exports.getPendingUsers = async (req, res) => {
  try {
    const { role } = req.query;

    const query = { verificationStatus: 'pending' };
    if (role) {
      query.role = role;
    } else {
      query.role = { $in: ['police_officer', 'officer', 'lawyer', 'legal_practitioner', 'ngo'] };
    }

    const pendingUsers = await User.find(query).sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: pendingUsers.length,
      data: pendingUsers,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PATCH /api/admin/users/:userId/approve
exports.approveUser = async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findByIdAndUpdate(
      userId,
      {
        isVerified: true,
        verificationStatus: 'approved',
        rejectionReason: null,
      },
      { new: true, runValidators: true }
    );

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    res.status(200).json({
      success: true,
      message: 'User account approved successfully',
      data: user,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PATCH /api/admin/users/:userId/reject
exports.rejectUser = async (req, res) => {
  try {
    const { userId } = req.params;
    const { reason } = req.body;

    const user = await User.findByIdAndUpdate(
      userId,
      {
        isVerified: false,
        verificationStatus: 'rejected',
        rejectionReason: reason || 'Credentials could not be verified.',
      },
      { new: true, runValidators: true }
    );

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    res.status(200).json({
      success: true,
      message: 'User request rejected',
      data: user,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};