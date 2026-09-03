const admin = require('firebase-admin');

const initFirebase = () => {
  if (admin.apps.length > 0) return;

  const projectId = process.env.FIREBASE_PROJECT_ID;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;

  // Skip Firebase init in development if placeholder credentials are present
  if (
    !projectId ||
    projectId === 'your-firebase-project-id' ||
    !privateKey ||
    privateKey.includes('YOUR_PRIVATE_KEY')
  ) {
    console.warn(
      '⚠️  Firebase Admin: No valid credentials found. Firebase auth routes will be unavailable.\n' +
      '   → Update FIREBASE_* values in .env to enable Firebase authentication.'
    );
    return;
  }

  try {
    admin.initializeApp({
      credential: admin.credential.cert({ projectId, clientEmail, privateKey }),
    });
    console.log('✅ Firebase Admin initialized');
  } catch (err) {
    console.error('❌ Firebase Admin initialization failed:', err.message);
  }
};

module.exports = { admin, initFirebase };
