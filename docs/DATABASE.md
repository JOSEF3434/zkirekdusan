# Database Documentation

**Zikire Kdusan (StreamHub) - Database Schema & Architecture**

This document provides comprehensive documentation for the database schema, including Prisma ORM configuration, Neon PostgreSQL setup, and all data models with their relationships.

---

## Table of Contents

1. [Database Overview](#database-overview)
2. [Technology Stack](#technology-stack)
3. [Schema Organization](#schema-organization)
4. [Core Models](#core-models)
5. [Authentication & Authorization](#authentication--authorization)
6. [User & Profile Models](#user--profile-models)
7. [Group & Channel Models](#group--channel-models)
8. [Messaging Models](#messaging-models)
9. [Video Platform Models](#video-platform-models)
10. [Live Streaming Models](#live-streaming-models)
11. [Social Features Models](#social-features-models)
12. [Ethiopian Calendar Models](#ethiopian-calendar-models)
13. [Discovery Models](#discovery-models)
14. [Admin & Moderation Models](#admin--moderation-models)
15. [Enumerations](#enumerations)
16. [Indexes & Performance](#indexes--performance)
17. [Relationships](#relationships)
18. [Migrations](#migrations)
19. [Seeding](#seeding)
20. [Best Practices](#best-practices)

---

## Database Overview

### Database Platform

**Neon PostgreSQL** - Serverless PostgreSQL database

**Key Features**:
- ✅ Serverless architecture (auto-scaling)
- ✅ Automatic backups
- ✅ Point-in-time recovery
- ✅ Database branching (instant copies for testing)
- ✅ Connection pooling
- ✅ Built-in monitoring and insights
- ✅ Compatible with standard PostgreSQL clients

### Connection

**Connection String Format**:
```
postgresql://user:password@host:5432/database?sslmode=require
```

**Environment Variable**:
```env
DATABASE_URL="postgresql://user:password@ep-xyz.us-east-1.aws.neon.tech:5432/database?sslmode=require"
```

### Schema Statistics

- **Total Models**: 80+
- **Total Fields**: 500+
- **Enumerations**: 40+
- **Relationships**: 200+
- **Indexes**: 100+

---

## Technology Stack

### Prisma ORM

**Version**: 7.8.x

**Configuration** (`prisma/schema.prisma`):
```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
}
```

**Benefits**:
- ✅ Type-safe database queries
- ✅ Auto-generated TypeScript types
- ✅ Migration management
- ✅ Database introspection
- ✅ Relation management
- ✅ Transaction support

### Prisma Client Usage

```typescript
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// Type-safe query
const user = await prisma.user.findUnique({
  where: { id: userId },
  include: {
    profile: true,
    role: {
      include: { permissions: true }
    }
  }
});
```

---

## Schema Organization

The schema is organized into **logical domains**:

### Phase 1: Foundation
- Authentication (User, Role, Permission, Session, RefreshToken)
- Authorization (RolePermission)
- Profiles (Profile)
- Groups (Group, GroupMember, GroupRole)
- Uploads (File, Upload)

### Phase 2: Social Features
- Social Graph (Follow)
- Posts (Post, PostMedia)
- Interactions (Like, Comment)
- Stories (Story)
- Reels (Reel)
- Saved Content (SavedPost)

### Phase 3: Messaging Platform
- Groups & Channels (Channel, ChannelMember)
- Conversations (Conversation, ConversationParticipant)
- Messages (Message, MessageRead, MessageReaction)
- Notifications (Notification, NotificationPreference, PushSubscription)
- Join Requests (GroupJoinRequest)
- Presence (Presence)

### Phase 4: Video Platform
- Video Channels (VideoChannel)
- Videos (Video, VideoView)
- Comments (VideoComment, VideoCommentReply)
- Playlists (VideoPlaylist, VideoPlaylistItem)
- Subscriptions (VideoSubscription)
- Downloads (VideoDownload)

### Phase 5: Live Streaming
- Streams (LiveStream)
- Viewers (LiveStreamViewer)
- Chat (StreamChat, StreamReaction)
- Analytics (StreamAnalytics)
- Processing (StreamProcessing)
- Highlights (StreamHighlight)
- Recordings (StreamRecording)

### Phase 6: Discovery
- Search (SearchHistory)
- Recommendations (Recommendation)
- Trending (TrendingItem)

### Phase 7: Admin & Moderation
- Reports (Report)
- Moderation (ModerationAction)
- Audit (AuditLog)

### Additional Features
- Ethiopian Calendar (CalendarNote, CalendarReminder)

---

## Core Models

### Role

Defines global platform roles (system-wide permissions).

```prisma
model Role {
  id          String  @id @default(uuid())
  name        String  @unique
  description String?
  isActive    Boolean @default(true)

  users       User[]
  permissions RolePermission[]

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@map("roles")
}
```

**Default Roles**:
- `SUPER_ADMIN` - Full system access
- `ADMIN` - Administrative access
- `MODERATOR` - Content moderation
- `SUPPORT` - Support functions
- `USER` - Regular user (default)

**Fields**:
- `name` - Role name (unique, e.g., "ADMIN")
- `description` - Human-readable description
- `isActive` - Whether role is active
- `users` - Users with this role
- `permissions` - Associated permissions

---

### Permission

Defines granular permissions for specific actions.

```prisma
model Permission {
  id          String  @id @default(uuid())
  name        String  @unique
  description String?

  roles RolePermission[]

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@map("permissions")
}
```

**Permission Examples**:
- `create:post` - Create posts
- `delete:own-post` - Delete own posts
- `delete:any-post` - Delete any post (admin)
- `create:livestream` - Start live streams
- `moderate:group` - Moderate group content
- `view:admin-panel` - Access admin panel

**Total Permissions**: 100+

---

### RolePermission

Many-to-many relationship between roles and permissions.

```prisma
model RolePermission {
  id           String @id @default(uuid())
  roleId       String
  permissionId String

  role       Role       @relation(fields: [roleId], references: [id], onDelete: Cascade)
  permission Permission @relation(fields: [permissionId], references: [id], onDelete: Cascade)

  createdAt DateTime @default(now())

  @@unique([roleId, permissionId])
  @@index([roleId])
  @@index([permissionId])
  @@map("role_permissions")
}
```

---

## Authentication & Authorization

### User

Core user account model.

```prisma
model User {
  id String @id @default(uuid())

  email       String? @unique
  phoneNumber String? @unique
  username    String? @unique

  passwordHash String

  roleId String
  role   Role   @relation(fields: [roleId], references: [id])

  status UserStatus @default(ACTIVE)

  isEmailVerified Boolean @default(false)
  isPhoneVerified Boolean @default(false)

  lastLoginAt DateTime?

  failedLoginAttempts Int       @default(0)
  lockedUntil         DateTime?

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  // Relations
  profile             Profile?
  sessions            Session[]
  refreshTokens       RefreshToken[]
  posts               Post[]
  videos              Video[]
  liveStreams         LiveStream[]
  groupMembers        GroupMember[]
  messages            Message[]
  notifications       Notification[]
  // ... many more relations

  @@index([email])
  @@index([username])
  @@index([phoneNumber])
  @@index([roleId])
  @@map("users")
}
```

**Key Fields**:
- `email`, `phoneNumber`, `username` - Unique identifiers (at least one required)
- `passwordHash` - Bcrypt hashed password
- `roleId` - Reference to global role
- `status` - Account status (ACTIVE, SUSPENDED, BANNED)
- `failedLoginAttempts` - Track failed logins for brute force protection
- `lockedUntil` - Lockout expiry timestamp

**Enums**:
```prisma
enum UserStatus {
  ACTIVE
  INACTIVE
  SUSPENDED
  BANNED
}
```

---

### Session

Tracks active user sessions.

```prisma
model Session {
  id String @id @default(uuid())

  userId String
  user   User   @relation(fields: [userId], references: [id], onDelete: Cascade)

  token  String   @unique
  status SessionStatus @default(ACTIVE)

  ipAddress String?
  userAgent String?

  expiresAt DateTime
  lastActivityAt DateTime @default(now())

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@index([userId])
  @@index([token])
  @@index([expiresAt])
  @@map("sessions")
}
```

**Purpose**:
- Track active sessions per user
- Support session invalidation
- Monitor login history

**Enums**:
```prisma
enum SessionStatus {
  ACTIVE
  REVOKED
  EXPIRED
}
```

---

### RefreshToken

Stores refresh tokens for JWT authentication.

```prisma
model RefreshToken {
  id String @id @default(uuid())

  userId String
  user   User   @relation(fields: [userId], references: [id], onDelete: Cascade)

  token     String   @unique
  expiresAt DateTime

  isRevoked Boolean @default(false)

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@index([userId])
  @@index([token])
  @@index([expiresAt])
  @@map("refresh_tokens")
}
```

**Purpose**:
- Store refresh tokens in database
- Enable token revocation
- Implement token rotation

**Lifecycle**:
- Created on login/register
- Used to obtain new access tokens
- Expires after 7 days
- Can be revoked manually

---

## User & Profile Models

### Profile

Extended user profile information.

```prisma
model Profile {
  id String @id @default(uuid())

  userId String @unique
  user   User   @relation(fields: [userId], references: [id], onDelete: Cascade)

  displayName String?
  bio         String?
  avatarUrl   String?
  coverImageUrl String?

  birthDate DateTime?
  gender    Gender?

  location String?
  website  String?

  visibility ProfileVisibility @default(PUBLIC)

  followersCount Int @default(0)
  followingCount Int @default(0)
  postsCount     Int @default(0)
  videosCount    Int @default(0)

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@index([userId])
  @@map("profiles")
}
```

**Fields**:
- `displayName` - Friendly name (can differ from username)
- `bio` - User biography (up to 500 characters)
- `avatarUrl` - Profile picture URL (Cloudinary)
- `coverImageUrl` - Banner image URL (Cloudinary)
- `visibility` - Profile visibility setting
- Counters: `followersCount`, `followingCount`, etc. (denormalized for performance)

**Enums**:
```prisma
enum ProfileVisibility {
  PUBLIC
  FOLLOWERS
  PRIVATE
}

enum Gender {
  MALE
  FEMALE
  OTHER
  PREFER_NOT_TO_SAY
}
```

---

### Follow

User-to-user following relationship.

```prisma
model Follow {
  id String @id @default(uuid())

  followerId  String
  followingId String

  follower  User @relation("Follower", fields: [followerId], references: [id], onDelete: Cascade)
  following User @relation("Following", fields: [followingId], references: [id], onDelete: Cascade)

  createdAt DateTime @default(now())

  @@unique([followerId, followingId])
  @@index([followerId])
  @@index([followingId])
  @@map("follows")
}
```

**Purpose**:
- Track follower/following relationships
- Enable follow/unfollow functionality
- Support social feed generation

---

## Group & Channel Models

### Group

User-created communities.

```prisma
model Group {
  id     String @id @default(uuid())
  name   String
  handle String @unique
  
  description String?
  avatarUrl   String?
  coverImageUrl String?

  creatorId String
  creator   User   @relation("GroupCreator", fields: [creatorId], references: [id])

  visibility GroupVisibility @default(PUBLIC)
  status     GroupStatus     @default(ACTIVE)

  memberCount   Int @default(0)
  channelCount  Int @default(0)

  isApprovalRequired Boolean @default(false)

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  // Relations
  members      GroupMember[]
  channels     Channel[]
  posts        Post[]
  liveStreams  LiveStream[]
  joinRequests GroupJoinRequest[]

  @@index([handle])
  @@index([creatorId])
  @@index([visibility])
  @@map("groups")
}
```

**Fields**:
- `handle` - Unique URL-safe identifier (e.g., "tech-enthusiasts")
- `visibility` - PUBLIC, PRIVATE, or INVITE_ONLY
- `status` - Group lifecycle status
- `isApprovalRequired` - Whether join requests need approval
- `memberCount` - Denormalized member count

**Enums**:
```prisma
enum GroupVisibility {
  PUBLIC
  PRIVATE
  INVITE_ONLY
}

enum GroupStatus {
  PENDING_APPROVAL
  ACTIVE
  SUSPENDED
  ARCHIVED
  REJECTED
}
```

---

### GroupMember

Group membership with roles.

```prisma
model GroupMember {
  id String @id @default(uuid())

  userId  String
  groupId String

  user  User  @relation(fields: [userId], references: [id], onDelete: Cascade)
  group Group @relation(fields: [groupId], references: [id], onDelete: Cascade)

  role GroupRole @default(MEMBER)

  joinedAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@unique([userId, groupId])
  @@index([userId])
  @@index([groupId])
  @@index([role])
  @@map("group_members")
}
```

**Group Roles**:
```prisma
enum GroupRole {
  GROUP_ADMIN   // Full control over group
  MODERATOR     // Moderate content, manage members
  MEMBER        // Full participation
  GUEST         // Limited read-only access
}
```

---

### Channel

Channels within groups (like Discord channels).

```prisma
model Channel {
  id String @id @default(uuid())

  name        String
  description String?
  type        ChannelType @default(TEXT)

  groupId String
  group   Group  @relation(fields: [groupId], references: [id], onDelete: Cascade)

  position Int @default(0)

  isPrivate Boolean @default(false)

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  messages       Message[]
  channelMembers ChannelMember[]

  @@index([groupId])
  @@index([type])
  @@map("channels")
}
```

**Channel Types**:
```prisma
enum ChannelType {
  TEXT          // Text chat
  ANNOUNCEMENT  // Read-only announcements
  VOICE         // Voice channel (future)
}
```

---

### GroupJoinRequest

Join requests for private/closed groups.

```prisma
model GroupJoinRequest {
  id String @id @default(uuid())

  userId  String
  groupId String

  user  User  @relation(fields: [userId], references: [id], onDelete: Cascade)
  group Group @relation(fields: [groupId], references: [id], onDelete: Cascade)

  status JoinRequestStatus @default(PENDING)

  message String?

  reviewedBy String?
  reviewedAt DateTime?

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@unique([userId, groupId])
  @@index([userId])
  @@index([groupId])
  @@index([status])
  @@map("group_join_requests")
}
```

**Enums**:
```prisma
enum JoinRequestStatus {
  PENDING
  APPROVED
  REJECTED
}
```

---

## Messaging Models

### Conversation

Direct or group conversations.

```prisma
model Conversation {
  id String @id @default(uuid())

  type ConversationType @default(DIRECT)

  name String?

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  participants ConversationParticipant[]
  messages     Message[]

  @@index([type])
  @@map("conversations")
}
```

**Conversation Types**:
```prisma
enum ConversationType {
  DIRECT         // 1-on-1 conversation
  GROUP_CHANNEL  // Group channel conversation
  GROUP_DIRECT   // Group-specific DM
}
```

---

### ConversationParticipant

Participants in a conversation.

```prisma
model ConversationParticipant {
  id String @id @default(uuid())

  conversationId String
  userId         String

  conversation Conversation @relation(fields: [conversationId], references: [id], onDelete: Cascade)
  user         User         @relation(fields: [userId], references: [id], onDelete: Cascade)

  lastReadAt DateTime?

  joinedAt DateTime @default(now())

  @@unique([conversationId, userId])
  @@index([conversationId])
  @@index([userId])
  @@map("conversation_participants")
}
```

---

### Message

Individual messages in conversations or channels.

```prisma
model Message {
  id String @id @default(uuid())

  conversationId String?
  channelId      String?

  conversation Conversation? @relation(fields: [conversationId], references: [id], onDelete: Cascade)
  channel      Channel?      @relation(fields: [channelId], references: [id], onDelete: Cascade)

  senderId String
  sender   User   @relation(fields: [senderId], references: [id], onDelete: Cascade)

  content String
  type    MessageType @default(TEXT)

  mediaUrl String?

  replyToId String?
  replyTo   Message? @relation("MessageReplies", fields: [replyToId], references: [id])
  replies   Message[] @relation("MessageReplies")

  isEdited  Boolean @default(false)
  isDeleted Boolean @default(false)

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  reads     MessageRead[]
  reactions MessageReaction[]

  @@index([conversationId])
  @@index([channelId])
  @@index([senderId])
  @@index([createdAt])
  @@map("messages")
}
```

**Message Types**:
```prisma
enum MessageType {
  TEXT
  IMAGE
  VIDEO
  AUDIO
  DOCUMENT
  VOICE_NOTE
  ANNOUNCEMENT
  SYSTEM
}
```

---

### MessageRead

Read receipts for messages.

```prisma
model MessageRead {
  id String @id @default(uuid())

  messageId String
  userId    String

  message Message @relation(fields: [messageId], references: [id], onDelete: Cascade)
  user    User    @relation(fields: [userId], references: [id], onDelete: Cascade)

  readAt DateTime @default(now())

  @@unique([messageId, userId])
  @@index([messageId])
  @@index([userId])
  @@map("message_reads")
}
```

---

### MessageReaction

Emoji reactions on messages.

```prisma
model MessageReaction {
  id String @id @default(uuid())

  messageId String
  userId    String

  message Message @relation(fields: [messageId], references: [id], onDelete: Cascade)
  user    User    @relation(fields: [userId], references: [id], onDelete: Cascade)

  emoji String

  createdAt DateTime @default(now())

  @@unique([messageId, userId, emoji])
  @@index([messageId])
  @@index([userId])
  @@map("message_reactions")
}
```

---

## Video Platform Models

### VideoChannel

Creator channels for organizing videos.

```prisma
model VideoChannel {
  id String @id @default(uuid())

  name   String
  handle String @unique

  description String?
  avatarUrl   String?
  bannerUrl   String?

  ownerId String
  owner   User   @relation(fields: [ownerId], references: [id], onDelete: Cascade)

  subscriberCount Int @default(0)
  videoCount      Int @default(0)

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  videos        Video[]
  subscriptions VideoSubscription[]

  @@index([handle])
  @@index([ownerId])
  @@map("video_channels")
}
```

---

### Video

Video content model.

```prisma
model Video {
  id String @id @default(uuid())

  title       String
  slug        String @unique
  description String?

  url          String
  thumbnailUrl String?
  publicId     String  @unique

  duration Int?

  userId String
  user   User   @relation(fields: [userId], references: [id], onDelete: Cascade)

  videoChannelId String?
  videoChannel   VideoChannel? @relation(fields: [videoChannelId], references: [id])

  visibility VideoVisibility @default(PUBLIC)
  status     VideoStatus     @default(DRAFT)

  viewCount     Int @default(0)
  likeCount     Int @default(0)
  dislikeCount  Int @default(0)
  commentCount  Int @default(0)

  allowComments  Boolean @default(true)
  allowDownloads Boolean @default(true)

  publishedAt DateTime?
  createdAt   DateTime  @default(now())
  updatedAt   DateTime  @updatedAt

  // Relations
  views        VideoView[]
  comments     VideoComment[]
  likes        Like[]
  playlists    VideoPlaylistItem[]
  downloads    VideoDownload[]

  @@index([slug])
  @@index([userId])
  @@index([videoChannelId])
  @@index([status])
  @@index([publishedAt])
  @@index([createdAt])
  @@map("videos")
}
```

**Enums**:
```prisma
enum VideoVisibility {
  PUBLIC
  UNLISTED
  PRIVATE
}

enum VideoStatus {
  DRAFT
  PROCESSING
  READY
  PUBLISHED
  FAILED
}
```

---

### VideoView

Track video views.

```prisma
model VideoView {
  id String @id @default(uuid())

  videoId String
  userId  String?

  video Video @relation(fields: [videoId], references: [id], onDelete: Cascade)
  user  User?  @relation(fields: [userId], references: [id], onDelete: SetNull)

  duration    Int?
  progressSeconds Int?

  ipAddress String?

  viewedAt DateTime @default(now())

  @@index([videoId])
  @@index([userId])
  @@index([viewedAt])
  @@map("video_views")
}
```

---

### VideoComment

Comments on videos.

```prisma
model VideoComment {
  id String @id @default(uuid())

  videoId String
  userId  String

  video Video @relation(fields: [videoId], references: [id], onDelete: Cascade)
  user  User  @relation(fields: [userId], references: [id], onDelete: Cascade)

  content String

  likeCount Int @default(0)

  isEdited  Boolean @default(false)
  isDeleted Boolean @default(false)

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  replies VideoCommentReply[]

  @@index([videoId])
  @@index([userId])
  @@index([createdAt])
  @@map("video_comments")
}
```

---

### VideoPlaylist

User-created playlists.

```prisma
model VideoPlaylist {
  id String @id @default(uuid())

  title       String
  description String?

  userId String
  user   User   @relation(fields: [userId], references: [id], onDelete: Cascade)

  visibility PlaylistVisibility @default(PUBLIC)

  videoCount Int @default(0)

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  items VideoPlaylistItem[]

  @@index([userId])
  @@map("video_playlists")
}
```

---

### VideoSubscription

Channel subscriptions.

```prisma
model VideoSubscription {
  id String @id @default(uuid())

  userId         String
  videoChannelId String

  user         User         @relation(fields: [userId], references: [id], onDelete: Cascade)
  videoChannel VideoChannel @relation(fields: [videoChannelId], references: [id], onDelete: Cascade)

  notificationsEnabled Boolean @default(true)

  subscribedAt DateTime @default(now())

  @@unique([userId, videoChannelId])
  @@index([userId])
  @@index([videoChannelId])
  @@map("video_subscriptions")
}
```

---

### VideoDownload

Track video downloads.

```prisma
model VideoDownload {
  id String @id @default(uuid())

  videoId String
  userId  String

  video Video @relation(fields: [videoId], references: [id], onDelete: Cascade)
  user  User  @relation(fields: [userId], references: [id], onDelete: Cascade)

  downloadedAt DateTime @default(now())

  @@unique([videoId, userId])
  @@index([videoId])
  @@index([userId])
  @@map("video_downloads")
}
```

---

## Live Streaming Models

### LiveStream

Live streaming sessions.

```prisma
model LiveStream {
  id String @id @default(uuid())

  title       String
  description String?

  userId String
  user   User   @relation(fields: [userId], references: [id], onDelete: Cascade)

  groupId String?
  group   Group?  @relation(fields: [groupId], references: [id])

  cloudinaryAssetId String  @unique
  rtmpUrl           String
  hlsUrl            String
  streamKey         String

  status LiveStreamStatus @default(PENDING)

  thumbnailUrl String?

  viewerCount     Int @default(0)
  peakViewerCount Int @default(0)
  likeCount       Int @default(0)

  startedAt DateTime?
  endedAt   DateTime?

  notifiedLiveAt DateTime?

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  // Relations
  viewers   LiveStreamViewer[]
  chat      StreamChat[]
  reactions StreamReaction[]
  analytics StreamAnalytics[]
  highlights StreamHighlight[]
  recording  StreamRecording?

  @@index([userId])
  @@index([groupId])
  @@index([status])
  @@index([startedAt])
  @@map("live_streams")
}
```

**Fields**:
- `cloudinaryAssetId` - Cloudinary live stream asset ID
- `rtmpUrl` - RTMP ingest URL for broadcaster
- `hlsUrl` - HLS playback URL for viewers
- `streamKey` - Secret key for RTMP streaming
- `notifiedLiveAt` - Timestamp when "went live" notifications sent (2-min delay)

**Enums**:
```prisma
enum LiveStreamStatus {
  PENDING     // Created, waiting for RTMP stream
  LIVE        // Currently streaming
  ENDED       // Stream ended
  INTERRUPTED // Stream interrupted (30s grace period)
  FAILED      // Stream failed to start
}
```

---

### LiveStreamViewer

Track live stream viewers.

```prisma
model LiveStreamViewer {
  id String @id @default(uuid())

  liveStreamId String
  userId       String?

  liveStream LiveStream @relation(fields: [liveStreamId], references: [id], onDelete: Cascade)
  user       User?      @relation(fields: [userId], references: [id], onDelete: SetNull)

  joinedAt DateTime @default(now())
  leftAt   DateTime?

  duration Int?

  @@index([liveStreamId])
  @@index([userId])
  @@map("live_stream_viewers")
}
```

---

### StreamChat

Live chat messages during streams.

```prisma
model StreamChat {
  id String @id @default(uuid())

  liveStreamId String
  userId       String

  liveStream LiveStream @relation(fields: [liveStreamId], references: [id], onDelete: Cascade)
  user       User       @relation(fields: [userId], references: [id], onDelete: Cascade)

  message String

  isDeleted Boolean @default(false)

  createdAt DateTime @default(now())

  @@index([liveStreamId])
  @@index([userId])
  @@index([createdAt])
  @@map("stream_chat")
}
```

---

### StreamReaction

Floating emoji reactions on live streams.

```prisma
model StreamReaction {
  id String @id @default(uuid())

  liveStreamId String
  userId       String

  liveStream LiveStream @relation(fields: [liveStreamId], references: [id], onDelete: Cascade)
  user       User       @relation(fields: [userId], references: [id], onDelete: Cascade)

  emoji String

  createdAt DateTime @default(now())

  @@index([liveStreamId])
  @@index([userId])
  @@map("stream_reactions")
}
```

---

### StreamRecording

VOD recording of past live streams.

```prisma
model StreamRecording {
  id String @id @default(uuid())

  liveStreamId String @unique
  liveStream   LiveStream @relation(fields: [liveStreamId], references: [id], onDelete: Cascade)

  url      String
  publicId String @unique

  duration Int?

  status RecordingStatus @default(PROCESSING)

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@index([liveStreamId])
  @@map("stream_recordings")
}
```

---

## Social Features Models

### Post

Social posts (text, images, videos).

```prisma
model Post {
  id String @id @default(uuid())

  userId String
  user   User   @relation(fields: [userId], references: [id], onDelete: Cascade)

  groupId String?
  group   Group?  @relation(fields: [groupId], references: [id])

  content String

  type       PostType       @default(TEXT)
  visibility PostVisibility @default(PUBLIC)
  status     PostStatus     @default(PUBLISHED)

  likeCount    Int @default(0)
  commentCount Int @default(0)
  shareCount   Int @default(0)

  publishedAt DateTime?
  createdAt   DateTime  @default(now())
  updatedAt   DateTime  @updatedAt

  // Relations
  media    PostMedia[]
  likes    Like[]
  comments Comment[]
  saved    SavedPost[]

  @@index([userId])
  @@index([groupId])
  @@index([status])
  @@index([publishedAt])
  @@index([createdAt])
  @@map("posts")
}
```

**Enums**:
```prisma
enum PostType {
  TEXT
  IMAGE
  VIDEO
  CAROUSEL
}

enum PostVisibility {
  PUBLIC
  FOLLOWERS
  PRIVATE
  GROUP_ONLY
}

enum PostStatus {
  DRAFT
  PUBLISHED
  ARCHIVED
  DELETED
}
```

---

### Like

Universal like system (posts, videos, etc.).

```prisma
model Like {
  id String @id @default(uuid())

  userId String
  user   User   @relation(fields: [userId], references: [id], onDelete: Cascade)

  postId  String?
  videoId String?

  post  Post?  @relation(fields: [postId], references: [id], onDelete: Cascade)
  video Video? @relation(fields: [videoId], references: [id], onDelete: Cascade)

  type LikeType @default(LIKE)

  createdAt DateTime @default(now())

  @@unique([userId, postId])
  @@unique([userId, videoId])
  @@index([userId])
  @@index([postId])
  @@index([videoId])
  @@map("likes")
}
```

**Enums**:
```prisma
enum LikeType {
  LIKE
  DISLIKE
}
```

---

### Comment

Comments on posts.

```prisma
model Comment {
  id String @id @default(uuid())

  postId String
  userId String

  post Post @relation(fields: [postId], references: [id], onDelete: Cascade)
  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  content String

  likeCount Int @default(0)

  isEdited  Boolean @default(false)
  isDeleted Boolean @default(false)

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@index([postId])
  @@index([userId])
  @@index([createdAt])
  @@map("comments")
}
```

---

### Story

24-hour temporary stories.

```prisma
model Story {
  id String @id @default(uuid())

  userId String
  user   User   @relation(fields: [userId], references: [id], onDelete: Cascade)

  mediaUrl String
  caption  String?

  type StoryType @default(IMAGE)

  viewCount Int @default(0)

  expiresAt DateTime
  createdAt DateTime @default(now())

  views StoryView[]

  @@index([userId])
  @@index([expiresAt])
  @@index([createdAt])
  @@map("stories")
}
```

**Enums**:
```prisma
enum StoryType {
  IMAGE
  VIDEO
  TEXT
}
```

**Expiration**:
- Stories automatically expire 24 hours after creation
- Expired stories can be automatically deleted via scheduled job

---

### Reel

Short-form videos (like TikTok/Instagram Reels).

```prisma
model Reel {
  id String @id @default(uuid())

  userId String
  user   User   @relation(fields: [userId], references: [id], onDelete: Cascade)

  videoUrl     String
  thumbnailUrl String?
  caption      String?

  duration Int

  viewCount Int @default(0)
  likeCount Int @default(0)

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@index([userId])
  @@index([createdAt])
  @@map("reels")
}
```

---

### SavedPost

Bookmarked posts.

```prisma
model SavedPost {
  id String @id @default(uuid())

  userId String
  postId String

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
  post Post @relation(fields: [postId], references: [id], onDelete: Cascade)

  savedAt DateTime @default(now())

  @@unique([userId, postId])
  @@index([userId])
  @@index([postId])
  @@map("saved_posts")
}
```

---

## Ethiopian Calendar Models

### CalendarNote

Notes on Ethiopian calendar dates.

```prisma
model CalendarNote {
  id String @id @default(uuid())

  userId String
  user   User   @relation(fields: [userId], references: [id], onDelete: Cascade)

  title   String
  content String?

  date         DateTime
  calendarType CalendarType @default(ETHIOPIAN)

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  reminders CalendarReminder[]

  @@index([userId])
  @@index([date])
  @@map("calendar_notes")
}
```

**Enums**:
```prisma
enum CalendarType {
  ETHIOPIAN
  GREGORIAN
}
```

---

### CalendarReminder

Reminders for calendar notes.

```prisma
model CalendarReminder {
  id String @id @default(uuid())

  calendarNoteId String
  calendarNote   CalendarNote @relation(fields: [calendarNoteId], references: [id], onDelete: Cascade)

  time String

  repeat  CalendarReminderRepeat @default(NONE)
  enabled Boolean                @default(true)

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@index([calendarNoteId])
  @@map("calendar_reminders")
}
```

**Enums**:
```prisma
enum CalendarReminderRepeat {
  NONE
  MONTHLY
  YEARLY
}
```

**How Reminders Work**:
- Stored in database
- Synced to mobile device
- Triggered by local alarm (work offline)
- Independent of server

---

## Discovery Models

### SearchHistory

User search history.

```prisma
model SearchHistory {
  id String @id @default(uuid())

  userId String
  user   User   @relation(fields: [userId], references: [id], onDelete: Cascade)

  query String

  searchedAt DateTime @default(now())

  @@index([userId])
  @@index([searchedAt])
  @@map("search_history")
}
```

---

### Recommendation

Personalized content recommendations.

```prisma
model Recommendation {
  id String @id @default(uuid())

  userId String
  user   User   @relation(fields: [userId], references: [id], onDelete: Cascade)

  contentType String
  contentId   String

  score  Float
  reason String?

  createdAt DateTime @default(now())

  @@index([userId])
  @@index([createdAt])
  @@map("recommendations")
}
```

---

### TrendingItem

Trending content tracking.

```prisma
model TrendingItem {
  id String @id @default(uuid())

  contentType String
  contentId   String

  score       Float
  trendingAt  DateTime
  
  viewCount24h Int @default(0)

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@unique([contentType, contentId])
  @@index([trendingAt])
  @@map("trending_items")
}
```

**How Trending Works**:
- Algorithm calculates score based on engagement metrics
- Updated periodically (e.g., every hour)
- Considers views, likes, comments, shares
- Time-weighted (recent activity weighted more)

---

## Admin & Moderation Models

### Report

User-reported content.

```prisma
model Report {
  id String @id @default(uuid())

  reporterId String
  reporter   User   @relation("Reporter", fields: [reporterId], references: [id], onDelete: Cascade)

  targetType ReportTargetType
  targetId   String

  reason      ReportReason
  description String?

  status ReportStatus @default(PENDING)

  reviewedById String?
  reviewedBy   User?    @relation("Reviewer", fields: [reviewedById], references: [id])
  reviewedAt   DateTime?

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  actions ModerationAction[]

  @@index([reporterId])
  @@index([targetType, targetId])
  @@index([status])
  @@index([createdAt])
  @@map("reports")
}
```

**Enums**:
```prisma
enum ReportTargetType {
  USER
  GROUP
  POST
  COMMENT
  VIDEO
  MESSAGE
}

enum ReportReason {
  SPAM
  HARASSMENT
  HATE_SPEECH
  MISINFORMATION
  INAPPROPRIATE_CONTENT
  VIOLENCE
  COPYRIGHT
  IMPERSONATION
  OTHER
}

enum ReportStatus {
  PENDING
  REVIEWING
  RESOLVED
  DISMISSED
}
```

---

### ModerationAction

Actions taken on reports.

```prisma
model ModerationAction {
  id String @id @default(uuid())

  reportId String?
  report   Report? @relation(fields: [reportId], references: [id])

  moderatorId String
  moderator   User   @relation(fields: [moderatorId], references: [id])

  action ActionType
  notes  String?

  targetType String
  targetId   String

  createdAt DateTime @default(now())

  @@index([reportId])
  @@index([moderatorId])
  @@index([targetType, targetId])
  @@map("moderation_actions")
}
```

**Enums**:
```prisma
enum ActionType {
  WARN_USER
  REMOVE_CONTENT
  SUSPEND_USER
  BAN_USER
  DISMISS_REPORT
}
```

---

### AuditLog

System audit trail.

```prisma
model AuditLog {
  id String @id @default(uuid())

  userId String?
  user   User?   @relation(fields: [userId], references: [id])

  action      String
  targetType  String?
  targetId    String?
  details     Json?

  ipAddress String?
  userAgent String?

  createdAt DateTime @default(now())

  @@index([userId])
  @@index([action])
  @@index([createdAt])
  @@map("audit_logs")
}
```

**Purpose**:
- Track important system events
- Security monitoring
- Compliance requirements
- Debugging

---

## Enumerations

### Complete Enum List

```prisma
// Authentication & Authorization
enum GlobalRole { SUPER_ADMIN, ADMIN, MODERATOR, SUPPORT, USER }
enum GroupRole { GROUP_ADMIN, MODERATOR, MEMBER, GUEST }
enum UserStatus { ACTIVE, INACTIVE, SUSPENDED, BANNED }
enum SessionStatus { ACTIVE, REVOKED, EXPIRED }

// Groups
enum GroupStatus { PENDING_APPROVAL, ACTIVE, SUSPENDED, ARCHIVED, REJECTED }
enum GroupVisibility { PUBLIC, PRIVATE, INVITE_ONLY }
enum JoinRequestStatus { PENDING, APPROVED, REJECTED }

// Profile
enum Gender { MALE, FEMALE, OTHER, PREFER_NOT_TO_SAY }
enum ProfileVisibility { PUBLIC, FOLLOWERS, PRIVATE }

// Messaging
enum ChannelType { TEXT, ANNOUNCEMENT, VOICE }
enum ConversationType { DIRECT, GROUP_CHANNEL, GROUP_DIRECT }
enum MessageType { TEXT, IMAGE, VIDEO, AUDIO, DOCUMENT, VOICE_NOTE, ANNOUNCEMENT, SYSTEM }
enum PresenceStatus { ONLINE, IDLE, BUSY, OFFLINE }

// Social
enum PostType { TEXT, IMAGE, VIDEO, CAROUSEL }
enum PostVisibility { PUBLIC, FOLLOWERS, PRIVATE, GROUP_ONLY }
enum PostStatus { DRAFT, PUBLISHED, ARCHIVED, DELETED }
enum StoryType { IMAGE, VIDEO, TEXT }
enum ReactionType { LIKE, LOVE, HAHA, WOW, SAD, ANGRY }

// Video Platform
enum VideoVisibility { PUBLIC, UNLISTED, PRIVATE }
enum VideoStatus { DRAFT, PROCESSING, READY, PUBLISHED, FAILED }
enum PlaylistVisibility { PUBLIC, UNLISTED, PRIVATE }

// Live Streaming
enum LiveStreamStatus { PENDING, LIVE, ENDED, INTERRUPTED, FAILED }
enum RecordingStatus { PROCESSING, READY, FAILED }

// Moderation
enum ReportReason { SPAM, HARASSMENT, HATE_SPEECH, MISINFORMATION, INAPPROPRIATE_CONTENT, VIOLENCE, COPYRIGHT, IMPERSONATION, OTHER }
enum ReportStatus { PENDING, REVIEWING, RESOLVED, DISMISSED }
enum ReportTargetType { USER, GROUP, POST, COMMENT, VIDEO, MESSAGE }
enum ActionType { WARN_USER, REMOVE_CONTENT, SUSPEND_USER, BAN_USER, DISMISS_REPORT }

// Calendar
enum CalendarType { ETHIOPIAN, GREGORIAN }
enum CalendarReminderRepeat { NONE, MONTHLY, YEARLY }

// Notifications
enum NotificationType { MESSAGE, MENTION, REACTION, GROUP_INVITE, GROUP_JOIN_REQUEST, GROUP_APPROVE, SYSTEM }

// Files
enum FileProvider { LOCAL, S3, CLOUDINARY, MINIO }
enum FileType { IMAGE, VIDEO, AUDIO, DOCUMENT, ARCHIVE, OTHER }
enum FileStatus { UPLOADING, PROCESSING, READY, FAILED, DELETED }
```

---

## Indexes & Performance

### Index Strategy

**Primary Indexes** (automatically created):
- `@id` fields (UUIDs)
- `@unique` fields

**Custom Indexes**:
- Foreign keys for joins
- Frequently queried fields
- Sort/filter fields
- Composite indexes for common query patterns

### Key Indexes

**User Lookups**:
```prisma
@@index([email])
@@index([username])
@@index([phoneNumber])
```

**Temporal Queries**:
```prisma
@@index([createdAt])
@@index([publishedAt])
@@index([expiresAt])
```

**Relationships**:
```prisma
@@index([userId])
@@index([groupId])
@@index([videoId])
```

**Status Filters**:
```prisma
@@index([status])
@@index([visibility])
```

### Query Optimization

**Selective Field Loading**:
```typescript
const user = await prisma.user.findUnique({
  where: { id: userId },
  select: {
    id: true,
    username: true,
    email: true,
    // Only load needed fields
  }
});
```

**Eager Loading** (avoid N+1 queries):
```typescript
const posts = await prisma.post.findMany({
  include: {
    user: true,
    likes: true,
    comments: true,
  }
});
```

**Pagination**:
```typescript
const videos = await prisma.video.findMany({
  take: 20,
  skip: (page - 1) * 20,
  orderBy: { createdAt: 'desc' },
});
```

---

## Relationships

### Relationship Types

**One-to-One**:
```prisma
model User {
  profile Profile?
}

model Profile {
  userId String @unique
  user   User   @relation(fields: [userId], references: [id])
}
```

**One-to-Many**:
```prisma
model User {
  posts Post[]
}

model Post {
  userId String
  user   User   @relation(fields: [userId], references: [id])
}
```

**Many-to-Many**:
```prisma
model User {
  groupMembers GroupMember[]
}

model Group {
  members GroupMember[]
}

model GroupMember {
  userId  String
  groupId String
  
  user  User  @relation(fields: [userId], references: [id])
  group Group @relation(fields: [groupId], references: [id])
  
  @@unique([userId, groupId])
}
```

### Referential Actions

**Cascade Delete**:
```prisma
user User @relation(fields: [userId], references: [id], onDelete: Cascade)
```
- When user deleted, all related records deleted

**Set Null**:
```prisma
user User? @relation(fields: [userId], references: [id], onDelete: SetNull)
```
- When user deleted, foreign key set to null

**Restrict** (default):
- Prevent deletion if related records exist

---

## Migrations

### Migration Commands

**Create Migration**:
```bash
npx prisma migrate dev --name add_calendar_reminders
```

**Apply Migrations** (production):
```bash
npx prisma migrate deploy
```

**Check Status**:
```bash
npx prisma migrate status
```

**Reset Database** (development only):
```bash
npx prisma migrate reset
```

### Migration Files

Located in `prisma/migrations/`:

```
prisma/migrations/
├── 20260718000138_init/
│   └── migration.sql
├── 20260719155851_sync_user_security_fields/
│   └── migration.sql
├── 20260825120000_reconcile_full_schema/
│   └── migration.sql
├── 20260903140000_add_message_client_id/
│   └── migration.sql
├── 20260908000000_add_calendar_notes/
│   └── migration.sql
├── 20260908120000_add_calendar_reminders/
│   └── migration.sql
├── 20260909120000_add_calendar_recurring_reminders/
│   └── migration.sql
├── 20260924130000_add_notified_live_at/
│   └── migration.sql
└── migration_lock.toml
```

**Each migration contains**:
- Timestamp (YYYYMMDDHHMMSS)
- Descriptive name
- SQL DDL statements

### Migration Best Practices

1. **Always review migrations** before applying
2. **Test migrations** in development/staging first
3. **Backup production database** before migrating
4. **Never edit applied migrations** (create new ones)
5. **Use descriptive names** for migrations
6. **Keep migrations small and focused**

---

## Seeding

### Seed Script

Located in `prisma/seed/index.ts`:

**Purpose**:
- Populate initial data
- Create default roles and permissions
- Add test data for development

**Run Seed**:
```bash
npm run db:seed
```

### Default Roles & Permissions

Seeded from `prisma/seed/role-permissions.ts`:

**Roles**:
- SUPER_ADMIN - All permissions
- ADMIN - Administrative permissions
- MODERATOR - Moderation permissions
- SUPPORT - Support permissions
- USER - Basic user permissions

**Permissions** (100+):
- Authentication: `register`, `login`, `refresh-token`
- Users: `view:user`, `update:own-profile`, `update:any-profile`
- Posts: `create:post`, `delete:own-post`, `delete:any-post`
- Videos: `create:video`, `delete:own-video`, `publish:video`
- Groups: `create:group`, `delete:group`, `moderate:group`
- Live: `create:livestream`, `moderate:livestream`
- Admin: `view:admin-panel`, `manage:users`, `view:reports`

---

## Best Practices

### Query Performance

1. **Use indexes** for frequently queried fields
2. **Avoid N+1 queries** with `include`/`select`
3. **Paginate large datasets**
4. **Use transactions** for related operations
5. **Cache frequently accessed data** (Redis)

### Data Integrity

1. **Use foreign key constraints**
2. **Define `onDelete` behavior** explicitly
3. **Validate data** in application layer
4. **Use enums** for fixed value sets
5. **Implement soft deletes** where appropriate

### Schema Design

1. **Normalize data** appropriately
2. **Denormalize counters** for performance (`viewCount`, `likeCount`)
3. **Use UUID** for primary keys
4. **Consistent naming** conventions
5. **Document relationships** clearly

### Security

1. **Never expose raw IDs** in URLs (use UUIDs)
2. **Validate all inputs** before queries
3. **Use parameterized queries** (Prisma does this automatically)
4. **Implement row-level security** in application logic
5. **Audit sensitive operations**

---

## Conclusion

The Zikire Kdusan database schema is designed to support a comprehensive video streaming and social platform with:

- ✅ **80+ models** covering all feature domains
- ✅ **Type-safe queries** via Prisma ORM
- ✅ **Scalable design** with proper indexing
- ✅ **Data integrity** through foreign key constraints
- ✅ **Flexibility** for future extensions

**Key Strengths**:
- Modular organization by feature domain
- Comprehensive relationship mapping
- Performance-optimized indexes
- Clear enumeration of valid states
- Audit trail for compliance

---

**Document Version**: 1.0  
**Last Updated**: Based on schema audit September 2026  
**Related Documentation**: ARCHITECTURE.md, API.md, DEVELOPMENT.md

For schema source, see: `backend/prisma/schema.prisma`
