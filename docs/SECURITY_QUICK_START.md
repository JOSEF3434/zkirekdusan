# Security Quick Start Guide

**⏱️ Time Required**: 15 minutes  
**Priority**: 🚨 CRITICAL - Do this NOW before any production deployment

---

## 🎯 What This Guide Does

This is a **fast-track** guide to secure your Zikire Kdusan deployment. If you need detailed explanations, see the full [SECURITY_REMEDIATION_GUIDE.md](./SECURITY_REMEDIATION_GUIDE.md).

---

## ✅ 5-Step Security Checklist

### Step 1: Generate New Secrets (2 minutes)

```bash
cd backend
npm run security:generate-secrets
```

**Copy the output** - you'll need these values in Step 2.

---

### Step 2: Create Secure `.env` File (5 minutes)

```bash
# Backup current .env (if it exists)
cp .env .env.backup

# Copy the template
cp .env.example .env

# Edit the new .env file
# Replace ALL placeholder values with:
# - The secrets you generated in Step 1
# - Your actual service credentials
```

**Required Changes:**

```env
# 1. Replace JWT secrets (from Step 1 output)
JWT_ACCESS_SECRET=<paste_first_secret_here>
JWT_REFRESH_SECRET=<paste_second_secret_here>
JWT_ACCESS_EXPIRES=15m

# 2. Fix CORS (replace * with your actual domains)
CORS_ORIGINS=https://zikrekidusan.onrender.com

# 3. Rotate Cloudinary credentials
# Log into https://cloudinary.com/console
# Settings → Security → Regenerate API Secret
CLOUDINARY_API_SECRET=<new_secret_from_cloudinary>

# 4. Rotate Firebase credentials
# Go to Firebase Console → Project Settings → Service Accounts
# Generate New Private Key → Download JSON
# Copy the entire JSON into FCM_SERVICE_ACCOUNT_JSON (single line)
FCM_SERVICE_ACCOUNT_JSON='<paste_new_firebase_json_here>'

# 5. Rotate database password
# Log into Neon Console → Settings → Reset Password
DATABASE_URL="postgresql://<user>:<NEW_PASSWORD>@<host>/neondb?sslmode=require"
```

---

### Step 3: Verify Configuration (1 minute)

```bash
npm run security:verify
```

**Expected output:**
```
✅ SECURITY VERIFICATION PASSED
All security checks passed. Configuration looks good!
```

**If you see failures**, fix them before continuing.

---

### Step 4: Update Production Environment Variables (5 minutes)

**On Render.com:**

1. Go to https://dashboard.render.com/
2. Select your `zikrekidusan` service
3. Click **Environment** tab
4. **Delete all old variables**
5. **Add new variables** from your `.env` file (one by one)
6. Click **Save Changes**
7. Trigger **Manual Deploy**

---

### Step 5: Verify Deployment (2 minutes)

```bash
# Test API health
curl https://zikrekidusan.onrender.com/health

# Should return: {"status":"ok"}
```

**Test authentication:**

```bash
curl -X POST https://zikrekidusan.onrender.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"wrong"}'
```

**Should return 401 Unauthorized** (not 500 or connection error).

---

## 🚨 If You Skip These Steps

Your application is vulnerable to:

- ❌ **Credential theft** - Anyone can steal your JWT secrets from git
- ❌ **Unauthorized API access** - CORS wildcard allows any website to access your API
- ❌ **Account takeover** - Weak JWT secrets can be brute-forced
- ❌ **Data breach** - Database credentials exposed in git history
- ❌ **Cloud resource abuse** - Cloudinary/Firebase credentials can be used by attackers

---

## ✅ Success Criteria

You're done when:

- [x] `npm run security:verify` passes without errors
- [x] New environment variables deployed to Render.com
- [x] Application deploys successfully
- [x] API health check returns 200 OK
- [x] Authentication works (users can log in)
- [x] No secrets remain in git repository

---

## 🆘 Need Help?

**Quick Questions:**
- Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for common issues

**Security Issues:**
- See full [SECURITY_REMEDIATION_GUIDE.md](./SECURITY_REMEDIATION_GUIDE.md)

**Critical Failures:**
- Contact your DevOps team immediately
- Do NOT deploy to production until issues are resolved

---

## 📋 Post-Deployment Checklist

After completing the 5 steps above:

- [ ] Update your team's password manager with new secrets
- [ ] Document the secret rotation date
- [ ] Set a calendar reminder to rotate secrets in 90 days
- [ ] Remove old `.env.backup` file after confirming everything works
- [ ] Update CI/CD pipelines with new secrets (if applicable)
- [ ] Test all API endpoints to ensure authentication works
- [ ] Monitor logs for any authentication errors

---

## ⏱️ Regular Maintenance

**Every 90 days:**
- Rotate all secrets using Steps 1-5
- Run `npm run security:verify`
- Update production environment variables

**After any security incident:**
- Rotate ALL secrets immediately
- Run forensic audit: `npx tsx scripts/forensic-audit.ts`
- Review access logs for unauthorized access

---

**Last Updated**: September 25, 2026  
**Version**: 1.0
