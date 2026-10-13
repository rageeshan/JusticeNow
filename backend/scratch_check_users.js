const mongoose = require('mongoose');
require('dotenv').config({ path: 'c:/Users/Ashen/Desktop/Mobile_App/JusticeNow/backend/.env' });
const User = require('c:/Users/Ashen/Desktop/Mobile_App/JusticeNow/backend/src/models/User.model');

async function check() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('Connected to MongoDB');
  const users = await User.find({}).lean();
  console.log(`Total users in DB: ${users.length}`);
  users.forEach(u => {
    console.log({
      _id: u._id,
      email: u.email,
      role: u.role,
      approvalStatus: u.approvalStatus,
      fullName: u.profile?.fullName,
      createdAt: u.createdAt
    });
  });
  await mongoose.disconnect();
}

check().catch(console.error);
