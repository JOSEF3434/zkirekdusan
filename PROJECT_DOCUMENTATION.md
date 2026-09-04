# ዝክረ ክዱሳን (Zikre Kidusan / StreamHub)
## Complete Project Documentation

**Version:** 4.0.0  
**Last Updated:** September 4, 2026  
**Project Type:** Enterprise Social Media & Video Streaming Platform  
**Architecture:** Full-Stack (Flutter Mobile/Web + NestJS Backend)

---

## 📑 Table of Contents

1. [Executive Summary](#executive-summary)
2. [Project Architecture](#project-architecture)
3. [Technology Stack](#technology-stack)
4. [System Components](#system-components)
5. [Backend Architecture](#backend-architecture)
6. [Mobile Application Architecture](#mobile-application-architecture)
7. [Database Design](#database-design)
8. [Key Features](#key-features)
9. [Development Setup](#development-setup)
10. [Build & Deployment](#build--deployment)
11. [API Documentation](#api-documentation)
12. [Security & Authentication](#security--authentication)
13. [Offline-First Architecture](#offline-first-architecture)
14. [Real-Time Features](#real-time-features)
15. [File Storage & Media Processing](#file-storage--media-processing)
16. [Testing Strategy](#testing-strategy)
17. [Known Issues & Troubleshooting](#known-issues--troubleshooting)
18. [Development Roadmap](#development-roadmap)
19. [Contributing Guidelines](#contributing-guidelines)
20. [License & Credits](#license--credits)

---

## 1. Executive Summary

**ዝክረ ክዱሳን (Zikre Kidusan)**, also known as **StreamHub**, is an enterprise-grade social media and video streaming platform that combines the features of YouTube, Instagram, Discord, and WhatsApp into a unified, offline-first mobile and web application.

### Project Vision

To create a professional, scalable, and feature-rich platform that enables:
- **Social Networking**: Posts, stories, reels, comments, reactions, and follows
- **Video Streaming**: Upload, transcode, stream, and manage video content with HLS/DASH adaptive streaming
- **Real-Time Messaging**: Direct messages, group chats, channels, voice messages, and file sharing
- **Live Streaming**: RTMP/WebRTC live broadcasts with real-time chat
- **Community Management**: Groups with granular role-based access control (RBAC)
- **Offline-First Experience**: Full functionality without internet connectivity using local SQLite database

### Target Platforms

- **Mobile**: iOS & Android (Flutter)
- **Web**: Progressive Web App (Flutter Web)
- **Backend**: RESTful API + WebSocket Gateway (NestJS)

### Current Status

✅ **Production-Ready Components:**
- Authentication & Authorization (JWT + Refresh Token Rotation)
- Social Features (Posts, Stories, Reels, Follows, Comments, Likes)
- Real-Time Messaging (Direct, Group, Channels)
- Video Platform (Upload, Transcoding, Streaming, Playlists)
- Offline Synchronization Engine
- Group Management with RBAC

⚠️ **Partial Implementation:**
- Live Streaming (Gateway exists, media server integration pending)
- Admin Dashboard (Backend ready, frontend UI pending)

📋 **Planned Features:**
- End-to-End Encryption (E2EE)
- AI-Powered Recommendations
- Advanced Analytics Dashboard

---

## 2. Project Architecture

### High-Level System Design

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          CLIENT APPLICATIONS                             │
│                                                                          │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐     │
│  │   Flutter iOS    │  │  Flutter Android │  │   Flutter Web    │     │
│  │     (Mobile)     │  │     (Mobile)     │  │     (PWA)        │     │
│  └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘     │
│           │                     │                     │                 │
│           └─────────────────────┴─────────────────────┘                 │
│                                 │                                       │
│                    ┌────────────▼────────────┐                         │
│                    │   Offline-First Layer   │                         │
│                    │  (Drift SQLite + Sync)  │                         │
│                    └────────────┬────────────┘                         │
└─────────────────────────────────┼──────────────────────────────────────┘
                                  │
                    ┌─────────────▼─────────────┐
                    │      API Gateway          │
                    │   (HTTPS + WebSocket)     │
                    └─────────────┬─────────────┘
                                  │
┌─────────────────────────────────▼──────────────────────────────────────┐
│                         BACKEND SERVICES                                │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                      NestJS Application                          │  │
│  │                                                                  │  │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌──────────┐ │  │
│  │  │   Auth     │  │   Social   │  │   Video    │  │   Chat   │ │  │
│  │  │  Modules   │  │  Modules   │  │  Modules   │  │ Modules  │ │  │
│  │  └──────┬─────┘  └──────┬─────┘  └──────┬─────┘  └────┬─────┘ │  │
│  │         │                │                │              │       │  │
│  │         └────────────────┴────────────────┴──────────────┘       │  │
│  │                              │                                   │  │
│  │                    ┌─────────▼─────────┐                        │  │
│  │                    │  Prisma ORM       │                        │  │
│  │                    └─────────┬─────────┘                        │  │
│  └──────────────────────────────┼──────────────────────────────────┘  │
│                                  │                                     │
│  ┌──────────────────────────────▼──────────────────────────────────┐  │
│  │              PostgreSQL Database (Neon)                          │  │
│  │  - Users, Roles, Sessions                                        │  │
│  │  - Posts, Stories, Reels, Comments, Likes                        │  │
│  │  │  - Videos, Channels, Playlists                                │  │
│  │  - Messages, Conversations, Channels                             │  │
│  │  - Groups, Permissions, Reports                                  │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                   Supporting Infrastructure                       │  │
│  │                                                                  │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │  │
│  │  │  Redis   │  │ BullMQ   │  │Cloudinary│  │ Firebase │       │  │
│  │  │ (Cache)  │  │ (Queue)  │  │  (CDN)   │  │  (FCM)   │       │  │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘       │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

### Architecture Principles

1. **Offline-First**: All data is cached locally and synchronized incrementally
2. **Clean Architecture**: Separation of concerns with layers (Presentation, Domain, Data)
3. **Microservices Ready**: Modular NestJS structure allows future service extraction
4. **Scalability**: Horizontal scaling with Redis adapter for Socket.IO
5. **Security**: JWT-based authentication, RBAC, input validation, and sanitization
6. **Performance**: Lazy loading, pagination, CDN delivery, and database indexing

---

## 3. Technology Stack

### Mobile & Web Frontend

| Technology | Version | Purpose |
|------------|---------|---------|
| **Flutter** | 3.47.2 | Cross-platform UI framework |
| **Dart SDK** | 3.13.2 | Programming language |
| **Riverpod** | 2.6.1 | State management |
| **Go Router** | 14.8.1 | Navigation & routing |
| **Drift** | 2.28.2 | Local SQLite ORM |
| **Dio** | 5.11.0 | HTTP client |
| **Socket.IO Client** | 2.0.3 | Real-time WebSocket |
| **Video Player** | 2.10.1 | Video playback |
| **Freezed** | 2.5.8 | Immutable data classes |
| **Firebase Messaging** | 16.6.0 | Push notifications |
| **Workmanager** | 0.9.2 | Background tasks |

### Backend

| Technology | Version | Purpose |
|------------|---------|---------|
| **NestJS** | 11.0.1 | Enterprise Node.js framework |
| **TypeScript** | 6.0.3 | Type-safe JavaScript |
| **Prisma** | 7.8.0 | Database ORM |
| **PostgreSQL** | Latest | Relational database |
| **Neon** | Latest | Serverless Postgres |
| **BullMQ** | 5.81.2 | Job queue processor |
| **Redis** | (ioredis 5.11.1) | Cache & pub/sub |
| **Socket.IO** | 4.8.3 | Real-time gateway |
| **Passport JWT** | 4.0.1 | Authentication strategy |
| **Cloudinary** | 2.10.0 | Media CDN & processing |
| **Firebase Admin** | 14.2.0 | Push notification sending |

### Build & Development Tools

| Tool | Purpose |
|------|---------|
| **Gradle** | 8.14.3 (Android build system) |
| **Android Gradle Plugin (AGP)** | 8.11.1 |
| **Kotlin** | 2.2.20 (Android) |
| **JDK** | 17 (Required for Gradle) |
| **npm** | Package manager |
| **ESLint** | Code linting |
| **Prettier** | Code formatting |
| **Swagger** | API documentation |

---

## 4. System Components

### Backend Modules (43 Total)

#### Phase 1: Foundation & Authentication
1. `auth` - JWT access/refresh token authentication
2. `users` - User management & CRUD
3. `roles` - Global role system (SUPER_ADMIN, ADMIN, USER)
4. `authorization` - Permission checks
5. `sessions` - Active session tracking
6. `refresh-token` - Token rotation with family revocation
7. `profiles` - User profile visibility & bio
8. `uploads` - Multipart file upload handler
9. `health` - System health checks

#### Phase 2: Social Features
10. `follows` - Follow/unfollow relationships
11. `posts` - Text, image, video, carousel posts
12. `comments` - Nested comment system
13. `likes` - Reaction system
14. `saved-posts` - Bookmark functionality
15. `stories` - 24-hour ephemeral content
16. `reels` - Short-form video feed
17. `reports` - Content moderation & reporting

#### Phase 3: Messaging
18. `conversations` - Direct & group messaging
19. `messages` - Message CRUD with attachments
20. `messaging-gateway` - Socket.IO real-time gateway
21. `channels` - Group text/announcement channels
22. `presence` - Online/offline/idle status
23. `notifications` - Push notification delivery

#### Phase 4: Video Platform
24. `videos` - Video upload & metadata
25. `video-processing` - BullMQ transcoding queue
26. `video-channels` - Content creator channels
27. `video-comments` - Video-specific comments
28. `video-playlists` - Playlist management
29. `video-subscriptions` - Channel subscriptions
30. `downloads` - Multi-resolution download API

#### Phase 5: Live Streaming
31. `live-streaming` - Live stream management
32. `live-gateway` - WebRTC/RTMP signaling
33. `stream-chat` - Live chat messages
34. `stream-analytics` - Concurrent viewer metrics
35. `stream-highlights` - Clip generation
36. `stream-processing` - Recording pipeline

#### Phase 6: Discovery & Search
37. `search` - Full-text search
38. `explore` - Content discovery
39. `trending` - Trending content algorithm
40. `recommendations` - Personalized suggestions

#### Phase 7: Groups & Community
41. `groups` - Group creation & settings
42. `group-join-requests` - Membership approval workflow
43. `admin` - Platform administration tools

### Mobile Features (21 Total)

1. **auth** - Login, registration, password reset
2. **splash** - App launch screen
3. **home** - Main feed with stories & posts
4. **social** - Social feed & interactions
5. **stories** - Story viewer & creator
6. **profile** - User profile & settings
7. **chats** - Messaging UI
8. **calls** - Voice/video call interface
9. **groups** - Group management UI
10. **explore** - Discovery & search
11. **create** - Content creation hub
12. **upload** - Video/photo upload
13. **player** - Video player with controls
14. **live** - Live streaming viewer/broadcaster
15. **library** - Saved & watch history
16. **notifications** - Notification center
17. **settings** - App preferences
18. **media_experience** - Full-screen media viewer
19. **creator** - Creator studio
20. **creator_analytics** - Analytics dashboard
21. **admin** - Admin tools

### Core Mobile Services

Located in `mobile/lib/core/`:

- **database** - Drift SQLite schema & DAOs (9 tables)
- **network** - HTTP client, interceptors, connectivity
- **storage** - Secure storage, file management, download manager
- **sync** - Background sync engine with retry logic
- **providers** - Riverpod global providers
- **utils** - Helpers, constants, extensions
- **error** - Error handling & logging
- **presentation** - Shared UI components & themes

---

## 5. Backend Architecture

### Module Structure Example

```
backend/src/modules/auth/
│
├── constants/           # Auth-related constants
├── decorators/          # Custom route decorators
│   ├── current-user.decorator.ts
│   └── public.decorator.ts
│
├── dto/                 # Data Transfer Objects
│   ├── register.dto.ts
│   ├── login.dto.ts
│   ├── refresh-token.dto.ts
│   ├── forgot-password.dto.ts
│   └── reset-password.dto.ts
│
├── guards/              # Route guards
│   ├── jwt-auth.guard.ts
│   └── refresh-auth.guard.ts
│
├── interfaces/          # TypeScript interfaces
│   └── jwt-payload.interface.ts
│
├── strategies/          # Passport strategies
│   ├── jwt.strategy.ts
│   └── refresh.strategy.ts
│
├── auth.controller.ts   # HTTP endpoints
├── auth.service.ts      # Business logic
└── auth.module.ts       # Module definition
```

### Database Layer (Prisma)

**Schema Location:** `backend/prisma/schema.prisma`

**Key Features:**
- 40+ tables covering all features
- Complex relationships with proper indexing
- Enum types for type safety
- Soft delete patterns
- Timestamp tracking (createdAt, updatedAt)
- Neon serverless Postgres adapter

**Migration System:**
```bash
# Generate Prisma Client
npm run prisma:generate

# Create new migration
npx prisma migrate dev --name <migration_name>

# Deploy to production
npm run prisma:deploy

# Seed database
npm run db:seed
```

### API Design Patterns

1. **RESTful Endpoints:**
   - GET /api/resource - List all
   - GET /api/resource/:id - Get one
   - POST /api/resource - Create
   - PATCH /api/resource/:id - Update
   - DELETE /api/resource/:id - Delete

2. **Pagination:**
   ```typescript
   GET /api/posts?page=1&limit=20&sortBy=createdAt&order=desc
   ```

3. **Filtering:**
   ```typescript
   GET /api/videos?channelId=123&status=PUBLISHED
   ```

4. **Delta Sync:**
   ```typescript
   GET /api/conversations/updates?since=2026-09-01T00:00:00Z
   ```

### Security Layers

1. **Authentication:** JWT access tokens (15 min) + refresh tokens (7 days)
2. **Authorization:** Two-level RBAC (Global roles + Group roles)
3. **Input Validation:** class-validator + class-transformer
4. **Rate Limiting:** @nestjs/throttler (100 req/min default)
5. **CORS:** Origin whitelist + localhost dev mode
6. **Helmet.js:** Security headers
7. **Password Hashing:** bcrypt (rounds: 10)

---

## 6. Mobile Application Architecture

### Clean Architecture Layers

```
mobile/lib/
│
├── app/                          # Application setup
│   ├── app.dart                  # Root widget
│   ├── router.dart               # Go Router config
│   ├── theme.dart                # Material theme
│   └── env/                      # Environment config
│
├── core/                         # Business-agnostic foundation
│   ├── database/                 # Drift SQLite
│   │   ├── app_database.dart     # Database instance
│   │   ├── tables/               # Table definitions (9 files)
│   │   └── daos/                 # Data Access Objects
│   │
│   ├── network/                  # HTTP & connectivity
│   │   ├── dio_client.dart       # Configured Dio instance
│   │   ├── interceptors/         # Auth, logging, error
│   │   └── connectivity_service.dart
│   │
│   ├── storage/                  # File & secure storage
│   │   ├── secure_storage.dart   # FlutterSecureStorage wrapper
│   │   ├── download_service.dart # Video download manager
│   │   └── file_manager.dart     # File system operations
│   │
│   ├── sync/                     # Background synchronization
│   │   ├── sync_manager.dart     # Queue processor
│   │   └── background_sync_service.dart  # Workmanager
│   │
│   └── providers/                # Global Riverpod providers
│
└── features/                     # Feature modules (21 total)
    │
    ├── auth/
    │   ├── presentation/         # UI (screens, widgets)
    │   ├── domain/               # Business logic (entities, use cases)
    │   └── data/                 # Data layer (repos, DTOs, datasources)
    │
    └── [similar structure for each feature]
```

### State Management Pattern

```dart
// Provider definition
final postListProvider = FutureProvider<List<Post>>((ref) async {
  final repository = ref.read(postRepositoryProvider);
  return repository.fetchPosts();
});

// UI consumption
Consumer(
  builder: (context, ref, child) {
    final postsAsync = ref.watch(postListProvider);
    return postsAsync.when(
      data: (posts) => PostList(posts: posts),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => ErrorWidget(err),
    );
  },
)
```

### Navigation Structure (Go Router)

```dart
GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => SplashScreen()),
    GoRoute(path: '/auth/login', builder: (context, state) => LoginScreen()),
    GoRoute(path: '/home', builder: (context, state) => HomeScreen()),
    GoRoute(path: '/profile/:userId', builder: (context, state) {
      final userId = state.pathParameters['userId']!;
      return ProfileScreen(userId: userId);
    }),
    // ... 50+ routes
  ],
  redirect: (context, state) {
    // Auth guard logic
  },
)
```

---

## 7. Database Design

### Local SQLite Schema (Drift)

**Location:** `mobile/lib/core/database/tables/`

#### Core Tables (9)

1. **local_users**
   - Columns: id, serverId, username, email, displayName, avatarUrl, bio, isOnline, lastSeenAt, syncedAt
   - Purpose: Cached user profiles

2. **local_videos**
   - Columns: id, serverId, title, description, thumbnailUrl, duration, viewCount, channelId, localFilePath, downloadStatus, watchPosition, syncedAt
   - Purpose: Video metadata + offline download tracking

3. **local_conversations**
   - Columns: id, serverId, type (DIRECT/GROUP/CHANNEL), title, avatarUrl, unreadCount, isPinned, isMuted, lastMessageAt, syncedAt
   - Purpose: Chat conversation list

4. **local_messages**
   - Columns: id, clientId, serverId, conversationId, senderId, content, type, status (pending/sent/delivered/read), isPendingSync, reactions (JSON), createdAt, syncedAt
   - Purpose: Message history with sync state

5. **local_message_attachments**
   - Columns: id, messageId, serverId, localPath, remotePath, mimeType, fileSize, uploadProgress, downloadStatus
   - Purpose: Media attachment tracking

6. **local_watch_history**
   - Columns: id, videoId, userId, watchPosition, duration, isCompleted, watchedAt, isPendingSync
   - Purpose: Video progress tracking

7. **local_search_history**
   - Columns: id, query, category, searchedAt
   - Purpose: Search suggestions (LRU cache)

8. **local_feed_items**
   - Columns: id, serverId, type (POST/REEL/VIDEO), contentJson, authorId, cachedAt
   - Purpose: Pre-loaded feed for offline

9. **sync_queue**
   - Columns: id, operationType (SEND_MESSAGE/UPDATE_WATCH_POSITION/etc.), payload (JSON), retryCount, status, createdAt
   - Purpose: Persistent mutation queue

### Backend PostgreSQL Schema (Prisma)

**Location:** `backend/prisma/schema.prisma`

#### Core Entity Groups

**Authentication & Users:**
- User, Role, Permission, RolePermission, UserRole
- Session, RefreshToken, Device

**Social Features:**
- Post, PostMedia, Comment, Like, SavedPost
- Story, Reel, Follow, Hashtag

**Messaging:**
- Conversation, ConversationMember, Message, MessageAttachment
- Channel (Group channels), Presence

**Video Platform:**
- Video, VideoView, VideoChannel, Playlist, PlaylistItem
- Subscription, VideoComment, VideoTag

**Live Streaming:**
- LiveStream, StreamParticipant, StreamChat, StreamHighlight

**Groups & Community:**
- Group, GroupMember, GroupJoinRequest, GroupChannel

**Admin & Moderation:**
- Report, Block, MutedUser, Notification

**Analytics:**
- WatchHistory, SearchHistory, StreamAnalytics

---

## 8. Key Features

### 🔐 Authentication & Authorization

**Features:**
- Email/password registration with verification
- JWT access token (15 min expiry) + refresh token (7 days)
- Refresh token rotation with automatic family revocation
- Session management (multiple device tracking)
- Password reset flow
- Global roles: SUPER_ADMIN, ADMIN, USER
- Group roles: GROUP_ADMIN, MODERATOR, MEMBER, GUEST
- Fine-grained permission system

**Endpoints:**
```
POST   /api/auth/register
POST   /api/auth/login
POST   /api/auth/refresh
POST   /api/auth/logout
GET    /api/auth/me
POST   /api/auth/forgot-password
POST   /api/auth/reset-password
```

### 📱 Social Features

**Posts:**
- Multi-type posts: TEXT, IMAGE, VIDEO, CAROUSEL
- Visibility: PUBLIC, FOLLOWERS, PRIVATE, GROUP_ONLY
- Hashtag support
- Rich text formatting
- Edit & delete with version history

**Stories:**
- 24-hour auto-expiration
- Image, video, text types
- View tracking
- Story replies

**Reels:**
- Short-form vertical video
- Discover feed algorithm
- Sound attribution

**Interactions:**
- 6 reaction types: LIKE, LOVE, HAHA, WOW, SAD, ANGRY
- Nested comments (unlimited depth)
- Comment pinning
- Mention system (@username)

**Follows:**
- Follow/unfollow users
- Follower/following lists
- Follow request approval for private profiles

### 💬 Real-Time Messaging

**Conversation Types:**
- Direct (1-on-1)
- Group (multi-user)
- Channel (announcement/discussion)

**Message Features:**
- Text, image, video, audio, document, voice note
- Message reactions
- Reply/quote
- Forward messages
- Pin messages
- Message search
- Read receipts (sent/delivered/read)
- Typing indicators
- Online presence

**Voice Messages:**
- Record directly in-app
- Waveform visualization
- Playback speed control

**File Sharing:**
- Multi-file attachments
- Download progress tracking
- Automatic thumbnail generation

**Push Notifications:**
- Firebase Cloud Messaging
- Background message handling
- Custom notification sounds
- Badge count updates

### 🎥 Video Platform

**Upload & Processing:**
- Multipart upload with progress
- Cloudinary integration for transcoding
- Adaptive streaming (HLS/DASH)
- Multiple resolution renditions (360p, 480p, 720p, 1080p)
- Automatic thumbnail extraction
- BullMQ background job processing

**Playback:**
- Adaptive bitrate streaming
- Seek preview thumbnails
- Picture-in-picture mode
- Playback speed control
- Quality selector
- Fullscreen support
- Chromecast support

**Video Management:**
- Video channels (creator accounts)
- Playlists with drag-reorder
- Watch history
- Watch later queue
- Subscription feed
- Like/dislike tracking
- View count analytics

**Comments & Engagement:**
- Threaded video comments
- Timestamp comments
- Comment pinning by creator
- Sort by: Newest, Top, Oldest

**Downloads (Offline Mode):**
- Multi-resolution download option
- Resumable downloads (HTTP Range)
- Download queue management
- Storage limit configuration
- Auto-delete watched videos

### 🔴 Live Streaming

**Broadcaster:**
- RTMP ingestion
- WebRTC peer-to-peer
- Screen sharing
- Camera source selection
- Stream key management
- Stream health monitoring

**Viewer:**
- Low-latency playback
- Live chat overlay
- Viewer count display
- Stream notifications
- DVR rewind (for RTMP)

**Live Chat:**
- Real-time message delivery
- Emote support
- Moderation tools (ban, timeout, delete)
- Slow mode
- Subscriber-only mode

### 🔍 Discovery & Search

**Search:**
- Full-text search across users, posts, videos, groups
- Search history with autocomplete
- Trending searches
- Filters: type, date, duration, relevance

**Explore:**
- Curated content feed
- Category browsing
- Trending hashtags
- Suggested users to follow

**Recommendations:**
- Personalized video suggestions
- Related videos
- Similar content algorithm
- Watch history-based recommendations

### 👥 Groups & Communities

**Group Features:**
- Public, private, invite-only visibility
- Approval workflow for new groups
- Group roles with custom permissions
- Group channels (text, announcement, voice)
- Group-specific posts
- Member directory
- Group announcements
- Group rules & description

**Group Administration:**
- Invite/remove members
- Promote to moderator/admin
- Kick/ban members
- Edit group settings
- Delete group

### 📊 Admin & Moderation

**Content Moderation:**
- Report system (spam, harassment, hate speech, etc.)
- Review queue
- Bulk actions (approve, reject, delete)
- User suspension & banning
- Content takedown

**Analytics:**
- User growth metrics
- Engagement statistics
- Video performance
- Platform health monitoring

### 📴 Offline-First Features

**Core Principles:**
1. App opens instantly without network
2. All actions work offline with optimistic UI updates
3. Automatic background sync when online
4. Conflict resolution with server-side authority

**Offline Capabilities:**
- View cached posts, stories, and videos
- Read message history
- Watch downloaded videos
- Browse user profiles
- Compose draft messages
- Queue uploads

**Synchronization:**
- Delta sync for efficient bandwidth usage
- Exponential backoff retry (2s → 60s)
- Atomic transaction processing
- Idempotency guarantees (client UUID)
- Periodic background sync (Workmanager, 15 min)

---

## 9. Development Setup

### Prerequisites

**Required Software:**
- **Node.js**: >= 22
- **JDK**: 17 (for Android builds)
- **Flutter SDK**: 3.47.2
- **Dart SDK**: 3.13.2
- **PostgreSQL**: Latest (or Neon account)
- **Redis**: Latest (optional, for Socket.IO scaling)
- **Android Studio**: Latest (for Android development)
- **Xcode**: Latest (for iOS development, macOS only)

### Backend Setup

1. **Clone Repository:**
   ```bash
   git clone <repository-url>
   cd zkirekdusan/backend
   ```

2. **Install Dependencies:**
   ```bash
   npm install
   ```

3. **Configure Environment:**
   Create `.env` file in `backend/`:
   ```env
   # Database
   DATABASE_URL="postgresql://user:password@localhost:5432/streamhub"
   
   # JWT Secrets
   JWT_ACCESS_SECRET="your-access-secret-here"
   JWT_REFRESH_SECRET="your-refresh-secret-here"
   ACCESS_TOKEN_EXPIRY="15m"
   REFRESH_TOKEN_EXPIRY="7d"
   
   # Redis (optional)
   REDIS_HOST="localhost"
   REDIS_PORT=6379
   
   # Cloudinary
   CLOUDINARY_CLOUD_NAME="your-cloud"
   CLOUDINARY_API_KEY="your-key"
   CLOUDINARY_API_SECRET="your-secret"
   
   # Firebase Admin (for FCM)
   FIREBASE_PROJECT_ID="your-project-id"
   FIREBASE_CLIENT_EMAIL="your-service-account@project.iam.gserviceaccount.com"
   FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
   
   # CORS Origins (comma-separated)
   CORS_ORIGINS="http://localhost:3000,http://localhost:8080"
   
   # Server
   PORT=3000
   ```

4. **Database Setup:**
   ```bash
   # Generate Prisma Client
   npm run prisma:generate
   
   # Run migrations
   npx prisma migrate dev
   
   # Seed database (optional)
   npm run db:seed
   ```

5. **Start Development Server:**
   ```bash
   npm run start:dev
   ```

   Server runs at: http://localhost:3000/api  
   Swagger docs: http://localhost:3000/api/docs

### Mobile Setup

1. **Navigate to Mobile Directory:**
   ```bash
   cd zkirekdusan/mobile
   ```

2. **Install Flutter Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Environment:**
   Create `.env` file in `mobile/`:
   ```env
   API_BASE_URL=http://localhost:3000/api
   SOCKET_URL=http://localhost:3000
   ```

4. **Generate Code (Freezed, JSON Serializable):**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. **Firebase Setup:**
   - Add `google-services.json` to `android/app/`
   - Add `GoogleService-Info.plist` to `ios/Runner/`
   - Update `firebase_options.dart` using FlutterFire CLI:
     ```bash
     flutterfire configure
     ```

6. **Fix Android Gradle Java Path (if needed):**
   Edit `android/gradle.properties`:
   ```properties
   org.gradle.java.home=C:/Program Files/Microsoft/jdk-17.0.18.8-hotspot
   ```

7. **Run Application:**
   ```bash
   # Android
   flutter run -d android
   
   # iOS
   flutter run -d ios
   
   # Web
   flutter run -d chrome --web-port 8080
   ```

### Verify Setup

**Backend Health Check:**
```bash
curl http://localhost:3000/api/health
```

**Mobile App:**
- Launch app on emulator/device
- Register a new account
- Post a message to verify full stack

---

## 10. Build & Deployment

### Backend Deployment

**Production Build:**
```bash
npm run build
```

**Environment Variables:**
Ensure all required env vars are set in production environment.

**Database Migration:**
```bash
npm run prisma:deploy
```

**Start Production Server:**
```bash
npm run start:prod
```

**Recommended Platforms:**
- **Render.com** (auto-deploy from Git)
- **Railway.app**
- **AWS Elastic Beanstalk**
- **Google Cloud Run**
- **Vercel** (serverless functions)

**Docker Support:**
```dockerfile
FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["node", "dist/src/main.js"]
```

### Mobile Deployment

**Android APK (Debug):**
```bash
flutter build apk --debug
```

**Android APK (Release):**
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

**Android App Bundle (Google Play):**
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

**iOS (Release):**
```bash
flutter build ios --release
# Open ios/Runner.xcworkspace in Xcode
# Archive and upload to App Store Connect
```

**Web (Production):**
```bash
flutter build web --release
# Output: build/web/
```

**Code Signing:**
- **Android:** Configure `android/key.properties` with keystore
- **iOS:** Configure signing in Xcode with Apple Developer account

---

## 11. API Documentation

### Accessing Swagger Docs

Once backend is running, navigate to:
```
http://localhost:3000/api/docs
```

### Authentication Flow

**1. Register:**
```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "username": "johndoe",
  "password": "SecurePass123!",
  "displayName": "John Doe"
}

Response:
{
  "success": true,
  "data": {
    "user": { "id": "uuid", "email": "user@example.com", ... },
    "accessToken": "eyJhbGc...",
    "refreshToken": "eyJhbGc..."
  }
}
```

**2. Login:**
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePass123!"
}

Response:
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGc...",
    "refreshToken": "eyJhbGc...",
    "user": { ... }
  }
}
```

**3. Refresh Token:**
```http
POST /api/auth/refresh
Content-Type: application/json

{
  "refreshToken": "eyJhbGc..."
}

Response:
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGc...",
    "refreshToken": "eyJhbGc..."
  }
}
```

**4. Authenticated Requests:**
```http
GET /api/users/me
Authorization: Bearer eyJhbGc...

Response:
{
  "success": true,
  "data": { "id": "uuid", "email": "user@example.com", ... }
}
```

### Key Endpoint Categories

**Posts:**
- GET /api/posts - List posts (paginated)
- POST /api/posts - Create post
- GET /api/posts/:id - Get post details
- PATCH /api/posts/:id - Update post
- DELETE /api/posts/:id - Delete post

**Videos:**
- GET /api/videos - List videos
- POST /api/videos - Upload video
- GET /api/videos/:id - Get video details
- POST /api/videos/:id/view - Track view
- GET /api/videos/:id/related - Get related videos

**Messaging:**
- GET /api/conversations - List conversations
- POST /api/conversations - Create conversation
- GET /api/conversations/:id/messages - Get messages
- POST /api/conversations/:id/messages - Send message
- GET /api/conversations/updates?since=<timestamp> - Delta sync

**Live Streaming:**
- GET /api/live-streaming - List active streams
- POST /api/live-streaming - Start stream
- PATCH /api/live-streaming/:id - Update stream
- DELETE /api/live-streaming/:id - End stream

---

## 12. Security & Authentication

### JWT Token Strategy

**Access Token:**
- Expiry: 15 minutes
- Payload: { userId, email, roles }
- Storage: Memory only (not localStorage)

**Refresh Token:**
- Expiry: 7 days
- Payload: { userId, sessionId, tokenFamily }
- Storage: HttpOnly secure cookie (backend) or secure storage (mobile)

**Token Rotation:**
1. Client sends expired access token
2. Backend validates refresh token
3. Backend issues new access token + new refresh token
4. Old refresh token family is revoked if reuse detected

### Role-Based Access Control (RBAC)

**Global Roles:**
- SUPER_ADMIN: Full platform control
- ADMIN: Moderation & management
- USER: Standard user access

**Group Roles:**
- GROUP_ADMIN: Full group control
- MODERATOR: Content moderation
- MEMBER: Standard participation
- GUEST: Read-only access

**Permission Enforcement:**
```typescript
// Backend guard
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(GlobalRole.ADMIN)
@Get('/admin/users')
async listUsers() { ... }

// Group-specific permission
@UseGuards(JwtAuthGuard, GroupMembershipGuard)
@GroupRoles(GroupRole.GROUP_ADMIN, GroupRole.MODERATOR)
@Delete('/groups/:groupId/members/:userId')
async removeMember() { ... }
```

### Input Validation

**Backend:**
```typescript
// DTO with validation
export class CreatePostDto {
  @IsString()
  @MinLength(1)
  @MaxLength(5000)
  content: string;

  @IsEnum(PostType)
  type: PostType;

  @IsOptional()
  @IsArray()
  @IsUrl({}, { each: true })
  mediaUrls?: string[];
}
```

**Mobile:**
```dart
// Form validation
TextFormField(
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Field is required';
    }
    if (value.length > 5000) {
      return 'Maximum 5000 characters';
    }
    return null;
  },
)
```

### Security Best Practices

1. ✅ Password hashing with bcrypt (rounds: 10)
2. ✅ HTTPS enforcement in production
3. ✅ Helmet.js security headers
4. ✅ CORS whitelist configuration
5. ✅ Rate limiting (100 req/min default)
6. ✅ Input sanitization
7. ✅ SQL injection prevention (Prisma parameterized queries)
8. ✅ XSS prevention (automatic escaping)
9. ✅ CSRF tokens (for cookie-based auth)
10. ✅ Secure file upload validation (MIME type, size, extension)

---

## 13. Offline-First Architecture

### Design Philosophy

The app prioritizes **local-first data access** with **eventual consistency** to the server. This ensures:
- Instant app launch (no loading spinners)
- Full functionality without internet
- Seamless transition between online/offline states
- No data loss from network failures

### Synchronization Flow

```
┌────────────────────────────────────────────────────────┐
│ 1. User Action (e.g., send message)                   │
└───────────┬────────────────────────────────────────────┘
            │
            ▼
┌────────────────────────────────────────────────────────┐
│ 2. Optimistic UI Update (render immediately)          │
└───────────┬────────────────────────────────────────────┘
            │
            ▼
┌────────────────────────────────────────────────────────┐
│ 3. Save to Local SQLite with clientId (UUID)          │
│    - local_messages.status = 'pending'                 │
│    - local_messages.isPendingSync = true               │
└───────────┬────────────────────────────────────────────┘
            │
            ▼
┌────────────────────────────────────────────────────────┐
│ 4. Enqueue in sync_queue table                        │
│    - operationType: 'SEND_MESSAGE'                     │
│    - payload: JSON of message data                     │
│    - retryCount: 0                                     │
└───────────┬────────────────────────────────────────────┘
            │
            ▼
┌────────────────────────────────────────────────────────┐
│ 5. SyncManager picks up queue (when online)           │
└───────────┬────────────────────────────────────────────┘
            │
            ▼
┌────────────────────────────────────────────────────────┐
│ 6. POST to server with clientId                       │
│    - Server checks: existing message with clientId?    │
│    - If yes: return existing (idempotency)             │
│    - If no: create new message                         │
└───────────┬────────────────────────────────────────────┘
            │
            ▼
┌────────────────────────────────────────────────────────┐
│ 7. Reconcile local record                             │
│    - local_messages.serverId = response.id             │
│    - local_messages.status = 'sent'                    │
│    - local_messages.isPendingSync = false              │
└───────────┬────────────────────────────────────────────┘
            │
            ▼
┌────────────────────────────────────────────────────────┐
│ 8. Remove from sync_queue                              │
└────────────────────────────────────────────────────────┘
```

### Conflict Resolution

**Strategy:** Server wins (last-write-wins with server timestamp authority)

**Example Scenarios:**

1. **Message sent offline, delivered when online:**
   - Client UUID prevents duplication
   - Server assigns authoritative ID and timestamp
   - Local record updated with server data

2. **Watch position updated offline:**
   - Multiple updates coalesced into latest position
   - Server accepts highest position value
   - Client reconciles with server response

3. **Deleted message while offline:**
   - Deletion marked in sync_queue
   - Server soft-deletes message (deletedAt timestamp)
   - Client removes from local database

### Delta Sync Protocol

**Purpose:** Minimize bandwidth by fetching only changes since last sync

**Endpoint Example:**
```http
GET /api/conversations/updates?since=2026-09-01T12:00:00.000Z

Response:
{
  "conversations": [
    { "id": "uuid", "updatedAt": "2026-09-04T10:30:00.000Z", ... }
  ],
  "serverTimestamp": "2026-09-04T10:35:00.000Z"
}
```

**Client Process:**
1. Load last sync cursor from local database (`syncedAt` column)
2. Fetch delta updates from server
3. Merge changes into local database (upsert by serverId)
4. Update sync cursor to `serverTimestamp`

### Background Sync Triggers

1. **Network Connectivity Change:** Online transition triggers immediate sync
2. **App Launch:** Sync queue processed on startup
3. **App Resume:** Sync triggered when app returns to foreground
4. **Periodic Background Task:** Workmanager runs sync every 15 minutes (configurable)
5. **Manual Trigger:** Pull-to-refresh in UI

### Storage Management

**Disk Space Tracking:**
```dart
// Check available space before download
final freeSpace = await getFreeSpace();
if (freeSpace < estimatedSize * 1.5) {
  throw InsufficientStorageException();
}
```

**Cache Eviction:**
- LRU (Least Recently Used) for search history
- 30-day expiration for cached feed items
- Manual "Clear Cache" button (preserves downloads)

**User Controls:**
- Download quality preference (360p/480p/720p/1080p)
- Auto-download on WiFi only
- Maximum download storage limit
- Delete downloaded videos

---

## 14. Real-Time Features

### Socket.IO Gateway

**Connection:**
```dart
// Mobile client
import 'package:socket_io_client/socket_io_client.dart';

final socket = io(
  'http://localhost:3000',
  OptionBuilder()
    .setTransports(['websocket'])
    .setExtraHeaders({'Authorization': 'Bearer $accessToken'})
    .build(),
);

socket.connect();
```

**Backend Gateway:**
```typescript
// messaging-gateway.ts
@WebSocketGateway({ cors: { origin: '*' } })
export class MessagingGateway {
  @WebSocketServer()
  server: Server;

  @SubscribeMessage('send_message')
  handleMessage(@MessageBody() data: SendMessageDto) {
    // Broadcast to conversation members
    this.server.to(`conversation:${data.conversationId}`).emit('new_message', message);
  }
}
```

### Event Types

**Messaging Events:**
- `new_message` - New message received
- `message_deleted` - Message removed
- `message_reaction` - Reaction added/removed
- `typing_start` - User started typing
- `typing_stop` - User stopped typing
- `message_read` - Read receipt update

**Presence Events:**
- `user_online` - User went online
- `user_offline` - User went offline
- `user_idle` - User inactive for 5 minutes

**Live Stream Events:**
- `stream_started` - Live stream went live
- `stream_ended` - Live stream ended
- `viewer_joined` - New viewer
- `viewer_left` - Viewer disconnected
- `chat_message` - Live chat message

### Redis Adapter (Horizontal Scaling)

**Purpose:** Share Socket.IO state across multiple backend instances

**Configuration:**
```typescript
// redis-io.adapter.ts
import { IoAdapter } from '@nestjs/platform-socket.io';
import { createAdapter } from '@socket.io/redis-adapter';
import { createClient } from 'redis';

export class RedisIoAdapter extends IoAdapter {
  async connectToRedis(): Promise<void> {
    const pubClient = createClient({ url: 'redis://localhost:6379' });
    const subClient = pubClient.duplicate();

    await Promise.all([pubClient.connect(), subClient.connect()]);

    this.adapterConstructor = createAdapter(pubClient, subClient);
  }
}
```

---

## 15. File Storage & Media Processing

### Upload Flow

**1. Client Prepares Upload:**
```dart
// Select file
final file = await FilePicker.platform.pickFiles(type: FileType.video);

// Create multipart request
final formData = FormData.fromMap({
  'file': await MultipartFile.fromFile(file.path),
  'title': 'My Video',
  'description': 'Description here',
});
```

**2. Backend Receives & Validates:**
```typescript
@Post('upload')
@UseInterceptors(FileInterceptor('file'))
async uploadFile(@UploadedFile() file: Express.Multer.File) {
  // Validate file type, size
  if (!['video/mp4', 'video/quicktime'].includes(file.mimetype)) {
    throw new BadRequestException('Invalid file type');
  }
  
  // Upload to Cloudinary
  const result = await cloudinary.uploader.upload(file.path, {
    resource_type: 'video',
    folder: 'videos',
    transformation: [
      { width: 1920, height: 1080, crop: 'limit' },
      { quality: 'auto', fetch_format: 'mp4' }
    ]
  });
  
  return { url: result.secure_url };
}
```

**3. Background Processing (BullMQ):**
```typescript
// Enqueue transcoding job
await this.videoQueue.add('transcode', {
  videoId: video.id,
  sourceUrl: result.secure_url,
});

// Worker processes job
@Processor('video-queue')
export class VideoProcessor {
  @Process('transcode')
  async handleTranscode(job: Job) {
    // Generate multiple resolutions
    // Create HLS playlist
    // Extract thumbnails
    // Update database
  }
}
```

### Cloudinary Configuration

**Presets:**
- **Upload Preset:** `streamhub_video_upload`
  - Max file size: 500MB
  - Auto quality optimization
  - Auto format (mp4)
  - Progressive streaming enabled

**Transformations:**
```typescript
// Generate adaptive streaming URLs
const hlsUrl = cloudinary.video('video_id', {
  resource_type: 'video',
  format: 'm3u8',
  streaming_profile: 'hd',
  transformation: [
    { quality: 'auto' }
  ]
});
```

### Video Download Manager

**Features:**
- Resumable downloads (HTTP Range requests)
- Pause/resume/cancel controls
- Multi-quality selection
- Free space validation
- Progress tracking

**Implementation:**
```dart
class VideoDownloadManager {
  Future<void> downloadVideo(String videoId, String quality) async {
    final url = await _getDownloadUrl(videoId, quality);
    final savePath = await _getLocalPath(videoId, quality);
    
    // Check disk space
    final estimatedSize = await _getFileSize(url);
    final freeSpace = await _getFreeSpace();
    if (freeSpace < estimatedSize * 1.5) {
      throw InsufficientStorageException();
    }
    
    // Start resumable download
    await dio.download(
      url,
      savePath,
      onReceiveProgress: (received, total) {
        _updateProgress(videoId, received / total);
      },
      options: Options(
        headers: {
          'Range': 'bytes=$currentBytes-',
        },
      ),
    );
    
    // Update database
    await _markDownloadComplete(videoId);
  }
}
```

---

## 16. Testing Strategy

### Backend Testing

**Unit Tests:**
```bash
npm run test
```

**E2E Tests:**
```bash
npm run test:e2e
```

**Coverage Report:**
```bash
npm run test:cov
```

**Example Test:**
```typescript
// auth.service.spec.ts
describe('AuthService', () => {
  let service: AuthService;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [AuthService, { provide: PrismaService, useValue: mockPrisma }],
    }).compile();

    service = module.get<AuthService>(AuthService);
  });

  it('should hash password during registration', async () => {
    const dto = { email: 'test@example.com', password: 'password123' };
    const result = await service.register(dto);
    expect(result.password).not.toEqual('password123');
  });
});
```

### Mobile Testing

**Widget Tests:**
```bash
flutter test
```

**Integration Tests:**
```bash
flutter drive --target=test_driver/app.dart
```

**Example Widget Test:**
```dart
// login_screen_test.dart
testWidgets('Login button triggers authentication', (WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: LoginScreen()),
    ),
  );

  await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');
  await tester.enterText(find.byKey(Key('password_field')), 'password123');
  await tester.tap(find.byKey(Key('login_button')));
  await tester.pumpAndSettle();

  expect(find.text('Welcome back!'), findsOneWidget);
});
```

### Test Coverage Goals

- Backend: > 80% code coverage
- Mobile: > 70% widget/unit test coverage
- E2E: Critical user flows (register, login, post, message, video upload)

---

## 17. Known Issues & Troubleshooting

### ✅ RESOLVED: Android Gradle Build Failure

**Issue:** `org.gradle.java.home` pointing to non-existent JDK 21 path

**Solution:**
1. Update `mobile/android/gradle.properties`:
   ```properties
   org.gradle.java.home=C:/Program Files/Microsoft/jdk-17.0.18.8-hotspot
   ```

2. Set system JAVA_HOME:
   ```bash
   setx JAVA_HOME "C:\Program Files\Microsoft\jdk-17.0.18.8-hotspot"
   ```

**Verification:**
```bash
cd mobile/android
.\gradlew.bat --version
# Should show: Daemon JVM: C:\Program Files\Microsoft\jdk-17.0.18.8-hotspot
```

### ⚠️ Firebase Configuration Issues

**Symptoms:**
- Push notifications not working
- Firebase initialization errors on startup

**Solutions:**
1. Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are present
2. Run `flutterfire configure` to regenerate `firebase_options.dart`
3. Verify Firebase project settings match app bundle ID
4. Check Firebase Cloud Messaging API is enabled

### ⚠️ Cloudinary Upload Failures

**Symptoms:**
- Video uploads timeout
- Transcoding never completes

**Solutions:**
1. Check Cloudinary dashboard for quota limits
2. Verify upload preset exists and is configured correctly
3. Increase request timeout in Dio client:
   ```dart
   dio.options.connectTimeout = Duration(minutes: 10);
   ```
4. Use signed uploads for large files

### ⚠️ Socket.IO Connection Drops

**Symptoms:**
- Real-time messages not received
- Connection disconnects frequently

**Solutions:**
1. Check CORS configuration on backend
2. Verify `Authorization` header is set:
   ```dart
   socket.io('url', OptionBuilder()
     .setExtraHeaders({'Authorization': 'Bearer $token'})
     .build());
   ```
3. Enable WebSocket transport only (disable polling fallback)
4. Check for network stability (mobile data vs WiFi)

### ⚠️ Database Migration Conflicts

**Symptoms:**
- `prisma migrate deploy` fails with conflicts
- Schema out of sync errors

**Solutions:**
1. Reset development database:
   ```bash
   npx prisma migrate reset
   ```
2. Generate new migration:
   ```bash
   npx prisma migrate dev --name fix_schema
   ```
3. For production, resolve conflicts manually by editing migration SQL

### 🔧 General Debugging Tips

**Backend Logs:**
```bash
# Detailed logging
npm run start:dev | pnpm exec pino-pretty
```

**Mobile Logs:**
```bash
# Android
flutter logs

# iOS
flutter logs --device-id <device-id>
```

**Database Inspection:**
```bash
# Open Prisma Studio
npx prisma studio
```

**Network Debugging:**
- Use Charles Proxy or Proxyman to inspect HTTP/WebSocket traffic
- Check Flutter DevTools Network tab

---

## 18. Development Roadmap

### Phase 8: Advanced Features (Q4 2026)

- [ ] End-to-End Encryption (Signal Protocol)
- [ ] Voice/Video Calling (WebRTC P2P)
- [ ] Screen Sharing
- [ ] Advanced Video Editor (trim, filters, effects)
- [ ] Multi-language Support (i18n)
- [ ] Dark Mode / Theme Customization

### Phase 9: AI & Machine Learning (Q1 2027)

- [ ] Content Recommendation Engine (collaborative filtering)
- [ ] Auto-moderation (spam detection, hate speech)
- [ ] Smart Video Thumbnails (scene detection)
- [ ] Auto-captioning (speech-to-text)
- [ ] Content Tags (auto-tagging with ML)

### Phase 10: Monetization (Q2 2027)

- [ ] Creator Subscriptions
- [ ] Tipping / Super Chat
- [ ] Ad Integration (video pre-roll, banner ads)
- [ ] Premium Memberships
- [ ] Paid Live Events

### Phase 11: Enterprise Features (Q3 2027)

- [ ] SSO Integration (SAML, OAuth)
- [ ] Advanced Analytics Dashboard
- [ ] Custom Branding (white-label)
- [ ] API Rate Limiting Tiers
- [ ] Audit Logs
- [ ] Data Export Tools (GDPR compliance)

---

## 19. Contributing Guidelines

### Code Style

**Backend (TypeScript):**
- Follow NestJS conventions
- Use ESLint + Prettier (config provided)
- Run `npm run lint` before committing
- Write JSDoc comments for public APIs

**Mobile (Dart):**
- Follow official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Run `dart format .` before committing
- Use `flutter analyze` to catch issues

### Git Workflow

1. **Fork the repository**
2. **Create feature branch:**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Commit changes:**
   ```bash
   git commit -m "feat: add amazing feature"
   ```
   Follow [Conventional Commits](https://www.conventionalcommits.org/)
4. **Push to branch:**
   ```bash
   git push origin feature/amazing-feature
   ```
5. **Open Pull Request**

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-reviewed code
- [ ] Commented complex areas
- [ ] Updated documentation
- [ ] Added tests
- [ ] All tests pass
- [ ] No new warnings
```

### Testing Requirements

- All new features must include tests
- Bug fixes should include regression tests
- Maintain or improve code coverage
- E2E tests for critical user flows

---

## 20. License & Credits

### License

This project is proprietary and confidential. All rights reserved.

### Technology Credits

**Frameworks & Libraries:**
- [NestJS](https://nestjs.com/) - Backend framework
- [Flutter](https://flutter.dev/) - Mobile/Web framework
- [Prisma](https://www.prisma.io/) - Database ORM
- [Socket.IO](https://socket.io/) - Real-time engine
- [Cloudinary](https://cloudinary.com/) - Media CDN
- [Firebase](https://firebase.google.com/) - Push notifications
- [Neon](https://neon.tech/) - Serverless Postgres

**Open Source Dependencies:**
See `backend/package.json` and `mobile/pubspec.yaml` for complete list.

### Contact

For questions, support, or collaboration inquiries:
- **Email:** support@zikrekidusan.com
- **Documentation:** [Internal Wiki]
- **Issue Tracker:** [GitHub Issues]

---

**Document Version:** 1.0  
**Last Updated:** September 4, 2026  
**Maintained By:** Development Team

---

## Appendix A: Environment Variables Reference

### Backend (.env)

```env
# ============================================
# DATABASE
# ============================================
DATABASE_URL="postgresql://user:password@host:5432/dbname"
DIRECT_URL="postgresql://user:password@host:5432/dbname"

# ============================================
# JWT AUTHENTICATION
# ============================================
JWT_ACCESS_SECRET="your-256-bit-secret-here"
JWT_REFRESH_SECRET="different-256-bit-secret-here"
ACCESS_TOKEN_EXPIRY="15m"
REFRESH_TOKEN_EXPIRY="7d"

# ============================================
# REDIS (Optional - for Socket.IO scaling)
# ============================================
REDIS_HOST="localhost"
REDIS_PORT="6379"
REDIS_PASSWORD=""

# ============================================
# CLOUDINARY
# ============================================
CLOUDINARY_CLOUD_NAME="your-cloud-name"
CLOUDINARY_API_KEY="123456789012345"
CLOUDINARY_API_SECRET="abcdefghijklmnopqrstuvwxyz"

# ============================================
# FIREBASE ADMIN (for FCM push notifications)
# ============================================
FIREBASE_PROJECT_ID="your-firebase-project-id"
FIREBASE_CLIENT_EMAIL="firebase-adminsdk-xxxxx@project.iam.gserviceaccount.com"
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIE...your-private-key-here...=\n-----END PRIVATE KEY-----\n"

# ============================================
# CORS
# ============================================
CORS_ORIGINS="http://localhost:3000,http://localhost:8080,https://yourdomain.com"

# ============================================
# SERVER
# ============================================
PORT="3000"
NODE_ENV="development"
```

### Mobile (.env)

```env
# ============================================
# API CONFIGURATION
# ============================================
API_BASE_URL="http://localhost:3000/api"
SOCKET_URL="http://localhost:3000"

# ============================================
# FEATURE FLAGS (optional)
# ============================================
ENABLE_LIVE_STREAMING="true"
ENABLE_ANALYTICS="true"
DEBUG_MODE="true"
```

---

## Appendix B: Database Schema Diagram

```mermaid
erDiagram
    User ||--o{ Post : creates
    User ||--o{ Comment : writes
    User ||--o{ Message : sends
    User ||--o{ Video : uploads
    User ||--o{ Story : publishes
    User ||--|| Profile : has
    User }o--o{ Group : member_of
    User }o--o{ Role : has_role
    
    Post ||--o{ Comment : has
    Post ||--o{ Like : receives
    Post ||--o{ PostMedia : contains
    
    Video ||--o{ VideoView : has
    Video ||--o{ VideoComment : receives
    Video }o--o{ Playlist : in
    
    Conversation ||--o{ Message : contains
    Conversation }o--o{ User : participant
    
    Group ||--o{ Channel : has
    Group ||--o{ GroupMember : has
    
    LiveStream ||--o{ StreamChat : has
    LiveStream ||--o{ StreamParticipant : has
```

---

**END OF DOCUMENTATION**
