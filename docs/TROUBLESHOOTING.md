# Troubleshooting Guide

**Zikire Kdusan (StreamHub) - Common Problems and Solutions**

This guide addresses common issues you might encounter while using Zikire Kdusan, organized by feature area. All solutions are based on the actual system implementation.

---

## Table of Contents

1. [Account & Authentication](#account--authentication)
2. [Login & Session Issues](#login--session-issues)
3. [Live Streaming](#live-streaming)
4. [Video Playback](#video-playback)
5. [Groups & Channels](#groups--channels)
6. [Messaging & Chat](#messaging--chat)
7. [Notifications](#notifications)
8. [Ethiopian Calendar](#ethiopian-calendar)
9. [Offline Mode & Sync](#offline-mode--sync)
10. [Downloads](#downloads)
11. [Search & Discovery](#search--discovery)
12. [Profile & Settings](#profile--settings)
13. [Performance Issues](#performance-issues)
14. [Network & Connectivity](#network--connectivity)

---

## Account & Authentication

### Cannot Register New Account

**Problem**: Registration fails or shows error message.

**Common Causes & Solutions**:

1. **Username already exists**
   - Error: "Username is already taken"
   - Solution: Choose a different username (must be unique across all users)
   - Try adding numbers or underscores to your preferred username

2. **Email already registered**
   - Error: "Email is already in use"
   - Solution: Use a different email address or try logging in if you already have an account
   - Check if you previously registered with this email

3. **Phone number already in use**
   - Error: "Phone number is already registered"
   - Solution: Use a different phone number or recover your existing account
   - Note: Each phone number can only be registered once

4. **Weak password**
   - Error: "Password does not meet requirements"
   - Solution: Password must meet minimum security requirements:
     - At least 8 characters long
     - Recommended: Mix of uppercase, lowercase, numbers, and special characters

5. **Invalid email format**
   - Error: "Invalid email address"
   - Solution: Ensure email is in proper format (e.g., user@example.com)

6. **Missing required fields**
   - Error: "All fields are required"
   - Solution: Fill in username, email, and password at minimum
   - Display name is optional

**Prevention Tips**:
- Choose a unique username before starting registration
- Use a valid, accessible email address
- Create a strong password and store it securely

---

### Email/Phone Verification Not Working

**Problem**: Verification code not received or doesn't work.

**Solutions**:

1. **Email verification code not received**:
   - Check spam/junk folder
   - Verify email address was entered correctly
   - Wait 2-3 minutes (email delivery may be delayed)
   - Request a new verification code if available
   - Check if email provider is blocking automated emails

2. **Phone verification code not received**:
   - Verify phone number format is correct (include country code)
   - Check if SMS service is available in your region
   - Ensure your phone can receive SMS messages
   - Wait 2-3 minutes before requesting another code

3. **Verification code expired**:
   - Codes typically expire after 10-15 minutes
   - Request a new verification code
   - Complete verification promptly after receiving code

4. **Code doesn't work**:
   - Ensure you're entering the most recent code
   - Check for typos (codes are case-sensitive)
   - Avoid copying extra spaces before/after the code

---

## Login & Session Issues

### Account Locked After Failed Login Attempts

**Problem**: "Account temporarily locked" message appears.

**How It Works**:
- System locks account after **5 consecutive failed login attempts**
- Lockout duration: **15 minutes**
- This is a security feature to protect your account from unauthorized access

**Solutions**:

1. **Wait for automatic unlock**:
   - Wait 15 minutes from the last failed attempt
   - Lockout expires automatically
   - No administrator intervention needed

2. **Verify your credentials**:
   - Double-check username/email and password
   - Check caps lock is off
   - Ensure correct keyboard layout

3. **Reset password if forgotten**:
   - Use "Forgot Password" option
   - Reset before lockout expires
   - Set a password you can remember

**Prevention**:
- Use password manager to store credentials securely
- Enable biometric login if available
- Reset password immediately if you can't remember it

---

### Logged Out Unexpectedly

**Problem**: Session expires and you're forced to log in again.

**Understanding Session Timeouts**:

The system uses **two types of tokens**:

1. **Access Token** (short-lived):
   - Expires after **15 minutes** of activity
   - Automatically refreshed in background
   - Used for API requests

2. **Refresh Token** (long-lived):
   - Expires after **7 days** of inactivity
   - Used to obtain new access tokens
   - When this expires, you must log in again

**Common Scenarios**:

1. **Inactive for 7 days**:
   - Cause: Refresh token expired
   - Solution: Log in again (security feature)
   - Prevention: Open app at least once every 7 days

2. **Logged in on another device**:
   - Cause: Some session invalidation events
   - Solution: Log in again
   - Note: Multiple concurrent sessions are supported

3. **Changed password**:
   - Cause: Password change invalidates all existing sessions
   - Solution: Log in with new password on all devices
   - Expected behavior for security

4. **Cleared app data/cache**:
   - Cause: Tokens stored locally were deleted
   - Solution: Log in again
   - Prevention: Avoid clearing app data unless necessary

**Solutions**:
- Keep app updated to avoid token refresh bugs
- Don't clear app cache unless troubleshooting
- Re-login is quick with saved credentials

---

### Cannot Switch Accounts

**Problem**: No option to add or switch between multiple accounts.

**Current Implementation**:
- Multi-account support status: **Check FEATURES.md for current status**
- System supports one active session per device

**Workaround**:
1. Log out of current account
2. Log in with different credentials
3. Note: You'll need to log out/in each time you switch

**Data Preservation**:
- Downloaded videos remain on device
- Offline data is account-specific
- Must sync before switching accounts

---

## Live Streaming

### Cannot Start Live Stream

**Problem**: "Failed to start stream" or stuck on "Starting..."

**Common Causes & Solutions**:

1. **Insufficient permissions**:
   - Required role: Must have `create:livestream` permission
   - Default: Regular USER role may not have permission
   - Solution: Contact admin to verify your account has streaming rights
   - Check your role in Profile → Account Info

2. **Poor network connection**:
   - Required: Stable upload speed (minimum 2-5 Mbps recommended)
   - Solution: 
     - Switch to WiFi if on mobile data
     - Move closer to router
     - Test upload speed at fast.com or speedtest.net
   - Disconnect other devices using bandwidth

3. **Camera/microphone permissions denied**:
   - Error: "Permission denied" or black screen
   - Solution:
     - Go to device Settings → Apps → Zikire Kdusan → Permissions
     - Enable Camera and Microphone permissions
     - Restart the app
   - On iOS: Settings → Privacy → Camera/Microphone

4. **Server capacity reached**:
   - Error: "Cannot start stream at this time"
   - Cause: Cloudinary concurrent stream limit reached
   - Solution: Wait a few minutes and try again
   - This is temporary and depends on server configuration

5. **Already streaming**:
   - Error: "Active stream detected"
   - Cause: You already have an active stream
   - Solution: 
     - Check if you're streaming from another device
     - End previous stream before starting new one
     - Wait 2-3 minutes for old stream to fully stop

**Pre-Stream Checklist**:
- ✅ Good internet connection (WiFi recommended)
- ✅ Camera and microphone permissions enabled
- ✅ Battery above 20% (streaming drains battery)
- ✅ Adequate lighting for video quality
- ✅ No other app using camera simultaneously

---

### Live Stream Interruptions

**Problem**: Stream stops unexpectedly or shows "Connection lost"

**How Interruption Handling Works**:

The system has a **30-second grace period** for network interruptions:
- Stream continues running on server for 30 seconds
- Viewers see "Reconnecting..." message
- Stream reconnects automatically if network recovers
- After 30 seconds, stream ends and becomes VOD

**Common Causes**:

1. **Network fluctuation**:
   - Symptoms: Brief disconnects, quality drops
   - Within 30 seconds: Stream reconnects automatically
   - After 30 seconds: Stream ends
   - Solution:
     - Use stable WiFi connection
     - Stay close to router
     - Avoid streaming while moving
     - Check other devices aren't consuming bandwidth

2. **Low upload bandwidth**:
   - Symptoms: Buffering for viewers, stream quality drops
   - Solution:
     - Reduce stream quality in settings
     - Close other apps using network
     - Disconnect devices from your network
     - Consider upgrading internet plan

3. **Device overheating**:
   - Symptoms: App crashes, device gets very hot
   - Solution:
     - Remove phone case while streaming
     - Avoid direct sunlight
     - Reduce screen brightness
     - Take breaks between streams
     - Close background apps

4. **Low battery**:
   - Symptoms: Stream ends when battery is low
   - Solution:
     - Keep device plugged in while streaming
     - Ensure battery above 20% before starting
     - Use battery saver mode cautiously (may affect performance)

**Recovery Steps**:
1. Check network connection
2. Wait 30 seconds if disconnected (auto-reconnect may work)
3. If stream ended, viewers can still watch as VOD
4. Start new stream once connection is stable

---

### Viewers Can't See My Live Stream

**Problem**: You're streaming but viewers report they can't see it.

**Troubleshooting Steps**:

1. **Check stream privacy settings**:
   - If stream is set to "Group only", only group members can see it
   - If streaming to a private group, only members can access
   - Solution: Verify your intended audience matches privacy settings

2. **Notification delay (2 minutes)**:
   - System waits **2 minutes** before sending "went live" notifications
   - This prevents notification spam from test streams
   - Viewers can still find stream in Live tab during this time
   - Solution: Wait 2 minutes after starting for notifications to go out

3. **Stream discovery issues**:
   - Stream may not appear immediately in "Live Now" section
   - Solution: Ask viewers to refresh the Live tab
   - Share direct stream link if available

4. **Group/channel permissions**:
   - Viewers must have access to the group/channel
   - Private groups require membership
   - Solution: Verify viewers are group members

5. **Stream quality set too high**:
   - Viewers with slow connection can't load high-quality stream
   - Solution: Reduce stream quality to reach more viewers
   - HLS adaptive streaming should handle this automatically

**Quick Test**:
- Open stream on another device with different account
- Check if stream appears in Live tab
- Verify playback works

---

### Live Chat Not Working

**Problem**: Messages not appearing in live chat, or can't send messages.

**Common Causes**:

1. **Not connected to chat**:
   - Chat uses WebSocket (Socket.IO) connection
   - Symptoms: "Connecting..." indicator, messages don't appear
   - Solution:
     - Check internet connection
     - Close and reopen stream
     - Restart app if problem persists
   - Network must support WebSocket connections

2. **Chat permissions**:
   - Group admin may have restricted who can chat
   - Guest role may not have `send:message` permission in group
   - Solution: Check your group role and permissions

3. **Rate limiting**:
   - System may limit rapid message sending
   - Solution: Wait a few seconds between messages
   - Prevents spam

4. **Blocked or muted**:
   - Streamer or moderator may have muted you
   - Solution: Contact streamer or group admin
   - Follow chat guidelines

5. **Message not sent due to disconnect**:
   - If you disconnect while sending, message may not go through
   - Solution: Resend message after reconnecting

**Verification**:
- Check if you can see other people's messages
- Try sending a simple message ("test")
- Verify internet connection is stable

---

### Floating Reactions Not Appearing

**Problem**: Emoji reactions don't show up on stream.

**How Reactions Work**:
- Floating emoji animations overlay on live stream
- Broadcast in real-time via WebSocket
- Visible to all viewers of the stream

**Troubleshooting**:

1. **WebSocket not connected**:
   - Reactions require active WebSocket connection
   - Solution: Same as live chat troubleshooting above

2. **Visual performance mode**:
   - Some devices may disable animations for performance
   - Check if chat messages work (uses same connection)

3. **Reaction flood prevention**:
   - System may limit reaction frequency
   - Solution: Space out reactions

**Workaround**:
- Use text messages in chat if reactions don't work
- Report issue if problem persists

---

## Video Playback

### Videos Won't Play or Buffer Constantly

**Problem**: Videos fail to load, endless buffering, or playback errors.

**Diagnosis Steps**:

1. **Check internet connection**:
   - Videos require continuous internet (streaming)
   - Minimum recommended: 2-5 Mbps for SD, 5-10 Mbps for HD
   - Solution:
     - Test speed at fast.com
     - Switch to WiFi if on mobile data
     - Move closer to router
   - Downloaded videos play without internet

2. **Video quality too high**:
   - HLS adaptive streaming should auto-adjust quality
   - Manual quality setting may be too high for your connection
   - Solution:
     - Reduce video quality in player settings
     - Let system auto-select quality
     - Wait for video to buffer before playing

3. **Cloudinary delivery issues**:
   - Rare: CDN or streaming service temporarily down
   - Symptoms: Many videos fail, not just one
   - Solution:
     - Wait a few minutes and try again
     - Check if other users report same issue
     - Try different video to isolate problem

4. **Corrupted video file**:
   - Symptoms: Specific video never plays, others work fine
   - Cause: Upload or processing error
   - Solution:
     - Report video to moderator/admin
     - Creator may need to re-upload
     - Try on different device to confirm

5. **Device storage full**:
   - Affects video caching and playback
   - Solution:
     - Free up device storage
     - Clear app cache (Settings → Storage)
     - Delete old downloads

**Quick Fixes**:
- Close and reopen video
- Restart app
- Clear app cache
- Restart device

---

### Video Quality is Poor

**Problem**: Video appears blurry, pixelated, or low resolution.

**Common Causes**:

1. **Network bandwidth limitation**:
   - HLS adaptive bitrate automatically lowers quality on slow connections
   - Solution:
     - Check internet speed
     - Move to WiFi for better quality
     - Player will increase quality when bandwidth improves

2. **Source video quality**:
   - Creator uploaded low-resolution video
   - Processing/compression reduced quality
   - Solution: Nothing you can do; depends on source
   - Contact creator to upload higher quality version

3. **Auto-quality setting**:
   - Player may be set to prioritize smooth playback over quality
   - Solution:
     - Manually select higher quality in player settings (if available)
     - Note: May cause buffering on slower connections

4. **Device screen limitations**:
   - Older devices may not support HD playback
   - Solution: Upgrade device or accept lower quality

**Optimization Tips**:
- Use WiFi for best quality
- Ensure good internet speed
- Let video buffer before playing
- Check if HD quality option is available

---

### Audio Out of Sync with Video

**Problem**: Audio plays ahead or behind video.

**Common Causes**:

1. **Network buffering mismatch**:
   - HLS streams audio and video separately
   - Network issues can desync them
   - Solution:
     - Pause and resume playback
     - Skip forward/backward to resync
     - Restart video

2. **Device performance issues**:
   - CPU can't keep up with decoding
   - Solution:
     - Close other apps
     - Reduce video quality
     - Restart device

3. **Source video issue**:
   - Video was uploaded with sync problems
   - Solution:
     - Report to content creator
     - Video needs to be re-encoded/re-uploaded

**Quick Fix**:
- Pause for 5 seconds, then resume
- Seek to different point in video
- Restart app

---

## Groups & Channels

### Cannot Create Group

**Problem**: "Failed to create group" or no "Create Group" option.

**Common Causes**:

1. **Missing permission**:
   - Required: `create:group` permission
   - Check ROLES_AND_PERMISSIONS.md for your role's capabilities
   - Solution: Regular USER role should have this permission by default
   - If not: Contact admin to verify your account status

2. **Group name already exists**:
   - Group names/URLs may need to be unique
   - Solution: Choose a different group name

3. **Validation errors**:
   - Group name too short or too long
   - Invalid characters in group URL/handle
   - Solution:
     - Use 3-50 characters for group name
     - Avoid special characters in group handle
     - Use only letters, numbers, hyphens, underscores

4. **Network error**:
   - Request timeout or connection lost
   - Solution: Check internet connection and retry

**Requirements Checklist**:
- ✅ Valid group name (3-50 characters)
- ✅ Unique group handle/URL
- ✅ Description (optional but recommended)
- ✅ Group type selected (public/private)
- ✅ Stable internet connection

---

### Cannot Join Group

**Problem**: Unable to join a group you want to access.

**Common Scenarios**:

1. **Private group requires approval**:
   - You sent join request but not yet approved
   - Solution: Wait for group admin to approve your request
   - You'll receive notification when approved

2. **Already a member**:
   - You might already be in the group
   - Check "My Groups" section

3. **Group is full**:
   - Admin may have set member limit
   - Solution: Wait for space or contact group admin

4. **Banned from group**:
   - Previous ban may prevent rejoining
   - Solution: Contact group admin if you believe ban was error

5. **Group was deleted**:
   - Group no longer exists
   - Old links/invitations won't work

**Join Request Not Approved**:
- Group admins review requests manually
- No automatic timeout on requests
- You can cancel request and try different group
- Consider contacting admin directly if urgent

---

### Cannot Post in Group/Channel

**Problem**: No option to post, or posts fail to send.

**Common Causes**:

1. **Insufficient group role**:
   - GUEST role typically can't post
   - Required: Usually MEMBER role minimum
   - Solution:
     - Check your role in group (Group Info)
     - Request role upgrade from admin
     - Refer to ROLES_AND_PERMISSIONS.md for role capabilities

2. **Group posting restrictions**:
   - Admin may have restricted posting
   - Only GROUP_ADMIN/MODERATOR can post in some groups
   - Solution: Contact group admin about posting policy

3. **Channel-specific restrictions**:
   - Some channels may be read-only
   - Announcements channels often restrict posting
   - Solution: Post in appropriate channel

4. **Validation errors**:
   - Post content too long
   - Missing required fields
   - Invalid media attachments
   - Solution:
     - Check character limits
     - Ensure media is valid format
     - Include required fields

5. **Network issues**:
   - Post failed to upload
   - Solution: Check connection and retry

**What Can I Post?**:
- Text posts (with character limits)
- Images (check file size limits)
- Videos (check file size limits)
- Links (may have preview generation)

---

### Not Receiving Group Notifications

**Problem**: Missing updates about group activity.

**Troubleshooting**:

1. **Notification preferences disabled**:
   - Check group notification settings
   - Groups can be muted individually
   - Solution:
     - Go to Group Settings → Notifications
     - Enable notifications for desired events
     - Check global notification settings

2. **Device notification permissions**:
   - App may not have permission to send notifications
   - Solution:
     - Device Settings → Apps → Zikire Kdusan → Notifications
     - Enable all notification categories
     - On iOS: Settings → Notifications → Zikire Kdusan

3. **Do Not Disturb mode**:
   - Device or app in DND mode
   - Solution: Check device DND settings

4. **Too many groups**:
   - Notification overload may cause delays
   - Solution: Mute less important groups

5. **Push notification service issues**:
   - Firebase Cloud Messaging may have temporary issues
   - Solution: Wait and see if notifications resume
   - Restart app to re-establish connection

**Notification Types**:
- New posts in group
- Mentions in group
- Join requests (for admins)
- Role changes
- Group announcements
- Channel messages

---

## Messaging & Chat

### Messages Not Sending

**Problem**: Messages stuck on "Sending..." or fail to send.

**Common Causes**:

1. **No internet connection**:
   - Messages queue offline, send when connection restored
   - Check connection status indicator
   - Solution: Connect to internet; queued messages send automatically

2. **Server unavailable**:
   - Rare: Backend temporarily down
   - Symptoms: All messages fail, across all chats
   - Solution: Wait a few minutes and retry

3. **Recipient blocked you**:
   - Messages may appear to send but won't deliver
   - You won't be notified of block
   - Solution: No workaround; respect user's choice

4. **Message too long**:
   - System may limit message length
   - Solution: Split into multiple messages

5. **Attachment too large**:
   - Media file exceeds size limit
   - Solution:
     - Compress image/video before sending
     - Send smaller files
     - Check file size limits in FEATURES.md

**Retry Failed Messages**:
- Tap failed message to see retry option
- Edit message if validation error
- Resend after connection restored

---

### Not Receiving Messages

**Problem**: Missing messages from contacts or groups.

**Troubleshooting**:

1. **Sync issues**:
   - Messages sync when app is open and online
   - Background sync runs every 15 minutes
   - Solution:
     - Open app to force sync
     - Check internet connection
     - Pull to refresh in chat list

2. **Notifications disabled**:
   - You're receiving messages but not notifications
   - Solution: Enable notification permissions (see Notifications section)

3. **Blocked/muted conversation**:
   - You may have muted the chat
   - Check if conversation is muted
   - Solution: Unmute chat to receive notifications

4. **App in background**:
   - Background sync may be delayed on some devices
   - Solution: Open app to receive messages immediately

5. **Account issue**:
   - Rare: Session expired or account issue
   - Solution: Log out and log back in

**Message Sync Behavior**:
- **App open**: Real-time via WebSocket
- **App closed**: Push notifications trigger fetch
- **Offline**: Messages queue until online
- **Background sync**: Every 15 minutes

---

### Can't Send Media in Chat

**Problem**: Unable to attach photos, videos, or files to messages.

**Common Causes**:

1. **Storage permissions denied**:
   - App can't access device media
   - Solution:
     - Device Settings → Apps → Zikire Kdusan → Permissions
     - Enable Storage/Photos permission
     - Restart app

2. **File size too large**:
   - Exceeds upload limit
   - Solution:
     - Compress media before sending
     - Use lower resolution photos
     - Trim video length
     - Check specific limits in FEATURES.md

3. **Unsupported file format**:
   - System may restrict certain file types
   - Solution:
     - Convert to common format (JPG for images, MP4 for videos)
     - Check supported formats

4. **Network issues**:
   - Upload fails on poor connection
   - Solution:
     - Switch to WiFi
     - Wait for better connection
     - Media uploads require more bandwidth than text

5. **Storage full on device**:
   - Can't create temporary upload file
   - Solution: Free up device storage

**Supported Media Types** (verify in FEATURES.md):
- Images: JPG, PNG, HEIC, WebP
- Videos: MP4, MOV
- Size limits vary by file type

---

### Chat Sync Issues Between Devices

**Problem**: Messages on one device don't appear on another device.

**How Multi-Device Sync Works**:
- Messages stored on server
- Each device syncs with server when online
- Real-time sync when app is active
- Background sync every 15 minutes

**Common Issues**:

1. **Device offline**:
   - Offline device won't receive new messages until online
   - Solution: Connect device to internet

2. **Not logged in on other device**:
   - Each device requires login
   - Sessions are independent
   - Solution: Log in on all devices

3. **Sync delay**:
   - Background sync may take up to 15 minutes
   - Solution:
     - Open app to force immediate sync
     - Pull to refresh in chat list

4. **Different accounts**:
   - Verify you're logged into same account on both devices
   - Solution: Check account in Settings

**Force Sync**:
- Pull to refresh on chat list
- Open specific conversation
- Close and reopen app
- Sync happens automatically when app opens

---

## Notifications

### Not Receiving Any Notifications

**Problem**: No push notifications appearing.

**Comprehensive Checklist**:

1. **Device notification permissions**:
   - **Android**:
     - Settings → Apps → Zikire Kdusan → Notifications
     - Enable "Show notifications"
     - Enable all categories (Messages, Groups, Live, etc.)
   - **iOS**:
     - Settings → Notifications → Zikire Kdusan
     - Enable "Allow Notifications"
     - Set alert style (Banner or Alert)
     - Enable Sounds, Badges, Lock Screen

2. **App notification settings**:
   - Open Zikire Kdusan → Settings → Notifications
   - Enable global notifications
   - Enable specific categories you want

3. **Do Not Disturb mode**:
   - Check device DND settings
   - Some devices have scheduled quiet hours
   - Solution: Disable DND or whitelist app

4. **Battery optimization**:
   - Aggressive battery saving may block notifications
   - **Android**:
     - Settings → Battery → Battery Optimization
     - Find Zikire Kdusan → Don't optimize
   - **iOS**:
     - Low Power Mode may delay notifications

5. **Background app refresh**:
   - **iOS**:
     - Settings → General → Background App Refresh
     - Enable for Zikire Kdusan
   - Allows app to receive notifications when closed

6. **Push notification service**:
   - Verify device has Google Play Services (Android) or Apple Push Notification service (iOS)
   - Solution: Update system services if outdated

7. **Logged out or session expired**:
   - Notifications require active account session
   - Solution: Open app and verify you're logged in

**Test Notifications**:
- Ask friend to send you a message
- Post in a group and have someone reply
- Check if notification appears

---

### Notification Delays

**Problem**: Notifications arrive late or in batches.

**Understanding Notification Timing**:

1. **Expected delays**:
   - **Live streaming**: 2-minute delay before "went live" notifications (prevents spam from test streams)
   - **Background sync**: 15-minute intervals for message sync
   - **System throttling**: Devices may delay non-urgent notifications to save battery

2. **Device battery optimization**:
   - Aggressive battery saving delays notifications
   - Solution: Disable battery optimization for app (see above)

3. **Network delays**:
   - Poor connection slows notification delivery
   - Solution: Ensure stable internet connection

4. **App closed for extended period**:
   - First notification after reopening may be delayed
   - Subsequent notifications arrive faster

**Improving Notification Speed**:
- Keep app in background (not force-closed)
- Disable battery optimization for app
- Maintain stable internet connection
- Update to latest app version

---

### Too Many Notifications

**Problem**: Notification overload from groups, chats, or live streams.

**Managing Notification Volume**:

1. **Mute individual groups**:
   - Group Settings → Notifications → Mute
   - Options: 1 hour, 8 hours, 1 week, Forever
   - You'll still see messages; just no notifications

2. **Customize notification types**:
   - Settings → Notifications
   - Disable specific categories:
     - Likes and reactions
     - New followers
     - Group posts
     - Live stream start notifications
   - Keep important ones: Direct messages, mentions

3. **Mute specific chats**:
   - Long-press chat → Mute
   - Reduces noise from busy conversations

4. **Scheduled quiet hours**:
   - Use device Do Not Disturb scheduling
   - Set automatic quiet hours (e.g., 10 PM - 7 AM)

5. **Leave noisy groups**:
   - If group is too active, consider leaving
   - Or reduce role to GUEST (if allowed)

**Recommended Settings**:
- Enable: Direct messages, mentions, live streams from favorites
- Disable: Likes, reactions, general group posts (check manually)
- Mute: Very active groups, promotional channels

---

## Ethiopian Calendar

### Calendar Dates Not Displaying Correctly

**Problem**: Wrong dates shown, or conversion issues between Gregorian and Ethiopian calendars.

**Understanding the Calendar System**:
- System supports **Ethiopian calendar** (13 months)
- Automatically converts between Gregorian and Ethiopian dates
- User can toggle preferred display format

**Common Issues**:

1. **Wrong calendar mode selected**:
   - Check if you're viewing Gregorian instead of Ethiopian (or vice versa)
   - Solution:
     - Settings → Calendar → Calendar Type
     - Select Ethiopian Calendar
     - Toggle in calendar view header

2. **Date conversion edge cases**:
   - Ethiopian calendar has 13 months (12 of 30 days + 1 of 5-6 days)
   - New Year differs from Gregorian (around September 11)
   - Solution: Dates are correctly converted; may look unexpected if unfamiliar with system

3. **Timezone issues**:
   - Dates may shift due to timezone differences
   - Solution: Verify device timezone is correct

**Calendar Features**:
- Notes creation in Ethiopian calendar
- Automatic conversion for display
- Events sync with both calendar systems

---

### Calendar Reminders Not Triggering

**Problem**: Scheduled reminders don't notify you.

**How Reminders Work**:
- Created with notes in calendar
- Stored locally on device
- Triggered by local alarm/notification system
- Work **offline** (don't require internet)

**Troubleshooting**:

1. **Notification permissions disabled**:
   - Reminders use device notification system
   - Solution: Enable notification permissions (see Notifications section)

2. **Reminder time passed**:
   - System doesn't retroactively notify for missed reminders
   - Solution: Check calendar for missed reminders
   - Set new reminder for future

3. **Device powered off**:
   - Reminders don't trigger when device is off
   - Solution: Keep device on around reminder times

4. **Battery optimization**:
   - Aggressive power saving may kill background alarms
   - Solution: Disable battery optimization for app

5. **Reminder not saved properly**:
   - Network issue during creation
   - Solution:
     - Verify reminder appears in calendar
     - Edit and resave if necessary

**Creating Effective Reminders**:
- Set reminder time before event
- Use recurring reminders for regular events
- Test with short-term reminder first
- Keep device on and charged

---

### Cannot Create Calendar Notes

**Problem**: Note creation fails or notes don't save.

**Common Causes**:

1. **Offline with sync pending**:
   - Notes created offline queue for sync
   - Appear in calendar but not synced to server
   - Solution: Connect to internet; notes sync automatically

2. **Validation errors**:
   - Title or description too long
   - Invalid characters
   - Solution: Shorten text and retry

3. **Permission issues**:
   - Verify you have calendar note permissions
   - Regular USER role should have access
   - Solution: Check your role in Settings

4. **Storage full**:
   - Local database can't save note
   - Solution: Free up device storage

**Note Sync Behavior**:
- Created offline → synced when online
- Edited offline → changes sync when online
- Sync happens automatically in background (15-minute intervals)
- Manual sync: Pull to refresh in calendar

---

## Offline Mode & Sync

### Offline Mode Not Working

**Problem**: Features that should work offline don't function.

**What Works Offline** (refer to FEATURES.md):
- ✅ Watch downloaded videos
- ✅ View downloaded content
- ✅ Read cached messages/posts
- ✅ View calendar with reminders
- ✅ Create calendar notes (sync later)
- ✅ Browse cached profiles/groups
- ❌ Send messages (queued until online)
- ❌ Post content (queued until online)
- ❌ Watch online videos
- ❌ Live streaming

**Common Issues**:

1. **Content not downloaded**:
   - Offline mode requires pre-downloaded content
   - Solution: Download videos/content while online

2. **Cache cleared**:
   - Cached data deleted
   - Solution: Browse content again while online to rebuild cache

3. **Database not initialized**:
   - Rare: Local SQLite database issue
   - Solution: Restart app to initialize database

**Preparing for Offline Use**:
- Download important videos beforehand
- Browse groups/channels while online (caches data)
- Ensure calendar notes are synced
- Check downloads section to verify content

---

### Sync Issues After Coming Back Online

**Problem**: Content doesn't sync properly after offline period.

**How Sync Works**:
- Automatic background sync every **15 minutes**
- Immediate sync when app opens from closed state
- Manual sync: Pull to refresh in most views
- Queued actions (messages, posts) send automatically when online

**Common Sync Problems**:

1. **Queued messages not sending**:
   - Should send automatically when online
   - Solution:
     - Check internet connection is stable
     - Open messaging section to trigger sync
     - Restart app if messages still stuck

2. **New content not appearing**:
   - Background sync may not have run yet
   - Solution: Pull to refresh in feed/chat list

3. **Conflicts from offline changes**:
   - Rare: Changes made offline conflict with server state
   - Solution: App should handle automatically; refresh to see latest

4. **Partial sync**:
   - Large sync operation may take time
   - Solution: Keep app open for a few minutes to complete sync

**Force Manual Sync**:
- Pull down to refresh in:
  - Home feed
  - Chat list
  - Group member list
  - Calendar view
- Or close and reopen app

**Sync Indicators**:
- Look for sync status icon
- "Syncing..." message in UI
- Check timestamp of last sync (if displayed)

---

### Downloaded Content Disappeared

**Problem**: Previously downloaded videos or content missing.

**Common Causes**:

1. **Storage cleared**:
   - Manually cleared app data or cache
   - Solution: Re-download content
   - Prevent: Don't clear app data unless necessary

2. **Download expired**:
   - Some content may have download expiration
   - Check if feature has time limits
   - Solution: Re-download if available

3. **Content deleted from server**:
   - Creator deleted original video
   - Download may be removed as well
   - Solution: Content unavailable; cannot recover

4. **Storage moved**:
   - SD card removed or storage location changed
   - Solution:
     - Check if SD card is present
     - Re-insert storage if removed
     - Re-download to new location if necessary

5. **App reinstalled**:
   - Reinstalling app removes downloads
   - Solution: Re-download content
   - Prevent: Don't uninstall unless necessary

**Checking Downloads**:
- Profile → Downloads → See all downloaded content
- Verify storage location settings
- Check available device storage

---

## Downloads

### Cannot Download Videos

**Problem**: Download button doesn't work or downloads fail.

**Common Causes**:

1. **Insufficient storage**:
   - Device storage full
   - Solution:
     - Check available storage (Settings → Storage)
     - Free up space (delete old apps, photos, downloads)
     - System needs room for download + temporary processing

2. **Download permission not granted**:
   - Video creator disabled downloads
   - Feature may be premium/subscription only
   - Solution:
     - Check if download icon is available
     - Contact creator if downloads should be allowed
     - Some content may be stream-only

3. **Storage permissions denied**:
   - App can't write to device storage
   - Solution:
     - Device Settings → Apps → Zikire Kdusan → Permissions
     - Enable Storage permission

4. **Network interruption during download**:
   - Download fails mid-transfer
   - Solution:
     - Check internet connection
     - Retry download
     - Use WiFi for large downloads (recommended)

5. **Concurrent download limit**:
   - System may limit simultaneous downloads
   - Solution: Wait for current downloads to complete

**Download Best Practices**:
- Use WiFi for large videos
- Ensure 2x file size available in storage
- Download during off-peak hours for speed
- Keep app in foreground during large downloads

---

### Downloads Stuck or Very Slow

**Problem**: Downloads don't progress or take very long time.

**Troubleshooting**:

1. **Slow internet connection**:
   - Large videos require good bandwidth
   - Solution:
     - Switch to WiFi
     - Pause and resume download
     - Download during better connectivity times

2. **Background download restrictions**:
   - Some devices restrict background downloads
   - Solution:
     - Keep app in foreground during download
     - Disable battery optimization for app

3. **Server congestion**:
   - Rare: CDN or server overloaded
   - Solution: Try downloading later

4. **Corrupted download**:
   - Download got stuck in error state
   - Solution:
     - Cancel download
     - Clear app cache (Settings → Storage)
     - Restart app
     - Try download again

**Download Progress**:
- Check Downloads section for progress
- Percentage indicator shows completion
- Notification shows download status
- Can pause and resume downloads

---

### Downloaded Videos Won't Play

**Problem**: Downloaded video opens but doesn't play.

**Common Causes**:

1. **Incomplete download**:
   - Download didn't finish properly
   - File corrupted during download
   - Solution:
     - Delete incomplete download
     - Re-download video
     - Ensure download completes to 100%

2. **Storage corruption**:
   - File corrupted after download
   - Rare: Storage hardware issue
   - Solution:
     - Delete and re-download
     - Check device storage health
     - Try downloading to different location (internal vs SD card)

3. **Unsupported video format**:
   - Video encoded in format device can't play
   - Rare: Should be prevented during download
   - Solution: Report issue; video may need re-encoding

4. **DRM or encryption issues**:
   - If content has DRM protection
   - Playback may require active internet connection
   - Solution: Connect to internet at least once after download

**Verification**:
- Try playing different downloaded video
- Try streaming same video (if available)
- Check if issue is specific video or all downloads

---

## Search & Discovery

### Search Not Finding Results

**Problem**: Search returns no results or incomplete results.

**How Search Works**:
- Searches across multiple entities: users, videos, groups, posts
- Full-text search on titles, descriptions, usernames
- Trending and recommendations use different algorithms

**Common Issues**:

1. **Search too specific**:
   - Exact match may not exist
   - Solution:
     - Use broader search terms
     - Try synonyms
     - Use fewer keywords
   - Example: "funny cat video" → "cat" or "funny"

2. **Typos in search query**:
   - Search may not have fuzzy matching
   - Solution: Check spelling carefully

3. **Content not indexed yet**:
   - Newly uploaded content may take time to appear in search
   - Solution: Wait a few minutes and try again

4. **Privacy settings**:
   - Private groups/content won't appear in search
   - You can only search content you have access to
   - Solution: Join group first, then search within group

5. **Network issues**:
   - Search requires internet connection
   - Solution: Check connectivity and retry

**Search Tips**:
- Use single keywords for broader results
- Use quotes for exact phrase matching (if supported)
- Filter by type: Users, Videos, Groups, Posts
- Sort by relevance or date

---

### Trending Section Empty or Outdated

**Problem**: Trending videos/content section shows nothing or old content.

**How Trending Works**:
- Algorithm tracks views, likes, shares, comments
- Updates periodically (not real-time)
- Considers recent activity (time-weighted)

**Common Causes**:

1. **Low overall platform activity**:
   - If community is small, trending may not populate
   - Solution: Check Explore section for recommendations instead

2. **Trending calculation period**:
   - Trending refreshes every few hours/days
   - May not show very recent content
   - Solution: Check "New" or "Recent" sections for latest content

3. **Geographic/language filters**:
   - Trending may be filtered by region or language
   - Solution: Check settings for location/language preferences

4. **Cache not refreshed**:
   - App showing cached trending data
   - Solution: Pull to refresh in Trending section

**Alternative Discovery**:
- Follow interesting users
- Browse category sections
- Check recommendations
- Join active groups

---

### Recommendations Not Relevant

**Problem**: Recommended videos or content don't match your interests.

**How Recommendations Work**:
- Based on viewing history, likes, subscriptions
- Considers similar users' behavior
- Improves over time with more data

**Improving Recommendations**:

1. **Interact with content you like**:
   - Like videos you enjoy
   - Subscribe to creators
   - Watch videos fully (completion rate matters)
   - Skip/dismiss content you don't like

2. **Clear watch history**:
   - If recommendations are way off
   - Settings → Privacy → Clear Watch History
   - Gives algorithm fresh start

3. **Build profile over time**:
   - Recommendations improve with usage
   - New accounts have generic recommendations
   - Solution: Use app regularly; algorithm learns preferences

4. **Check subscriptions**:
   - Recommendations influenced by subscriptions
   - Unsubscribe from channels you no longer like

**Manual Discovery**:
- Use search for specific topics
- Browse categories
- Check trending
- Follow users directly

---

## Profile & Settings

### Cannot Update Profile Information

**Problem**: Profile changes don't save or fail to update.

**Common Fields & Issues**:

1. **Username change fails**:
   - **Username already taken**: Choose different username
   - **Invalid characters**: Use only letters, numbers, underscores, hyphens
   - **Too short/long**: Check length requirements
   - **Username change limit**: System may limit how often you can change username
   - Solution: Try different username or wait before changing again

2. **Bio/description too long**:
   - Character limit enforced
   - Solution: Shorten text to fit limit

3. **Profile photo upload fails**:
   - **File too large**: Compress image before uploading
   - **Unsupported format**: Use JPG or PNG
   - **Network error**: Check connection and retry
   - Solution: Try smaller, common format image

4. **Email/phone already in use**:
   - Another account using same email/phone
   - Solution: Use different email/phone or recover other account

5. **Network issues**:
   - Changes not syncing to server
   - Solution: Check internet connection and retry

**Verification**:
- Log out and log back in to see if changes persisted
- Check profile from different device
- Some changes may require re-authentication

---

### Cannot Change Password

**Problem**: Password change fails or doesn't work.

**Common Issues**:

1. **Current password incorrect**:
   - Must enter current password correctly
   - Solution:
     - Double-check current password
     - Use "Forgot Password" if you don't remember

2. **New password doesn't meet requirements**:
   - Password strength validation
   - Requirements:
     - Minimum 8 characters
     - Mix of uppercase, lowercase, numbers recommended
   - Solution: Create stronger password

3. **New password same as old**:
   - System may prevent reusing recent passwords
   - Solution: Choose different password

4. **Password change confirmation fails**:
   - Verification email/SMS not received
   - Solution: Check inbox/SMS and wait a few minutes

5. **Account security hold**:
   - Recent security event may temporarily prevent changes
   - Solution: Wait 24 hours or contact support

**After Password Change**:
- You'll be logged out on all devices (security feature)
- Log back in with new password
- Update saved passwords in browser/password manager

---

### Two-Factor Authentication Issues

**Problem**: Cannot enable 2FA, or 2FA codes don't work.

**Status**: Check FEATURES.md for 2FA implementation status.

**If Implemented**:

1. **Cannot enable 2FA**:
   - Ensure email/phone is verified first
   - Check if required role/permission
   - Solution: Complete verification steps before enabling 2FA

2. **2FA codes not working**:
   - **Time-based codes (TOTP)**: Device time must be accurate
   - **SMS codes**: May have delivery delay
   - Solution:
     - Verify device time is correct (automatic time sync)
     - Wait 60 seconds for new TOTP code
     - Request new SMS code if expired

3. **Lost 2FA device**:
   - Cannot access authenticator app or phone
   - Solution:
     - Use backup codes (if you saved them)
     - Use recovery email/phone option
     - Contact support for account recovery

4. **Backup codes not working**:
   - Each backup code usable only once
   - Solution: Use different backup code

**2FA Best Practices**:
- Save backup codes in secure location
- Use authenticator app (more reliable than SMS)
- Keep recovery email/phone updated
- Test 2FA before fully relying on it

---

### Account Deletion/Deactivation

**Problem**: Cannot find option to delete or deactivate account.

**Feature Status**: Check FEATURES.md for account deletion implementation.

**If Implemented**:

1. **Cannot find option**:
   - Usually in: Settings → Account → Delete Account
   - May require re-authentication
   - Solution: Look for "Account Management" or "Privacy" section

2. **Deletion confirmation required**:
   - May need to enter password
   - May need to verify via email/SMS
   - Purpose: Prevent accidental/unauthorized deletion
   - Solution: Complete verification steps

3. **Waiting period**:
   - Account may deactivate immediately but delete after waiting period (e.g., 30 days)
   - Allows account recovery if changed mind
   - Solution: Wait out period; account fully deletes after

4. **Cannot delete due to active subscription/role**:
   - Admin roles may need to be transferred first
   - Active subscriptions may need cancellation
   - Solution: Cancel subscriptions, transfer roles, then delete

**What Happens When Account Deleted**:
- Personal data removed from system
- Posts/content may remain (anonymized) or be deleted (check policy)
- Username may become available for reuse
- Cannot recover account after permanent deletion

**Alternative: Deactivation**:
- Temporarily disables account
- Data preserved
- Can reactivate by logging in
- Useful if you might return

---

## Performance Issues

### App Runs Slowly or Lags

**Problem**: App feels sluggish, delayed responses, UI lag.

**Common Causes**:

1. **Device resources low**:
   - Too many apps running
   - Insufficient RAM
   - Solution:
     - Close background apps
     - Restart device
     - Clear recent apps tray

2. **Storage nearly full**:
   - App performance degrades with low storage
   - Solution:
     - Free up device storage
     - Delete old downloads
     - Clear app cache (Settings → Storage → Clear Cache)
     - Note: Clearing cache removes offline content

3. **App cache too large**:
   - Accumulated cache may slow app
   - Solution: Clear app cache periodically

4. **Outdated app version**:
   - Old version may have performance bugs
   - Solution:
     - Check for app updates
     - Update to latest version
     - Check changelog for performance improvements

5. **Network latency**:
   - Slow server responses
   - Solution:
     - Check internet speed
     - Switch to WiFi
     - Try again during off-peak hours

**Performance Optimization**:
- Restart app regularly
- Update to latest version
- Keep 10-20% device storage free
- Close app completely (not just minimize) occasionally
- Restart device weekly

---

### App Crashes Frequently

**Problem**: App closes unexpectedly or freezes.

**Troubleshooting Steps**:

1. **Update app**:
   - Crashes may be fixed in newer version
   - Solution: Check app store for updates

2. **Restart device**:
   - Clears temporary issues
   - Solution: Power off and on (not just lock/unlock)

3. **Clear app cache**:
   - Corrupted cache may cause crashes
   - Solution:
     - Settings → Apps → Zikire Kdusan → Storage → Clear Cache
     - Note: Will need to re-download offline content

4. **Reinstall app**:
   - Fresh installation fixes corrupted files
   - Solution:
     - Uninstall app
     - Restart device
     - Reinstall from app store
     - Note: Will lose downloads and offline data

5. **Device compatibility**:
   - Very old devices may not run app smoothly
   - Check minimum requirements
   - Solution: Upgrade device if too old

6. **Conflicting apps**:
   - Other apps may interfere (rare)
   - Solution:
     - Identify recently installed apps
     - Try uninstalling to isolate conflict

**Reporting Crashes**:
- Enable crash reporting in app settings
- Check if device sends automatic crash reports
- Contact support with:
  - Device model and OS version
  - App version
  - What you were doing when crash occurred
  - How often it happens

---

### High Battery Drain

**Problem**: App uses too much battery.

**Common Causes**:

1. **Live streaming**:
   - Streaming video is battery-intensive
   - Camera, encoding, upload use significant power
   - Solution:
     - Keep device plugged in while streaming
     - Reduce stream quality
     - Limit stream duration

2. **Background activity**:
   - App running in background continuously
   - Fetching messages, notifications
   - Solution:
     - Close app when not using
     - Disable background refresh (Settings)
     - Reduce notification frequency

3. **Location services**:
   - GPS usage drains battery
   - Solution: Disable location permission if not needed

4. **Screen brightness**:
   - Watching videos at high brightness
   - Solution: Reduce screen brightness

5. **Network activity**:
   - Constant data sync
   - Solution:
     - Use WiFi instead of mobile data (more efficient)
     - Disable auto-play videos in feeds

**Battery Optimization**:
- Enable battery saver mode when low
- Download videos for offline watching (more efficient than streaming)
- Close app completely when done
- Reduce notification frequency
- Lower video quality settings

---

### High Data Usage

**Problem**: App consumes too much mobile data.

**Common Causes**:

1. **Video streaming**:
   - Streaming videos uses significant data
   - HD video uses more than SD
   - Solution:
     - Download videos on WiFi for offline watching
     - Reduce video quality in settings
     - Enable "WiFi only" mode for video playback

2. **Auto-play videos**:
   - Videos in feed auto-play
   - Solution:
     - Disable auto-play in settings
     - Set auto-play to "WiFi only"

3. **Background sync**:
   - App syncing messages, notifications in background
   - Solution:
     - Enable "WiFi only" sync in settings
     - Reduce sync frequency

4. **Media uploads**:
   - Uploading photos/videos to groups/profile
   - Solution:
     - Wait for WiFi to upload media
     - Compress media before uploading

5. **Live streaming**:
   - Broadcasting live uses significant upload bandwidth
   - Solution: Only stream on WiFi

**Data Saving Tips**:
- Enable "Data Saver" mode in app settings (if available)
- Download content on WiFi for offline viewing
- Disable auto-play
- Monitor data usage: Device Settings → Data Usage
- Set mobile data limit in device settings

---

## Network & Connectivity

### Constant "No Internet Connection" Errors

**Problem**: App shows connection errors even though internet works.

**Troubleshooting**:

1. **Verify internet connection**:
   - Open browser to confirm internet works
   - Try other apps
   - Solution: If internet truly down, fix connection first

2. **DNS issues**:
   - Can't resolve server addresses
   - Solution:
     - Switch between WiFi and mobile data
     - Restart router if on WiFi
     - Try different WiFi network

3. **Firewall or network restrictions**:
   - Corporate/school networks may block app
   - VPN may interfere
   - Solution:
     - Try different network
     - Disable VPN temporarily
     - Contact network admin about restrictions

4. **App server issues**:
   - Rare: Backend temporarily down
   - Check if other users report same issue
   - Solution: Wait and try again later

5. **Outdated app version**:
   - Old version may have connection bugs
   - Solution: Update to latest version

6. **Device network settings**:
   - Airplane mode, data saver, etc.
   - Solution:
     - Verify airplane mode is off
     - Check mobile data is enabled (if not on WiFi)
     - Disable aggressive data saver modes

**Quick Fixes**:
- Toggle airplane mode on and off
- Restart app
- Restart device
- Reconnect to WiFi
- Switch between WiFi and mobile data

---

### WebSocket Connection Failures

**Problem**: Real-time features not working (live chat, reactions, live viewer count).

**Understanding WebSockets**:
- Used for real-time features via Socket.IO
- Requires persistent connection to server
- Some networks block WebSocket connections

**Common Issues**:

1. **Network doesn't support WebSockets**:
   - Some corporate/school networks block WebSocket protocol
   - Solution:
     - Try different network
     - Use mobile data instead of restricted WiFi
     - Contact network admin

2. **Proxy or VPN interference**:
   - Proxies may not support WebSocket upgrades
   - Solution: Disable proxy/VPN temporarily

3. **Connection timeout**:
   - Poor network causes frequent disconnects
   - Solution:
     - Move closer to WiFi router
     - Switch to more stable connection

4. **Firewall blocking ports**:
   - WebSocket may use specific ports that are blocked
   - Solution: Try different network or contact IT

**Symptoms of WebSocket Failure**:
- Live chat messages don't appear real-time
- Floating reactions don't show
- Viewer count doesn't update
- "Connecting..." indicator persists

**Workaround**:
- Refresh page/screen to manually update
- Use text chat instead of real-time features
- Wait for better network connection

---

### Cannot Connect to Specific Features

**Problem**: Some features work, others don't (e.g., videos work but messaging doesn't).

**Diagnosis**:

1. **Identify affected features**:
   - Note which features fail
   - Note which features work

2. **Feature-specific issues**:
   - **Messaging fails**: May be WebSocket issue (see above)
   - **Videos fail**: May be CDN/Cloudinary issue
   - **Upload fails**: May be upload service issue
   - **Live streaming fails**: May be RTMP/streaming service issue

3. **Server-side problems**:
   - Rare: Specific backend services down
   - Solution:
     - Wait and retry later
     - Check if issue is reported by others
     - Contact support if persistent

4. **Permission/role issues**:
   - Your account may not have permission for certain features
   - Solution: Check ROLES_AND_PERMISSIONS.md
   - Contact admin if you should have access

5. **Network selective blocking**:
   - Some networks block specific services (e.g., video streaming but not messaging)
   - Solution: Try different network

**Isolation Testing**:
- Try feature on different network
- Try feature on different device
- Try feature with different account
- Helps identify if issue is device, network, or account specific

---

## Additional Help

### Features Not Covered Here

If you're experiencing an issue not listed in this guide:

1. **Check other documentation**:
   - **USER_GUIDE.md**: Comprehensive feature documentation
   - **FEATURES.md**: Implementation status of features
   - **ROLES_AND_PERMISSIONS.md**: Permission-related issues
   - **KNOWN_ISSUES.md**: Documented limitations

2. **Verify feature is implemented**:
   - Check FEATURES.md for implementation status
   - Feature may be partially implemented or not available

3. **Check for updates**:
   - Newer versions may add features or fix bugs
   - Update to latest version

### Reporting Bugs

When reporting issues to support or developers:

**Include**:
- Device model and operating system version
- App version
- Exact error message (screenshot if possible)
- Steps to reproduce the issue
- What you expected to happen vs. what actually happened
- Whether issue is consistent or intermittent

**Examples**:
- ✅ Good: "On Samsung Galaxy S21 (Android 13), app version 2.1.0, when I try to start a live stream, I get error 'Failed to start stream' after loading for 30 seconds. I have camera permissions enabled and WiFi connection is strong. Happens every time."
- ❌ Poor: "Live streaming doesn't work"

### Contact Support

**Support Channels** (verify with admin):
- In-app support/feedback option
- Email support (check app or website for address)
- Community forums or groups
- Social media channels

**For Urgent Issues**:
- Account security concerns
- Payment/billing issues
- Harassment or abuse reports
- Critical bugs affecting many users

### Community Resources

- Join official community groups within app
- Check announcement channels for known issues
- User forums for tips and workarounds
- FAQ sections in user guide

---

## Preventive Maintenance

**Regular Maintenance to Avoid Issues**:

1. **Weekly**:
   - Restart app
   - Check for app updates
   - Clear old downloads if storage is low

2. **Monthly**:
   - Clear app cache if performance degrades
   - Review notification settings
   - Update device OS if available

3. **As Needed**:
   - Restart device if experiencing general issues
   - Review and adjust permissions
   - Clean up old content and downloads

**Best Practices**:
- Keep app updated to latest version
- Maintain adequate device storage (10-20% free)
- Use stable internet connection for uploads and streaming
- Enable automatic backups (if available)
- Don't force-close app unnecessarily
- Allow app to complete sync operations

---

**Document Version**: 1.0  
**Last Updated**: Based on implementation audit September 2026  
**Related Documents**: USER_GUIDE.md, FEATURES.md, ROLES_AND_PERMISSIONS.md, KNOWN_ISSUES.md

For technical troubleshooting and developer issues, refer to DEVELOPMENT.md and ARCHITECTURE.md documentation.
