# Zikire Kdusan User Guide

## Welcome to Zikire Kdusan

Zikire Kdusan (also known as StreamHub) is a comprehensive video streaming and social platform designed for the Ethiopian community. The platform combines live streaming, video content, social networking, messaging, and community features with integrated Ethiopian calendar support.

**Supported Platforms:**
- Android mobile app
- iOS mobile app
- Web application

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Account Management](#account-management)
3. [Home and Navigation](#home-and-navigation)
4. [Watching Videos](#watching-videos)
5. [Live Streaming](#live-streaming)
6. [Groups and Communities](#groups-and-communities)
7. [Messaging and Chat](#messaging-and-chat)
8. [Social Features](#social-features)
9. [Stories and Reels](#stories-and-reels)
10. [Ethiopian Calendar](#ethiopian-calendar)
11. [Search and Discovery](#search-and-discovery)
12. [Notifications](#notifications)
13. [Downloads and Offline](#downloads-and-offline)
14. [Profile and Settings](#profile-and-settings)

---

## Getting Started

### What is Zikire Kdusan?

Zikire Kdusan is a multi-purpose platform that provides:
- **Live streaming** with real-time chat and reactions
- **Video hosting and playback** with adaptive quality
- **Social networking** with posts, stories, and reels
- **Group communities** with channels and messaging
- **Direct messaging** with multimedia support
- **Ethiopian calendar integration** with notes and reminders
- **Content discovery** with trending and recommendations
- **Offline downloads** for watching without internet

### System Requirements

**Mobile (Android/iOS):**
- Android 6.0+ or iOS 12+
- Minimum 2GB RAM recommended
- Camera and microphone for creating content
- Stable internet connection (Wi-Fi or 4G/5G)

**Web:**
- Modern browser (Chrome, Firefox, Safari, Edge)
- JavaScript enabled
- WebRTC support for live streaming

---

## Account Management

### Creating an Account

**What you need:** At least one of the following:
- Email address
- Phone number (E.164 format: +251...)
- Username (optional during registration)

**Registration Steps:**

1. **Open the app** and tap "Sign Up" or "Create Account"

2. **Enter your details:**
   - Email OR phone number (required)
   - Password (minimum 8 characters)
   - First name and last name (optional but recommended)
   - Username (optional, can be added later)

3. **Complete registration:**
   - Tap "Sign Up"
   - You'll receive access and refresh tokens
   - You're automatically logged in

**Important Notes:**
- Each email, phone number, and username must be unique
- Passwords are securely hashed with bcrypt
- You can use email, phone, or username to log in later
- Your default role is "USER" with standard permissions

### Logging In

**Login Options:**
- Email address
- Phone number
- Username

**Login Steps:**

1. Open the app and tap "Sign In"
2. Enter your email, phone, or username
3. Enter your password
4. Tap "Sign In"

**Security Features:**
- Failed login tracking: After 5 incorrect attempts, your account is locked for 15 minutes
- Account status validation: Suspended or banned accounts cannot log in
- JWT tokens expire after 15 minutes for security

### Account Security

**Password Security:**
- Minimum 8 characters required
- Passwords are hashed with bcrypt (never stored in plain text)
- Change your password in Settings → Security

**Session Management:**
- Access tokens valid for 15 minutes
- Refresh tokens valid for 7 days
- You're automatically logged out when refresh token expires
- Logout revokes all active sessions

**Account Protection:**
- Account automatically locked after 5 failed login attempts
- Lock duration: 15 minutes
- Counter resets on successful login

**Account Status Types:**
- **ACTIVE**: Normal account (can log in and use all features)
- **INACTIVE**: Temporarily disabled
- **SUSPENDED**: Restricted by moderator/admin
- **BANNED**: Permanently restricted

---

## Home and Navigation

### App Structure

**Bottom Navigation Bar (Mobile):**
1. **Home** - Main feed with videos, posts, and stories
2. **Explore** - Discover trending content and live streams
3. **Create** (+) - Quick access to upload/create content
4. **Library** - Your saved content, watch history, downloads
5. **Profile** - Your account, settings, and personal content

**Top Navigation:**
- **Search** - Find content, users, groups, and channels
- **Notifications** - Activity updates and mentions
- **Messages** - Direct messages and group chats

### Home Feed

The home feed displays:
- **Stories** (at the top, horizontal scroll)
- **Live streams** currently happening
- **Videos** from subscribed channels
- **Posts** from people you follow
- **Reels** (short videos)
- **Group activity** from your groups

**Feed Customization:**
- Pull down to refresh
- Scroll to load more content
- Tap filter icon to show specific content types

### Navigation Tips

- **Swipe right** on most screens to go back
- **Long press** on videos to see quick actions
- **Double tap** videos to like
- **Swipe down** on video player to minimize to mini-player
- **Pull down** mini-player to dismiss

---

## Watching Videos

### Finding Videos

**Methods:**
1. **Home feed** - Personalized recommendations
2. **Explore tab** - Trending and popular videos
3. **Search** - Search by title, tags, or creator
4. **Channel pages** - Browse creator's content
5. **Playlists** - Curated video collections
6. **Library → Watch History** - Previously watched videos

### Video Playback

**Playback Controls:**
- **Play/Pause** - Tap the screen or play button
- **Seek** - Drag the progress bar
- **Volume** - Use device volume buttons or on-screen slider
- **Quality** - Tap settings gear icon to change quality (240p-1080p)
- **Fullscreen** - Rotate device or tap fullscreen icon
- **Speed** - Adjust playback speed (0.5x - 2x)
- **Captions** - Enable subtitles if available

**Supported Quality Levels:**
- 240p (low bandwidth)
- 360p (mobile data)
- 480p (SD)
- 720p (HD)
- 1080p (Full HD)
- Automatic quality adaptation based on connection speed

**Video Features:**
- **Adaptive bitrate streaming** - Quality adjusts automatically
- **Resume playback** - Continues where you left off
- **Watch progress tracking** - System remembers your position
- **Picture-in-picture** (mobile) - Watch while using other apps
- **Mini-player** - Swipe down to continue watching while browsing

### Interacting with Videos

**Actions:**
- **Like/Dislike** - Tap thumbs up or down
- **Comment** - Tap comment icon, write your comment, submit
- **Share** - Tap share icon, choose method (link, social media, copy)
- **Save** - Bookmark video to watch later
- **Report** - Flag inappropriate content (requires reason)
- **Download** - Save for offline viewing (if enabled by creator)

**Comments:**
- **Reply** - Tap reply on any comment
- **Like comments** - Show support for helpful comments
- **Sort** - View by Top, Newest, or Oldest
- **Delete your comments** - Long press your own comment

---

## Live Streaming

### Watching Live Streams

**Finding Live Streams:**
1. **Explore → Live** tab shows all active streams
2. **Home feed** displays live content from followed channels
3. **Notifications** alert you when subscribed channels go live
4. **Group pages** show active group streams

**Live Stream Features:**

**🔴 Live Badge** - Red indicator shows stream is currently live

**Viewer Count** - See how many people are watching

**Live Chat:**
- **Send messages** - Type in the chat box and tap send
- **Emoji reactions** - Tap emoji picker for quick reactions
- **Floating reactions** - Animated emojis float up the screen when sent
- **Pinned messages** - Important announcements highlighted at top
- **Chat rules:**
  - Rate limit: 10 messages per 10 seconds
  - Slow mode: Configurable delay between messages (if enabled by streamer)
  - Members-only: May require group membership to chat
  - Subscribers-only: May require channel subscription to chat

**Interactive Features:**
- **Reactions** - Tap emoji at bottom to send floating reactions (❤️🔥👏😂😮💯🎉👍)
- **Polls** - Vote on broadcaster's polls (one vote per poll)
- **Quality selection** - Adjust stream quality based on your connection
- **DVR** - Rewind live streams if enabled (Cloudinary feature)

**Stream Quality:**
- Automatic adaptation based on your bandwidth
- Manual quality selection available in settings
- System recommends quality based on connection:
  - < 1000 kbps: 240p recommended
  - 1000-2500 kbps: 480p recommended
  - > 2500 kbps: 720p-1080p available

**Interruption Handling:**
- If broadcaster disconnects temporarily, you'll see "Reconnecting..." message
- Grace period: 30 seconds before stream is automatically ended
- Stream continues seamlessly if broadcaster reconnects within grace period

**After Stream Ends:**
- **Instant replay** - Watch recording immediately if replay enabled
- **VOD conversion** - Stream may be published as regular video
- **Chat history** - Read chat messages after stream ends

### Creating Live Streams

**Requirements:**
- Group membership with streaming permissions
- Video channel created in your group
- Stable internet connection (recommended: 3+ Mbps upload)
- Camera and microphone permissions

**Stream Setup Process:**

1. **Navigate to Create:**
   - Tap (+) in bottom navigation
   - Select "Go Live"

2. **Choose Channel:**
   - Select which video channel to stream in
   - Must be a channel where you have streaming permission

3. **Configure Stream:**
   - **Title** (required, 3-300 characters)
   - **Description** (optional, up to 5000 characters)
   - **Thumbnail** - Upload or capture preview image
   - **Visibility:**
     - PUBLIC - Anyone can watch
     - PRIVATE - Only you
     - GROUP_ONLY - Group members only
     - UNLISTED - Anyone with link
   - **Category** - Select relevant category
   - **Tags** - Add searchable tags

4. **Advanced Settings:**
   - **Schedule stream** - Set future start time (creates SCHEDULED status)
   - **Recording** - Enable/disable automatic recording (enabled by default)
   - **DVR** - Allow viewers to rewind (enabled by default)
   - **Replay** - Make recording available after stream (enabled by default)
   - **Chat settings:**
     - Enable/disable chat
     - Slow mode (0-600 seconds between messages)
     - Members-only chat
     - Subscribers-only chat
   - **Notifications:**
     - Notify followers (default)
     - Notify all users (requires special permission)

5. **Get Stream Key:**
   - Tap "Get Stream Key" or "Generate Key"
   - System provisions Cloudinary live stream (may take 30 seconds)
   - **CRITICAL:** Stream key shown ONCE - copy and save securely
   - RTMP URL: `rtmp://live.cloudinary.com/streams`
   - Stream Key: Your unique key (starts with "cld_...")

6. **Start Broadcasting:**
   - **Mobile built-in broadcaster:**
     - Tap "Go Live" button
     - System automatically connects to Cloudinary RTMP
     - Camera preview shows what viewers will see
     - Go live countdown (3-2-1)
     - You're now LIVE!
   
   - **External streaming software:**
     - Copy RTMP URL and stream key
     - Configure in OBS, Streamlabs, or other software
     - Start streaming from external tool
     - Backend detects ingest and activates stream

**While Live:**

**Broadcaster Controls:**
- **Viewer count** - Real-time viewer count displayed
- **Stream duration** - Timer shows how long you've been live
- **Chat moderation** - Delete inappropriate messages
- **Pin messages** - Highlight important announcements
- **Stream quality** - View current bitrate and connection health
- **End stream** - Tap "End Stream" button when finished

**Moderator Tools:**
- Assign co-hosts or moderators before going live
- Moderators can delete chat messages and pin announcements
- View analytics dashboard (viewer count, engagement, quality metrics)

**Notification System:**
- **2-minute rule:** Notifications only sent after you've been live for 2+ minutes
- Prevents spam notifications for test streams
- Subscribers and group members receive push notifications
- If "Notify all users" enabled, entire platform receives notification

**Ending Stream:**

1. Tap "End Stream" button
2. Confirm you want to end
3. Stream transitions to ENDED status
4. Recording is automatically processed
5. Summary screen shows:
   - Total duration
   - Peak viewers
   - Total viewers
   - Total chat messages
   - Total reactions
6. Options:
   - **Publish as VOD** - Make recording available as regular video
   - **Delete recording** - Remove recording permanently
   - **View analytics** - Detailed performance metrics

**After Stream:**

**Recording Processing:**
- Automatic recording if enabled during setup
- Recording available within minutes
- Cloudinary generates VOD-ready HLS stream
- Recording appears in your channel's video library

**Publishing VOD:**
1. Go to stream details page
2. Tap "Publish as Video"
3. Recording becomes discoverable video in your channel
4. All metadata (title, description, categories) carried over
5. Video gets unique ID separate from stream ID

---

## Groups and Communities

### What are Groups?

Groups are community spaces where members can:
- Share posts, videos, and media
- Create video channels
- Host live streams
- Chat in channels
- Organize with custom roles

**Group Features:**
- Public, Private, or Invite-Only visibility
- Member management with roles
- Multiple communication channels
- Group-specific content
- Moderation tools

### Finding and Joining Groups

**Discover Groups:**
1. **Explore tab** → Groups section
2. **Search** for group names or topics
3. **Invitations** from existing members
4. **Recommendations** based on interests

**Join Public Groups:**
1. Find group in Explore or Search
2. Tap group card to view details
3. Tap "Join Group" button
4. You're added as MEMBER immediately

**Join Private/Invite-Only Groups:**
1. Tap "Request to Join"
2. Write optional message explaining why you want to join
3. Group admin receives notification
4. Wait for approval
5. Receive notification when accepted or rejected

**Group Visibility Types:**
- **PUBLIC** - Anyone can find and join
- **PRIVATE** - Anyone can find, but must request to join
- **INVITE_ONLY** - Only visible to invited members

### Group Roles and Permissions

**See [ROLES_AND_PERMISSIONS.md](ROLES_AND_PERMISSIONS.md) for complete details**

**Quick Overview:**
- **GROUP_ADMIN** - Full control over group
- **MODERATOR** - Moderate content and members
- **MEMBER** - Standard member access
- **GUEST** - Limited view-only access

### Creating a Group

**Requirements:**
- Active user account
- Admin approval may be required (depending on platform settings)

**Creation Steps:**

1. **Navigate to Create:**
   - Tap (+) button
   - Select "Create Group"

2. **Basic Information:**
   - **Name** (required)
   - **Description** - Explain group purpose
   - **Avatar** - Group profile picture
   - **Cover image** - Banner image
   - **Website** - Optional website link
   - **Country** - Location

3. **Settings:**
   - **Visibility** - Public, Private, or Invite-Only
   - **Category** - Select relevant category

4. **Submit for Review:**
   - If platform requires approval, group starts in PENDING_APPROVAL status
   - Admin reviews and approves/rejects within 24-48 hours
   - You receive notification of decision

5. **After Approval:**
   - Group status changes to ACTIVE
   - You become GROUP_ADMIN automatically
   - Start inviting members and creating content

### Group Management (Admins)

**Member Management:**
- **Invite members** - Send email or in-app invitations
- **Approve requests** - Review and accept/reject join requests
- **Change roles** - Promote members to MODERATOR or GROUP_ADMIN
- **Remove members** - Remove disruptive members
- **Ban members** - Permanently block from rejoining

**Content Management:**
- **Create channels** - Organize discussions by topic
- **Create video channels** - Set up video content areas
- **Moderate posts** - Delete inappropriate content
- **Pin announcements** - Highlight important messages
- **Configure permissions** - Control who can post, upload, stream

**Group Settings:**
- **Edit details** - Update name, description, images
- **Change visibility** - Switch between Public/Private/Invite-Only
- **Set posting rules** - Define community guidelines
- **Configure channels** - Enable/disable features

---

## Messaging and Chat

### Direct Messages

**Starting a Conversation:**

1. **From Profile:**
   - Visit user's profile
   - Tap "Message" button

2. **From Messages Tab:**
   - Tap (+) or "New Message"
   - Search for user
   - Select user and start typing

**Message Features:**
- **Text messages** - Standard text chat
- **Photos** - Send images from gallery or camera
- **Videos** - Share video files
- **Voice messages** - Record and send voice notes
- **Files** - Send documents and other files
- **Emojis and reactions** - Express emotions

**Message Controls:**
- **Reply** - Swipe right on message to reply
- **React** - Long press message to add emoji reaction
- **Star** - Mark important messages
- **Forward** - Share message to another conversation
- **Delete** - Remove message (for you or everyone)
- **Edit** - Modify sent messages (shows "edited" indicator)

**Conversation Settings:**
- **Mute notifications** - Silence alerts for this chat
- **Pin conversation** - Keep at top of messages list
- **Block user** - Prevent receiving messages
- **Clear chat** - Delete message history
- **Media gallery** - View all shared photos/videos

### Channel Messages

**What are Channels?**
Channels are topic-based chat rooms within groups. Types:
- **TEXT** - Standard text chat
- **ANNOUNCEMENT** - Admin-only posting
- **VOICE** - Voice chat (future feature)

**Sending Channel Messages:**
1. Navigate to group
2. Select channel from channel list
3. Type message in input box
4. Add attachments if needed
5. Tap send

**Channel Features:**
- **Threading** - Reply to specific messages
- **Mentions** - Tag users with @username
- **Pinned messages** - Important announcements stay at top
- **Message history** - Scroll to load previous messages
- **Read receipts** - See who viewed your message

**Channel Permissions:**
- Controlled by group role (ADMIN, MODERATOR, MEMBER)
- Announcement channels: Admin/Moderator only can post
- Private channels: Invitation required

---

## Social Features

### Posts

**Creating Posts:**

1. Tap (+) in bottom navigation
2. Select "Create Post"
3. Choose post type:
   - **Text** - Status update or thoughts
   - **Image** - Single or multiple photos (carousel)
   - **Video** - Video post
4. Add content:
   - Write caption
   - Add photos/videos
   - Tag users with @mention
   - Add hashtags #topic
   - Select group (optional) to post in specific group
5. Choose visibility:
   - PUBLIC - Everyone can see
   - FOLLOWERS - Only your followers
   - PRIVATE - Only you
   - GROUP_ONLY - Group members only
6. Tap "Post"

**Interacting with Posts:**
- **Like** - Tap heart icon (supports reactions: LIKE, LOVE, HAHA, WOW, SAD, ANGRY)
- **Comment** - Tap comment icon, write comment
- **Share** - Share to your timeline or send to friends
- **Save** - Bookmark for later (accessible in Library)
- **Report** - Flag inappropriate content

**Your Posts:**
- View all your posts on your profile
- Edit or delete your own posts
- View post analytics (views, likes, comments)

### Following and Followers

**Following Users:**
1. Visit user's profile
2. Tap "Follow" button
3. Their content appears in your home feed

**Follower Notifications:**
- You're notified when someone follows you
- View follower list on your profile

**Unfollowing:**
- Visit their profile
- Tap "Following" button to unfollow
- Their content no longer appears in your feed

### Likes and Reactions

**Available Reactions:**
- ❤️ **LIKE** - General appreciation
- 💕 **LOVE** - Strong positive emotion
- 😂 **HAHA** - Funny content
- 😮 **WOW** - Surprising or impressive
- 😢 **SAD** - Touching or sad content
- 😠 **ANGRY** - Frustrating content

**How to React:**
- **Quick like:** Tap heart icon
- **Choose reaction:** Long press heart icon, select emoji

**View Reactions:**
- Tap reaction count to see who reacted
- See breakdown by reaction type

---

## Stories and Reels

### Stories

**What are Stories?**
Stories are temporary posts that disappear after 24 hours. They appear at the top of the home feed.

**Creating Stories:**

1. Tap (+) button
2. Select "Create Story"
3. Choose story type:
   - **Photo story** - Single image
   - **Video story** - Short video (up to 15 seconds)
   - **Text story** - Colored background with text
4. Add enhancements:
   - Text overlays
   - Stickers
   - Draw on image
   - Background color (for text stories)
5. Tap "Share to Story"

**Viewing Stories:**
- Stories appear in horizontal row at top of home
- Tap profile circle to view story
- Tap right side of screen to go to next story
- Tap left side to go back
- Swipe down to exit

**Story Features:**
- **Views** - See who viewed your story
- **Reactions** - Viewers can react with emojis
- **Comments** - Private comments on your story (direct messages)
- **24-hour expiration** - Automatically deleted after 24 hours

### Reels

**What are Reels?**
Reels are short-form vertical videos (similar to TikTok/Instagram Reels).

**Creating Reels:**

1. Tap (+) button
2. Select "Create Reel"
3. Record or upload video:
   - **Record:** Tap and hold record button
   - **Upload:** Select video from gallery
4. Edit reel:
   - Trim video
   - Add music (if available)
   - Add text overlays
   - Add effects and filters
5. Add details:
   - Caption
   - Hashtags
   - Mentions
6. Choose visibility
7. Tap "Share"

**Discovering Reels:**
- Dedicated Reels section in Explore
- Vertical swipe interface
- Algorithm shows relevant content

**Interacting with Reels:**
- **Like** - Double tap or tap heart
- **Comment** - Tap comment icon
- **Share** - Share reel with friends
- **Save** - Bookmark reel
- **Original audio** - Use same audio for your reel

---

## Ethiopian Calendar

### Overview

Zikire Kdusan includes integrated Ethiopian calendar support with:
- Full calendar view (13 months)
- Daily notes and entries
- Reminder system
- Photo/media attachments to dates
- Recurring reminders (monthly/yearly)

### Calendar Features

**Viewing Calendar:**
1. Navigate to Calendar section
2. View current Ethiopian date
3. Switch between:
   - Month view (default)
   - Gregorian calendar toggle
4. Dates with notes show indicator dot

**Ethiopian Calendar Specifics:**
- 12 months of 30 days each
- 13th month (Pagumen) with 5 or 6 days
- Dates automatically converted to/from Gregorian

### Creating Calendar Notes

**Add Note to Date:**

1. **Select Date:**
   - Tap date in calendar view
   - Or tap (+) and select date

2. **Add Content:**
   - **Title** (optional) - Brief description
   - **Content** - Detailed note (supports rich text)
   - **Media** - Attach photos or files
   - Multiple media attachments supported

3. **Set Reminder (Optional):**
   - Toggle "Set Reminder" switch
   - Choose date and time
   - Select timezone (defaults to Africa/Addis_Ababa)
   - Choose repeat option:
     - **NONE** - One-time reminder
     - **MONTHLY** - Same Ethiopian day each month
     - **YEARLY** - Same Ethiopian date each year

4. **Save Note:**
   - Tap "Save"
   - Note stored locally and synced to server

**Editing Notes:**
1. Tap existing note
2. Modify title, content, or media
3. Update reminder settings
4. Tap "Save"

**Deleting Notes:**
1. Tap note
2. Tap delete icon
3. Confirm deletion (soft delete - can be restored by admin)

### Reminder System

**How Reminders Work:**
- Background system checks every 15 minutes
- Notifications sent at exact reminder time
- Supports recurring reminders (monthly/yearly on Ethiopian calendar)
- Works even when app is closed

**Reminder Notifications:**
- Push notification at scheduled time
- Shows note title and preview
- Tap notification to open calendar note
- Dismiss or snooze options

**Managing Reminders:**
- View upcoming reminders in calendar
- Edit reminder time without editing note
- Disable reminder while keeping note
- Delete reminder separately from note

**Recurring Reminder Logic:**
- **Monthly:** Triggers on same Ethiopian day each month (e.g., Meskerem 15 every month)
- **Yearly:** Triggers on same Ethiopian date each year (e.g., Tikimt 10 annually)
- System calculates next occurrence automatically
- `reminderNextOccurrence` field tracks when next notification will fire

### Calendar Sync

**Synchronization:**
- Notes stored locally in SQLite database (offline-first)
- Auto-sync to backend every 15 minutes when online
- Manual sync: Pull down to refresh calendar
- Conflict resolution: Server version wins

**Offline Behavior:**
- Create, edit, and view notes while offline
- Changes queued for sync when connection restored
- Local notifications work offline
- Media attachments uploaded when online

---

## Search and Discovery

### Search

**Global Search:**
1. Tap search icon in top bar
2. Enter search query
3. Results categorized by:
   - **Videos** - Matching title, description, tags
   - **Users** - Matching username, name
   - **Groups** - Matching name, description
   - **Channels** - Video channels and group channels
   - **Live Streams** - Currently live matching query

**Search Filters:**
- **Content type** - Videos, Posts, Groups, Users
- **Upload date** - Today, This week, This month, This year
- **Duration** (videos) - Short (< 4 min), Medium (4-20 min), Long (> 20 min)
- **Sort by** - Relevance, Upload date, View count

**Search History:**
- Your recent searches saved locally
- Clear search history in Settings → Privacy

### Explore and Trending

**Explore Tab:**

**Live Now:**
- Currently active live streams
- Sort by viewer count
- Filter by category
- Real-time updates

**Trending:**
- Most popular content in last 24 hours
- Based on views, likes, comments, shares
- Updated hourly
- Algorithm considers:
  - Engagement rate (views/likes/comments ratio)
  - Velocity (speed of engagement)
  - Recency (newer content prioritized)

**Recommended:**
- Personalized recommendations
- Based on your watch history
- Users you follow
- Groups you're in
- Content you've liked

**Categories:**
- Music
- Education
- Entertainment
- News
- Sports
- Technology
- Religion
- Arts & Culture
- Gaming
- Lifestyle

**Browse by Category:**
1. Tap category
2. View top content in category
3. Filter by Today, This Week, All Time

---

## Notifications

### Notification Types

**Activity Notifications:**
- **MESSAGE** - New direct message or channel message
- **MENTION** - Someone mentioned you (@yourname)
- **REACTION** - Someone reacted to your content
- **GROUP_INVITE** - Invitation to join group
- **GROUP_JOIN_REQUEST** - Someone requested to join your group
- **GROUP_APPROVE** - Your join request was approved
- **SYSTEM** - Platform announcements

**Content Notifications:**
- **New video** from subscribed channel
- **Live stream started** from followed creator
- **New post** from followed user
- **Comment** on your content
- **Reply** to your comment

**Calendar Notifications:**
- **Reminder** - Ethiopian calendar reminder triggered

### Notification Settings

**Configuring Notifications:**
1. Go to Settings → Notifications
2. Toggle categories on/off:
   - Messages
   - Mentions
   - Reactions
   - Group activity
   - Live streams
   - Video uploads
   - Calendar reminders
   - System announcements

**Push Notification Settings:**
- Enable/disable push notifications entirely
- Quiet hours - No notifications during specified hours
- Notification sound
- Vibration

**In-App Notifications:**
- Badge on notification icon shows unread count
- Notification center shows last 30 days
- Mark all as read
- Clear notifications

---

## Downloads and Offline

### Downloading Content

**What Can Be Downloaded:**
- Videos (if enabled by creator)
- Reels
- Live stream recordings (VOD)
- Posts with images

**Download Requirements:**
- Creator must enable downloads for video
- Sufficient storage space on device
- Active internet connection for initial download

**Downloading Videos:**

1. **While Viewing Video:**
   - Tap download icon (⬇️)
   - Select quality (lower = smaller file)
   - Download starts in background

2. **Download Settings:**
   - Choose default quality for downloads
   - Download only on Wi-Fi (save mobile data)
   - Download location

**Download Status:**
- **PENDING** - Queued for download
- **IN_PROGRESS** - Actively downloading
- **COMPLETED** - Ready to watch offline
- **FAILED** - Download error (retry available)

**Managing Downloads:**
1. Go to Library → Downloads
2. View all downloaded content
3. Actions:
   - **Play** - Watch offline
   - **Delete** - Free up storage
   - **Share** - Share with other apps

### Offline Functionality

**What Works Offline:**
✅ Watch downloaded videos
✅ View downloaded posts with images
✅ Read saved content
✅ Browse local watch history
✅ View calendar notes created locally
✅ Receive calendar reminder notifications

**What Requires Internet:**
❌ Stream live content
❌ Watch non-downloaded videos
❌ Send messages or comments
❌ Upload new content
❌ Sync calendar notes to server
❌ Receive real-time notifications
❌ Search for new content

**Background Sync:**
- App syncs changes when connection restored
- Calendar notes auto-sync every 15 minutes
- Message delivery queued when offline
- Watch progress updated when online

**Storage Management:**
- View storage usage in Settings → Storage
- Clear cache to free space
- Delete old downloads automatically (configure in settings)
- Recommended: Keep at least 1GB free space

---

## Profile and Settings

### Your Profile

**Profile Information:**
- **Username** - Your unique @handle
- **Display name** - Your full name or nickname
- **Bio** - Brief description (up to 500 characters)
- **Avatar** - Profile picture
- **Cover photo** - Banner image
- **Website** - Optional link
- **Location** - Country
- **Verified badge** - If verified by platform

**Editing Profile:**
1. Go to Profile tab
2. Tap "Edit Profile"
3. Update information
4. Upload new avatar or cover (tap to change)
5. Tap "Save"

**Profile Visibility:**
- **PUBLIC** - Anyone can view your profile and content
- **FOLLOWERS** - Only followers see your posts
- **PRIVATE** - Approval required to follow, hidden from search

**Your Content:**
- **Videos** tab - All your uploaded videos
- **Posts** tab - Your text/image posts
- **Reels** tab - Your reels
- **Live** tab - Past and upcoming live streams

### Settings

**Account Settings:**
- **Email** - Change email address (requires verification)
- **Phone** - Change phone number (requires verification)
- **Username** - Change username (must be unique)
- **Password** - Change password
- **Language** - App language (supports multiple languages)

**Privacy Settings:**
- **Profile visibility** - Public, Followers, Private
- **Who can message you** - Everyone, Followers, Nobody
- **Who can tag you** - Everyone, Followers, Nobody
- **Search history** - Clear search history
- **Watch history** - Clear or disable watch history

**Security Settings:**
- **App lock** - PIN or biometric lock for app access
- **Change password** - Update your password
- **Active sessions** - View devices logged into your account
- **Two-factor authentication** - Coming soon

**Notification Settings:**
- See [Notifications](#notifications) section above

**Data and Storage:**
- **Cache** - Clear app cache
- **Downloads** - Manage downloaded content
- **Data usage** - View bandwidth statistics
- **Auto-play** - Enable/disable auto-play on mobile data
- **Video quality** - Default quality for mobile/Wi-Fi

**Theme:**
- **Light mode** - Bright theme
- **Dark mode** - Dark theme
- **System default** - Follow device theme

**About:**
- App version
- Terms of service
- Privacy policy
- Contact support
- Licenses

### Account Management

**Deleting Your Account:**
1. Settings → Account → Delete Account
2. Review what will be deleted (all content, messages, history)
3. Enter password to confirm
4. Account permanently deleted after 30 days
5. Cancel deletion within 30 days to restore

**Logging Out:**
1. Settings → Account → Log Out
2. Confirm logout
3. All sessions on this device terminated
4. Refresh tokens revoked (must log in again)

---

## Getting Help

**Support Resources:**
- **FAQ** - Common questions and answers
- **Help Center** - Detailed guides and tutorials
- **Contact Support** - Submit support ticket
- **Community Forum** - Get help from other users
- **Report a Problem** - Technical issues

**Reporting Content:**
If you encounter inappropriate content:
1. Tap report icon on content
2. Select reason:
   - SPAM
   - HARASSMENT
   - HATE_SPEECH
   - MISINFORMATION
   - INAPPROPRIATE_CONTENT
   - VIOLENCE
   - COPYRIGHT
   - IMPERSONATION
   - OTHER
3. Add optional details
4. Submit report
5. Moderators review within 24 hours

---

## Tips and Best Practices

**For Better Experience:**
- Use Wi-Fi for uploads and downloads
- Download content before traveling
- Enable notifications for favorite creators
- Organize content with playlists
- Use hashtags to increase post visibility
- Post during active hours for more engagement
- Engage with comments to build community
- Keep app updated for latest features

**Content Creation Tips:**
- Good lighting improves video quality
- Use descriptive titles and thumbnails
- Add relevant tags and categories
- Engage with your audience in comments
- Consistent posting schedule builds audience
- Promote streams in advance for better attendance

**Safety Tips:**
- Never share your password
- Use strong, unique password
- Enable app lock for sensitive content
- Don't accept group invitations from strangers
- Report suspicious accounts
- Be respectful in comments and messages
- Review privacy settings regularly

---

*Last updated: Based on platform audit conducted September 2026*
