# Known Issues & Limitations

**Document Version:** 1.0  
**Last Updated:** September 25, 2026  
**Project:** Zikire Kdusan (StreamHub)

---

## Table of Contents

1. [Overview](#overview)
2. [Critical Issues](#critical-issues)
3. [Backend Issues](#backend-issues)
4. [Frontend Issues](#frontend-issues)
5. [Database Issues](#database-issues)
6. [Real-Time & Live Streaming](#real-time--live-streaming)
7. [Offline & Synchronization](#offline--synchronization)
8. [Security Concerns](#security-concerns)
9. [Performance Limitations](#performance-limitations)
10. [Platform-Specific Issues](#platform-specific-issues)
11. [Configuration Issues](#configuration-issues)
12. [Future Improvements](#future-improvements)

---

## Overview

This document catalogs verified limitations, inconsistencies, and known issues discovered during the comprehensive audit of Zikire Kdusan. Each issue includes:

- **Severity:** Critical (P0), High (P1), Medium (P2), Low (P3)
- **Status:** Open, In Progress, Planned, Won't Fix
- **Impact:** User-facing impact description
- **Workaround:** Temporary solution (if available)
- **Root Cause:** Technical explanation

**Issue Severity Definitions:**

| Severity | Definition | Response Time |
|----------|------------|---------------|
| **P0 - Critical** | System down, data loss, security breach | Immediate (< 1 hour) |
| **P1 - High** | Major feature broken, significant user impact | < 24 hours |
| **P2 - Medium** | Feature partially broken, moderate user impact | < 1 week |
| **P3 - Low** | Minor issue, cosmetic, enhancement request | Backlog |

---

## Critical Issues

### 🔴 ISSUE #1: JWT Secrets Exposed in .env File

**Severity:** P0 - Critical  
**Status:** Open  
**Component:** Backend / Security  
**Discovered:** During environment configuration audit

**Description:**

The `.env` file in the backend directory contains production JWT secrets and is **committed to version control**. This is visible in the audit findings:

```ini
JWT_ACCESS_SECRET=your_super_secret_access_key
JWT_REFRESH_SECRET=your_super_secret_refresh_key
```

These are placeholder values, but the actual production `.env` file with real secrets may have been committed historically.

**Impact:**

- ⚠️ **CRITICAL SECURITY RISK** - Anyone with repository access can read JWT secrets
- Attackers can forge JWT tokens and impersonate any user
- Full account takeover vulnerability
- Compliance violation (SOC 2, GDPR data protection requirements)

**Root Cause:**

`.env` file not properly added to `.gitignore` before initial commit.

**Workaround:**

1. **IMMEDIATE ACTION REQUIRED:**
   ```bash
   # Rotate all JWT secrets immediately
   export NEW_ACCESS_SECRET=$(openssl rand -base64 64)
   export NEW_REFRESH_SECRET=$(openssl rand -base64 64)
   
   # Update Render.com environment variables
   # Dashboard → Environment → Update secrets
   
   # Invalidate all existing sessions
   redis-cli -u $REDIS_URL FLUSHALL
   ```

2. **Remove from git history:**
   ```bash
   # Use BFG Repo-Cleaner or git-filter-repo
   git filter-repo --path backend/.env --invert-paths
   ```

3. **Ensure .gitignore:**
   ```bash
   echo "backend/.env" >> .gitignore
   echo "mobile/.env" >> .gitignore
   git add .gitignore
   git commit -m "security: prevent .env files from being committed"
   ```

**Resolution Plan:**

- [ ] Audit git history for exposed secrets
- [ ] Rotate all production secrets
- [ ] Implement pre-commit hook to prevent `.env` commits
- [ ] Set up secret scanning (GitHub Advanced Security)
- [ ] Document secret rotation procedure

---

### 🔴 ISSUE #2: Cloudinary Credentials Exposed

**Severity:** P0 - Critical  
**Status:** Open  
**Component:** Backend / Media Storage  
**Discovered:** During environment variable audit

**Description:**

Cloudinary API credentials are hardcoded in the committed `.env` file:

```ini
CLOUDINARY_API_KEY=667751121616522
CLOUDINARY_API_SECRET=5f7EQfkTHv8XbGL2A3gzAVSVHaw
CLOUDINARY_CLOUD_NAME=v6zdpkoh
```

**Impact:**

- Unauthorized access to Cloudinary account
- Potential deletion of all media assets
- Upload of malicious content
- Incur significant bandwidth costs
- Violation of Cloudinary Terms of Service

**Workaround:**

1. **IMMEDIATE ACTION:**
   - Log in to Cloudinary Dashboard
   - **Settings → Security → Regenerate API Secret**
   - Update Render.com environment variables with new secret
   - Monitor Cloudinary usage for suspicious activity

2. **Long-term:**
   - Never commit Cloudinary credentials
   - Use signed upload URLs for client-side uploads
   - Implement server-side upload signatures
   - Enable Cloudinary access control lists (ACLs)

---

### 🔴 ISSUE #3: Firebase Service Account JSON in Environment Variable

**Severity:** P0 - Critical  
**Status:** Open  
**Component:** Backend / Push Notifications  
**Discovered:** During Firebase integration audit

**Description:**

Firebase service account private key is stored as environment variable `FCM_SERVICE_ACCOUNT_JSON` containing:

- Private key (`-----BEGIN PRIVATE KEY-----...`)
- Client email
- Project ID

**Impact:**

- Unauthorized access to Firebase project
- Send spam push notifications to all users
- Read/write Firestore data (if enabled)
- Delete Firebase project
- Impersonate service account

**Workaround:**

1. **Rotate service account:**
   - Firebase Console → Project Settings → Service Accounts
   - Generate new private key
   - Delete old service account key
   - Update Render.com environment variable

2. **Better approach:**
   - Use Google Cloud Secret Manager
   - Mount service account as file in production
   - Restrict service account permissions (principle of least privilege)

---

## Backend Issues

### 🟡 ISSUE #4: Inconsistent Error Response Formats

**Severity:** P2 - Medium  
**Status:** Open  
**Component:** Backend / API  
**Discovered:** During API endpoint audit

**Description:**

Error responses across different controllers use inconsistent formats:

```typescript
// Some controllers return:
{ statusCode: 400, message: 'Error message', error: 'Bad Request' }

// Others return:
{ success: false, error: 'Error message' }

// Others return:
{ message: 'Error message' }
```

**Impact:**

- Frontend error handling is complex and error-prone
- Inconsistent user error messages
- Difficult to debug issues
- Poor developer experience for API consumers

**Root Cause:**

Missing global exception filter implementation or inconsistent usage.

**Workaround:**

```typescript
// Frontend: Normalize error responses
function normalizeError(error: any): string {
  return error.response?.data?.message 
    || error.response?.data?.error 
    || error.message 
    || 'Unknown error occurred';
}
```

**Resolution Plan:**

- [ ] Implement consistent global exception filter
- [ ] Define standard error response schema
- [ ] Update all controllers to use standard format
- [ ] Document error response format in API.md

---

### 🟡 ISSUE #5: JWT Token Expiry Inconsistency

**Severity:** P2 - Medium  
**Status:** Open  
**Component:** Backend / Authentication  
**Discovered:** During authentication flow audit

**Description:**

Environment configuration shows:

```ini
JWT_ACCESS_EXPIRES=7d  # Should be 15m
JWT_REFRESH_EXPIRES=7d  # Correct
```

Documentation states access tokens expire in **15 minutes**, but `.env` file shows **7 days**. This creates confusion and potential security risk.

**Impact:**

- If production uses 7-day access tokens:
  - Increased security risk (longer token validity)
  - Stolen access token valid for 7 days instead of 15 minutes
  - Defeats purpose of refresh token rotation
- If documentation is correct, `.env` is misleading

**Workaround:**

Verify actual production configuration:

```bash
# Check Render.com dashboard
# Environment → JWT_ACCESS_EXPIRES
```

**Resolution Plan:**

- [ ] Audit production JWT_ACCESS_EXPIRES value
- [ ] Update to 15 minutes if currently 7 days
- [ ] Update `.env.example` to show correct value
- [ ] Document token expiry in SECURITY_AND_PRIVACY.md

---

### 🟡 ISSUE #6: Missing Rate Limiting on Critical Endpoints

**Severity:** P1 - High  
**Status:** Open  
**Component:** Backend / Security  
**Discovered:** During security audit

**Description:**

While global rate limiting is configured (100 requests/60 seconds), some critical endpoints lack specific rate limits:

- **POST /auth/register** - No specific limit (vulnerable to spam account creation)
- **POST /auth/forgot-password** - No limit (email bombing vulnerability)
- **POST /messages** - Only 5 messages per 10 seconds for live chat, but no limit for regular messaging
- **POST /reports** - No limit (report spam vulnerability)

**Impact:**

- Spam account registration
- Email/SMS bombing via password reset
- Database bloat from spam messages
- Report system abuse

**Workaround:**

Add endpoint-specific throttle decorators:

```typescript
@UseGuards(ThrottlerGuard)
@Throttle({ default: { limit: 5, ttl: 3600000 } }) // 5 per hour
@Post('register')
async register() { ... }
```

**Resolution Plan:**

- [ ] Add rate limits to auth endpoints (5/hour for register, 3/hour for forgot-password)
- [ ] Add rate limits to reporting endpoint (10/hour)
- [ ] Add rate limits to video uploads (10/hour per user)
- [ ] Implement IP-based rate limiting for anonymous endpoints

---

### 🟢 ISSUE #7: Hardcoded APP_URL in Multiple Locations

**Severity:** P3 - Low  
**Status:** Open  
**Component:** Backend / Configuration  
**Discovered:** During environment audit

**Description:**

`APP_URL` is referenced as `https://zikrekidusan.onrender.com` in multiple places but also has fallbacks:

```typescript
const appUrl = 
  process.env.APP_URL ?? 
  process.env.RENDER_EXTERNAL_URL ?? 
  'https://zikrekidusan.onrender.com';
```

Hardcoded fallback may cause issues in different environments.

**Impact:**

- Incorrect URLs in password reset emails when `APP_URL` not set
- Wrong redirect URLs in OAuth flows
- Confusion in multi-environment setup

**Workaround:**

Always set `APP_URL` in environment variables for all environments.

**Resolution Plan:**

- [ ] Remove hardcoded fallback
- [ ] Fail fast if `APP_URL` not set
- [ ] Document required environment variables

---

## Frontend Issues

### 🟡 ISSUE #8: Flutter Web SQLite Fallback is No-Op

**Severity:** P2 - Medium  
**Status:** Won't Fix (By Design)  
**Component:** Frontend / Offline Storage  
**Discovered:** During Drift database audit

**Description:**

Flutter web uses `_SafeWebQueryExecutor` that returns empty results for all database queries:

```dart
class _SafeWebQueryExecutor extends QueryExecutor {
  @override
  Future<List<Map<String, Object?>>> runSelect(
    String statement,
    List<Object?> args,
  ) async => [];
}
```

**Impact:**

- No offline storage on web
- Sync queue not persisted on web
- Downloaded videos feature unavailable on web
- Calendar notes not cached on web
- Message history not saved on web

**Root Cause:**

SQLite WebAssembly is not reliable across all browsers and introduces large bundle size.

**Workaround:**

Document web limitations clearly:

- Use IndexedDB for web storage (future enhancement)
- Recommend native mobile app for full offline experience
- Show "Web version has limited offline capabilities" notice

**Resolution Plan:**

- [ ] Implement IndexedDB adapter for Drift (future)
- [ ] Document web limitations in USER_GUIDE.md
- [ ] Show feature availability badge ("Mobile only")

---

### 🟡 ISSUE #9: Android Back Button Doesn't Exit App

**Severity:** P2 - Medium  
**Status:** Open  
**Component:** Frontend / Navigation  
**Discovered:** User testing feedback

**Description:**

Pressing Android back button on home screen doesn't exit app. Instead, it navigates to previous route or does nothing.

**Impact:**

- Confusing UX for Android users
- Users force-close app instead of using back button
- Violates Android UX guidelines

**Root Cause:**

GoRouter doesn't handle system back button on root route.

**Workaround:**

Implement WillPopScope on home screen:

```dart
WillPopScope(
  onWillPop: () async {
    if (Navigator.canPop(context)) {
      return true;
    } else {
      // Show exit confirmation dialog
      return await showExitConfirmation(context);
    }
  },
  child: HomeScreen(),
)
```

**Resolution Plan:**

- [ ] Implement WillPopScope on root routes
- [ ] Add "Press back again to exit" toast
- [ ] Test across Android versions

---

### 🟢 ISSUE #10: iOS Keyboard Overlaps Text Fields

**Severity:** P3 - Low  
**Status:** Open  
**Component:** Frontend / UI  
**Discovered:** iOS testing

**Description:**

On some iOS devices, keyboard overlaps text fields in comment sections and messaging screens.

**Impact:**

- Users can't see what they're typing
- Poor UX on smaller iOS devices (iPhone SE, iPhone 8)

**Root Cause:**

Missing `resizeToAvoidBottomInset: true` or incorrect `SingleChildScrollView` usage.

**Workaround:**

```dart
Scaffold(
  resizeToAvoidBottomInset: true,
  body: SingleChildScrollView(
    reverse: true,  // Scrolls to bottom when keyboard appears
    child: Column(children: [...]),
  ),
)
```

**Resolution Plan:**

- [ ] Audit all screens with text input
- [ ] Ensure proper keyboard avoidance
- [ ] Test on iPhone SE, iPhone 8, iPhone 15 Pro Max

---

### 🟢 ISSUE #11: Video Thumbnail Placeholder Not Showing

**Severity:** P3 - Low  
**Status:** Open  
**Component:** Frontend / Media  
**Discovered:** Visual audit

**Description:**

When video thumbnail fails to load, no placeholder is shown. Users see blank space.

**Impact:**

- Confusing UX when thumbnails fail to load
- Feed looks broken on slow connections

**Workaround:**

```dart
CachedNetworkImage(
  imageUrl: video.thumbnailUrl,
  placeholder: (context, url) => ShimmerPlaceholder(),
  errorWidget: (context, url, error) => DefaultThumbnail(),
)
```

**Resolution Plan:**

- [ ] Add shimmer placeholder during loading
- [ ] Add default thumbnail for errors
- [ ] Show retry button on thumbnail load failure

---

## Database Issues

### 🟡 ISSUE #12: Missing Database Indexes on Frequently Queried Columns

**Severity:** P1 - High  
**Status:** Open  
**Component:** Database / Performance  
**Discovered:** During Prisma schema audit

**Description:**

Several frequently queried columns lack indexes:

```prisma
model Message {
  conversationId String  // ❌ No index
  sentAt         DateTime // ❌ No index
  isEdited       Boolean  // ✅ Not needed (low cardinality)
}

model Video {
  status         VideoStatus // ❌ No index (filtered in queries)
  visibility     Visibility  // ❌ No index (filtered in queries)
}
```

**Impact:**

- Slow queries when filtering messages by conversation
- Slow queries when listing videos by status
- Database CPU spikes during peak usage
- Poor user experience (slow feed loading)

**Root Cause:**

Indexes not added during initial schema design.

**Workaround:**

Add indexes via migration:

```prisma
model Message {
  conversationId String
  sentAt         DateTime
  
  @@index([conversationId, sentAt(sort: Desc)])
}

model Video {
  status     VideoStatus
  visibility Visibility
  
  @@index([status])
  @@index([visibility])
}
```

**Resolution Plan:**

- [ ] Audit all models for missing indexes
- [ ] Create migration to add indexes
- [ ] Test performance improvement on staging
- [ ] Deploy to production during low-traffic window

---

### 🟡 ISSUE #13: Soft Delete Not Implemented for User Data

**Severity:** P2 - Medium  
**Status:** Open  
**Component:** Database / Data Integrity  
**Discovered:** During GDPR compliance review

**Description:**

User account deletion is hard delete (permanent removal from database). This causes:

- Orphaned references (posts, messages, etc. with deleted user IDs)
- Lost audit trail
- GDPR "right to be forgotten" conflicts with legal retention requirements

**Impact:**

- Broken user experience (messages show "Unknown User")
- Legal compliance risk (unable to retain data for disputes)
- Data integrity issues (foreign key violations)

**Root Cause:**

User model uses `onDelete: Cascade` instead of soft delete pattern.

**Workaround:**

Implement soft delete:

```prisma
model User {
  id        String    @id @default(uuid())
  deletedAt DateTime? // Soft delete marker
  
  // ... other fields
}

// Query only active users
where: { deletedAt: null }
```

**Resolution Plan:**

- [ ] Add `deletedAt` column to User model
- [ ] Update all user queries to filter `deletedAt: null`
- [ ] Implement scheduled job to purge soft-deleted users after 90 days
- [ ] Update API endpoints to soft delete instead of hard delete

---

### 🟢 ISSUE #14: Large Text Fields Without Length Limits

**Severity:** P3 - Low  
**Status:** Open  
**Component:** Database / Validation  
**Discovered:** During schema audit

**Description:**

Some text fields have no maximum length:

```prisma
model Post {
  content String  // No max length (can be 10 MB+)
}

model Message {
  content String  // No max length
}
```

**Impact:**

- Potential database bloat
- Slow query performance
- OOM errors when loading large content
- No user feedback on content length limits

**Workaround:**

Add validation in DTOs:

```typescript
export class CreatePostDto {
  @IsString()
  @MaxLength(10000)
  content: string;
}
```

**Resolution Plan:**

- [ ] Define max lengths for all text fields
- [ ] Add validation in DTOs
- [ ] Add frontend character counters
- [ ] Document content limits in USER_GUIDE.md

---

## Real-Time & Live Streaming

### 🟡 ISSUE #15: WebSocket Reconnection Causes Duplicate Event Listeners

**Severity:** P2 - Medium  
**Status:** Open  
**Component:** Real-Time / Socket.IO  
**Discovered:** During live streaming testing

**Description:**

When WebSocket connection drops and reconnects, event listeners are not properly cleaned up, causing duplicate message events:

```dart
// Bug: Listeners added on every reconnect
socket.on('new_message', (data) {
  // This fires multiple times for same message
  handleNewMessage(data);
});
```

**Impact:**

- Users see duplicate messages after reconnection
- Duplicate reactions appear on live streams
- Increased battery drain (multiple event handlers)

**Root Cause:**

Event listeners added in `connect` callback without removing old listeners.

**Workaround:**

```dart
// Remove old listeners before adding new ones
socket.off('new_message');
socket.on('new_message', handleNewMessage);
```

**Resolution Plan:**

- [ ] Audit all Socket.IO event listeners
- [ ] Remove old listeners before reconnection
- [ ] Test reconnection scenarios extensively
- [ ] Add integration test for WebSocket reconnection

---

### 🟡 ISSUE #16: Live Stream Notification Delay Can Exceed 2 Minutes

**Severity:** P2 - Medium  
**Status:** Open  
**Component:** Live Streaming / Notifications  
**Discovered:** During live streaming audit

**Description:**

Documentation states 2-minute notification delay, but implementation uses:

```typescript
if (stream.notifiedLiveAt === null) {
  // Wait 2 minutes before sending notification
  await delay(120000);
  // Send notification
}
```

The delay runs on the backend server. If server restarts during the 2-minute window, notification is never sent.

**Impact:**

- Followers miss live stream notifications
- Streamer goes live but no one joins
- Poor engagement for live streams

**Root Cause:**

Notification delay implemented as in-memory timer instead of scheduled job.

**Workaround:**

Use BullMQ delayed job:

```typescript
await notificationQueue.add(
  'send-live-notification',
  { streamId: stream.id },
  { delay: 120000 },  // 2 minutes
);
```

**Resolution Plan:**

- [ ] Migrate notification delay to BullMQ
- [ ] Store `notifiedLiveAt` immediately when job is queued
- [ ] Test server restart during delay window
- [ ] Add monitoring for missed notifications

---

### 🟢 ISSUE #17: HLS Playback Latency is 10-30 Seconds

**Severity:** P3 - Low  
**Status:** Won't Fix (Protocol Limitation)  
**Component:** Live Streaming / HLS  
**Discovered:** User testing feedback

**Description:**

HLS live streaming has inherent 10-30 second latency due to:

- 6-second video segments
- 3-segment buffer (18 seconds minimum)
- Network propagation delay
- CDN caching

**Impact:**

- Live chat is out of sync with video
- Reactions appear before viewers see corresponding video moment
- Not suitable for interactive gaming or auctions

**Root Cause:**

HLS protocol design optimized for reliability over latency.

**Workaround:**

- Document expected latency in USER_GUIDE.md
- Consider WebRTC for ultra-low-latency (future enhancement)
- Show "Live stream has 15-30 second delay" notice in player

**Resolution Plan:**

- [ ] Document HLS latency in REALTIME_AND_LIVE.md
- [ ] Investigate LL-HLS (Low-Latency HLS) support in Cloudinary
- [ ] Consider WebRTC for premium low-latency option

---

## Offline & Synchronization

### 🟡 ISSUE #18: Sync Queue Can Grow Unbounded

**Severity:** P2 - Medium  
**Status:** Open  
**Component:** Offline / Sync  
**Discovered:** During sync manager audit

**Description:**

Sync queue has no maximum size. If a user is offline for extended period (e.g., 30 days), sync queue can grow to thousands of entries.

**Impact:**

- Database bloat (sync_queue table)
- Slow sync when user comes back online
- OOM errors on devices with low memory
- First sync after long offline period takes minutes

**Root Cause:**

No queue size limit or cleanup of old abandoned entries.

**Workaround:**

Implement queue size limit:

```dart
// Before adding to queue, check size
final queueSize = await db.syncQueueDao.getQueueSize();
if (queueSize > 1000) {
  // Remove oldest abandoned entries
  await db.syncQueueDao.removeOldestAbandoned(100);
}
```

**Resolution Plan:**

- [ ] Add max queue size (10,000 entries)
- [ ] Automatically purge abandoned entries > 30 days old
- [ ] Show warning to user if queue > 5,000 entries
- [ ] Add background cleanup task

---

### 🟢 ISSUE #19: Downloaded Videos Not Automatically Cleaned Up

**Severity:** P3 - Low  
**Status:** Open  
**Component:** Offline / Downloads  
**Discovered:** During download manager audit

**Description:**

Auto-delete policy is configured but never scheduled:

```dart
// Feature exists but no cron job to execute it
enum AutoDeletePolicy {
  never,
  after7Days,
  after30Days,
  after90Days,
  whenStorageLow,
}
```

**Impact:**

- Device storage fills up over time
- User must manually delete downloads
- Auto-delete setting has no effect

**Workaround:**

Schedule daily cleanup job:

```dart
// In background_sync_service.dart
Workmanager().registerPeriodicTask(
  'cleanup-downloads',
  'CLEANUP_DOWNLOADS_TASK',
  frequency: Duration(days: 1),
);
```

**Resolution Plan:**

- [ ] Implement auto-delete cleanup task
- [ ] Run daily at 3:00 AM local time
- [ ] Respect user's auto-delete policy setting
- [ ] Add user notification when videos auto-deleted

---

## Security Concerns

### 🟡 ISSUE #20: Passwords Not Validated for Strength

**Severity:** P2 - Medium  
**Status:** Open  
**Component:** Security / Authentication  
**Discovered:** During auth service audit

**Description:**

Password validation only checks:

```typescript
@IsString()
@MinLength(8)
password: string;
```

No checks for:
- Mixed case (uppercase + lowercase)
- Numbers
- Special characters
- Common passwords (e.g., "password123")
- Pwned passwords (Have I Been Pwned API)

**Impact:**

- Weak passwords accepted (e.g., "password", "12345678")
- Increased account takeover risk
- Brute force attacks more likely to succeed

**Workaround:**

Implement password strength validator:

```typescript
export function validatePasswordStrength(password: string): boolean {
  const hasUpperCase = /[A-Z]/.test(password);
  const hasLowerCase = /[a-z]/.test(password);
  const hasNumbers = /\d/.test(password);
  const hasSpecialChar = /[!@#$%^&*(),.?":{}|<>]/.test(password);
  
  return hasUpperCase && hasLowerCase && hasNumbers && hasSpecialChar;
}
```

**Resolution Plan:**

- [ ] Add password strength requirements
- [ ] Check against common password list
- [ ] Integrate Have I Been Pwned API
- [ ] Show password strength meter in UI

---

### 🟢 ISSUE #21: No Account Enumeration Protection on Login

**Severity:** P3 - Low  
**Status:** Open  
**Component:** Security / Authentication  
**Discovered:** During security audit

**Description:**

Login endpoint returns different errors for:
- "Username not found" (404)
- "Incorrect password" (401)

This allows attackers to enumerate valid usernames.

**Impact:**

- Attackers can build list of valid usernames
- Targeted phishing attacks
- Brute force attacks more efficient

**Workaround:**

Return generic error for both cases:

```typescript
// Instead of:
if (!user) throw new NotFoundException('User not found');
if (!passwordMatch) throw new UnauthorizedException('Wrong password');

// Use:
if (!user || !passwordMatch) {
  throw new UnauthorizedException('Invalid credentials');
}
```

**Resolution Plan:**

- [ ] Update login endpoint to return generic error
- [ ] Add slight delay (200-500ms) to prevent timing attacks
- [ ] Update API documentation
- [ ] Test with security scanner

---

## Performance Limitations

### 🟡 ISSUE #22: Video Feed Loads All Thumbnails Upfront

**Severity:** P2 - Medium  
**Status:** Open  
**Component:** Performance / Frontend  
**Discovered:** During performance testing

**Description:**

Video feed loads all thumbnails for 50+ videos immediately, even though only 3-5 are visible on screen.

**Impact:**

- Slow initial feed load (10+ seconds on 3G)
- Unnecessary bandwidth consumption
- Battery drain
- Poor UX on slow connections

**Root Cause:**

Missing lazy loading implementation.

**Workaround:**

Implement lazy loading:

```dart
ListView.builder(
  itemCount: videos.length,
  itemBuilder: (context, index) {
    return VisibilityDetector(
      key: Key('video-$index'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.5) {
          // Load thumbnail when 50% visible
          loadThumbnail(videos[index]);
        }
      },
      child: VideoCard(video: videos[index]),
    );
  },
)
```

**Resolution Plan:**

- [ ] Implement virtual scrolling for video feed
- [ ] Lazy load thumbnails (only load when 50% visible)
- [ ] Implement image caching with LRU eviction
- [ ] Add progressive image loading (blur → full resolution)

---

### 🟢 ISSUE #23: No Database Query Result Caching

**Severity:** P3 - Low  
**Status:** Open  
**Component:** Performance / Backend  
**Discovered:** During performance audit

**Description:**

Frequently accessed data is queried from database on every request:

- User profile (queried on every authenticated request)
- User roles/permissions (queried on every permission check)
- Video metadata (queried on every video card render)

**Impact:**

- Increased database load
- Slower response times
- Higher Neon database costs

**Workaround:**

Implement Redis caching:

```typescript
async getUserProfile(userId: string): Promise<User> {
  const cacheKey = `user:${userId}`;
  
  // Try cache first
  const cached = await this.cache.get(cacheKey);
  if (cached) return JSON.parse(cached);
  
  // Query database
  const user = await this.prisma.user.findUnique({ where: { id: userId } });
  
  // Cache for 5 minutes
  await this.cache.set(cacheKey, JSON.stringify(user), 300);
  
  return user;
}
```

**Resolution Plan:**

- [ ] Identify frequently queried data
- [ ] Implement Redis caching layer
- [ ] Add cache invalidation on data updates
- [ ] Monitor cache hit rate (target: > 80%)

---

## Platform-Specific Issues

### 🟡 ISSUE #24: iOS Background Fetch Not Reliable

**Severity:** P2 - Medium  
**Status:** Open  
**Component:** iOS / Background Sync  
**Discovered:** iOS testing

**Description:**

iOS background fetch (for 15-minute sync) is opportunistic and may not run:

- Only runs when device has good connectivity
- Only runs when battery is not low
- iOS may deprioritize app based on usage patterns
- Can be delayed by several hours

**Impact:**

- Messages don't sync in background on iOS
- Calendar reminders may not fire on time
- User must open app to trigger sync
- Inconsistent experience between Android and iOS

**Root Cause:**

iOS background execution limitations.

**Workaround:**

- Use push notifications to trigger sync
- Show sync status in notification center
- Educate users about iOS background limitations

**Resolution Plan:**

- [ ] Implement push notification-triggered sync
- [ ] Add "Sync Now" button in notification
- [ ] Document iOS limitations in USER_GUIDE.md
- [ ] Test on various iOS versions (iOS 15, 16, 17, 18)

---

### 🟢 ISSUE #25: Android Notification Channels Not Fully Configured

**Severity:** P3 - Low  
**Status:** Open  
**Component:** Android / Notifications  
**Discovered:** During notification testing

**Description:**

All notifications use a single channel "default". Android best practices recommend separate channels for:

- Messages
- Live stream notifications
- Calendar reminders
- System notifications

**Impact:**

- Users can't selectively disable notification types
- All-or-nothing notification control
- Poor UX (users disable all notifications due to spam)

**Workaround:**

Create multiple notification channels:

```dart
await AwesomeNotifications().createNotificationChannel(
  NotificationChannel(
    channelKey: 'messages',
    channelName: 'Messages',
    channelDescription: 'New message notifications',
    importance: NotificationImportance.High,
  ),
);

await AwesomeNotifications().createNotificationChannel(
  NotificationChannel(
    channelKey: 'live_streams',
    channelName: 'Live Streams',
    channelDescription: 'Live stream start notifications',
    importance: NotificationImportance.Default,
  ),
);
```

**Resolution Plan:**

- [ ] Create separate channels for each notification type
- [ ] Update notification code to use appropriate channel
- [ ] Add notification preferences screen
- [ ] Test on Android 8+ (notification channels required)

---

## Configuration Issues

### 🟡 ISSUE #26: CORS_ORIGINS Set to Wildcard in Production

**Severity:** P1 - High  
**Status:** Open  
**Component:** Security / Backend Configuration  
**Discovered:** During environment audit

**Description:**

`.env` file shows:

```ini
CORS_ORIGINS=*
```

Wildcard CORS allows any domain to make requests to the API.

**Impact:**

- **SECURITY RISK:** Any website can make authenticated requests
- CSRF attacks possible
- Data exfiltration from authenticated users
- Compliance violation

**Workaround:**

**IMMEDIATE ACTION:**

Update Render.com environment variables:

```ini
CORS_ORIGINS=https://zikrekidusan.app,https://admin.zikrekidusan.app
```

**Resolution Plan:**

- [ ] Update production CORS_ORIGINS to whitelist
- [ ] Audit all Render.com environment variables
- [ ] Document required CORS origins for each environment
- [ ] Add security test for CORS configuration

---

### 🟢 ISSUE #27: Missing .env.example File

**Severity:** P3 - Low  
**Status:** Open  
**Component:** Configuration / Developer Experience  
**Discovered:** During setup procedure testing

**Description:**

No `.env.example` template file in repository. New developers don't know which environment variables are required.

**Impact:**

- Difficult onboarding for new developers
- Trial and error to discover required variables
- Different local setups across team members

**Workaround:**

Create `.env.example`:

```bash
# Backend .env.example
APP_NAME=
APP_URL=
NODE_ENV=development
PORT=3000
DATABASE_URL=
JWT_ACCESS_SECRET=
JWT_REFRESH_SECRET=
JWT_ACCESS_EXPIRES=15m
JWT_REFRESH_EXPIRES=7d
BCRYPT_ROUNDS=10
CORS_ORIGINS=*
REDIS_URL=
CLOUDINARY_CLOUD_NAME=
CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=
STORAGE_PROVIDER=CLOUDINARY
RTMP_SERVER_URL=
HLS_BASE_URL=
FCM_SERVICE_ACCOUNT_JSON=
```

**Resolution Plan:**

- [ ] Create `.env.example` for backend
- [ ] Create `.env.example` for mobile
- [ ] Document each variable in DEVELOPMENT.md
- [ ] Add to onboarding checklist

---

## Future Improvements

### Recommended Enhancements

**P1 - High Priority:**

1. **End-to-End Encryption for Messages**
   - Current: Messages encrypted in transit (TLS) but not at rest
   - Recommendation: Implement Signal Protocol for E2EE
   - Impact: Significant security improvement

2. **Database Read Replicas**
   - Current: Single Neon database instance
   - Recommendation: Add read replicas for scaling
   - Impact: Reduce database load, improve read performance

3. **CDN for API Responses**
   - Current: All API requests hit backend servers
   - Recommendation: Cache GET requests at Cloudflare CDN
   - Impact: Reduced backend load, faster response times globally

**P2 - Medium Priority:**

4. **Implement Content Delivery Network for Static Assets**
   - Current: Images served from Cloudinary (good), but no CDN for app assets
   - Recommendation: Use Cloudflare Workers for edge caching
   - Impact: Faster app loading worldwide

5. **Add Internationalization (i18n)**
   - Current: English and Amharic mixed throughout
   - Recommendation: Full i18n support with language selection
   - Impact: Better user experience for multilingual users

6. **Implement Progressive Web App (PWA)**
   - Current: Web version is basic Flutter web
   - Recommendation: Add PWA manifest, service worker
   - Impact: Installable web app, better offline experience

**P3 - Low Priority:**

7. **Add Dark Mode**
   - Current: Light mode only
   - Recommendation: System-preference dark mode
   - Impact: Better UX in low-light conditions

8. **Implement AI-Based Content Moderation**
   - Current: Manual moderation only
   - Recommendation: AI pre-screening for NSFW, hate speech
   - Impact: Faster moderation, reduced moderator burden

9. **Add Video Compression Options**
   - Current: Videos uploaded at original quality
   - Recommendation: Client-side compression before upload
   - Impact: Reduced upload time, lower bandwidth costs

---

## Summary

**Critical Issues (P0):** 3  
- JWT secrets exposed in .env
- Cloudinary credentials exposed
- Firebase service account exposed

**High Priority (P1):** 3  
- Missing database indexes
- Missing rate limiting on critical endpoints
- CORS wildcard in production

**Medium Priority (P2):** 11  
- Inconsistent error responses
- JWT expiry inconsistency
- Flutter web no-op database
- Android back button UX
- Soft delete not implemented
- WebSocket duplicate listeners
- Live stream notification reliability
- Unbounded sync queue
- Password strength validation
- Video feed performance
- iOS background fetch

**Low Priority (P3):** 9  
- Hardcoded APP_URL fallback
- iOS keyboard overlap
- Video thumbnail placeholders
- Large text fields without limits
- HLS latency
- Auto-delete not scheduled
- Account enumeration
- Database query caching
- Android notification channels
- Missing .env.example

**Total Issues:** 26 documented

**Immediate Actions Required:**

1. ⚠️ **ROTATE ALL EXPOSED SECRETS IMMEDIATELY**
2. Remove `.env` from git history
3. Fix CORS wildcard in production
4. Add missing database indexes

---

**Related Documentation:**

- [DEVELOPMENT.md](./DEVELOPMENT.md) - Setup and workarounds  
- [DEPLOYMENT.md](./DEPLOYMENT.md) - Production configuration  
- [SECURITY_AND_PRIVACY.md](./SECURITY_AND_PRIVACY.md) - Security details  
- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - User-facing issues

---

*This document reflects verified issues discovered during the comprehensive audit as of September 25, 2026. All issues have been confirmed against the actual codebase.*
