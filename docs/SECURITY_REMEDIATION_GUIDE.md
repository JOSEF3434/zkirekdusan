# Security Remediation Guide

**Status**: ⚠️ **CRITICAL - IMMEDIATE ACTION REQUIRED**  
**Date**: September 25, 2026  
**Priority**: P0 (Critical)

---

## 🚨 Executive Summary

Three **critical security vulnerabilities (P0)** have been identified in the Zikire Kdusan project that expose sensitive credentials and allow unauthorized access. These issues require **immediate remediation** before any production deployment.

### Critical Findings
1. **Exposed Secrets in `.env` file** - JWT secrets, database credentials, API keys committed to git
2. **CORS Wildcard Configuration** - `CORS_ORIGINS=*` allows any origin to access the API
3. **Weak JWT Secrets** - Using placeholder secrets in production

---

## 📋 Immediate Action Checklist

### ✅ Step 1: Generate New Secrets (5 minutes)

**1.1 Generate Strong JWT Secrets**

Run these commands to generate cryptographically secure secrets:

```bash
# Generate JWT Access Secret (32+ characters)
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"

# Generate JWT Refresh Secret (32+ characters)  
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

Example output:
```
7xK9mP3vN8qR2wT5yU6zL1aS4dF7gH0jB9nM2cV5xE8=
aB3dC5eF7gH9jK2lM4nP6qR8sT0uV2wX4yZ6aB8cD0e=
```

**1.2 Rotate Cloudinary Credentials**

1. Log into [Cloudinary Dashboard](https://cloudinary.com/console)
2. Navigate to **Settings → Security**
3. Click **"Regenerate API Secret"**
4. Save the new credentials securely
5. Update your environment variables immediately

**1.3 Rotate Firebase Service Account**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Navigate to **Project Settings → Service Accounts**
3. Click **"Generate New Private Key"**
4. Download the new JSON file
5. Delete the old service account key
6. Update `FCM_SERVICE_ACCOUNT_JSON` with new credentials

**1.4 Rotate Database Credentials**

1. Log into [Neon Console](https://console.neon.tech/)
2. Navigate to your project → **Settings → Reset Password**
3. Generate a new strong password
4. Update `DATABASE_URL` connection string

**1.5 Rotate Redis Credentials (if applicable)**

1. Access your Redis provider dashboard
2. Regenerate the password/connection string
3. Update `REDIS_URL` environment variable

---

### ✅ Step 2: Create New `.env` File (10 minutes)

**2.1 Backup Current `.env` (DO NOT COMMIT)**

```bash
cd backend
cp .env .env.backup.old
```

**2.2 Create New `.env` with Rotated Secrets**

Use the `.env.example` template and fill in your new credentials:

```bash
# Copy template
cp .env.example .env.production
```

Edit `.env.production` and replace ALL placeholder values:

```env
# Application Configuration
APP_NAME="ዝክረ ክዱሳን"
APP_URL=https://zikrekidusan.onrender.com
NODE_ENV=production
PORT=3000

# Security Configuration
BCRYPT_ROUNDS=12

# JWT Configuration - REPLACE WITH NEW SECRETS FROM STEP 1.1
JWT_ACCESS_SECRET=<NEW_ACCESS_SECRET_FROM_STEP_1.1>
JWT_REFRESH_SECRET=<NEW_REFRESH_SECRET_FROM_STEP_1.1>
JWT_ACCESS_EXPIRES=15m
JWT_REFRESH_EXPIRES=7d

# Database Configuration - REPLACE WITH NEW CREDENTIALS FROM STEP 1.4
DATABASE_URL="postgresql://<new_user>:<new_password>@ep-summer-cake-a-tdooq3n.us-east-1.aws.neon.tech/neondb?sslmode=require"

# Redis Configuration - REPLACE WITH NEW CREDENTIALS FROM STEP 1.5
REDIS_URL=redis://<host>:<port>
REDIS_PASSWORD=<new_redis_password>

# Cloudinary Configuration - REPLACE WITH NEW CREDENTIALS FROM STEP 1.2
CLOUDINARY_CLOUD_NAME=v6zdpkoh
CLOUDINARY_API_KEY=<new_api_key>
CLOUDINARY_API_SECRET=<new_api_secret>
RTMP_SERVER_URL=rtmp://live.cloudinary.com/streams
HLS_BASE_URL=https://res.cloudinary.com/v6zdpkoh/video/live
STORAGE_PROVIDER=CLOUDINARY

# Firebase Configuration - REPLACE WITH NEW SERVICE ACCOUNT FROM STEP 1.3
FCM_SERVICE_ACCOUNT_JSON='<new_service_account_json_from_step_1.3>'

# CORS Configuration - REPLACE * WITH YOUR ACTUAL DOMAINS
CORS_ORIGINS=https://zikrekidusan.onrender.com,https://app.zikrekidusan.com

# Upload Configuration
UPLOAD_MAX_SIZE=52428800
```

**2.3 Validate New Configuration**

```bash
# Check that no placeholder values remain
grep -E "REPLACE_WITH|your_super_secret|your-domain" .env.production

# If output is empty, configuration is valid
# If output shows matches, you have placeholder values that need to be replaced
```

---

### ✅ Step 3: Secure Git Repository (15 minutes)

**3.1 Verify `.gitignore` Protects Secrets**

```bash
cd backend
cat .gitignore | grep -E "^\.env$"
```

If `.env` is NOT in `.gitignore`, add it:

```bash
echo ".env" >> .gitignore
echo ".env.production" >> .gitignore
echo ".env.backup.*" >> .gitignore
```

**3.2 Remove `.env` from Git History**

⚠️ **WARNING**: This rewrites git history. Coordinate with your team first.

```bash
# Option A: Using git-filter-repo (recommended)
pip install git-filter-repo
git filter-repo --path backend/.env --invert-paths --force

# Option B: Using BFG Repo-Cleaner (alternative)
java -jar bfg.jar --delete-files .env
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# After either option, force push (COORDINATE WITH TEAM FIRST)
git push origin --force --all
```

**3.3 Add `.env.example` to Git (Safe)**

```bash
git add backend/.env.example
git commit -m "security: add .env.example template (no secrets)"
git push origin main
```

---

### ✅ Step 4: Fix CORS Configuration (5 minutes)

**4.1 Identify Your Frontend Domains**

List all domains that need API access:
- Production web app: `https://zikrekidusan.onrender.com`
- Mobile app domains (if using WebView): `https://app.zikrekidusan.com`
- Admin panel (if separate): `https://admin.zikrekidusan.com`
- Development: `http://localhost:3000` (for local testing only)

**4.2 Update CORS Origins in `.env`**

Replace the wildcard with explicit domains:

```env
# BEFORE (INSECURE):
CORS_ORIGINS=*

# AFTER (SECURE):
CORS_ORIGINS=https://zikrekidusan.onrender.com,https://app.zikrekidusan.com
```

**4.3 Verify CORS Configuration in Code**

Check `backend/src/main.ts` or `backend/src/app.module.ts`:

```typescript
// Verify CORS configuration reads from environment
app.enableCors({
  origin: process.env.CORS_ORIGINS.split(','),
  credentials: true,
});
```

---

### ✅ Step 5: Deploy Securely (10 minutes)

**5.1 Update Environment Variables on Render.com**

1. Log into [Render Dashboard](https://dashboard.render.com/)
2. Navigate to your backend service: `zikrekidusan`
3. Go to **Environment** tab
4. **Delete** all old environment variables
5. **Add** new variables from your `.env.production` file one by one
6. Click **Save Changes**

**5.2 Force Redeploy**

```bash
# Trigger manual deploy on Render
# Dashboard → Manual Deploy → Deploy Latest Commit
```

**5.3 Verify Deployment**

```bash
# Test health endpoint
curl https://zikrekidusan.onrender.com/health

# Test authentication (should require valid JWT now)
curl -X POST https://zikrekidusan.onrender.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"wrong"}'

# Should return 401 Unauthorized (not 500 or connection error)
```

---

### ✅ Step 6: Revoke Compromised Secrets (5 minutes)

**6.1 Invalidate All Existing JWT Tokens**

With new JWT secrets, all existing tokens are automatically invalid. Users will need to log in again.

**Optional**: Notify users via email/push notification:
```
"For security reasons, you have been logged out. Please log in again."
```

**6.2 Monitor for Unauthorized Access Attempts**

Check logs for failed authentication attempts:

```bash
# On Render.com dashboard
# Navigate to Logs → Filter for "401" or "Unauthorized"
```

---

## 🔐 Additional Security Hardening (Optional but Recommended)

### Implement Rate Limiting

Add to `backend/src/main.ts`:

```typescript
import rateLimit from '@nestjs/throttler';

app.use(
  rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // limit each IP to 100 requests per windowMs
  })
);
```

### Add Security Headers

Install helmet:

```bash
npm install helmet
```

Add to `backend/src/main.ts`:

```typescript
import helmet from 'helmet';

app.use(helmet());
```

### Enable HTTPS Only

In `.env`:

```env
FORCE_HTTPS=true
```

### Implement IP Whitelisting (if applicable)

For admin endpoints, restrict access to specific IPs:

```typescript
// In admin.guard.ts
const allowedIPs = process.env.ADMIN_IP_WHITELIST.split(',');
if (!allowedIPs.includes(request.ip)) {
  throw new ForbiddenException('IP not whitelisted');
}
```

---

## 📊 Verification Checklist

After completing all steps, verify:

- [ ] New JWT secrets are 32+ characters, cryptographically random
- [ ] JWT Access Token expiry is set to 15 minutes (not 7 days)
- [ ] Cloudinary API secret has been rotated
- [ ] Firebase service account key has been rotated and old key deleted
- [ ] Database password has been changed
- [ ] Redis credentials have been rotated (if applicable)
- [ ] `.env` file is in `.gitignore`
- [ ] `.env` file has been removed from git history
- [ ] CORS origins are explicit domains (no `*` wildcard)
- [ ] New environment variables deployed to Render.com
- [ ] Old environment variables deleted from Render.com
- [ ] Application deploys successfully with new secrets
- [ ] Authentication works (users can log in)
- [ ] API rejects requests from unauthorized origins
- [ ] All compromised secrets documented in incident log

---

## 🚨 If Secrets Have Been Publicly Exposed

If your repository is public or secrets were exposed in commits:

1. **Assume Compromise**: Treat all exposed secrets as compromised
2. **Immediate Rotation**: Rotate ALL secrets immediately (Steps 1-2)
3. **Audit Access Logs**: Check Cloudinary, Firebase, Neon, and application logs for unauthorized access
4. **Database Audit**: Run forensic audit script:
   ```bash
   npx ts-node backend/scripts/forensic-audit.ts
   ```
5. **Incident Response**: Document the incident, timeline, and remediation steps
6. **User Notification**: If user data was potentially accessed, notify affected users
7. **Legal Compliance**: Check if breach notification is required under GDPR/CCPA

---

## 📞 Support Contacts

- **Cloudinary Support**: https://support.cloudinary.com/
- **Firebase Support**: https://firebase.google.com/support
- **Neon Support**: https://neon.tech/docs/introduction/support
- **Render Support**: https://render.com/docs/support

---

## 📝 Change Log

| Date | Action | Status |
|------|--------|--------|
| 2026-09-25 | Initial security audit completed | ⚠️ Critical issues identified |
| 2026-09-25 | Remediation guide created | 📋 Pending implementation |
| _TBD_ | Secrets rotated | ⏳ Pending |
| _TBD_ | Git history cleaned | ⏳ Pending |
| _TBD_ | CORS fixed | ⏳ Pending |
| _TBD_ | Deployment updated | ⏳ Pending |
| _TBD_ | Verification complete | ⏳ Pending |

---

## ⏱️ Estimated Time to Complete

- **Minimum**: 45 minutes (if all tools are ready)
- **Realistic**: 2-3 hours (including coordination and verification)
- **With git history cleanup**: +1-2 hours

---

## 🎯 Success Criteria

Remediation is complete when:

1. ✅ All secrets have been rotated
2. ✅ New `.env` file contains only new, strong secrets
3. ✅ `.env` is not in git repository or history
4. ✅ CORS origins are explicit (no wildcard)
5. ✅ Application deployed with new secrets
6. ✅ Authentication and authorization working correctly
7. ✅ No exposed secrets remain in public repositories
8. ✅ Security verification checklist 100% complete

---

**Document Version**: 1.0  
**Last Updated**: September 25, 2026  
**Next Review**: After remediation complete
