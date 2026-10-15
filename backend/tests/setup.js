const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

let mongoServer;

/**
 * Connect to in-memory MongoDB before all tests
 */
beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  const uri = mongoServer.getUri();

  // Set env vars required by the app
  process.env.JWT_SECRET = 'test-jwt-secret-key-for-unit-tests';
  process.env.JWT_EXPIRES_IN = '1d';
  process.env.NODE_ENV = 'test';
  process.env.UPLOAD_DIR = '/tmp/justicenow-test-uploads';

  await mongoose.connect(uri);

  // Register all models so populate never fails with MissingSchemaError
  require('../src/models/User.model');
  require('../src/models/Organization.model');
  require('../src/models/Case.model');
  require('../src/models/Evidence.model');
  require('../src/models/EvidenceRequest.model');
  require('../src/models/Notification.model');
  require('../src/models/AuditLog.model');
  require('../src/models/Consultation.model');
  require('../src/models/Advertisement.model');
});

/**
 * Clear all collections after each test
 */
afterEach(async () => {
  const collections = mongoose.connection.collections;
  for (const key in collections) {
    await collections[key].deleteMany({});
  }
});

/**
 * Disconnect and stop MongoDB after all tests
 */
afterAll(async () => {
  await mongoose.disconnect();
  if (mongoServer) {
    await mongoServer.stop();
  }
});
