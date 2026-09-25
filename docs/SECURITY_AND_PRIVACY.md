# Security and Privacy Guide

**Zikire Kdusan (StreamHub) - How We Keep You Safe**

This guide explains the security and privacy features built into Zikire Kdusan in plain language. Understanding these mechanisms helps you make informed decisions about your data and account security.

---

## Table of Contents

1. [Account Security](#account-security)
2. [Password Security](#password-security)
3. [Authentication & Sessions](#authentication--sessions)
4. [Data Privacy](#data-privacy)
5. [Communication Security](#communication-security)
6. [Content Privacy](#content-privacy)
7. [Group & Channel Privacy](#group--channel-privacy)
8. [Location & Device Permissions](#location--device-permissions)
9. [Data Collection & Usage](#data-collection--usage)
10. [Third-Party Services](#third-party-services)
11. [User Rights & Controls](#user-rights--controls)
12. [Security Best Practices](#security-best-practices)
13. [Reporting Security Issues](#reporting-security-issues)

---

## Account Security

### How Your Account is Protected

**Registration & Identity Verification**

When you create an account, the system verifies your identity through:

- **Email Verification**: Confirms you own the email address
- **Phone Verification**: Optional, confirms phone number ownership
- **Unique Username**: Prevents impersonation by requiring unique usernames

**Why This Matters**: Verification prevents fake accounts and ensures you're a real person. It also provides account recovery options if you forget your password.

---

### Brute Force Protection

**What It Is**: Protection against attackers trying to guess your password by attempting many combinations rapidly.

**How It Works**:
- System tracks failed login attempts per account
- After **5 consecutive failed attempts**, your account is temporarily locked
- Lockout duration: **15 minutes**
- Counter resets after successful login

**What This Means for You**:
- ✅ **Good**: Protects your account even if you use a simple password
- ⚠️ **Note**: If you're locked out, wait 15 minutes or use "Forgot Password"
- 💡 **Tip**: Use a password manager to avoid lockouts from typos

**Example Scenario**:
```
Attempt 1-4: Wrong password → "Incorrect credentials" message
Attempt 5: Wrong password → Account locked for 15 minutes
After 15 minutes: Can try again or reset password anytime
```

---

### Session Management

**What Are Sessions?**
A session is your active login period. Once logged in, you don't need to enter credentials for every action.

**How Sessions Work**:
- When you log in successfully, system creates a session
- Session allows you to use the app without re-entering password
- Multiple sessions supported: You can be logged in on phone, tablet, and web simultaneously
- Each session is independent: Logging out on one device doesn't affect others

**Session Security**:
- Sessions tied to device and app installation
- Clearing app data ends session (requires re-login)
- Changing password invalidates all sessions (security feature)

---

### Account Takeover Prevention

**Security Measures**:

1. **Password Change Notification**
   - If your password changes, you're notified via email/phone
   - Allows you to take action if unauthorized

2. **Session Invalidation on Password Change**
   - Changing password logs out all devices
   - Ensures attacker can't stay logged in after you change password
   - You'll need to log in again on all devices

3. **Failed Login Notifications** (if implemented)
   - May notify you of repeated failed login attempts
   - Alerts you to potential attack on your account

**What to Do If You Suspect Compromise**:
1. Change your password immediately
2. Check recent account activity
3. Review active sessions (if feature available)
4. Enable two-factor authentication (if available)
5. Contact support if suspicious activity detected

---

## Password Security

### How Passwords Are Stored

**The Technical Side (Simplified)**:

Your password is **never stored in plain text**. Here's what happens:

1. **You enter password**: `MySecretPassword123`
2. **System hashes it**: Converts it to a long string like `$2b$10$N9qo8...` using bcrypt algorithm
3. **Only hash is stored**: Original password is discarded immediately
4. **Login verification**: System hashes your entry and compares hashes, not passwords

**Why This Matters**:
- ✅ Even database administrators cannot see your password
- ✅ If database is compromised, attackers get useless hashes, not passwords
- ✅ Each password has unique hash (salt) making cracking very difficult

**Bcrypt Algorithm**:
- Industry-standard password hashing
- Computationally expensive (slows down cracking attempts)
- Automatically adds unique "salt" to each password
- Used by major platforms like GitHub, Facebook, Twitter

---

### Password Requirements

**Current Requirements** (based on implementation):

**Minimum Standards**:
- At least **8 characters long**
- No maximum length limit (within reason)

**Recommendations** (best practices):
- Mix uppercase and lowercase letters
- Include numbers
- Include special characters (!@#$%^&*)
- Avoid common words or patterns
- Don't reuse passwords from other sites

**Example Passwords**:
- ❌ Weak: `password`, `12345678`, `username123`
- ⚠️ Okay: `mypassword123` (meets minimum but predictable)
- ✅ Strong: `T7g!mK3p@Qx9`, `Horse-Battery-Staple-42!`

---

### Password Reset Process

**How Password Reset Works** (security perspective):

1. **Request Reset**:
   - You click "Forgot Password"
   - Enter your email/username
   - System sends reset link (if account exists)

2. **Security Token**:
   - Reset link contains unique, time-limited token
   - Token is random and impossible to guess
   - Expires after short period (typically 15-60 minutes)

3. **Reset Password**:
   - Click link, enter new password
   - Token is validated and consumed (can only be used once)
   - All existing sessions are invalidated

**Security Features**:
- Reset links work only once
- Links expire quickly
- System doesn't reveal if email exists (prevents account enumeration)
- Old password cannot be reused immediately

**What to Do After Password Reset**:
- Log in on all your devices with new password
- Update saved passwords in password manager
- Review account activity for anything suspicious

---

## Authentication & Sessions

### JWT Token System

**What Are Tokens?**
Instead of sending your password with every request, the system uses tokens — temporary digital keys that prove you're logged in.

**How Zikire Kdusan Uses Tokens**:

The system uses **two types of tokens**:

#### 1. Access Token (Short-Lived)
- **Lifespan**: 15 minutes
- **Purpose**: Authorizes your actions (like posting, messaging)
- **Storage**: Kept in memory on your device
- **Security**: Short lifespan limits damage if stolen

#### 2. Refresh Token (Long-Lived)
- **Lifespan**: 7 days
- **Purpose**: Gets you new access tokens without re-entering password
- **Storage**: Stored securely on your device
- **Security**: Can be revoked if compromise is detected

**How They Work Together**:

```
Login → Get both tokens → Use access token for 15 minutes
→ Access token expires → Refresh token gets new access token
→ Use new access token for 15 minutes → Repeat
→ After 7 days: Refresh token expires → Must log in again
```

**What This Means for You**:
- ✅ You stay logged in for up to 7 days without entering password
- ✅ If inactive for 7+ days, you'll need to log in again (security feature)
- ✅ Even if someone steals your access token, it expires in 15 minutes
- ⚠️ If someone steals refresh token, they can access account for up to 7 days (change password to revoke)

---

### Session Expiration & Timeout

**When Sessions Expire**:

1. **Automatic Expiration**:
   - After 7 days of inactivity (refresh token expires)
   - When you log out manually
   - When you change your password
   - When you clear app data/cache

2. **Forced Expiration**:
   - Security events (suspicious activity detected)
   - Account recovery operations
   - Administrative actions

**What Happens When Session Expires**:
- You're redirected to login screen
- Unsent messages/actions are queued (sent after re-login)
- Offline data remains available
- Simply log in again to continue

**Security Benefit**:
Automatic expiration means old sessions don't stay active forever, reducing risk if you lose a device or forget to log out.

---

### Multi-Device Sessions

**How It Works**:
- You can be logged in on multiple devices simultaneously
- Each device has its own independent session
- Actions on one device sync to others in real-time (when online)

**Session Independence**:
- Logging out on phone doesn't log you out on tablet
- Each device needs its own login
- Changing password logs out ALL devices (security feature)

**Security Considerations**:

**Advantages**:
- ✅ Convenience: Stay logged in on all your devices
- ✅ Flexibility: Use app anywhere without repeated logins

**Risks**:
- ⚠️ If you lose a device, session may remain active
- ⚠️ Shared devices may have lingering sessions

**Protection**:
- Change password to invalidate all sessions if device is lost
- Always log out on shared/public devices
- Consider enabling device management features (if available)

---

## Data Privacy

### What Data We Collect

Based on the system implementation, here's what data the platform collects:

#### Account Data
- **Required**:
  - Username (unique identifier)
  - Email address
  - Password (stored as hash only)
  - Account creation date
- **Optional**:
  - Phone number
  - Display name
  - Profile photo
  - Bio/description
  - Birth date

#### Usage Data
- **Activity**:
  - Videos watched (watch history)
  - Search queries
  - Posts, comments, likes
  - Group memberships
  - Subscriptions
- **Technical**:
  - Login timestamps
  - Failed login attempts
  - Device information (for session management)
  - IP address (for security)

#### Content You Create
- Videos uploaded
- Posts and comments
- Messages sent
- Live streams
- Calendar notes
- Stories and reels

#### Analytics & Performance
- App usage patterns
- Feature engagement
- Performance metrics
- Error logs (for debugging)

---

### How Your Data Is Used

**Primary Uses**:

1. **Service Delivery**:
   - Display your profile to other users
   - Deliver messages and notifications
   - Personalize your feed and recommendations
   - Provide search results

2. **Security & Fraud Prevention**:
   - Detect and prevent unauthorized access
   - Identify and stop spam/abuse
   - Enforce terms of service
   - Protect other users

3. **Service Improvement**:
   - Analyze usage patterns to improve features
   - Fix bugs and performance issues
   - Develop new features
   - Optimize user experience

4. **Communication**:
   - Send you notifications about account activity
   - Inform you of service updates
   - Respond to your support requests
   - Send important security alerts

**What We Don't Do**:
- ❌ Sell your personal data to third parties
- ❌ Share your private messages with advertisers
- ❌ Use your data for purposes you didn't consent to
- ❌ Access your data without legitimate reason

---

### Data Retention

**How Long We Keep Your Data**:

#### Active Accounts
- **Profile data**: As long as your account exists
- **Content**: As long as you don't delete it
- **Messages**: Stored until you delete conversation
- **Watch history**: May be retained for recommendations
- **Analytics**: Aggregated data may be kept longer

#### Deleted Accounts
- **Immediate deletion**: Login credentials, session tokens
- **Gradual deletion**: Personal data removed within 30-90 days
- **Retention**: Some data may be kept for legal/safety reasons:
  - Security logs (to prevent ban evasion)
  - Transaction records (legal requirements)
  - Aggregated analytics (anonymized)

#### Content You Delete
- **Posts/Comments**: Removed immediately from public view
- **Messages**: Deleted from your view; may persist in recipient's view
- **Videos**: Removed from platform; may take time to delete from CDN
- **Backups**: May persist in backups for 30-90 days

---

### Data Portability

**Accessing Your Data** (if implemented):

You may have the right to:
- Download a copy of your data
- Export your content (videos, posts, messages)
- Transfer data to another service
- Request data correction or deletion

**How to Request** (verify availability):
- Settings → Privacy → Download My Data
- Settings → Account → Export Data
- Contact support for assistance

**What You Can Export**:
- Profile information
- Posted content
- Messages and comments
- Watch history
- Subscriptions and preferences

---

## Communication Security

### Message Encryption

**Current Implementation** (based on audit):

**In-Transit Encryption** ✅
- All communication between app and server uses **HTTPS/TLS**
- Messages encrypted during transmission
- Prevents eavesdropping on network
- Industry-standard encryption (TLS 1.2 or higher)

**At-Rest Encryption** (database):
- Messages stored in Neon PostgreSQL database
- Database has encryption at rest (provided by Neon)
- Server-side encryption protects against storage theft

**End-to-End Encryption (E2EE)** ❌
- **Not implemented** in current system
- Server can read message content
- Messages are visible to platform administrators (for moderation)
- Standard approach for platforms with content moderation

**What This Means**:
- ✅ Your messages are protected from hackers intercepting network traffic
- ✅ Messages are encrypted in database storage
- ⚠️ Platform administrators can access messages (for safety/moderation)
- ⚠️ Not suitable for highly sensitive communications requiring E2EE

**When E2EE Matters**:
- Ultra-sensitive personal conversations
- Financial or medical information
- Whistleblowing or journalism
- High-risk political/activist communications

For these use cases, consider platforms with E2EE (Signal, WhatsApp, iMessage).

---

### WebSocket Security

**Real-Time Features**:
- Live chat during streams
- Floating reactions
- Real-time notifications
- Online status indicators

**How WebSocket Is Secured**:

1. **Secure Connection**:
   - Uses **WSS** (WebSocket Secure) protocol
   - Equivalent to HTTPS for WebSockets
   - Encrypted connection prevents eavesdropping

2. **Authentication**:
   - Must provide valid JWT token to establish WebSocket connection
   - Server verifies token before accepting connection
   - Unauthorized users cannot connect

3. **Authorization**:
   - Each WebSocket event checked against permissions
   - Cannot send messages to groups you're not in
   - Cannot see private streams without access

**Security Implications**:
- ✅ Real-time messages are encrypted in transit
- ✅ Only authenticated users can connect
- ✅ Permissions enforced for all real-time actions
- ⚠️ WebSocket connections may not work on highly restrictive networks (security software may block)

---

### Group Message Privacy

**How Group Messages Work**:

**Visibility**:
- Messages visible to all group members with appropriate role
- GROUP_ADMIN and MODERATOR roles can see all messages
- MEMBER and GUEST roles see messages in channels they can access
- Private channels restrict visibility further

**Message Retention**:
- Group messages stored in database indefinitely
- Group admins cannot delete other users' messages (typically)
- Moderators may have message deletion permissions
- Leaving group doesn't delete your past messages

**Privacy Considerations**:

**Think Before You Send**:
- ⚠️ Group messages are seen by all members (current and future)
- ⚠️ Group admins add new members who can see message history
- ⚠️ Screenshots can be taken by any member
- ⚠️ Deleted messages may be cached on devices

**Best Practices**:
- Don't share sensitive personal information in groups
- Assume group messages are permanent
- Verify group membership before posting sensitive content
- Use direct messages for private conversations

---

## Content Privacy

### Content Visibility Controls

**Who Can See Your Content?**

Content visibility depends on where and how you post:

#### Videos
- **Public videos**: Anyone can see, search, share
- **Unlisted videos**: Anyone with link can see (not in search)
- **Private videos**: Only you (or specified users) can see
- **Group videos**: Only group members can see

#### Posts
- **Public posts**: Visible to all users
- **Group posts**: Visible to group members only
- **Private groups**: Posts only visible to group members

#### Profile
- **Public profile**: Username, display name, bio visible to all
- **Private profile** (if implemented): Limited info visible to non-followers
- **Activity**: What's visible depends on privacy settings

#### Live Streams
- **Public streams**: Anyone can watch, appears in "Live Now"
- **Group-only streams**: Only group members can watch
- **Private group streams**: Only members of private group can watch

---

### Content Moderation & Review

**How Content Is Monitored**:

#### Automated Moderation
- System may scan for prohibited content (spam, harmful material)
- Algorithms flag potentially violating content for review
- Automated filters for common issues

#### Human Moderation
- Moderators and admins can review reported content
- Platform staff may review flagged content
- Group moderators oversee group content

**What Moderators Can See**:
- ✅ Your public posts and comments
- ✅ Content you post in groups they moderate
- ✅ Reported content
- ✅ Metadata about content (upload time, edit history)
- ❌ Your private messages (unless specifically reported)
- ❌ Content in groups they're not moderators of

**Privacy Implication**:
- Content moderation requires platform access to your posts
- Trade-off between privacy and community safety
- Reported content may be reviewed by multiple staff members

---

### Deleted Content

**What Happens When You Delete**:

#### Immediate Effects
- Content removed from public view instantly
- No longer appears in feeds, search results, your profile
- Links to content return "not found" error

#### Backend Cleanup
- Content may be "soft deleted" (hidden but not erased immediately)
- Database record marked as deleted
- Media files queued for deletion from storage/CDN

#### Permanent Deletion Timeline
- **Database**: Permanent removal may take days to weeks
- **CDN/Storage**: Files deleted from Cloudinary/storage within hours to days
- **Caches**: May persist in various caches temporarily
- **Backups**: May remain in backups for 30-90 days

**Cannot Be Recovered**:
- ⚠️ Once permanently deleted, content cannot be recovered
- ⚠️ No "undo" after deletion completes
- 💡 Consider downloading important content before deleting

**What Persists**:
- References/replies from other users may remain (with your content removed)
- Analytics/aggregated data (anonymized)
- Moderation records (if content was reported)

---

## Group & Channel Privacy

### Public vs Private Groups

**Public Groups**:

**Characteristics**:
- ✅ Anyone can see group exists
- ✅ Anyone can see member list
- ✅ Anyone can see group content (posts, videos)
- ✅ Joining may be open or require approval
- ✅ Appears in search results

**Best For**:
- Communities open to everyone
- Public discussions
- Content creators building audience
- Educational or informational groups

**Privacy Level**: Low
- Assume anything you post is publicly visible
- Search engines may index content
- Non-members can view without account

---

**Private Groups**:

**Characteristics**:
- ✅ Only members can see group content
- ✅ Group may be hidden from search (depends on settings)
- ✅ Member list only visible to members
- ⚠️ Joining requires approval from admin
- ⚠️ May still appear in search (name/description visible)

**Best For**:
- Close-knit communities
- Sensitive discussions
- Exclusive content
- Family or friend groups

**Privacy Level**: Medium
- Content not publicly visible
- Membership required for access
- Still not end-to-end encrypted
- Group admins can see all content

**Not Private**:
- Group name and description may be public
- Group existence may be visible
- Admins and moderators see all content
- Platform staff can access for moderation

---

### Group Role Privacy

**What Group Roles Can See**:

#### GUEST
- Public group content (if allowed)
- May not see member list
- Cannot see private channels

#### MEMBER
- All public channels in group
- Member list (depending on settings)
- Group announcements
- May access some private channels

#### MODERATOR
- All group content (including private channels)
- Member activity and reports
- Moderation logs
- May see edit history of posts

#### GROUP_ADMIN
- Everything moderators can see
- Member permissions and roles
- Group settings and configuration
- Analytics and insights
- All member activities

**Privacy Implications**:
- Higher roles have more visibility into group activities
- Admins can see detailed member engagement
- Moderators monitor content and behavior
- Trust group leadership before posting sensitive content

---

### Channel Privacy Within Groups

**Channel Types**:

1. **Public Channels** (within group):
   - All group members can see
   - Default channel type

2. **Private Channels** (if implemented):
   - Only members with specific permissions can see
   - Useful for admin discussions or sub-groups
   - Must be invited to access

3. **Announcement Channels**:
   - Everyone can see, only admins/moderators can post
   - Read-only for most members

**Privacy Tips**:
- Check channel settings before posting
- Verify who has access to channel
- Use appropriate channel for sensitivity level
- Remember admins always have access to all channels

---

## Location & Device Permissions

### What Permissions the App Requests

**Camera** 🎥
- **Used For**: Taking photos, recording videos, live streaming
- **Access**: Only when actively using camera features
- **Privacy**: Not accessed in background
- **Can Disable**: Yes, prevents camera-based features

**Microphone** 🎙️
- **Used For**: Recording videos, live streaming, voice messages (if supported)
- **Access**: Only when actively recording
- **Privacy**: Not accessed in background
- **Can Disable**: Yes, prevents audio features

**Photos/Storage** 📁
- **Used For**: Uploading photos/videos, downloading content, caching
- **Access**: When you upload/download content
- **Privacy**: Only accesses files you explicitly select
- **Can Disable**: Yes, prevents upload/download

**Notifications** 🔔
- **Used For**: Message alerts, live notifications, updates
- **Access**: Permission to send notifications
- **Privacy**: No data collected, just delivery mechanism
- **Can Disable**: Yes, prevents push notifications

**Location** 📍 (if used)
- **Used For**: Local recommendations, event features, timezone
- **Access**: Depends on implementation (check app settings)
- **Privacy**: May share approximate or precise location
- **Can Disable**: Yes, may affect location-based features

**Contacts** 📞 (if used)
- **Used For**: Finding friends on platform
- **Access**: Only if you grant permission
- **Privacy**: Contacts uploaded for matching, may be stored
- **Can Disable**: Yes, find friends manually instead

---

### Managing Permissions

**How to Review Permissions**:

**Android**:
1. Device Settings → Apps → Zikire Kdusan → Permissions
2. Review each permission
3. Toggle on/off as desired
4. Choose "Ask every time" for selective access

**iOS**:
1. Settings → Privacy → [Permission Type]
2. Find Zikire Kdusan
3. Toggle on/off
4. Some permissions have "Ask Next Time" option

**Impact of Disabling Permissions**:
- ❌ Camera: Cannot take photos, record videos, or live stream
- ❌ Microphone: Videos have no audio, cannot live stream
- ❌ Storage: Cannot upload or download content
- ❌ Notifications: Won't receive alerts (can still check app manually)
- ⚠️ Location: May affect timezone, local content

**Recommendations**:
- Enable only permissions you actually use
- Review permissions periodically
- Disable unnecessary permissions for privacy
- Re-enable temporarily when needed

---

### Background Activity

**What Happens When App Is Closed**:

**Background Processes**:
- **Message sync**: Every 15 minutes, syncs new messages
- **Notifications**: Receives push notifications
- **Upload queue**: Completes pending uploads (if enabled)
- **Download completion**: Finishes active downloads

**What Doesn't Happen**:
- ❌ Camera/microphone not accessed
- ❌ Continuous location tracking (if location used)
- ❌ Constant data sync (only periodic)

**Controlling Background Activity**:

**Android**:
- Settings → Apps → Zikire Kdusan → Battery → Optimize battery usage
- Restricting background activity may delay notifications/sync

**iOS**:
- Settings → General → Background App Refresh
- Disabling may delay message delivery

**Privacy vs Convenience**:
- More background access = faster sync & notifications
- Less background access = better privacy & battery life
- Choose based on your priorities

---

## Data Collection & Usage

### Analytics & Tracking

**What We Track**:

#### Usage Analytics
- Features used and frequency
- Time spent in app
- Navigation patterns
- Button clicks and interactions
- Error occurrences

#### Content Analytics
- Videos watched (which, duration, completion rate)
- Search queries
- Likes, comments, shares
- Subscriptions and follows
- Group engagement

#### Technical Analytics
- App version and device type
- Operating system version
- Network type (WiFi, mobile data)
- App performance metrics
- Crash reports

**Purpose**:
- Improve app performance
- Fix bugs and errors
- Understand feature usage
- Prioritize development
- Optimize user experience

**Privacy Considerations**:
- ✅ Analytics typically anonymized or aggregated
- ✅ Used internally for product improvement
- ⚠️ May be shared with analytics services (Google Analytics, etc.)
- ⚠️ Combined with account data for personalization

---

### Recommendations Algorithm

**How Content Is Recommended**:

The app recommends videos, groups, and users based on:

#### Your Activity
- Videos you watched
- Content you liked, shared, commented on
- Subscriptions and follows
- Search history
- Time spent watching specific content

#### Similar Users
- What users with similar interests watch
- Collaborative filtering algorithms
- Popular content in your demographic

#### Content Attributes
- Video categories and tags
- Description and title
- Upload date (freshness)
- Engagement metrics (views, likes)

**Privacy Implications**:

**Data Used**:
- Your watch history is analyzed
- Likes and interactions inform recommendations
- Search queries reveal interests

**What This Means**:
- ⚠️ Platform knows your viewing preferences
- ⚠️ Can infer interests and demographics
- ✅ Used to personalize your experience
- ✅ Typically not sold to third parties

**Controlling Recommendations**:
- Clear watch history (Settings → Privacy)
- Unlike content you're not interested in
- Use Incognito/Private mode (if available)
- Interact with content you want more of

---

### Third-Party Analytics (if used)

**Common Third-Party Services**:

These are typical services used (verify in privacy policy):

#### Firebase (Google)
- **Purpose**: Push notifications, crash reporting, analytics
- **Data Shared**: Device info, usage patterns, crash logs
- **Privacy Policy**: Google Firebase Privacy

#### Cloudinary
- **Purpose**: Video/image storage and streaming
- **Data Shared**: Media you upload, viewer analytics
- **Privacy Policy**: Cloudinary Privacy Policy

#### Neon PostgreSQL
- **Purpose**: Database hosting
- **Data Shared**: All app data stored in database
- **Privacy Policy**: Neon Privacy Policy

**What This Means**:
- Third parties have access to certain data
- Subject to their privacy policies
- Necessary for service delivery
- Choose providers with strong privacy practices

---

## User Rights & Controls

### Privacy Settings & Controls

**Account Privacy Controls** (availability depends on implementation):

#### Profile Privacy
- Public vs Private profile
- Hide email/phone from profile
- Control who can see your posts
- Hide your online status

#### Activity Privacy
- Hide watch history
- Disable activity status
- Prevent search indexing
- Control who can see your subscriptions

#### Communication Privacy
- Control who can message you (Everyone, Followers, No One)
- Control who can comment on your posts
- Block/mute users
- Report harassment

#### Content Privacy
- Set default video visibility (Public, Unlisted, Private)
- Control who can download your videos
- Set group post visibility
- Archive or hide old content

**Where to Find Settings**:
- App → Settings → Privacy
- Profile → Edit Profile → Privacy Settings
- Individual content → Visibility Options

---

### Blocking & Muting

**Blocking a User**:

**What Happens**:
- They cannot send you messages
- They cannot see your posts (depending on platform implementation)
- They cannot comment on your content
- They cannot see your profile (or see limited info)
- You won't see their content in feeds

**They Are Not Notified**:
- Blocking is silent
- User may deduce they're blocked (can't message you)
- Your profile appears non-existent or restricted to them

**You Can Still See** (if you choose):
- Their profile (by searching)
- Their public posts (if you explicitly visit their profile)
- Allows monitoring if necessary

**Unblocking**:
- Can unblock anytime
- Previous messages/connections not restored
- Must re-follow, re-friend, etc.

---

**Muting a User or Group**:

**What Happens**:
- You don't see their posts in your feed
- You don't receive notifications from them
- They are NOT notified
- They can still message you (messages go to a filtered folder, depending on implementation)

**Difference from Blocking**:
- Less severe than blocking
- They can still interact with you
- Just reduces visibility in your experience

**Use Cases**:
- Temporarily reduce noise from active friend/group
- Hide content without unfollowing
- Avoid confrontation of unfollowing

---

### Reporting & Safety

**What You Can Report**:

- **Harassment or bullying**: Targeted attacks, threats
- **Spam**: Unwanted promotional content, scams
- **Impersonation**: Fake accounts pretending to be someone else
- **Inappropriate content**: Violates community guidelines
- **Self-harm or suicide threats**: Urgent safety concerns
- **Copyright infringement**: Unauthorized use of copyrighted content
- **Privacy violations**: Sharing private information without consent

**How to Report**:
1. Find report option on content/profile (usually three-dot menu)
2. Select reason for report
3. Provide additional details (optional but helpful)
4. Submit report

**What Happens After Reporting**:
- Report is reviewed by moderation team
- Typically reviewed within 24-72 hours
- Action taken if violation confirmed:
  - Content removed
  - Warning issued to user
  - Account suspended or banned
- You may receive notification of outcome

**Your Privacy When Reporting**:
- Reports are confidential
- Reported user typically doesn't see who reported them
- Moderators see report details but handle confidentially

---

### Account Deletion

**How to Delete Your Account** (if implemented):

1. **Backup Your Data** (optional but recommended):
   - Download your content (videos, posts, messages)
   - Export data if feature available
   - Save anything important locally

2. **Initiate Deletion**:
   - Settings → Account → Delete Account
   - May require password re-entry
   - Confirm deletion (may have warning/confirmation screen)

3. **Grace Period** (if applicable):
   - Account may deactivate immediately
   - Permanent deletion after 30 days
   - Can cancel deletion during grace period by logging in

**What Gets Deleted**:
- ✅ Profile information (name, email, phone)
- ✅ Login credentials
- ✅ Your posts and comments
- ✅ Your messages (from your view; may persist in recipient's view)
- ✅ Your uploaded videos
- ✅ Your watch history and preferences
- ✅ Your subscriptions and follows

**What May Remain**:
- ⚠️ Comments/replies from others on your deleted posts (your content removed, their reply may stay)
- ⚠️ Group content you contributed (depending on policy)
- ⚠️ Anonymized analytics data
- ⚠️ Legal records if required by law

**Cannot Be Undone**:
- Permanent deletion is irreversible
- Cannot recover account or data after deletion completes
- Username may become available for reuse

---

## Third-Party Services

### External Services We Use

Based on the implementation, Zikire Kdusan integrates with external services for various functions:

#### **Cloudinary** (Media Storage & Streaming)

**What It Does**:
- Stores your uploaded videos and images
- Delivers video streams to viewers
- Processes and optimizes media
- Handles live streaming (RTMP/HLS)

**Data Shared**:
- Videos and images you upload
- Viewer analytics (who watched, duration, geography)
- Stream metadata

**Privacy Implications**:
- Your media content is stored on Cloudinary servers
- Subject to Cloudinary's privacy policy
- Industry-standard security practices
- Data stored in Cloudinary's data centers (location varies)

**Learn More**: [Cloudinary Privacy Policy](https://cloudinary.com/privacy)

---

#### **Neon PostgreSQL** (Database Hosting)

**What It Does**:
- Hosts the application database
- Stores user accounts, messages, posts, etc.
- Provides database reliability and backups

**Data Shared**:
- All application data (accounts, content, interactions)
- Encrypted at rest and in transit

**Privacy Implications**:
- All your account and activity data stored here
- Subject to Neon's privacy and security practices
- Neon has encryption and security measures in place

**Learn More**: [Neon Privacy & Security](https://neon.tech/privacy-policy)

---

#### **Firebase / Google Cloud** (If Used)

**Potential Uses**:
- Push notifications
- Crash reporting and analytics
- Cloud functions

**Data Shared**:
- Device tokens for notifications
- App usage analytics
- Crash reports and error logs

**Privacy Implications**:
- Google has access to analytics data
- Subject to Google's privacy policy
- Can opt out of analytics in app settings

---

#### **Email Service Provider**

**What It Does**:
- Sends verification emails
- Delivers password reset emails
- Sends notification emails

**Data Shared**:
- Your email address
- Content of transactional emails
- Email engagement (opens, clicks)

**Privacy Implications**:
- Email provider can see sender, recipient, subject
- Transactional emails (not marketing without consent)
- Industry-standard email security (TLS)

---

### Third-Party Access Control

**OAuth / Third-Party Apps** (if implemented):

If the platform supports third-party integrations or OAuth:

**What Is OAuth**:
- Allows you to authorize third-party apps to access your Zikire Kdusan account
- Example: "Sign in with Zikire Kdusan" on another website
- You control what permissions each app has

**Permissions Third-Party Apps May Request**:
- Read your profile information
- Post on your behalf
- Access your messages
- View your followers/subscriptions
- Upload content to your account

**Managing Third-Party Access**:
- Review regularly (Settings → Connected Apps)
- Revoke access for apps you no longer use
- Only authorize trusted apps
- Check permissions carefully before approving

**Security Tips**:
- Don't grant more permissions than necessary
- Revoke access if app seems suspicious
- Third-party apps have same access to your data as you (within granted permissions)

---

## Security Best Practices

### For Users

**Account Security**:
1. ✅ Use a strong, unique password (8+ characters, mixed case, numbers, symbols)
2. ✅ Enable two-factor authentication (if available)
3. ✅ Don't share your password with anyone
4. ✅ Log out on shared or public devices
5. ✅ Review active sessions periodically (if feature available)
6. ✅ Change password if you suspect compromise

**Privacy Protection**:
1. ✅ Review privacy settings regularly
2. ✅ Think before posting sensitive information
3. ✅ Use private groups for sensitive discussions
4. ✅ Be cautious about what you share in public groups
5. ✅ Block/report abusive users
6. ✅ Clear watch history if you share your device

**Device Security**:
1. ✅ Keep your device OS updated
2. ✅ Use device lock screen (PIN, pattern, biometric)
3. ✅ Don't root/jailbreak your device (reduces security)
4. ✅ Download apps only from official stores
5. ✅ Review app permissions regularly
6. ✅ Enable "Find My Device" in case of loss

**Network Security**:
1. ⚠️ Avoid public WiFi for sensitive actions (login, password change)
2. ⚠️ Use VPN on public networks (if you trust the VPN provider)
3. ✅ Prefer mobile data for sensitive actions when on public WiFi
4. ✅ Verify you're on HTTPS/secure connection (app handles this)

---

### Recognizing Phishing & Scams

**Common Phishing Attempts**:

1. **Fake Login Pages**:
   - Copycat websites that look like Zikire Kdusan
   - Steal your credentials when you "log in"
   - **Prevention**: Only log in through official app or verified website

2. **Email/SMS Phishing**:
   - "Your account will be suspended" urgent messages
   - Links to fake login pages
   - **Prevention**: Don't click links in suspicious emails; go to app directly

3. **Impersonation**:
   - Fake accounts pretending to be admins or support
   - Asking for password or personal info
   - **Prevention**: Real admins NEVER ask for your password

4. **Prize/Giveaway Scams**:
   - "You won! Click here to claim"
   - Leads to phishing site or malware
   - **Prevention**: Verify giveaways through official channels

**Red Flags**:
- ❌ Urgency ("Act now or lose your account!")
- ❌ Requests for password or sensitive info
- ❌ Suspicious links (check URL carefully)
- ❌ Poor grammar or spelling
- ❌ Unexpected attachments
- ❌ Too good to be true offers

**What to Do If You Suspect Phishing**:
1. Don't click links or download attachments
2. Don't provide credentials or personal info
3. Report the message/account to platform admins
4. Delete the message
5. If you clicked a link or entered credentials, change your password immediately

---

### Safe Sharing Practices

**What to Share Safely**:
- ✅ Username and display name (designed to be public)
- ✅ Content you create (if you're comfortable with it being public)
- ✅ Opinions and interests
- ✅ Public profile information

**What to NEVER Share**:
- ❌ Password or security questions
- ❌ Full credit card or bank account numbers
- ❌ Social Security Number or national ID
- ❌ Home address (unless necessary and you trust the recipient)
- ❌ Phone number publicly (DMs okay if you choose)
- ❌ Private photos you wouldn't want public

**What to Share Cautiously**:
- ⚠️ Email address (enables spam, consider using secondary email)
- ⚠️ Birth date (useful for identity theft)
- ⚠️ Location/check-ins (reveals patterns, wait to post until you leave)
- ⚠️ Travel plans (broadcasting empty home)
- ⚠️ Photos revealing identifiable locations

**Think Before You Post**:
- Would you be comfortable if this was seen by everyone?
- Could this information be used against you?
- Can you delete this later if needed?
- Are you okay with this being permanent (screenshots exist)?

---

## Reporting Security Issues

### If You Discover a Security Vulnerability

**Responsible Disclosure**:

If you find a security bug or vulnerability in Zikire Kdusan:

1. **Do Not**:
   - ❌ Exploit the vulnerability
   - ❌ Access other users' data
   - ❌ Publicly disclose until fixed
   - ❌ Sell or share vulnerability information

2. **Do**:
   - ✅ Report to security team immediately
   - ✅ Provide detailed reproduction steps
   - ✅ Give developers time to fix before public disclosure
   - ✅ Follow responsible disclosure practices

**How to Report**:
- Email: security@[domain] (check app/website for actual address)
- In-app: Settings → Help → Report Security Issue
- Include:
  - Detailed description of vulnerability
  - Steps to reproduce
  - Potential impact
  - Your contact info (for follow-up)

**What to Expect**:
- Acknowledgment within 24-72 hours
- Investigation and assessment
- Fix deployed (timeframe depends on severity)
- Possible recognition/reward (if bug bounty program exists)
- Public disclosure after fix (with your consent)

---

### If Your Account Is Compromised

**Signs of Compromise**:
- Unexplained posts or messages from your account
- Notifications of login from unfamiliar devices/locations
- Password changed without your action
- Friends report strange messages from you
- Account settings changed

**Immediate Actions**:

1. **Change Password Immediately**:
   - Use "Forgot Password" if you can't log in
   - Choose a strong, unique password
   - This will log out all devices

2. **Review Account Activity**:
   - Check recent posts, messages, follows
   - Delete any unauthorized content
   - Undo unwanted actions

3. **Secure Other Accounts**:
   - Change passwords on accounts using same password
   - Enable two-factor authentication elsewhere
   - Check email account for compromise

4. **Notify Contacts**:
   - Inform friends you may have been compromised
   - Warn them about suspicious messages from you

5. **Contact Support**:
   - Report the compromise
   - Request review of account activity
   - Ask about additional security measures

6. **Learn and Prevent**:
   - Identify how compromise occurred (weak password, phishing, malware)
   - Take steps to prevent recurrence
   - Use password manager
   - Enable 2FA

---

## Privacy Policy & Terms

### Understanding Privacy Policy

**What Is a Privacy Policy?**
- Legal document explaining data collection, use, and sharing
- Your rights regarding your data
- How to contact company about privacy concerns

**Key Sections to Read**:
1. **What data is collected** (personal info, usage data, etc.)
2. **How data is used** (service delivery, analytics, advertising)
3. **Who data is shared with** (third parties, partners, law enforcement)
4. **Your rights** (access, deletion, portability, opt-out)
5. **Contact information** (for privacy questions or requests)

**Where to Find It**:
- App → Settings → Privacy Policy
- Website footer
- Usually labeled "Privacy Policy" or "Privacy Notice"

**Recommendation**: Read at least once to understand how your data is handled.

---

### Terms of Service

**What Are Terms of Service?**
- Contract between you and the platform
- Rules you agree to follow
- What the platform promises to provide
- Consequences for violations

**Key Points Usually Covered**:
1. **Acceptable Use**: What you can and cannot do on platform
2. **Content Ownership**: Who owns content you post
3. **Prohibited Content**: Types of content not allowed
4. **Account Termination**: When your account can be suspended/banned
5. **Liability**: Platform's liability limits
6. **Dispute Resolution**: How conflicts are handled

**Important to Know**:
- Violating Terms of Service can result in account suspension or ban
- Terms can change (you're usually notified)
- By using the service, you agree to terms

---

## Regional Privacy Laws

### GDPR (European Union)

If you're in the EU, you have additional rights under GDPR:

**Your Rights**:
1. **Right to Access**: Request copy of your data
2. **Right to Rectification**: Correct inaccurate data
3. **Right to Erasure** ("Right to be Forgotten"): Request deletion
4. **Right to Restrict Processing**: Limit how data is used
5. **Right to Data Portability**: Receive data in machine-readable format
6. **Right to Object**: Object to certain types of processing
7. **Rights Related to Automated Decision-Making**: Explanation of automated decisions

**How to Exercise Rights**:
- Email: privacy@[domain] or dpo@[domain]
- In-app: Settings → Privacy → GDPR Requests
- Allow up to 30 days for response

---

### CCPA (California, USA)

If you're a California resident, you have rights under CCPA:

**Your Rights**:
1. **Right to Know**: What personal information is collected, used, shared, sold
2. **Right to Delete**: Request deletion of personal information
3. **Right to Opt-Out**: Opt out of sale of personal information
4. **Right to Non-Discrimination**: Equal service regardless of privacy choices

**How to Exercise Rights**:
- Similar process to GDPR rights above
- "Do Not Sell My Personal Information" link (if applicable)

---

### Other Jurisdictions

Privacy laws vary by country/region. Check your local laws for additional protections:
- **Brazil**: LGPD (Lei Geral de Proteção de Dados)
- **Canada**: PIPEDA
- **UK**: UK GDPR (post-Brexit)
- **Australia**: Privacy Act 1988

---

## Children's Privacy

### Age Requirements

**Minimum Age**:
- Platform likely requires users to be **13+ years old** (COPPA compliance in US)
- Some regions require 16+ (GDPR in EU)
- Check Terms of Service for specific age requirement

**Why Age Restrictions Exist**:
- Legal requirements (COPPA, GDPR, etc.)
- Children's privacy protection
- Content appropriateness

**If Under Minimum Age**:
- Cannot create account
- Account may be terminated if age discovered
- Parental consent may be required in some jurisdictions

---

### Parental Controls

**For Parents**:

If your child uses the platform:

1. **Review Privacy Settings Together**:
   - Help child set appropriate privacy settings
   - Limit profile visibility
   - Control who can contact them

2. **Discuss Safe Usage**:
   - Don't share personal information
   - Think before posting
   - Report inappropriate content or users

3. **Monitor Activity** (with child's knowledge):
   - Check what they post and who they interact with
   - Look for signs of cyberbullying or inappropriate contact

4. **Use Device Parental Controls**:
   - Screen time limits
   - App usage monitoring
   - Content filtering

**Platform Features** (if available):
- Restricted Mode (filters content)
- Safety Mode (limits interactions)
- Parental accounts (link to child's account)

---

## Updates to This Document

**This guide reflects the security and privacy implementation as of September 2026.**

**Future Changes**:
- Security features may be added or updated
- Privacy policies may change
- New regulations may affect practices

**Stay Informed**:
- Check for updated versions of this document
- Review privacy policy updates (usually notified in-app)
- Subscribe to security announcements

---

## Additional Resources

**Related Documentation**:
- **USER_GUIDE.md**: How to use platform features
- **TROUBLESHOOTING.md**: Common issues and solutions
- **FEATURES.md**: Feature implementation status
- **ROLES_AND_PERMISSIONS.md**: What each role can access

**External Resources**:
- Privacy Policy (official document)
- Terms of Service (official document)
- Community Guidelines
- Safety Center (if available)

**Getting Help**:
- In-app support: Settings → Help & Support
- Email support: support@[domain]
- Community forums

---

**Document Version**: 1.0  
**Last Updated**: Based on implementation audit September 2026  
**Next Review**: Recommended quarterly review for updates

**Disclaimer**: This guide explains security and privacy features in user-friendly language based on technical implementation audit. For legally binding information, always refer to the official Privacy Policy and Terms of Service.

For technical security details (developers), refer to ARCHITECTURE.md and DEVELOPMENT.md documentation.
