const mongoose = require('mongoose');
require('dotenv').config();
const User = require('./src/models/User.model');

async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  const users = await User.find({ approvalStatus: 'pending' }).select('-passwordHash').lean();
  console.log('=== PENDING USERS IN DB ===');
  console.log(JSON.stringify(users, null, 2));
  await mongoose.disconnect();
}
run().catch(console.error);
