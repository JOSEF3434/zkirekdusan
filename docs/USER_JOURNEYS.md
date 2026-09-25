# Zikire Kdusan - User Journeys

## Overview

This document maps complete end-to-end user workflows based on verified implementation. Each journey includes technical flows, API calls, database interactions, and state transitions.

---

## Table of Contents

1. [Journey 1: New User Onboarding](#journey-1-new-user-onboarding)
2. [Journey 2: Content Discovery and Video Watching](#journey-2-content-discovery-and-video-watching)
3. [Journey 3: Joining and Participating in Groups](#journey-3-joining-and-participating-in-groups)
4. [Journey 4: Content Creator Upload Video](#journey-4-content-creator-upload-video)
5. [Journey 5: Live Streaming (Broadcaster)](#journey-5-live-streaming-broadcaster)
6. [Journey 6: Live Streaming (Viewer)](#journey-6-live-streaming-viewer)
7. [Journey 7: Offline Content Consumption](#journey-7-offline-content-consumption)
8. [Journey 8: Ethiopian Calendar with Reminders](#journey-8-ethiopian-calendar-with-reminders)
9. [Journey 9: Direct Messaging](#journey-9-direct-messaging)
10. [Journey 10: Admin Moderating Content](#journey-10-admin-moderating-content)

---

## Journey 1: New User Onboarding

### Goal
New user discovers app, creates account, sets up profile, and explores content.

### Prerequisites
- Mobile device (Android/iOS) or web browser
- Internet connection
- Valid email or phone number

### Step-by-Step Flow

#### 1. App Installation and Launch
**User Action:** Downloads app from store, opens app

**Technical Flow:**
- App loads environment configuration from `Env.init()`
- Firebase initialized with platform-specific options
- Database initialized: `AppDatabase()` (SQLite)
- Background services registered (sync, notifications, calendar)
- Router initialized with initial route

**Result:** Splash screen → Welcome/Login screen

---

#### 2. Registration
**User Action:** Taps "Sign Up", enters email/phone and password

**Frontend (Flutter):**
```dart
// lib/features/auth/presentation/providers/auth_provider.dart
authRepository.register(RegisterRequest(
  email: "user@example.com",
  password: "securepass123",
  firstName: "John",
  lastName: "Doe"
))
```

**API Call:**
```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepass123",
  "firstName": "John",
  "lastName": "Doe"
}
```

**Backend Processing** (`backend/src/modules/auth/auth.service.ts`):
1. Validate email uniqueness
2. Fetch default USER role from database
3. Hash password with bcrypt (12 rounds)
4. Create User record with roleId
5. Create Profile record (linked via userId)
6. Generate JWT access token (15min expiry)
7. Generate refresh token (7 days expiry)
8. Hash refresh token, store in RefreshToken table
9. Create Session record (ACTIVE status)

**Database Writes:**
```sql
-- Insert user
INSERT INTO users (id, email, password_hash, role_id, status)
VALUES (uuid, 'user@example.com', bcrypt_hash, user_role_id, 'ACTIVE');

-- Insert profile
INSERT INTO profiles (id, user_id, first_name, last_name)
VALUES (uuid, user_id, 'John', 'Doe');

-- Insert refresh token
INSERT INTO refresh_tokens (id, user_id, token_hash, expires_at)
VALUES (uuid, user_id, bcrypt_hash, NOW() + INTERVAL '7 days');

-- Insert session
INSERT INTO sessions (id, user_id, status, expires_at)
VALUES (uuid, user_id, 'ACTIVE', NOW() + INTERVAL '7 days');
```

**API Response:**
```json
{
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "role": "USER"
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

**Frontend State Update:**
- Tokens stored securely (FlutterSecureStorage)
- User state updated in Riverpod provider
- Auto-navigate to home screen

**Result:** User account created, logged in, tokens stored

---

#### 3. Profile Setup
**User Action:** Prompted to complete profile, uploads avatar

**Frontend:**
```dart
// Upload avatar
profileRepository.uploadAvatar(imageFile)
```

**API Calls:**
```http
POST /api/uploads
Content-Type: multipart/form-data

file: [binary data]
type: IMAGE
```

**Backend Processing** (`backend/src/modules/uploads/uploads.service.ts`):
1. Validate file (image, max 10MB)
2. Upload to Cloudinary
3. Create File record with Cloudinary URL
4. Return file metadata

```http
PATCH /api/profiles/me
Content-Type: application/json

{
  "avatarFileId": "file-uuid",
  "bio": "Love streaming Ethiopian content!"
}
```

**Database Update:**
```sql
UPDATE profiles
SET avatar_file_id = 'file-uuid', bio = 'Love streaming...'
WHERE user_id = 'user-uuid';
```

**Result:** Profile complete with avatar and bio

---

#### 4. Explore Content
**User Action:** Browse home feed

**API Call:**
```http
GET /api/home/feed?page=1&limit=20
Authorization: Bearer {accessToken}
```

**Backend Processing:**
- Fetch posts from followed users (initially empty)
- Fetch public posts from popular creators
- Fetch live streams currently active
- Fetch stories from followed users
- Mix content types algorithmically

**Response:** Paginated feed with posts, videos, live streams, stories

**Frontend:** Display in scrollable feed with infinite scroll

**Result:** User sees content, discovers creators

---

### Journey Success Criteria
✅ Account created with valid credentials
✅ JWT tokens issued and stored
✅ Profile created in database
✅ User can navigate app
✅ Content feed loads successfully
✅ User role is USER with default permissions

### Common Issues
- Email already exists → Error message, suggest login
- Weak password → Validation error
- Network timeout → Retry mechanism
- Upload failure → Fallback to default avatar

---

## Journey 2: Content Discovery and Video Watching

### Goal
User discovers videos through search/trending, watches video, interacts with content.

### Step-by-Step Flow

#### 1. Discover Video
**User Action:** Taps Explore tab, browses trending videos

**API Call:**
```http
GET /api/trending?type=videos&window=DAILY&page=1&limit=20
Authorization: Bearer {accessToken}
```

**Backend Processing** (`backend/src/modules/trending/trending.service.ts`):
- Query TrendingScore table
- Filter by entityType = VIDEO, window = DAILY
- Sort by score DESC
- Join with Video table for metadata
- Return top 20 videos

**Result:** Grid of trending videos with thumbnails

---

#### 2. Open Video
**User Action:** Taps video thumbnail

**API Call:**
```http
GET /api/videos/{videoId}
Authorization: Bearer {accessToken}
```

**Backend Response:**
```json
{
  "data": {
    "id": "video-uuid",
    "title": "Ethiopian Coffee Ceremony",
    "hlsUrl": "https://cloudinary.../video.m3u8",
    "duration": 420.5,
    "viewsCount": 15234,
    "likesCount": 892,
    "videoChannel": {
      "id": "channel-uuid",
      "name": "Ethiopian Culture"
    },
    "status": "READY",
    "visibility": "PUBLIC"
  }
}
```

**Frontend:**
- Navigate to video player screen
- Initialize VideoPlayerController with hlsUrl
- Video player fetches HLS manifest from Cloudinary
- Adaptive bitrate streaming begins

---

#### 3. Track View
**Backend (Automatic):**
When video plays for > 3 seconds:

```http
POST /api/videos/{videoId}/view
Authorization: Bearer {accessToken}
```

**Database Update:**
```sql
-- Increment view count
UPDATE videos
SET views_count = views_count + 1
WHERE id = 'video-uuid';

-- Record watch history
INSERT INTO video_watch_history (id, user_id, video_id, watched_seconds)
VALUES (uuid, 'user-uuid', 'video-uuid', 0)
ON CONFLICT (user_id, video_id)
DO UPDATE SET watched_at = NOW();
```

---

#### 4. Like Video
**User Action:** Taps heart icon

**API Call:**
```http
POST /api/videos/{videoId}/like
Authorization: Bearer {accessToken}

{
  "isLike": true
}
```

**Database Writes:**
```sql
-- Upsert like
INSERT INTO video_likes (user_id, video_id, is_like)
VALUES ('user-uuid', 'video-uuid', true)
ON CONFLICT (user_id, video_id)
DO UPDATE SET is_like = true, created_at = NOW();

-- Update counter
UPDATE videos
SET likes_count = (
  SELECT COUNT(*) FROM video_likes WHERE video_id = 'video-uuid' AND is_like = true
)
WHERE id = 'video-uuid';
```

**Frontend:** Heart icon fills, counter increments

---

#### 5. Comment
**User Action:** Types comment, taps send

**API Call:**
```http
POST /api/videos/{videoId}/comments
Authorization: Bearer {accessToken}

{
  "content": "Beautiful ceremony! 🇪🇹",
  "parentId": null
}
```

**Database Writes:**
```sql
-- Insert comment
INSERT INTO video_comments (id, video_id, user_id, content)
VALUES (uuid, 'video-uuid', 'user-uuid', 'Beautiful ceremony! 🇪🇹');

-- Update comment count
UPDATE videos
SET comments_count = comments_count + 1
WHERE id = 'video-uuid';
```

**Result:** Comment appears in comment section

---

#### 6. Subscribe to Channel
**User Action:** Taps "Subscribe" button

**API Call:**
```http
POST /api/video-channels/{channelId}/subscribe
Authorization: Bearer {accessToken}
```

**Database Writes:**
```sql
-- Create subscription
INSERT INTO video_subscriptions (user_id, video_channel_id, notify_on_upload)
VALUES ('user-uuid', 'channel-uuid', true);

-- Update subscriber count
UPDATE video_channels
SET subscribers_count = subscribers_count + 1
WHERE id = 'channel-uuid';
```

**Result:** "Subscribed" button shows, user gets notifications for new videos

---

### Journey Success Criteria
✅ Video discovered through trending
✅ Video plays successfully with adaptive quality
✅ View counted after 3+ seconds
✅ Like registered and counter updated
✅ Comment posted and visible
✅ Channel subscription created
✅ User will receive notifications for new uploads

---

## Journey 3: Joining and Participating in Groups

### Goal
User discovers group, joins, participates in channels, posts content.

### Step-by-Step Flow

#### 1. Discover Group
**User Action:** Search for "Ethiopian Culture"

**API Call:**
```http
GET /api/search?q=Ethiopian Culture&type=groups&page=1
Authorization: Bearer {accessToken}
```

**Result:** List of matching groups with visibility PUBLIC

---

#### 2. Join Public Group
**User Action:** Taps "Join Group"

**API Call:**
```http
POST /api/groups/{groupId}/join
Authorization: Bearer {accessToken}
```

**Backend Processing** (`backend/src/modules/groups/groups.service.ts`):
1. Check group status is ACTIVE
2. Check user not already member
3. Create GroupMember record with role MEMBER
4. Trigger notification to group admins

**Database Write:**
```sql
INSERT INTO group_members (id, group_id, user_id, role, joined_at)
VALUES (uuid, 'group-uuid', 'user-uuid', 'MEMBER', NOW());
```

**Result:** User is now MEMBER of group

---

#### 3. Browse Group Channels
**User Action:** Views group page, sees channel list

**API Call:**
```http
GET /api/groups/{groupId}/channels
Authorization: Bearer {accessToken}
```

**Backend Response:**
```json
{
  "data": [
    {
      "id": "channel-uuid",
      "name": "General Discussion",
      "type": "TEXT",
      "isPrivate": false
    },
    {
      "id": "channel2-uuid",
      "name": "Announcements",
      "type": "ANNOUNCEMENT",
      "isPrivate": false
    }
  ]
}
```

---

#### 4. Post in Channel
**User Action:** Types message in channel, taps send

**API Call:**
```http
POST /api/channels/{channelId}/messages
Authorization: Bearer {accessToken}

{
  "content": "Hello everyone! Happy to join this group! 👋",
  "type": "TEXT"
}
```

**Backend Authorization Check:**
1. JwtAuthGuard validates token
2. GroupMembershipGuard checks user is MEMBER of channel's group
3. ChannelService checks user can post (ANNOUNCEMENT channels: admin-only)

**Database Write:**
```sql
-- Insert message
INSERT INTO messages (id, conversation_id, channel_id, sender_id, content, type)
VALUES (uuid, conversation_uuid, 'channel-uuid', 'user-uuid', 'Hello everyone!...', 'TEXT');

-- Create read receipt for sender
INSERT INTO message_reads (message_id, user_id, read_at)
VALUES (message_uuid, 'user-uuid', NOW());
```

**Real-Time Broadcast:** Message sent via WebSocket to all channel members

**Result:** Message appears for all group members

---

#### 5. Create Group Post
**User Action:** Taps "Create Post" in group feed

**API Call:**
```http
POST /api/posts
Authorization: Bearer {accessToken}

{
  "type": "TEXT",
  "content": "Check out this amazing Ethiopian coffee recipe!",
  "visibility": "GROUP_ONLY",
  "groupId": "group-uuid",
  "hashtags": ["ethiopiancoffee", "culture"]
}
```

**Backend Processing:**
1. Verify user is group member
2. Create Post record linked to group
3. Parse hashtags for search indexing

**Database Write:**
```sql
INSERT INTO posts (id, author_id, group_id, type, content, visibility, hashtags, status)
VALUES (uuid, 'user-uuid', 'group-uuid', 'TEXT', 'Check out...', 'GROUP_ONLY', ARRAY['ethiopiancoffee', 'culture'], 'PUBLISHED');
```

**Result:** Post visible to all group members in group feed

---

### Journey Success Criteria
✅ User found group via search
✅ Successfully joined public group as MEMBER
✅ Can view and access group channels
✅ Posted message in text channel
✅ Created post visible to group members
✅ Group role properly enforced (MEMBER permissions)

---

## Journey 4: Content Creator Upload Video

### Goal
Content creator uploads video to their channel, configures settings, publishes.

### Prerequisites
- User is MEMBER of a group
- Group has video channel created
- User has upload permissions in channel

### Step-by-Step Flow

#### 1. Initiate Upload
**User Action:** Taps (+) → "Upload Video", selects video file

**Frontend:**
```dart
// Pick video file
final video = await ImagePicker().pickVideo(source: ImageSource.gallery);

// Get video metadata
final info = await VideoCompress.getMediaInfo(video.path);
```

---

#### 2. Upload Video File
**API Call:**
```http
POST /api/uploads
Authorization: Bearer {accessToken}
Content-Type: multipart/form-data

file: [binary video data]
type: VIDEO
groupId: group-uuid
```

**Backend Processing** (`backend/src/modules/uploads/uploads.service.ts`):
1. Validate file size (max 2GB)
2. Validate mime type (video/mp4, video/quicktime, etc.)
3. Generate unique filename with UUID
4. Upload to Cloudinary video storage
5. Extract video metadata (duration, dimensions, codec)
6. Create File record with status UPLOADING

**Cloudinary Processing:**
- Cloudinary receives video upload
- Generates thumbnail automatically
- Transcodes to multiple qualities (if configured)
- Creates HLS manifest for adaptive streaming

**Database Write:**
```sql
INSERT INTO files (
  id, uploaded_by_id, group_id, original_name, file_name,
  mime_type, extension, size, file_type, provider,
  storage_key, url, status, duration, width, height, thumbnail_url
)
VALUES (
  uuid, 'user-uuid', 'group-uuid', 'my_video.mp4', 'uuid-filename.mp4',
  'video/mp4', 'mp4', 15728640, 'VIDEO', 'CLOUDINARY',
  'videos/uuid-filename', 'https://res.cloudinary.com/.../video.mp4',
  'READY', 125.5, 1920, 1080, 'https://res.cloudinary.com/.../thumbnail.jpg'
);
```

**Result:** File uploaded, metadata stored, fileId returned

---

#### 3. Create Video Record
**User Action:** Fills video details (title, description, tags), taps "Publish"

**API Call:**
```http
POST /api/video-channels/{channelId}/videos
Authorization: Bearer {accessToken}

{
  "title": "Traditional Ethiopian Coffee Ceremony Tutorial",
  "description": "Learn how to perform the traditional coffee ceremony...",
  "sourceFileId": "file-uuid",
  "categories": ["Education", "Culture"],
  "tags": ["coffee", "ethiopia", "tutorial"],
  "hashtags": ["#ethiopiancoffee", "#culture"],
  "visibility": "PUBLIC",
  "isDownloadable": true,
  "downloadPermission": "MEMBERS_ONLY"
}
```

**Backend Processing** (`backend/src/modules/videos/videos.service.ts`):
1. Verify user has upload permission in channel
2. Generate unique slug from title
3. Extract video metadata from File record
4. Create Video record with status READY (already processed by Cloudinary)
5. Link to video channel and group

**Database Write:**
```sql
INSERT INTO videos (
  id, video_channel_id, uploaded_by_id, source_file_id,
  title, description, slug, status, visibility,
  duration, width, height, hls_url, thumbnail_url,
  categories, tags, hashtags, is_downloadable, download_permission
)
VALUES (
  uuid, 'channel-uuid', 'user-uuid', 'file-uuid',
  'Traditional Ethiopian Coffee...', 'Learn how to...', 'traditional-ethiopian-coffee-xyz123',
  'READY', 'PUBLIC',
  125.5, 1920, 1080, 'https://res.cloudinary.com/.../video.m3u8', 'https://res.cloudinary.com/.../thumb.jpg',
  ARRAY['Education', 'Culture'], ARRAY['coffee', 'ethiopia', 'tutorial'],
  ARRAY['#ethiopiancoffee', '#culture'], true, 'MEMBERS_ONLY'
);

-- Update channel video count
UPDATE video_channels
SET videos_count = videos_count + 1
WHERE id = 'channel-uuid';
```

---

#### 4. Notify Subscribers
**Backend (Automatic):**
After video published, notification service triggers:

```typescript
// backend/src/modules/videos/videos.service.ts
await this.notificationsService.notifyChannelSubscribers(
  videoChannelId,
  {
    type: 'VIDEO_UPLOAD',
    title: `New video from ${channelName}`,
    body: videoTitle,
    data: { videoId: video.id }
  }
);
```

**Database Queries:**
```sql
-- Find all subscribers
SELECT user_id FROM video_subscriptions
WHERE video_channel_id = 'channel-uuid' AND notify_on_upload = true;

-- Create notifications
INSERT INTO notifications (id, user_id, type, title, body, data)
SELECT uuid, user_id, 'VIDEO_UPLOAD', 'New video from...', video_title, json_build_object('videoId', video_uuid)
FROM subscriber_list;
```

**Push Notifications:** FCM sends to all subscriber devices

---

### Journey Success Criteria
✅ Video file uploaded successfully to Cloudinary
✅ File record created with metadata
✅ Video record created and linked to channel
✅ Video status is READY and publicly visible
✅ HLS streaming URL available
✅ Subscribers notified of new upload
✅ Video appears in channel feed

---

## Journey 5: Live Streaming (Broadcaster)

### Goal
Creator goes live, broadcasts to audience, interacts via chat, ends stream.

### Step-by-Step Flow

#### 1. Create Stream
**User Action:** Taps (+) → "Go Live", fills stream details

**API Call:**
```http
POST /api/video-channels/{channelId}/streams
Authorization: Bearer {accessToken}

{
  "title": "Live: Ethiopian Music Session 🎵",
  "description": "Traditional music performance",
  "categories": ["Music", "Culture"],
  "tags": ["live", "ethiopian", "music"],
  "visibility": "PUBLIC",
  "isChatEnabled": true,
  "isChatSlowMode": false,
  "isRecordingEnabled": true,
  "notifyAllUsers": false
}
```

**Backend Processing** (`backend/src/modules/live-streaming/live-streaming.service.ts`):
1. Verify user has streaming permission
2. Generate unique slug
3. Create LiveStream with status DRAFT
4. Set rtmpIngestUrl

**Database Write:**
```sql
INSERT INTO live_streams (
  id, video_channel_id, group_id, created_by_id,
  title, description, slug, status, visibility, protocol,
  rtmp_ingest_url, categories, tags,
  is_chat_enabled, is_recording_enabled
)
VALUES (
  uuid, 'channel-uuid', 'group-uuid', 'user-uuid',
  'Live: Ethiopian Music...', 'Traditional music...', 'live-ethiopian-music-xyz123',
  'DRAFT', 'PUBLIC', 'RTMP',
  'rtmp://live.cloudinary.com/streams', ARRAY['Music', 'Culture'], ARRAY['live', 'ethiopian', 'music'],
  true, true
);
```

**Response:** Returns stream object with streamId

---

#### 2. Go Live
**User Action:** Taps "Go Live" button

**API Call:**
```http
POST /api/streams/{streamId}/go-live
Authorization: Bearer {accessToken}
```

**Backend Processing (Complex):**
1. Provision Cloudinary live stream (or retrieve existing)
2. Activate Cloudinary stream (polls until active, up to 35s)
3. Update stream status to LIVE, set startedAt
4. Create StreamSession record
5. Upsert StreamChatRoom if chat enabled
6. Clear any pending interruption timers
7. Broadcast stream-started event via WebSocket

**Cloudinary API Calls:**
```javascript
// Create live stream
POST https://api.cloudinary.com/v1_1/{cloud}/live_streams
{
  "name": "stream_live-ethiopian-music_123456",
  "archive": { "enabled": true }
}

// Activate stream
PUT https://api.cloudinary.com/v1_1/{cloud}/live_streams/{id}/activate
```

**Database Updates:**
```sql
-- Update stream
UPDATE live_streams
SET status = 'LIVE',
    started_at = NOW(),
    hls_url = 'https://res.cloudinary.com/.../stream.m3u8',
    webrtc_url = 'cloudinary:cld_abc123',
    dash_url = 'live_stream_abc123_archive'
WHERE id = 'stream-uuid';

-- Create session
INSERT INTO stream_sessions (id, live_stream_id, started_at)
VALUES (uuid, 'stream-uuid', NOW());

-- Create chat room
INSERT INTO stream_chat_rooms (id, live_stream_id, is_enabled)
VALUES (uuid, 'stream-uuid', true)
ON CONFLICT (live_stream_id) DO NOTHING;
```

**Response:**
```json
{
  "data": {
    "id": "stream-uuid",
    "status": "LIVE",
    "hlsUrl": "https://res.cloudinary.com/.../stream.m3u8",
    "rtmpIngestUrl": "rtmp://live.cloudinary.com/streams",
    "streamKey": "cld_abc123_xyz789_secret"
  }
}
```

---

#### 3. Start Broadcasting
**Frontend (Flutter):**
```dart
// Initialize RTMP pusher
final rtmpConnection = await RTMPConnection.create();
await rtmpConnection.connect(
  url: 'rtmp://live.cloudinary.com/streams',
  key: streamKey
);

// Start camera stream
await rtmpConnection.publish();

// Connect to WebSocket
await liveSocketService.connect(accessToken);
await liveSocketService.joinStream(streamId);

// Send heartbeat every 10 seconds
Timer.periodic(Duration(seconds: 10), (_) {
  liveSocketService.sendBroadcasterHeartbeat(streamId);
});
```

**Backend (WebSocket):**
- Broadcaster socket joins `stream:{streamId}` room
- Backend registers broadcaster via `registerBroadcasterSocket()`
- Heartbeat prevents auto-end during temporary disconnects

---

#### 4. Viewers Join
**Backend (Automatic):**
When viewers emit `stream:join`:
1. Create StreamViewer record
2. Increment currentViewerCount
3. Update peakViewerCount if new peak
4. Broadcast updated viewer count to all

**Database:**
```sql
-- Track viewer
INSERT INTO stream_viewers (id, live_stream_id, user_id, joined_at)
VALUES (uuid, 'stream-uuid', 'viewer-uuid', NOW());

-- Update counts
UPDATE live_streams
SET current_viewer_count = (SELECT COUNT(*) FROM stream_viewers WHERE live_stream_id = 'stream-uuid' AND left_at IS NULL),
    peak_viewer_count = GREATEST(peak_viewer_count, current_viewer_count),
    total_viewer_count = total_viewer_count + 1
WHERE id = 'stream-uuid';
```

---

#### 5. Chat Interaction
**Viewers Send Chat:**
```javascript
// WebSocket event
socket.emit('chat:send', {
  streamId: 'stream-uuid',
  content: 'Amazing performance! 🎵',
  type: 'TEXT'
});
```

**Backend Processing:**
1. Rate limit check (10 msg/10s)
2. Save StreamChatMessage
3. Broadcast to all sockets in room

**Broadcaster Moderates:**
```javascript
// Delete inappropriate message
socket.emit('chat:delete', {
  streamId: 'stream-uuid',
  messageId: 'msg-uuid'
});
```

---

#### 6. End Stream
**User Action:** Taps "End Stream"

**API Call:**
```http
POST /api/streams/{streamId}/end
Authorization: Bearer {accessToken}
```

**Backend Processing:**
1. Calculate duration: (now - startedAt)
2. Update stream: status=ENDED, endedAt=now, duration
3. End StreamSession
4. Idle Cloudinary live stream
5. Create StreamRecording if enabled
6. Mark recording as READY with VOD URL
7. Enqueue processing job (BullMQ)
8. Clear broadcaster session and interruption timers
9. Broadcast stream-ended via WebSocket

**Database Updates:**
```sql
-- Update stream
UPDATE live_streams
SET status = 'ENDED',
    ended_at = NOW(),
    duration = EXTRACT(EPOCH FROM (NOW() - started_at))
WHERE id = 'stream-uuid';

-- End session
UPDATE stream_sessions
SET ended_at = NOW()
WHERE live_stream_id = 'stream-uuid' AND ended_at IS NULL;

-- Create recording
INSERT INTO stream_recordings (
  id, live_stream_id, status, hls_url, duration, started_at
)
VALUES (
  uuid, 'stream-uuid', 'READY',
  'https://res.cloudinary.com/.../sp_hd/archive.m3u8',
  duration_seconds, started_at_timestamp
);
```

---

### Journey Success Criteria
✅ Stream created in DRAFT status
✅ Cloudinary provisioned and activated
✅ Stream transitioned to LIVE status
✅ RTMP broadcast connected successfully
✅ HLS playback URL available for viewers
✅ Chat enabled and moderated
✅ Viewer counts tracked accurately
✅ Stream ended gracefully
✅ Recording created and VOD available

---

## Journey 6: Live Streaming (Viewer)

### Goal
Viewer discovers live stream, watches, participates in chat, sends reactions.

### Step-by-Step Flow

#### 1. Discover Live Stream
**User Action:** Opens Explore → Live Now tab

**API Call:**
```http
GET /api/streams/live?category=Music&page=1&limit=20
Authorization: Bearer {accessToken}
```

**Result:** List of currently LIVE streams sorted by viewer count

---

#### 2. Join Stream
**User Action:** Taps stream thumbnail

**API Call:**
```http
GET /api/streams/{streamId}
Authorization: Bearer {accessToken}
```

**Frontend:**
```dart
// Initialize player
final controller = VideoPlayerController.networkUrl(
  Uri.parse(stream.hlsUrl)
);
await controller.initialize();
await controller.play();

// Connect WebSocket
await liveSocketService.connect(accessToken);
await liveSocketService.joinStream(streamId);
```

**WebSocket Event:**
```javascript
socket.emit('stream:join', { streamId: 'stream-uuid' });
```

**Backend Processing:**
1. Join socket to room
2. Create StreamViewer record
3. Increment viewer count
4. Broadcast updated count

---

#### 3. Watch Stream
**Frontend:** 
- VideoPlayer plays HLS stream
- Adaptive bitrate based on bandwidth
- Reports quality every 30s

**WebSocket (Quality Report):**
```javascript
socket.emit('quality:report', {
  streamId: 'stream-uuid',
  bandwidth: 3500,
  quality: '720p'
});
```

**Backend:** Aggregates reports for health dashboard

---

#### 4. Send Chat Message
**User Action:** Types message, taps send

**WebSocket:**
```javascript
socket.emit('chat:send', {
  streamId: 'stream-uuid',
  content: 'This is beautiful! 🇪🇹'
});
```

**Backend:**
- Rate limit: 10 msg/10s
- Save to database
- Broadcast to all viewers

**All Viewers Receive:**
```javascript
socket.on('chat:message', (message) => {
  // message: { id, senderId, sender: {username, avatar}, content, createdAt }
});
```

---

#### 5. Send Floating Reaction
**User Action:** Taps heart emoji in picker

**WebSocket:**
```javascript
socket.emit('reaction:send', {
  streamId: 'stream-uuid',
  emoji: '❤️'
});
```

**Backend:**
- Rate limit: 20 reactions/5s
- Create StreamReaction record
- Count recent reactions (last 5s)
- Broadcast to room

**All Viewers:**
```javascript
socket.on('reaction:broadcast', ({ emoji, count }) => {
  // Spawn `count` animated emoji particles
});
```

**Frontend:** Animates floating emojis from bottom to top with fade

---

#### 6. Leave Stream
**User Action:** Swipes down or navigates away

**WebSocket:**
```javascript
socket.emit('stream:leave', { streamId: 'stream-uuid' });
```

**Backend:**
1. Calculate watch duration
2. Update StreamViewer: leftAt, watchDuration
3. Decrement current viewer count
4. Broadcast updated count

**Database:**
```sql
UPDATE stream_viewers
SET left_at = NOW(),
    watch_duration = EXTRACT(EPOCH FROM (NOW() - joined_at))
WHERE id = 'viewer-session-uuid';
```

---

### Journey Success Criteria
✅ Discovered live stream in Explore
✅ Joined stream successfully
✅ HLS video playback working
✅ WebSocket connected and receiving events
✅ Chat messages sent and received
✅ Floating reactions animated
✅ Viewer count updated in real-time
✅ Watch duration tracked for analytics

---

## Journey 7: Offline Content Consumption

### Goal
User downloads videos, goes offline, watches downloaded content, syncs when online.

### Step-by-Step Flow

#### 1. Download Video (While Online)
**User Action:** Taps download icon on video

**Frontend:**
```dart
await downloadService.downloadVideo(
  videoId: videoId,
  quality: VideoQuality.p720
);
```

**API Call:**
```http
POST /api/downloads/videos/{videoId}
Authorization: Bearer {accessToken}

{
  "quality": "720p"
}
```

**Backend Processing:**
1. Check download permission (creator must enable)
2. Generate signed URL for video file
3. Create DownloadRecord with status PENDING

**Database:**
```sql
INSERT INTO download_records (
  id, user_id, video_id, resolution, status, signed_url, expires_at
)
VALUES (
  uuid, 'user-uuid', 'video-uuid', 'R_720P', 'PENDING',
  'https://res.cloudinary.com/.../video_720p.mp4?signature=...', NOW() + INTERVAL '1 hour'
);
```

**Frontend (Download Manager):**
```dart
// Use Dio to download with progress tracking
await dio.download(
  signedUrl,
  localPath,
  onReceiveProgress: (received, total) {
    progress = received / total;
  }
);

// Update local database
await db.downloadedVideos.insert(
  DownloadedVideo(
    videoId: videoId,
    localPath: localPath,
    quality: quality,
    downloadedAt: DateTime.now()
  )
);
```

**Result:** Video file stored locally, metadata in SQLite

---

#### 2. Go Offline
**User Action:** Enables airplane mode or loses connection

**Frontend (Automatic):** Connectivity status listener detects offline state

---

#### 3. Watch Downloaded Video
**User Action:** Opens Library → Downloads, taps video

**Frontend:**
```dart
// Check if video is downloaded
final downloaded = await db.downloadedVideos.getByVideoId(videoId);

if (downloaded != null) {
  // Play from local file
  final controller = VideoPlayerController.file(
    File(downloaded.localPath)
  );
  await controller.initialize();
  await controller.play();
} else {
  // Show "Download required" message
}
```

**Local Database Query:**
```sql
-- SQLite
SELECT * FROM downloaded_videos
WHERE video_id = 'video-uuid';
```

**Result:** Video plays from local storage without internet

---

#### 4. View Calendar Notes (Offline)
**User Action:** Opens calendar, views notes

**Local Database:**
```dart
// Query SQLite
final notes = await db.calendarNotes
  .where()
  .ethiopianYearMonthEqualTo(2016, 3) // Hidar 2016
  .findAll();
```

**Result:** All notes visible, reminders still fire

---

#### 5. Go Back Online
**User Action:** Disables airplane mode, Wi-Fi reconnects

**Frontend (Automatic Background Sync):**
```dart
// Every 15 minutes or on connectivity change
Timer.periodic(Duration(minutes: 15), (_) async {
  if (await connectivity.checkConnectivity() != ConnectivityResult.none) {
    await CalendarBackgroundSyncManager.syncNow();
  }
});
```

**Sync Process:**
1. Fetch server calendar notes since last sync
2. Compare with local notes
3. Upload local changes (created/updated notes)
4. Download server changes
5. Resolve conflicts (server wins)
6. Update local database

**API Calls:**
```http
GET /api/calendar/notes?since=2024-09-20T10:00:00Z
Authorization: Bearer {accessToken}

POST /api/calendar/notes/bulk-sync
Authorization: Bearer {accessToken}

{
  "notes": [
    { "id": "local-uuid", "title": "...", "content": "...", "ethiopianDate": {...} }
  ]
}
```

---

### Journey Success Criteria
✅ Video downloaded successfully while online
✅ Downloaded video played offline
✅ Calendar notes visible offline
✅ Local reminders fired offline
✅ Background sync triggered when online
✅ Local changes synced to server
✅ Server changes synced to device
✅ No data loss during offline period

---

## Journey 8: Ethiopian Calendar with Reminders

### Goal
User creates calendar note with photo, sets yearly reminder, receives notification.

### Step-by-Step Flow

#### 1. Create Calendar Note
**User Action:** Opens Calendar, selects date (e.g., Meskerem 1, 2017), taps "Add Note"

**Frontend:**
```dart
// User selects Ethiopian date
final ethiopianDate = EthiopianCalendar(year: 2017, month: 1, day: 1);

// Convert to Gregorian for storage
final gregorianDate = ethiopianDate.toGregorian(); // 2024-09-11
```

---

#### 2. Add Content and Media
**User Action:** Adds title, content, uploads photo

**Upload Photo:**
```http
POST /api/uploads
Content-Type: multipart/form-data

file: [image data]
type: IMAGE
```

**Response:** `{ fileId: "file-uuid", url: "..." }`

---

#### 3. Set Reminder
**User Action:** Toggles "Set Reminder", chooses yearly repeat

**Frontend Form:**
```dart
{
  "title": "Ethiopian New Year Celebration",
  "content": "Annual celebration with family",
  "ethiopianYear": 2017,
  "ethiopianMonth": 1,
  "ethiopianDay": 1,
  "gregorianDate": "2024-09-11",
  "hasReminder": true,
  "reminderDateTime": "2024-09-11T08:00:00+03:00",
  "reminderRepeat": "YEARLY",
  "reminderEthiopianMonth": 1,
  "reminderEthiopianDay": 1,
  "reminderHour": 8,
  "reminderMinute": 0,
  "reminderTimezone": "Africa/Addis_Ababa",
  "media": [{ "fileId": "file-uuid", "order": 0 }]
}
```

**API Call:**
```http
POST /api/calendar/notes
Authorization: Bearer {accessToken}
```

**Backend Processing:**
1. Validate Ethiopian date
2. Convert to Gregorian for indexing
3. Calculate next reminder occurrence
4. Create CalendarNote with reminder fields
5. Create CalendarNoteMedia entries

**Database Writes:**
```sql
-- Insert note
INSERT INTO calendar_notes (
  id, user_id, ethiopian_year, ethiopian_month, ethiopian_day,
  gregorian_date, title, content,
  has_reminder, reminder_date_time, reminder_repeat,
  reminder_ethiopian_month, reminder_ethiopian_day,
  reminder_hour, reminder_minute, reminder_timezone,
  reminder_next_occurrence
)
VALUES (
  uuid, 'user-uuid', 2017, 1, 1,
  '2024-09-11', 'Ethiopian New Year...', 'Annual celebration...',
  true, '2024-09-11 08:00:00+03', 'YEARLY',
  1, 1, 8, 0, 'Africa/Addis_Ababa',
  '2024-09-11 08:00:00+03'
);

-- Insert media
INSERT INTO calendar_note_media (id, note_id, file_id, "order", caption)
VALUES (uuid, note_uuid, 'file-uuid', 0, null);
```

---

#### 4. Background Reminder Service
**Backend (Cron Job):** Runs every 15 minutes

```typescript
// backend/src/modules/calendar/calendar-reminder.service.ts

async checkReminders() {
  const now = new Date();
  const fiveMinutesAgo = subMinutes(now, 5);
  
  // Find due reminders
  const dueReminders = await this.prisma.calendarNote.findMany({
    where: {
      hasReminder: true,
      reminderNotified: false,
      reminderNextOccurrence: {
        gte: fiveMinutesAgo,
        lte: now
      }
    }
  });
  
  for (const note of dueReminders) {
    await this.sendReminderNotification(note);
    await this.calculateNextOccurrence(note);
  }
}
```

---

#### 5. Notification Delivery
**When reminder triggers (2024-09-11 08:00 AM):**

**Push Notification:**
```http
POST https://fcm.googleapis.com/fcm/send
Authorization: key={FCM_SERVER_KEY}

{
  "to": "device_token",
  "notification": {
    "title": "Calendar Reminder",
    "body": "Ethiopian New Year Celebration"
  },
  "data": {
    "noteId": "note-uuid",
    "type": "CALENDAR_REMINDER"
  }
}
```

**Database Update:**
```sql
-- Mark as notified
UPDATE calendar_notes
SET reminder_notified = true
WHERE id = 'note-uuid';

-- For yearly repeat, calculate next occurrence
UPDATE calendar_notes
SET reminder_next_occurrence = '2025-09-11 08:00:00+03',
    reminder_notified = false
WHERE id = 'note-uuid' AND reminder_repeat = 'YEARLY';
```

---

#### 6. User Receives Notification
**Frontend (Flutter):**
```dart
// FCM message handler
FirebaseMessaging.onMessage.listen((message) {
  if (message.data['type'] == 'CALENDAR_REMINDER') {
    showLocalNotification(
      title: message.notification?.title,
      body: message.notification?.body,
      payload: message.data['noteId']
    );
  }
});

// User taps notification
void onNotificationTap(String? payload) {
  // Navigate to calendar note
  router.push('/calendar/notes/$payload');
}
```

---

### Journey Success Criteria
✅ Calendar note created with Ethiopian date
✅ Photo attached to note
✅ Yearly reminder configured
✅ Note stored locally and synced to server
✅ Background service found due reminder
✅ Push notification sent at correct time
✅ User received notification on device
✅ Next occurrence calculated (2025-09-11)
✅ Reminder will repeat annually

---

## Journey 9: Direct Messaging

### Goal
Users exchange direct messages with text, images, and voice notes.

### Step-by-Step Flow

#### 1. Start Conversation
**User Action:** Views profile, taps "Message"

**API Call:**
```http
POST /api/conversations
Authorization: Bearer {accessToken}

{
  "type": "DIRECT",
  "participantIds": ["recipient-uuid"]
}
```

**Backend Processing:**
1. Check if conversation already exists between users
2. If exists, return existing conversation
3. If new, create Conversation and ConversationMember records

**Database Writes:**
```sql
-- Create conversation
INSERT INTO conversations (id, type)
VALUES (uuid, 'DIRECT');

-- Add members
INSERT INTO conversation_members (id, conversation_id, user_id)
VALUES 
  (uuid, conversation_uuid, 'sender-uuid'),
  (uuid, conversation_uuid, 'recipient-uuid');
```

---

#### 2. Send Text Message
**User Action:** Types message, taps send

**API Call:**
```http
POST /api/conversations/{conversationId}/messages
Authorization: Bearer {accessToken}

{
  "content": "Hey! Saw your Ethiopian coffee video. Amazing!",
  "type": "TEXT",
  "clientId": "mobile-msg-12345"
}
```

**Backend Processing:**
1. Validate user is conversation member
2. Create Message record
3. Update conversation's lastMessageAt
4. Increment unread count for recipient
5. Create MessageRead for sender
6. Send push notification to recipient

**Database Writes:**
```sql
-- Insert message
INSERT INTO messages (id, conversation_id, sender_id, content, type, client_id)
VALUES (uuid, conversation_uuid, 'sender-uuid', 'Hey! Saw your...', 'TEXT', 'mobile-msg-12345');

-- Update conversation
UPDATE conversations
SET last_message_id = message_uuid,
    last_message_at = NOW(),
    updated_at = NOW()
WHERE id = conversation_uuid;

-- Update recipient unread count
UPDATE conversation_members
SET unread_count = unread_count + 1
WHERE conversation_id = conversation_uuid AND user_id = 'recipient-uuid';

-- Mark as read for sender
INSERT INTO message_reads (message_id, user_id, read_at)
VALUES (message_uuid, 'sender-uuid', NOW());
```

---

#### 3. Recipient Receives Message
**Push Notification:**
```json
{
  "notification": {
    "title": "John Doe",
    "body": "Hey! Saw your Ethiopian coffee video..."
  },
  "data": {
    "type": "MESSAGE",
    "conversationId": "conversation-uuid",
    "messageId": "message-uuid"
  }
}
```

**Recipient Opens App:**
```http
GET /api/conversations/{conversationId}/messages?limit=50
Authorization: Bearer {accessToken}
```

**Mark as Read:**
```http
POST /api/conversations/{conversationId}/messages/{messageId}/read
Authorization: Bearer {accessToken}
```

**Database:**
```sql
-- Create read receipt
INSERT INTO message_reads (message_id, user_id, read_at)
VALUES ('message-uuid', 'recipient-uuid', NOW());

-- Decrement unread count
UPDATE conversation_members
SET unread_count = unread_count - 1,
    last_read_message_id = 'message-uuid'
WHERE conversation_id = conversation_uuid AND user_id = 'recipient-uuid';
```

---

#### 4. Send Image
**User Action:** Taps camera icon, selects image

**Upload Image:**
```http
POST /api/uploads
Content-Type: multipart/form-data

file: [image data]
type: IMAGE
```

**Send Message with Attachment:**
```http
POST /api/conversations/{conversationId}/messages

{
  "type": "IMAGE",
  "content": "Check this out! 📸",
  "attachments": [{"fileId": "file-uuid"}]
}
```

**Database:**
```sql
-- Insert message
INSERT INTO messages (id, conversation_id, sender_id, content, type)
VALUES (uuid, conversation_uuid, 'sender-uuid', 'Check this out!', 'IMAGE');

-- Link attachment
INSERT INTO message_attachments (id, message_id, file_id)
VALUES (uuid, message_uuid, 'file-uuid');
```

---

#### 5. Send Voice Message
**User Action:** Holds record button, records audio, releases

**Frontend:**
```dart
// Record audio
final recording = await audioRecorder.start();
final audioFile = await audioRecorder.stop();

// Upload voice note
final uploaded = await uploadVoiceNote(audioFile);
```

**Upload:**
```http
POST /api/uploads
Content-Type: multipart/form-data

file: [audio data]
type: AUDIO
```

**Send Message:**
```http
POST /api/conversations/{conversationId}/messages

{
  "type": "VOICE_NOTE",
  "voiceNote": {
    "fileId": "file-uuid",
    "duration": 15
  }
}
```

**Database:**
```sql
-- Insert message
INSERT INTO messages (id, conversation_id, sender_id, type)
VALUES (uuid, conversation_uuid, 'sender-uuid', 'VOICE_NOTE');

-- Link voice note
INSERT INTO voice_messages (id, message_id, file_id, duration)
VALUES (uuid, message_uuid, 'file-uuid', 15);
```

---

### Journey Success Criteria
✅ Conversation created between two users
✅ Text messages sent and received
✅ Push notifications delivered
✅ Read receipts tracked
✅ Unread count accurate
✅ Images sent and displayed
✅ Voice notes recorded and sent
✅ Message history persisted

---

## Journey 10: Admin Moderating Content

### Goal
Admin reviews reported content, takes moderation action, logs activity.

### Prerequisites
- User has ADMIN or MODERATOR role

### Step-by-Step Flow

#### 1. View Reports
**Admin Action:** Opens admin panel, navigates to Reports

**API Call:**
```http
GET /api/admin/reports?status=PENDING&page=1&limit=20
Authorization: Bearer {accessToken}
```

**Backend Authorization:**
1. JwtAuthGuard validates token
2. RolesGuard checks role is ADMIN or MODERATOR
3. PermissionsGuard checks `reports.view` permission

**Response:** List of pending reports

---

#### 2. Review Reported Video
**Admin Action:** Clicks on report, views video

**API Call:**
```http
GET /api/reports/{reportId}
Authorization: Bearer {accessToken}
```

**Response:**
```json
{
  "data": {
    "id": "report-uuid",
    "targetType": "VIDEO",
    "targetId": "video-uuid",
    "reason": "INAPPROPRIATE_CONTENT",
    "comment": "Contains offensive language",
    "status": "PENDING",
    "reporter": {
      "id": "reporter-uuid",
      "username": "concerned_user"
    },
    "target": {
      "id": "video-uuid",
      "title": "Controversial Video",
      "uploader": {"username": "uploader123"}
    }
  }
}
```

**Admin watches video to assess violation**

---

#### 3. Take Action: Delete Video
**Admin Action:** Clicks "Delete Video", enters reason

**API Call:**
```http
DELETE /api/admin/videos/{videoId}
Authorization: Bearer {accessToken}

{
  "reason": "Violates community guidelines - inappropriate content"
}
```

**Backend Processing:**
1. Check permission `videos.delete`
2. Soft delete video (set deletedAt)
3. Create audit log entry
4. Resolve report
5. Notify video uploader

**Database Updates:**
```sql
-- Soft delete video
UPDATE videos
SET deleted_at = NOW()
WHERE id = 'video-uuid';

-- Create audit log
INSERT INTO audit_logs (
  id, user_id, action, resource, target_type, target_id,
  before, after, reason, ip_address
)
VALUES (
  uuid, 'admin-uuid', 'VIDEO_DELETED', 'VIDEO', 'VIDEO', 'video-uuid',
  json_build_object('status', 'READY', 'deletedAt', null),
  json_build_object('status', 'READY', 'deletedAt', NOW()::text),
  'Violates community guidelines - inappropriate content',
  'admin-ip-address'
);

-- Resolve report
UPDATE reports
SET status = 'RESOLVED',
    action_taken = 'VIDEO_DELETED',
    resolved_by_id = 'admin-uuid',
    resolved_at = NOW()
WHERE id = 'report-uuid';

-- Notify uploader
INSERT INTO notifications (id, user_id, type, title, body, data)
VALUES (
  uuid, 'uploader-uuid', 'SYSTEM',
  'Content Removed',
  'Your video was removed for violating community guidelines',
  json_build_object('videoId', 'video-uuid', 'reason', 'inappropriate_content')
);
```

---

#### 4. Alternative Action: Dismiss Report
**If admin determines no violation:**

**API Call:**
```http
POST /api/admin/reports/{reportId}/dismiss
Authorization: Bearer {accessToken}

{
  "reason": "Reviewed - no policy violation found"
}
```

**Database:**
```sql
-- Dismiss report
UPDATE reports
SET status = 'DISMISSED',
    resolved_by_id = 'admin-uuid',
    resolved_at = NOW()
WHERE id = 'report-uuid';

-- Log action
INSERT INTO audit_logs (id, user_id, action, target_type, target_id, reason)
VALUES (uuid, 'admin-uuid', 'REPORT_DISMISSED', 'REPORT', 'report-uuid', 'Reviewed - no policy violation');
```

---

#### 5. Suspend User (Escalation)
**For repeat offender:**

**API Call:**
```http
POST /api/admin/users/{userId}/suspend
Authorization: Bearer {accessToken}

{
  "reason": "Multiple community guideline violations",
  "duration": 7
}
```

**Backend:**
1. Check `users.suspend` permission
2. Update user status to SUSPENDED
3. Revoke all sessions
4. Create audit log

**Database:**
```sql
-- Suspend user
UPDATE users
SET status = 'SUSPENDED',
    locked_until = NOW() + INTERVAL '7 days'
WHERE id = 'user-uuid';

-- Revoke sessions
UPDATE sessions
SET status = 'REVOKED'
WHERE user_id = 'user-uuid' AND status = 'ACTIVE';

-- Revoke tokens
UPDATE refresh_tokens
SET revoked_at = NOW()
WHERE user_id = 'user-uuid' AND revoked_at IS NULL;

-- Audit log
INSERT INTO audit_logs (user_id, action, target_type, target_id, reason, before, after)
VALUES (
  'admin-uuid', 'USER_SUSPENDED', 'USER', 'user-uuid',
  'Multiple community guideline violations',
  json_build_object('status', 'ACTIVE'),
  json_build_object('status', 'SUSPENDED', 'lockedUntil', (NOW() + INTERVAL '7 days')::text)
);
```

**User Impact:**
- All sessions terminated immediately
- Cannot log in until suspension ends
- Receives notification of suspension

---

### Journey Success Criteria
✅ Admin accessed reports with proper permissions
✅ Report reviewed with full context
✅ Moderation action taken (delete video)
✅ Audit log created with before/after snapshots
✅ Report marked as resolved
✅ Content creator notified
✅ All actions logged for accountability
✅ Alternative dismissal path available for false reports

---

## Summary

These journeys demonstrate the complete system flow across:
- **10 key user scenarios** from onboarding to moderation
- **Frontend → API → Backend → Database** data flows
- **Authentication and authorization** at every step
- **Real-time features** via WebSocket
- **Offline capabilities** with sync
- **Role-based access control** enforcement
- **Audit logging** for admin actions

Each journey is **verified against actual implementation** based on:
- Backend service code review
- API endpoint examination
- Database schema validation
- Frontend repository inspection
- Real-time architecture analysis

---

*Last updated: September 2026 - Based on comprehensive system audit*
