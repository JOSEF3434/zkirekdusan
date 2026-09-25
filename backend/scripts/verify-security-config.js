#!/usr/bin/env node

/**
 * Security Configuration Verification Script
 * 
 * Verifies that all security-sensitive environment variables are properly configured.
 * Run this before deploying to production.
 * 
 * Usage: node scripts/verify-security-config.js
 */

const fs = require('fs');
const path = require('path');

console.log('\n🔍 Security Configuration Verification\n');
console.log('='.repeat(70));

// Load .env file
const envPath = path.join(__dirname, '..', '.env');
let envContent;

try {
  envContent = fs.readFileSync(envPath, 'utf8');
} catch (error) {
  console.error('\n❌ ERROR: .env file not found at', envPath);
  console.error('   Create a .env file based on .env.example\n');
  process.exit(1);
}

// Parse .env file
const envVars = {};
envContent.split('\n').forEach(line => {
  const trimmed = line.trim();
  if (trimmed && !trimmed.startsWith('#')) {
    const [key, ...valueParts] = trimmed.split('=');
    if (key) {
      envVars[key.trim()] = valueParts.join('=').trim().replace(/^["']|["']$/g, '');
    }
  }
});

// Security checks
const checks = [];

// Check 1: JWT Secrets
function checkJWTSecrets() {
  const accessSecret = envVars.JWT_ACCESS_SECRET || '';
  const refreshSecret = envVars.JWT_REFRESH_SECRET || '';

  const weakSecrets = [
    'your_super_secret_access_key',
    'your_super_secret_refresh_key',
    'secret',
    'password',
    'changeme',
    '123456',
  ];

  let status = 'pass';
  const issues = [];

  if (accessSecret.length < 32) {
    status = 'fail';
    issues.push(`JWT_ACCESS_SECRET is too short (${accessSecret.length} chars, min 32 required)`);
  }

  if (refreshSecret.length < 32) {
    status = 'fail';
    issues.push(`JWT_REFRESH_SECRET is too short (${refreshSecret.length} chars, min 32 required)`);
  }

  if (weakSecrets.some(weak => accessSecret.toLowerCase().includes(weak))) {
    status = 'fail';
    issues.push('JWT_ACCESS_SECRET contains weak/placeholder text');
  }

  if (weakSecrets.some(weak => refreshSecret.toLowerCase().includes(weak))) {
    status = 'fail';
    issues.push('JWT_REFRESH_SECRET contains weak/placeholder text');
  }

  if (accessSecret === refreshSecret) {
    status = 'fail';
    issues.push('JWT_ACCESS_SECRET and JWT_REFRESH_SECRET must be different');
  }

  checks.push({
    name: 'JWT Secrets',
    status,
    issues,
  });
}

// Check 2: JWT Expiration
function checkJWTExpiration() {
  const accessExpires = envVars.JWT_ACCESS_EXPIRES || '';
  const refreshExpires = envVars.JWT_REFRESH_EXPIRES || '';

  let status = 'pass';
  const issues = [];

  // Access token should be short-lived (15m recommended)
  if (accessExpires === '7d') {
    status = 'warn';
    issues.push('JWT_ACCESS_EXPIRES is set to 7 days (recommended: 15m for security)');
  }

  // Refresh token can be longer (7d is acceptable)
  if (!refreshExpires || refreshExpires === '') {
    status = 'fail';
    issues.push('JWT_REFRESH_EXPIRES is not set');
  }

  checks.push({
    name: 'JWT Expiration',
    status,
    issues,
  });
}

// Check 3: CORS Configuration
function checkCORS() {
  const corsOrigins = envVars.CORS_ORIGINS || '';

  let status = 'pass';
  const issues = [];

  if (corsOrigins === '*') {
    status = 'fail';
    issues.push('CORS_ORIGINS is set to wildcard (*) - allows any origin (major security risk)');
  }

  if (!corsOrigins || corsOrigins.trim() === '') {
    status = 'fail';
    issues.push('CORS_ORIGINS is not set');
  }

  if (corsOrigins.includes('localhost') && envVars.NODE_ENV === 'production') {
    status = 'warn';
    issues.push('CORS_ORIGINS includes localhost in production environment');
  }

  checks.push({
    name: 'CORS Configuration',
    status,
    issues,
  });
}

// Check 4: Database URL
function checkDatabaseURL() {
  const databaseUrl = envVars.DATABASE_URL || '';

  let status = 'pass';
  const issues = [];

  if (!databaseUrl) {
    status = 'fail';
    issues.push('DATABASE_URL is not set');
  }

  if (!databaseUrl.includes('sslmode=require')) {
    status = 'warn';
    issues.push('DATABASE_URL does not enforce SSL (sslmode=require missing)');
  }

  if (databaseUrl.includes('localhost') && envVars.NODE_ENV === 'production') {
    status = 'warn';
    issues.push('DATABASE_URL points to localhost in production');
  }

  checks.push({
    name: 'Database Configuration',
    status,
    issues,
  });
}

// Check 5: Cloudinary Credentials
function checkCloudinary() {
  const cloudName = envVars.CLOUDINARY_CLOUD_NAME || '';
  const apiKey = envVars.CLOUDINARY_API_KEY || '';
  const apiSecret = envVars.CLOUDINARY_API_SECRET || '';

  let status = 'pass';
  const issues = [];

  if (!cloudName || cloudName.includes('your_cloud_name')) {
    status = 'fail';
    issues.push('CLOUDINARY_CLOUD_NAME is not properly configured');
  }

  if (!apiKey || apiKey.includes('your_api_key')) {
    status = 'fail';
    issues.push('CLOUDINARY_API_KEY is not properly configured');
  }

  if (!apiSecret || apiSecret.includes('your_api_secret') || apiSecret.length < 20) {
    status = 'fail';
    issues.push('CLOUDINARY_API_SECRET is not properly configured or too short');
  }

  checks.push({
    name: 'Cloudinary Credentials',
    status,
    issues,
  });
}

// Check 6: Firebase Service Account
function checkFirebase() {
  const fcmJson = envVars.FCM_SERVICE_ACCOUNT_JSON || '';

  let status = 'pass';
  const issues = [];

  if (!fcmJson) {
    status = 'fail';
    issues.push('FCM_SERVICE_ACCOUNT_JSON is not set');
    checks.push({ name: 'Firebase Configuration', status, issues });
    return;
  }

  try {
    const serviceAccount = JSON.parse(fcmJson);

    if (!serviceAccount.private_key || !serviceAccount.client_email) {
      status = 'fail';
      issues.push('FCM_SERVICE_ACCOUNT_JSON is missing required fields');
    }

    if (serviceAccount.private_key.includes('YOUR_PRIVATE_KEY')) {
      status = 'fail';
      issues.push('FCM_SERVICE_ACCOUNT_JSON contains placeholder values');
    }
  } catch (error) {
    status = 'fail';
    issues.push('FCM_SERVICE_ACCOUNT_JSON is not valid JSON');
  }

  checks.push({
    name: 'Firebase Configuration',
    status,
    issues,
  });
}

// Check 7: Node Environment
function checkNodeEnv() {
  const nodeEnv = envVars.NODE_ENV || '';

  let status = 'pass';
  const issues = [];

  if (!nodeEnv) {
    status = 'warn';
    issues.push('NODE_ENV is not set (defaults to development)');
  }

  if (nodeEnv === 'production' && envVars.APP_URL?.includes('localhost')) {
    status = 'warn';
    issues.push('NODE_ENV is production but APP_URL includes localhost');
  }

  checks.push({
    name: 'Environment Configuration',
    status,
    issues,
  });
}

// Check 8: Placeholder Detection
function checkPlaceholders() {
  const placeholders = [
    'REPLACE_WITH',
    'your-domain',
    'your_super_secret',
    'changeme',
    'localhost:3000',
  ];

  let status = 'pass';
  const issues = [];

  Object.entries(envVars).forEach(([key, value]) => {
    placeholders.forEach(placeholder => {
      if (value.toLowerCase().includes(placeholder.toLowerCase())) {
        status = 'fail';
        issues.push(`${key} contains placeholder value: "${placeholder}"`);
      }
    });
  });

  checks.push({
    name: 'Placeholder Detection',
    status,
    issues,
  });
}

// Run all checks
checkJWTSecrets();
checkJWTExpiration();
checkCORS();
checkDatabaseURL();
checkCloudinary();
checkFirebase();
checkNodeEnv();
checkPlaceholders();

// Display results
console.log('\n');

let hasFailures = false;
let hasWarnings = false;

checks.forEach(check => {
  const icon = check.status === 'pass' ? '✅' : check.status === 'warn' ? '⚠️' : '❌';
  console.log(`${icon} ${check.name}: ${check.status.toUpperCase()}`);

  if (check.issues.length > 0) {
    check.issues.forEach(issue => {
      console.log(`   └─ ${issue}`);
    });
  }

  if (check.status === 'fail') hasFailures = true;
  if (check.status === 'warn') hasWarnings = true;

  console.log('');
});

console.log('='.repeat(70));
console.log('\n📊 Summary:\n');

const passCount = checks.filter(c => c.status === 'pass').length;
const warnCount = checks.filter(c => c.status === 'warn').length;
const failCount = checks.filter(c => c.status === 'fail').length;

console.log(`   ✅ Passed: ${passCount}`);
console.log(`   ⚠️  Warnings: ${warnCount}`);
console.log(`   ❌ Failed: ${failCount}`);
console.log('');

// Exit code
if (hasFailures) {
  console.log('❌ SECURITY VERIFICATION FAILED\n');
  console.log('   Action Required: Fix all failed checks before deploying to production.');
  console.log('   See docs/SECURITY_REMEDIATION_GUIDE.md for detailed instructions.\n');
  process.exit(1);
} else if (hasWarnings) {
  console.log('⚠️  SECURITY VERIFICATION PASSED WITH WARNINGS\n');
  console.log('   Review warnings and address them if deploying to production.\n');
  process.exit(0);
} else {
  console.log('✅ SECURITY VERIFICATION PASSED\n');
  console.log('   All security checks passed. Configuration looks good!\n');
  process.exit(0);
}
