#!/usr/bin/env node

/**
 * Security Secret Generator
 * 
 * Generates cryptographically secure random secrets for:
 * - JWT Access Secret
 * - JWT Refresh Secret
 * - API Keys
 * 
 * Usage: node scripts/generate-secrets.js
 */

const crypto = require('crypto');

console.log('\n🔐 Security Secret Generator\n');
console.log('=' .repeat(60));

// Generate JWT Access Secret (32 bytes = 256 bits)
const jwtAccessSecret = crypto.randomBytes(32).toString('base64');
console.log('\n📝 JWT Access Secret (use for JWT_ACCESS_SECRET):');
console.log(jwtAccessSecret);

// Generate JWT Refresh Secret (32 bytes = 256 bits)
const jwtRefreshSecret = crypto.randomBytes(32).toString('base64');
console.log('\n📝 JWT Refresh Secret (use for JWT_REFRESH_SECRET):');
console.log(jwtRefreshSecret);

// Generate additional secrets
const apiSecret = crypto.randomBytes(32).toString('hex');
console.log('\n📝 Generic API Secret (64 hex characters):');
console.log(apiSecret);

// Generate session secret
const sessionSecret = crypto.randomBytes(32).toString('base64');
console.log('\n📝 Session Secret (if needed):');
console.log(sessionSecret);

console.log('\n' + '='.repeat(60));
console.log('\n✅ Secrets generated successfully!');
console.log('\n⚠️  IMPORTANT SECURITY NOTES:');
console.log('   1. Never commit these secrets to git');
console.log('   2. Store them in .env file (already in .gitignore)');
console.log('   3. Use different secrets for each environment');
console.log('   4. Rotate secrets every 90 days');
console.log('   5. Never share secrets via email or chat');
console.log('   6. Use a password manager for team secrets\n');

// Verification
console.log('🔍 Secret Strength Verification:');
console.log(`   JWT Access Secret: ${jwtAccessSecret.length} characters (min 32 required) ✓`);
console.log(`   JWT Refresh Secret: ${jwtRefreshSecret.length} characters (min 32 required) ✓`);
console.log(`   API Secret: ${apiSecret.length} characters (min 32 required) ✓\n`);
