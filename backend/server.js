require('dotenv').config();
const app = require('./app');
const connectDB = require('./src/config/db');

const PORT = process.env.PORT || 3000;

const startServer = async () => {
  try {
    await connectDB();
    app.listen(PORT, () => {
      console.log('');
      console.log('  ⚖️  JusticeNow API');
      console.log(`  🚀 Server running at http://localhost:${PORT}`);
      console.log(`  🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log(`  📋 Health check: http://localhost:${PORT}/api/health`);
      console.log('');
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error.message);
    process.exit(1);
  }
};

startServer();
