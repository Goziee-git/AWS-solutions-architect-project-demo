#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

console.log('🚀 Starting AWS MongoDB Backend Application...\n');

// Check if .env file exists
const envPath = path.join(__dirname, '.env');
if (!fs.existsSync(envPath)) {
  console.error('❌ Error: .env file not found!');
  console.log('Please create a .env file based on .env.example');
  process.exit(1);
}

// Load environment variables
require('dotenv').config();

// Check required environment variables
const requiredEnvVars = ['JWT_SECRET', 'MONGODB_URI'];
const missingEnvVars = requiredEnvVars.filter(envVar => !process.env[envVar]);

if (missingEnvVars.length > 0) {
  console.error('❌ Error: Missing required environment variables:');
  missingEnvVars.forEach(envVar => console.log(`  - ${envVar}`));
  process.exit(1);
}

console.log('✅ Environment variables loaded successfully');
console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
console.log(`🔌 Port: ${process.env.PORT || 5000}`);
console.log(`🗄️  Database: ${process.env.MONGODB_URI}`);
console.log(`🔐 JWT configured with ${process.env.JWT_EXPIRE || '7d'} expiration`);
console.log('');

// Start the server
require('./server.js');
