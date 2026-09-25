# System Architecture

**Zikire Kdusan (StreamHub) - Technical Architecture Documentation**

This document describes the system architecture, technology stack, component relationships, and design patterns used in Zikire Kdusan, a full-stack video streaming and social platform.

---

## Table of Contents

1. [Overview](#overview)
2. [High-Level Architecture](#high-level-architecture)
3. [Technology Stack](#technology-stack)
4. [Backend Architecture](#backend-architecture)
5. [Frontend Architecture](#frontend-architecture)
6. [Database Architecture](#database-architecture)
7. [Authentication & Authorization](#authentication--authorization)
8. [Real-Time Communication](#real-time-communication)
9. [Media Pipeline](#media-pipeline)
10. [Offline & Sync Strategy](#offline--sync-strategy)
11. [Caching Strategy](#caching-strategy)
12. [Queue Management](#queue-management)
13. [API Design](#api-design)
14. [Security Architecture](#security-architecture)
15. [Scalability Considerations](#scalability-considerations)
16. [Deployment Architecture](#deployment-architecture)
17. [Monitoring & Observability](#monitoring--observability)

---

## Overview

### Project Description

**Zikire Kdusan** (also known as **StreamHub**) is a comprehensive video streaming and social platform built with modern web technologies. The platform provides:

- Video uploading, streaming, and management
- Live streaming with real-time chat
- Social networking features (posts, stories, reels)
- Group-based communities with channels
- Direct messaging and group chat
- Ethiopian calendar integration
- Content discovery and recommendations
- Mobile and web applications

### Design Philosophy

**Core Principles**:
1. **Modular Architecture**: Clear separation of concerns with independent, reusable modules
2. **Security First**: Authentication and authorization enforced at every layer
3. **Real-Time Capable**: WebSocket integration for live features
4. **Offline Support**: Mobile app works offline with background sync
5. **Scalability**: Designed to scale horizontally with Redis, BullMQ, and stateless services
6. **Type Safety**: End-to-end type safety with TypeScript (backend) and Dart (frontend)

---

## High-Level Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CLIENT LAYER                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────────┐              ┌──────────────────┐            │
│  │  Flutter Mobile  │              │   Flutter Web    │            │
│  │   (iOS/Android)  │              │   Application    │            │
│  └────────┬─────────┘              └─────────┬────────┘            │
│           │                                   │                      │
│           └───────────────┬───────────────────┘                      │
│                           │                                          │
└───────────────────────────┼──────────────────────────────────────────┘
                            │
                            │ HTTPS/REST + WebSocket (WSS)
                            │
┌───────────────────────────┼──────────────────────────────────────────┐
│                  APPLICATION LAYER (NestJS Backend)                  │
├───────────────────────────┼──────────────────────────────────────────┤
│                           │                                          │
│  ┌────────────────────────▼─────────────────────────┐               │
│  │         API Gateway & Load Balancer              │               │
│  │  (Express + Guards + Interceptors + Throttling)  │               │
│  └────────┬─────────────────────────────┬───────────┘               │
│           │                             │                            │
│  ┌────────▼─────────┐         ┌────────▼────────────┐              │
│  │   REST API       │         │  WebSocket Gateway  │              │
│  │   Controllers    │         │   (Socket.IO)       │              │
│  │                  │         │                     │              │
│  │ • Auth           │         │ • Live Streaming    │              │
│  │ • Users          │         │ • Real-time Chat    │              │
│  │ • Videos         │         │ • Notifications     │              │
│  │ • Groups         │         │ • Presence          │              │
│  │ • Messages       │         └─────────────────────┘              │
│  │ • Calendar       │                                                │
│  │ • Admin          │                                                │
│  └────────┬─────────┘                                                │
│           │                                                          │
│  ┌────────▼──────────────────────────────────────────┐              │
│  │          Business Logic Layer (Services)          │              │
│  │                                                    │              │
│  │  50+ Domain Modules:                              │              │
│  │  • Authentication & Authorization                 │              │
│  │  • User & Profile Management                      │              │
│  │  • Video Processing & Streaming                   │              │
│  │  • Live Streaming Management                      │              │
│  │  • Social Features (Posts, Stories, Reels)        │              │
│  │  • Messaging & Notifications                      │              │
│  │  • Group & Channel Management                     │              │
│  │  • Calendar & Reminders                           │              │
│  │  • Search & Discovery                             │              │
│  │  • Admin & Moderation                             │              │
│  └────────┬──────────────────────────────────────────┘              │
│           │                                                          │
└───────────┼──────────────────────────────────────────────────────────┘
            │
            │ Prisma ORM
            │
┌───────────▼──────────────────────────────────────────────────────────┐
│                     DATA LAYER                                       │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────────┐    ┌──────────────┐    ┌──────────────────┐  │
│  │  Neon PostgreSQL │    │    Redis     │    │   Cloudinary     │  │
│  │                  │    │              │    │                  │  │
│  │  • User Data     │    │ • Cache      │    │ • Video Storage  │  │
│  │  • Content       │    │ • Sessions   │    │ • Image Storage  │  │
│  │  • Relationships │    │ • Pub/Sub    │    │ • Live Streaming │  │
│  │  • 80+ Models    │    │ • Queue      │    │ • HLS Delivery   │  │
│  └──────────────────┘    └──────────────┘    └──────────────────┘  │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────────────┐
│                    EXTERNAL SERVICES                                  │
├───────────────────────────────────────────────────────────────────────┤
│  • Firebase Cloud Messaging (Push Notifications)                     │
│  • Email Service Provider (Verification, Notifications)              │
│  • Analytics Services (Optional)                                     │
└───────────────────────────────────────────────────────────────────────┘
```

### Request Flow Examples

#### **Standard REST API Request**
```
1. Client → HTTPS Request → NestJS API Gateway
2. API Gateway → ThrottlerGuard (rate limiting)
3. API Gateway → JwtAuthGuard (verify JWT token)
4. API Gateway → RolesGuard (check user role)
5. API Gateway → PermissionsGuard (check specific permissions)
6. Controller → Service (business logic)
7. Service → Prisma → Database
8. Database → Prisma → Service
9. Service → Controller → ResponseInterceptor
10. ResponseInterceptor → Client (formatted JSON response)
```

#### **WebSocket Connection & Real-Time Message**
```
1. Client → WSS Connection Request → Socket.IO Gateway
2. Gateway → Verify JWT from handshake
3. Gateway → Establish WebSocket connection
4. Client → Emit event (e.g., send_message)
5. Gateway → Verify permissions for event
6. Gateway → Service (process message)
7. Service → Database (save message)
8. Service → Redis Pub/Sub (broadcast to other servers)
9. Gateway → Emit to recipient(s) (real-time delivery)
10. Optional: Queue push notification if recipient offline
```

---

## Technology Stack

### Backend Technologies

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **Runtime** | Node.js | ≥22 | JavaScript runtime |
| **Framework** | NestJS | 11.x | Backend framework with DI, decorators, modularity |
| **Language** | TypeScript | 6.x | Type-safe JavaScript |
| **Database** | PostgreSQL (Neon) | Latest | Primary data store (cloud-hosted) |
| **ORM** | Prisma | 7.8.x | Type-safe database client |
| **Cache** | Redis | Latest | Caching, sessions, pub/sub, queue |
| **Queue** | BullMQ | 5.x | Background job processing |
| **WebSocket** | Socket.IO | 4.8.x | Real-time bidirectional communication |
| **Auth** | JWT | 9.x | Token-based authentication |
| **Validation** | class-validator | 0.15.x | DTO validation |
| **Password** | bcrypt | 6.x | Password hashing |
| **Media** | Cloudinary | 2.10.x | Video/image storage and streaming |
| **File Upload** | Multer | (via NestJS) | File upload handling |
| **Rate Limiting** | @nestjs/throttler | 6.5.x | API rate limiting |
| **Logging** | Pino | 10.x | High-performance logging |
| **HTTP** | Express | (via NestJS) | HTTP server |

### Frontend Technologies

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **Framework** | Flutter | 3.8+ | Cross-platform UI framework |
| **Language** | Dart | ≥3.8 | Type-safe language for Flutter |
| **State Management** | Riverpod | 2.5.x | Reactive state management |
| **Routing** | go_router | 14.x | Declarative routing |
| **HTTP Client** | Dio | 5.11.x | HTTP requests with interceptors |
| **WebSocket** | socket_io_client | 2.0.x | Real-time communication |
| **Local Storage** | flutter_secure_storage | 10.3.x | Secure credential storage |
| **Local Database** | Drift (SQLite) | 2.30.x | Offline data persistence |
| **Video Player** | video_player | 2.9.x | Video playback |
| **Camera** | camera | 0.11.x | Camera access for live streaming |
| **Live Streaming** | apivideo_live_stream | 1.2.x | RTMP streaming from mobile |
| **Push Notifications** | Firebase Messaging | 16.6.x | FCM integration |
| **Background Tasks** | workmanager | 0.9.x | Background sync |
| **Connectivity** | connectivity_plus | 7.3.x | Network status monitoring |
| **Image Caching** | cached_network_image | 3.4.x | Image caching |
| **Audio** | just_audio | 0.9.x | Audio playback |

### Infrastructure & DevOps

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Database Hosting** | Neon PostgreSQL | Serverless PostgreSQL |
| **Cache/Queue** | Redis Cloud / Upstash | Managed Redis |
| **Media CDN** | Cloudinary | Media storage and delivery |
| **Deployment** | Render / Vercel / Railway | Backend hosting |
| **Version Control** | Git | Source control |
| **Package Manager** | npm (backend), pub (Flutter) | Dependency management |

---

## Backend Architecture

### Module Organization

The NestJS backend is organized into **7 phases** of feature development:

#### **Phase 1: Foundation** (Authentication & Core)
- `AuthModule` - Login, registration, JWT issuance
- `UsersModule` - User CRUD operations
- `RolesModule` - Role management
- `SessionsModule` - Session tracking
- `RefreshTokenModule` - Token refresh mechanism
- `AuthorizationModule` - Permission checking
- `ProfilesModule` - User profile management
- `GroupsModule` - Group creation and management
- `UploadsModule` - File upload handling

#### **Phase 2: Social Features**
- `FollowsModule` - User following/followers
- `PostsModule` - Social posts (text, images)
- `LikesModule` - Liking content
- `CommentsModule` - Commenting on posts
- `StoriesModule` - Temporary stories (24-hour expiry)
- `ReelsModule` - Short-form videos
- `SavedPostsModule` - Bookmarking posts

#### **Phase 3: Messaging Platform**
- `ChannelsModule` - Group channels
- `ConversationsModule` - Direct conversations
- `MessagesModule` - Message CRUD
- `MessagingGatewayModule` - WebSocket gateway for messages
- `NotificationsModule` - Notification system
- `GroupJoinRequestsModule` - Join request management
- `PresenceModule` - Online/offline status

#### **Phase 4: Video Platform**
- `VideoChannelsModule` - Creator channels
- `VideosModule` - Video CRUD and metadata
- `VideoProcessingModule` - Video transcoding/processing (via Cloudinary)
- `VideoPlaylistsModule` - Playlist management
- `VideoCommentsModule` - Video comments
- `VideoSubscriptionsModule` - Channel subscriptions
- `DownloadsModule` - Download tracking

#### **Phase 5: Live Streaming**
- `LiveStreamingModule` - Stream management (RTMP, HLS)
- `StreamChatModule` - Live chat during streams
- `StreamAnalyticsModule` - Viewer analytics
- `StreamProcessingModule` - Stream processing
- `LiveGatewayModule` - WebSocket gateway for live features
- `StreamHighlightsModule` - Stream highlights/clips

#### **Phase 6: Discovery**
- `SearchModule` - Full-text search
- `RecommendationsModule` - Content recommendations
- `TrendingModule` - Trending content algorithm
- `ExploreModule` - Content discovery

#### **Phase 7: Admin & Moderation**
- `AdminModule` - Administrative functions
- `ReportsModule` - Content reporting and moderation

#### **Additional Modules**
- `CalendarModule` - Ethiopian calendar with notes and reminders
- `HealthModule` - Health check endpoint
- `PrismaModule` - Database client (shared)
- `CommonModule` - Shared utilities (guards, decorators, filters)

### Layered Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                       │
│  (Controllers, DTOs, Guards, Interceptors, Filters)         │
├─────────────────────────────────────────────────────────────┤
│  • Controllers: Handle HTTP requests                        │
│  • DTOs: Request/response validation and transformation     │
│  • Guards: Authentication, authorization, rate limiting     │
│  • Interceptors: Response formatting, logging               │
│  • Filters: Global exception handling                       │
└──────────────────┬──────────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────────┐
│                    BUSINESS LOGIC LAYER                      │
│                    (Services, Use Cases)                     │
├─────────────────────────────────────────────────────────────┤
│  • Services: Business logic implementation                  │
│  • Validation: Business rule enforcement                    │
│  • Orchestration: Coordinate multiple operations            │
│  • Event emission: Trigger side effects                     │
└──────────────────┬──────────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────────┐
│                    DATA ACCESS LAYER                         │
│                    (Prisma ORM, Repositories)                │
├─────────────────────────────────────────────────────────────┤
│  • Prisma Client: Type-safe database queries                │
│  • Transaction management                                   │
│  • Relationship loading (eager/lazy)                        │
│  • Query optimization                                       │
└──────────────────┬──────────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────────┐
│                      DATABASE LAYER                          │
│                   (PostgreSQL via Neon)                      │
├─────────────────────────────────────────────────────────────┤
│  • Data persistence                                         │
│  • ACID transactions                                        │
│  • Indexing and optimization                                │
│  • Constraints and relationships                            │
└─────────────────────────────────────────────────────────────┘
```

### Global Middleware & Guards

Applied in order for every request:

1. **ThrottlerGuard** - Rate limiting (100 requests per 60 seconds per IP)
2. **JwtAuthGuard** - JWT token verification (extracts user from token)
3. **RolesGuard** - Role-based access control (checks `@Roles()` decorator)
4. **PermissionsGuard** - Permission-based access control (checks `@Permissions()` decorator)
5. **ResponseInterceptor** - Formats all responses consistently
6. **GlobalExceptionFilter** - Catches and formats all exceptions

### Dependency Injection

NestJS uses **constructor-based dependency injection**:

```typescript
@Injectable()
export class VideosService {
  constructor(
    private readonly prisma: PrismaService,      // Database access
    private readonly cloudinary: CloudinaryService, // Media operations
    private readonly queue: BullQueue,           // Background jobs
    private readonly cache: CacheService,        // Redis cache
  ) {}
  
  async createVideo(dto: CreateVideoDto, userId: string) {
    // Service implementation
  }
}
```

**Benefits**:
- Testability: Easy to mock dependencies
- Loose coupling: Swap implementations without changing consumers
- Lifecycle management: NestJS handles instantiation and cleanup

---

## Frontend Architecture

### Flutter Architecture Pattern

The Flutter app follows **Feature-First Architecture** with **Riverpod** for state management:

```
mobile/lib/
├── core/                      # Core utilities and configuration
│   ├── config/                # App configuration
│   ├── constants/             # Constants and enums
│   ├── error/                 # Error handling
│   ├── network/               # HTTP client (Dio) setup
│   ├── storage/               # Secure storage
│   └── utils/                 # Utility functions
│
├── features/                  # Feature modules (23 total)
│   ├── auth/                  # Authentication
│   │   ├── data/
│   │   │   ├── models/        # Data models
│   │   │   ├── datasources/   # API & local data sources
│   │   │   └── repositories/  # Repository implementations
│   │   ├── domain/
│   │   │   ├── entities/      # Domain entities
│   │   │   └── repositories/  # Repository interfaces
│   │   └── presentation/
│   │       ├── providers/     # Riverpod providers
│   │       ├── screens/       # UI screens
│   │       └── widgets/       # Reusable widgets
│   │
│   ├── home/                  # Home feed
│   ├── explore/               # Content discovery
│   ├── groups/                # Group management
│   ├── chats/                 # Messaging
│   ├── live/                  # Live streaming
│   ├── player/                # Video player
│   ├── profile/               # User profiles
│   ├── stories/               # Stories feature
│   ├── calendar/              # Ethiopian calendar
│   ├── admin/                 # Admin panel
│   └── ...                    # Other features
│
├── shared/                    # Shared widgets and utilities
│   ├── widgets/               # Common widgets
│   └── providers/             # Global providers
│
└── main.dart                  # Application entry point
```

### State Management (Riverpod)

**Providers** manage state and dependencies:

```dart
// Provider for authentication state
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

// Provider for video list
final videosProvider = FutureProvider<List<Video>>((ref) async {
  final repository = ref.watch(videoRepositoryProvider);
  return repository.getVideos();
});

// Usage in widget
class VideoListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(videosProvider);
    
    return videosAsync.when(
      data: (videos) => ListView.builder(...),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(error),
    );
  }
}
```

**Benefits**:
- Reactive: UI rebuilds automatically when state changes
- Testable: Easy to mock providers
- Type-safe: Compile-time type checking
- Memory-safe: Automatic disposal of unused providers

### Routing (go_router)

Declarative routing configuration:

```dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => HomeScreen(),
    ),
    GoRoute(
      path: '/video/:id',
      builder: (context, state) => VideoPlayerScreen(
        videoId: state.params['id']!,
      ),
    ),
    GoRoute(
      path: '/profile/:username',
      builder: (context, state) => ProfileScreen(
        username: state.params['username']!,
      ),
    ),
  ],
  redirect: (context, state) {
    // Authentication guard
    final isAuthenticated = ...;
    if (!isAuthenticated && state.location != '/login') {
      return '/login';
    }
    return null;
  },
);
```

### Local Database (Drift)

SQLite database for offline data:

```dart
// Database schema definition
@DriftDatabase(tables: [
  Users,
  Messages,
  Videos,
  CalendarNotes,
  // ... other tables
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  
  // Queries
  Future<List<Message>> getOfflineMessages() {
    return (select(messages)
      ..where((m) => m.synced.equals(false)))
      .get();
  }
  
  Future<void> saveMessageForSync(Message message) {
    return into(messages).insert(message);
  }
}
```

**Drift Features**:
- Type-safe SQL queries
- Migration support
- Reactive streams (watch queries)
- Cross-platform (iOS, Android, Web)

---

## Database Architecture

### Database Technology

**Neon PostgreSQL** - Serverless PostgreSQL with:
- Auto-scaling
- Branching (instant database copies)
- Automatic backups
- Connection pooling
- Built-in monitoring

### Schema Overview

The database contains **80+ models** organized into domains:

#### **Core Models**
- `User` - User accounts
- `Role` - User roles (SUPER_ADMIN, ADMIN, MODERATOR, SUPPORT, USER)
- `Permission` - Granular permissions (100+ permissions)
- `RolePermission` - Many-to-many relationship
- `Session` - Active user sessions
- `RefreshToken` - Refresh tokens for JWT

#### **Profile & Social**
- `Profile` - Extended user profile information
- `Follow` - Following relationships
- `Post` - Social posts
- `Like` - Likes on various content types
- `Comment` - Comments on posts/videos
- `Story` - Temporary stories (24h expiry)
- `Reel` - Short-form videos
- `SavedPost` - Bookmarked content

#### **Groups & Channels**
- `Group` - User groups (communities)
- `GroupMember` - Group membership with roles
- `GroupRole` - Roles within groups (GROUP_ADMIN, MODERATOR, MEMBER, GUEST)
- `Channel` - Channels within groups
- `ChannelMember` - Channel membership
- `GroupJoinRequest` - Pending join requests

#### **Messaging**
- `Conversation` - Direct message conversations
- `ConversationParticipant` - Participants in conversations
- `Message` - Individual messages
- `MessageRead` - Read receipts
- `MessageReaction` - Emoji reactions on messages

#### **Video Platform**
- `VideoChannel` - Creator channels
- `Video` - Video metadata and URLs
- `VideoView` - View tracking
- `VideoComment` - Comments on videos
- `VideoPlaylist` - Playlists
- `VideoPlaylistItem` - Videos in playlists
- `VideoSubscription` - Channel subscriptions
- `VideoDownload` - Download tracking

#### **Live Streaming**
- `LiveStream` - Active and past streams
- `LiveStreamViewer` - Viewer tracking
- `StreamChat` - Chat messages during live streams
- `StreamReaction` - Floating reactions
- `StreamAnalytics` - Stream performance metrics
- `StreamHighlight` - Saved highlights/clips
- `StreamRecording` - VOD recordings of past streams

#### **Notifications**
- `Notification` - User notifications
- `NotificationPreference` - Per-user notification settings
- `PushSubscription` - FCM device tokens

#### **Calendar**
- `CalendarNote` - Ethiopian calendar notes
- `CalendarReminder` - Reminders for calendar notes

#### **Discovery**
- `SearchHistory` - User search queries
- `Recommendation` - Personalized recommendations
- `TrendingItem` - Trending content tracking

#### **Admin & Moderation**
- `Report` - User-reported content
- `ModerationAction` - Actions taken by moderators
- `AuditLog` - System audit trail

### Database Relationships

**Example: User-centric relationships**
```
User (1) ─────< (many) Session
User (1) ─────< (many) RefreshToken
User (1) ───── (1) Profile
User (1) ─────< (many) Post
User (1) ─────< (many) Video
User (1) ─────< (many) LiveStream
User (1) ─────< (many) GroupMember
User (1) ─────< (many) Message
User (1) ─────< (many) Notification
```

**Example: Group relationships**
```
Group (1) ─────< (many) GroupMember
Group (1) ─────< (many) Channel
Group (1) ─────< (many) Post [group-specific posts]
Group (1) ─────< (many) LiveStream [group-only streams]
```

### Indexing Strategy

Key indexes for performance:

```sql
-- Authentication & session lookups
CREATE INDEX idx_users_email ON "User"(email);
CREATE INDEX idx_users_username ON "User"(username);
CREATE INDEX idx_sessions_userId ON "Session"("userId");
CREATE INDEX idx_refresh_tokens_userId ON "RefreshToken"("userId");

-- Content discovery
CREATE INDEX idx_videos_createdAt ON "Video"("createdAt" DESC);
CREATE INDEX idx_posts_createdAt ON "Post"("createdAt" DESC);
CREATE INDEX idx_livestreams_startedAt ON "LiveStream"("startedAt" DESC);

-- Social features
CREATE INDEX idx_follows_followerId ON "Follow"("followerId");
CREATE INDEX idx_follows_followingId ON "Follow"("followingId");
CREATE INDEX idx_likes_userId ON "Like"("userId");

-- Messaging
CREATE INDEX idx_messages_conversationId ON "Message"("conversationId");
CREATE INDEX idx_messages_senderId ON "Message"("senderId");

-- Group features
CREATE INDEX idx_group_members_groupId ON "GroupMember"("groupId");
CREATE INDEX idx_group_members_userId ON "GroupMember"("userId");
```

### Migration Strategy

**Prisma Migrations** - Version-controlled schema changes:

```bash
# Create migration
npx prisma migrate dev --name add_calendar_reminders

# Apply migration to production
npx prisma migrate deploy
```

**Migration Files**:
- Stored in `backend/prisma/migrations/`
- Each migration has timestamp and descriptive name
- Contains SQL DDL statements
- Applied sequentially in order

---

## Authentication & Authorization

### Authentication Flow

**1. Registration**
```
Client → POST /auth/register
        { username, email, password }
Backend → Validate input
       → Hash password (bcrypt)
       → Create User record
       → Generate JWT access token (15min expiry)
       → Generate refresh token (7d expiry)
       → Return tokens + user info
Client → Store tokens securely (flutter_secure_storage)
```

**2. Login**
```
Client → POST /auth/login
        { username/email, password }
Backend → Find user by username/email
       → Verify password (bcrypt compare)
       → Check failed login attempts (<5)
       → If locked (5+ attempts), return error + lockout time
       → If valid, reset failed attempts
       → Generate JWT access token (15min)
       → Generate refresh token (7d)
       → Create session record
       → Return tokens + user info
Client → Store tokens securely
```

**3. Authenticated Request**
```
Client → GET /videos (with Authorization: Bearer <access_token>)
Backend → JwtAuthGuard extracts token from header
       → Verify token signature & expiry
       → Decode user ID from token
       → Attach user object to request
       → Pass to controller
Controller → Access user via @CurrentUser() decorator
```

**4. Token Refresh**
```
Client → POST /auth/refresh
        { refreshToken }
Backend → Verify refresh token exists in database
       → Check expiry (7 days)
       → Generate new access token (15min)
       → Optional: Rotate refresh token
       → Return new access token
Client → Update stored access token
```

### Authorization Mechanisms

#### **Role-Based Access Control (RBAC)**

**Global Roles** (system-wide):
- `SUPER_ADMIN` - Full system access
- `ADMIN` - Administrative access
- `MODERATOR` - Content moderation
- `SUPPORT` - Support functions
- `USER` - Regular user

**Usage in controllers**:
```typescript
@Post('users/:id/ban')
@Roles('ADMIN', 'MODERATOR')
async banUser(@Param('id') userId: string) {
  // Only admins and moderators can execute
}
```

#### **Permission-Based Access Control (PBAC)**

**100+ Granular Permissions**, e.g.:
- `create:post`
- `delete:own-post`
- `create:livestream`
- `moderate:group`
- `view:admin-panel`

**Usage in controllers**:
```typescript
@Post('livestreams')
@Permissions('create:livestream')
async createLiveStream(@Body() dto: CreateLiveStreamDto) {
  // Only users with 'create:livestream' permission can execute
}
```

#### **Group-Based Access Control**

**Group Roles** (within specific groups):
- `GROUP_ADMIN` - Group owner, full control
- `MODERATOR` - Moderate content, manage members
- `MEMBER` - Full group participation
- `GUEST` - Limited read-only access

**Dynamic permission checking in services**:
```typescript
async createPostInGroup(groupId: string, userId: string, dto: CreatePostDto) {
  // Check if user is group member
  const member = await this.prisma.groupMember.findUnique({
    where: { userId_groupId: { userId, groupId } }
  });
  
  if (!member) throw new ForbiddenException('Not a group member');
  
  // Check if role has permission
  if (member.role === 'GUEST') {
    throw new ForbiddenException('Guests cannot post');
  }
  
  // Proceed with post creation
}
```

### Security Features

**Password Security**:
- **Hashing Algorithm**: bcrypt (cost factor 10)
- **Salt**: Unique per password
- **No plain-text storage**: Only hash stored

**Token Security**:
- **JWT Signature**: HS256 or RS256
- **Short access token expiry**: 15 minutes (limits impact of theft)
- **Refresh token rotation**: Optional, can rotate on each refresh
- **Token revocation**: Refresh tokens stored in DB, can be deleted

**Brute Force Protection**:
- Track failed login attempts per user
- Lockout after 5 failed attempts
- Lockout duration: 15 minutes
- Counter reset on successful login

**Session Management**:
- Track active sessions per user
- Invalidate all sessions on password change
- Optional: Limit concurrent sessions per user

---

## Real-Time Communication

### WebSocket Architecture

**Technology**: Socket.IO over WebSocket (WSS)

**Gateways**:
1. **MessagingGatewayModule** - Real-time messaging
2. **LiveGatewayModule** - Live streaming features

### Socket.IO Setup

**Server Configuration**:
```typescript
@WebSocketGateway({
  cors: { origin: '*' },
  transports: ['websocket', 'polling'],
  namespace: '/live',
})
export class LiveGateway {
  @WebSocketServer()
  server: Server;
  
  constructor(private redisAdapter: RedisAdapter) {
    // Redis adapter for horizontal scaling
    this.server.adapter(redisAdapter);
  }
  
  @SubscribeMessage('join_stream')
  async handleJoinStream(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { streamId: string }
  ) {
    // Join stream room
    client.join(`stream:${data.streamId}`);
    
    // Broadcast new viewer
    this.server.to(`stream:${data.streamId}`).emit('viewer_joined', {
      viewerId: client.data.userId,
    });
  }
}
```

**Client Connection** (Flutter):
```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

IO.Socket socket = IO.io('https://api.example.com/live', <String, dynamic>{
  'transports': ['websocket'],
  'auth': {
    'token': accessToken,
  },
});

socket.on('connect', (_) {
  print('Connected to WebSocket');
  socket.emit('join_stream', {'streamId': '123'});
});

socket.on('chat_message', (data) {
  print('New message: ${data['text']}');
  // Update UI
});

socket.on('disconnect', (_) {
  print('Disconnected');
});
```

### Authentication

**Handshake Authentication**:
```typescript
@WebSocketGateway()
export class LiveGateway implements OnGatewayConnection {
  async handleConnection(client: Socket) {
    try {
      // Extract token from handshake
      const token = client.handshake.auth.token;
      
      // Verify JWT
      const payload = await this.jwtService.verify(token);
      
      // Attach user to socket
      client.data.userId = payload.sub;
      client.data.username = payload.username;
      
      console.log(`User ${payload.username} connected`);
    } catch (error) {
      console.error('WebSocket auth failed', error);
      client.disconnect();
    }
  }
}
```

### Event-Driven Communication

**Server → Client Events** (broadcast):
- `chat_message` - New message in live chat
- `floating_reaction` - Emoji reaction on stream
- `viewer_joined` / `viewer_left` - Viewer tracking
- `viewer_count` - Updated viewer count
- `stream_ended` - Stream ended notification
- `notification` - Real-time notification

**Client → Server Events** (requests):
- `send_message` - Send chat message
- `send_reaction` - Send floating reaction
- `join_stream` - Join stream room
- `leave_stream` - Leave stream room

### Rooms & Namespaces

**Rooms** for targeted broadcasting:
```typescript
// Join user to specific stream room
socket.join(`stream:${streamId}`);

// Broadcast to all in room
this.server.to(`stream:${streamId}`).emit('chat_message', message);

// Broadcast to all except sender
socket.to(`stream:${streamId}`).emit('viewer_joined', data);
```

**Namespaces** for feature separation:
- `/live` - Live streaming features
- `/messaging` - Real-time messaging
- `/notifications` - Real-time notifications

### Horizontal Scaling with Redis

**Redis Adapter** enables multi-server WebSocket:

```typescript
import { createAdapter } from '@socket.io/redis-adapter';
import { createClient } from 'redis';

const pubClient = createClient({ url: 'redis://localhost:6379' });
const subClient = pubClient.duplicate();

await Promise.all([pubClient.connect(), subClient.connect()]);

io.adapter(createAdapter(pubClient, subClient));
```

**How it works**:
1. Server A receives WebSocket message
2. Server A publishes to Redis
3. Redis broadcasts to all servers
4. Server B receives from Redis
5. Server B emits to its connected clients

**Result**: Clients on different servers receive messages seamlessly.

---

## Media Pipeline

### Media Storage Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENT                                  │
│  (Upload video/image from mobile or web)                        │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  │ HTTP POST /uploads
                  │ multipart/form-data
                  │
┌─────────────────▼───────────────────────────────────────────────┐
│                    NESTJS BACKEND                               │
│                                                                 │
│  1. Receive file (Multer middleware)                            │
│  2. Validate file (size, type, dimensions)                      │
│  3. Upload to Cloudinary                                        │
│  4. Receive Cloudinary response (URL, public_id)                │
│  5. Save metadata to database                                   │
│  6. Return response to client                                   │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  │ Cloudinary SDK Upload
                  │
┌─────────────────▼───────────────────────────────────────────────┐
│                      CLOUDINARY                                 │
│                                                                 │
│  • Store original file                                          │
│  • Generate transformations (thumbnails, HLS manifests)         │
│  • Optimize for delivery (compression, format conversion)       │
│  • Serve via CDN (global edge locations)                        │
└─────────────────┬───────────────────────────────────────────────┘
                  │
                  │ CDN delivery (HLS, progressive download)
                  │
┌─────────────────▼───────────────────────────────────────────────┐
│                CLIENT (Playback)                                │
│  • Video Player fetches HLS manifest                            │
│  • Adaptive bitrate streaming                                   │
│  • Caching for offline playback (optional)                      │
└─────────────────────────────────────────────────────────────────┘
```

### Video Upload Flow

**1. Client Side** (Flutter):
```dart
// Pick video from gallery
final XFile? video = await ImagePicker().pickVideo(source: ImageSource.gallery);

// Create multipart request
FormData formData = FormData.fromMap({
  'video': await MultipartFile.fromFile(video.path, filename: 'video.mp4'),
  'title': 'My Video',
  'description': 'Video description',
});

// Upload to backend
final response = await dio.post('/videos', data: formData);
```

**2. Backend Processing**:
```typescript
@Post()
@UseInterceptors(FileInterceptor('video'))
async uploadVideo(
  @UploadedFile() file: Express.Multer.File,
  @Body() dto: CreateVideoDto,
  @CurrentUser() user: User,
) {
  // Validate file
  if (!file) throw new BadRequestException('No file uploaded');
  if (file.size > 500 * 1024 * 1024) {
    throw new BadRequestException('File too large (max 500MB)');
  }
  
  // Upload to Cloudinary
  const cloudinaryResult = await this.cloudinaryService.uploadVideo(file);
  
  // Save to database
  const video = await this.prisma.video.create({
    data: {
      title: dto.title,
      description: dto.description,
      url: cloudinaryResult.secure_url,
      publicId: cloudinaryResult.public_id,
      duration: cloudinaryResult.duration,
      userId: user.id,
    },
  });
  
  // Queue background processing (thumbnail generation, etc.)
  await this.videoProcessingQueue.add('process-video', { videoId: video.id });
  
  return video;
}
```

**3. Cloudinary Processing**:
- Receives video file
- Generates HLS adaptive streaming manifest
- Creates multiple quality versions (360p, 480p, 720p, 1080p)
- Generates thumbnail images
- Optimizes for web delivery
- Returns URLs and metadata

### Video Streaming

**HLS (HTTP Live Streaming)**:
- Adaptive bitrate streaming (switches quality based on bandwidth)
- Chunks video into small segments (typically 6-10 seconds)
- Manifest file (.m3u8) describes available qualities
- Player requests appropriate chunks based on network conditions

**Playback** (Flutter video_player):
```dart
VideoPlayerController controller = VideoPlayerController.network(
  'https://res.cloudinary.com/.../video.m3u8',
);

await controller.initialize();
controller.play();
```

### Live Streaming Flow

**1. Broadcaster Setup** (Flutter mobile):
```dart
// Initialize camera
final CameraController cameraController = CameraController(
  cameras[0],
  ResolutionPreset.high,
);

// Initialize live stream controller
final LiveStreamController liveStreamController = LiveStreamController();

// Start streaming
await liveStreamController.startStreaming(
  streamKey: 'rtmp://rtmp.cloudinary.com/...',
  videoConfig: VideoConfig(bitrate: 2000000, resolution: Resolution.RESOLUTION_720),
);
```

**2. Backend Stream Management**:
```typescript
@Post('start')
async startLiveStream(
  @CurrentUser() user: User,
  @Body() dto: StartLiveStreamDto,
) {
  // Create Cloudinary Live stream
  const cloudinaryStream = await this.cloudinaryService.createLiveStream({
    name: dto.title,
  });
  
  // Save to database
  const stream = await this.prisma.liveStream.create({
    data: {
      title: dto.title,
      description: dto.description,
      userId: user.id,
      cloudinaryAssetId: cloudinaryStream.asset_id,
      rtmpUrl: cloudinaryStream.rtmp_url,
      hlsUrl: cloudinaryStream.hls_url,
      status: 'PENDING',
      startedAt: new Date(),
    },
  });
  
  // Return RTMP ingest URL to client
  return {
    streamId: stream.id,
    rtmpUrl: cloudinaryStream.rtmp_url,
    streamKey: cloudinaryStream.stream_key,
  };
}
```

**3. RTMP Ingest**:
- Client streams via RTMP to Cloudinary
- Cloudinary receives RTMP stream
- Transcodes in real-time
- Generates HLS manifest for viewers

**4. Viewer Playback**:
- Backend provides HLS URL
- Viewer's player fetches HLS manifest
- Adaptive streaming delivers video
- Typically 10-30 second latency

**5. Real-Time Chat**:
- WebSocket connection for chat messages
- Floating reactions via WebSocket events
- Viewer count updates

**6. Stream End**:
- Broadcaster stops stream
- Backend marks stream as ended
- Cloudinary automatically creates VOD (Video On Demand) from recording
- VOD available for replay

### Thumbnail Generation

**Background Job** (BullMQ):
```typescript
@Process('generate-thumbnail')
async handleThumbnailGeneration(job: Job<{ videoId: string }>) {
  const video = await this.prisma.video.findUnique({
    where: { id: job.data.videoId },
  });
  
  // Generate thumbnail via Cloudinary transformation
  const thumbnailUrl = this.cloudinaryService.generateThumbnail(
    video.publicId,
    { width: 1280, height: 720, crop: 'fill' }
  );
  
  // Update video with thumbnail
  await this.prisma.video.update({
    where: { id: video.id },
    data: { thumbnailUrl },
  });
}
```

---

## Offline & Sync Strategy

### Mobile Offline Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    FLUTTER APPLICATION                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │           UI Layer (Screens & Widgets)                    │ │
│  └───────────────┬───────────────────────────────────────────┘ │
│                  │                                               │
│  ┌───────────────▼───────────────────────────────────────────┐ │
│  │        State Management (Riverpod Providers)              │ │
│  └───────────────┬───────────────────────────────────────────┘ │
│                  │                                               │
│  ┌───────────────▼───────────────────────────────────────────┐ │
│  │             Repository Layer                              │ │
│  │  (Coordinates between remote and local data sources)      │ │
│  └─────┬───────────────────────────────────────────────┬─────┘ │
│        │                                               │         │
│  ┌─────▼─────────────┐                    ┌──────────▼───────┐ │
│  │  Remote Data      │                    │  Local Data      │ │
│  │  Source (API)     │                    │  Source (Drift)  │ │
│  │                   │                    │                  │ │
│  │  • Dio HTTP       │                    │  • SQLite DB     │ │
│  │  • Socket.IO      │                    │  • Cached data   │ │
│  └───────────────────┘                    └──────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Offline-First Features

**What Works Offline**:
1. ✅ View downloaded videos
2. ✅ Read cached messages and posts
3. ✅ Browse cached profiles and groups
4. ✅ View calendar with notes
5. ✅ Create calendar notes (synced later)
6. ✅ Compose messages (queued for sending)
7. ✅ View notifications (already received)

**What Requires Internet**:
1. ❌ Stream videos (not downloaded)
2. ❌ Live streaming (broadcaster and viewer)
3. ❌ Real-time chat
4. ❌ Send messages immediately
5. ❌ Upload content
6. ❌ Search (server-side search)

### Sync Strategy

**Background Sync Schedule**:
- **Interval**: Every 15 minutes
- **Triggered by**: WorkManager (Android), Background Tasks (iOS)
- **Connectivity check**: Only syncs when online

**Sync Operations**:

1. **Upload Queued Actions**:
   ```dart
   // Fetch queued messages from local DB
   final queuedMessages = await db.getUnsentMessages();
   
   for (final message in queuedMessages) {
     try {
       // Send to server
       await api.sendMessage(message);
       
       // Mark as synced
       await db.markMessageAsSent(message.id);
     } catch (e) {
       // Keep in queue for next sync
       print('Failed to sync message: $e');
     }
   }
   ```

2. **Download New Data**:
   ```dart
   // Fetch latest messages since last sync
   final lastSyncTime = await prefs.getLastSyncTime();
   final newMessages = await api.getMessagesSince(lastSyncTime);
   
   // Save to local DB
   for (final message in newMessages) {
     await db.insertMessage(message);
   }
   
   // Update last sync time
   await prefs.setLastSyncTime(DateTime.now());
   ```

3. **Resolve Conflicts** (if any):
   ```dart
   // Simple conflict resolution: Server wins
   // More complex strategies (e.g., CRDTs) can be implemented if needed
   ```

### Offline Data Storage

**Drift Database Schema** (simplified):
```dart
@DataClassName('LocalMessage')
class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().nullable()();  // Null until synced
  TextColumn get conversationId => text()();
  TextColumn get senderId => text()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  BoolColumn get sent => boolean().withDefault(const Constant(false))();
}

@DataClassName('LocalVideo')
class DownloadedVideos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get videoId => text()();
  TextColumn get title => text()();
  TextColumn get localPath => text()();  // Path to downloaded file
  DateTimeColumn get downloadedAt => dateTime()();
  IntColumn get fileSizeBytes => integer()();
}

@DataClassName('LocalCalendarNote')
class CalendarNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().nullable()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  DateTimeColumn get date => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
}
```

### Connectivity Monitoring

```dart
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  
  Stream<bool> get isOnline {
    return _connectivity.onConnectivityChanged.map((result) {
      return result != ConnectivityResult.none;
    });
  }
  
  Future<bool> checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}

// Usage in repository
class MessageRepository {
  Future<void> sendMessage(Message message) async {
    if (await connectivityService.checkConnection()) {
      // Online: Send immediately
      await api.sendMessage(message);
    } else {
      // Offline: Queue for later
      await localDb.queueMessage(message);
    }
  }
}
```

### Download Management

**Video Downloads**:
```dart
class DownloadService {
  Future<void> downloadVideo(String videoId) async {
    // Get video metadata
    final video = await api.getVideo(videoId);
    
    // Check storage availability
    final availableSpace = await getAvailableSpace();
    if (availableSpace < video.fileSizeBytes) {
      throw InsufficientStorageException();
    }
    
    // Download file
    final localPath = await _downloadFile(video.url, videoId);
    
    // Save to local DB
    await db.saveDownloadedVideo(
      videoId: videoId,
      title: video.title,
      localPath: localPath,
      fileSizeBytes: video.fileSizeBytes,
    );
  }
  
  Future<String> _downloadFile(String url, String videoId) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/downloads/$videoId.mp4';
    
    await dio.download(
      url,
      filePath,
      onReceiveProgress: (received, total) {
        final progress = (received / total * 100).toStringAsFixed(0);
        print('Download progress: $progress%');
      },
    );
    
    return filePath;
  }
}
```

---

## Caching Strategy

### Redis Caching Layers

**1. Session Caching**:
```typescript
// Store session data in Redis
await cacheManager.set(`session:${userId}`, sessionData, 900000); // 15 min TTL

// Retrieve session
const session = await cacheManager.get(`session:${userId}`);
```

**2. Data Caching**:
```typescript
// Cache frequently accessed data
await cacheManager.set(`user:${userId}`, userData, 3600000); // 1 hour TTL

// Cache trending content
await cacheManager.set('trending:videos', trendingVideos, 1800000); // 30 min TTL
```

**3. Query Result Caching**:
```typescript
@Injectable()
export class VideosService {
  async getPopularVideos() {
    const cacheKey = 'videos:popular';
    
    // Check cache first
    const cached = await this.cacheManager.get(cacheKey);
    if (cached) return cached;
    
    // Query database
    const videos = await this.prisma.video.findMany({
      where: { published: true },
      orderBy: { viewCount: 'desc' },
      take: 50,
    });
    
    // Store in cache
    await this.cacheManager.set(cacheKey, videos, 300000); // 5 min TTL
    
    return videos;
  }
}
```

### Cache Invalidation

**Time-based expiration** (TTL):
- Short TTL (1-5 min): Trending, recommendations
- Medium TTL (15-30 min): User profiles, group data
- Long TTL (1-24 hours): Static content, configuration

**Event-based invalidation**:
```typescript
async updateUserProfile(userId: string, dto: UpdateProfileDto) {
  // Update database
  const updated = await this.prisma.user.update({
    where: { id: userId },
    data: dto,
  });
  
  // Invalidate cache
  await this.cacheManager.del(`user:${userId}`);
  
  return updated;
}
```

### Client-Side Caching (Flutter)

**Image Caching**:
```dart
CachedNetworkImage(
  imageUrl: 'https://example.com/image.jpg',
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
  cacheManager: CustomCacheManager.instance,
);
```

**HTTP Response Caching** (Dio interceptor):
```dart
class CacheInterceptor extends Interceptor {
  final CacheManager cacheManager;
  
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Check if response is cached
    final cacheKey = options.uri.toString();
    final cached = await cacheManager.get(cacheKey);
    
    if (cached != null) {
      // Return cached response
      return handler.resolve(Response(
        requestOptions: options,
        data: cached,
        statusCode: 200,
      ));
    }
    
    handler.next(options);
  }
  
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    // Cache successful responses
    if (response.statusCode == 200) {
      final cacheKey = response.requestOptions.uri.toString();
      await cacheManager.put(cacheKey, response.data, Duration(minutes: 15));
    }
    
    handler.next(response);
  }
}
```

---

## Queue Management

### BullMQ Architecture

**Job Queues** for asynchronous processing:

```typescript
// Queue registration
BullModule.registerQueue(
  { name: 'video-processing' },
  { name: 'notifications' },
  { name: 'email' },
  { name: 'analytics' },
)

// Job producer (add job to queue)
@Injectable()
export class VideosService {
  constructor(
    @InjectQueue('video-processing') private videoQueue: Queue,
  ) {}
  
  async uploadVideo(file: Express.Multer.File) {
    // ... save video to Cloudinary ...
    
    // Queue background processing
    await this.videoQueue.add('process-video', {
      videoId: video.id,
      publicId: video.publicId,
    }, {
      attempts: 3,
      backoff: { type: 'exponential', delay: 5000 },
    });
    
    return video;
  }
}

// Job consumer (process jobs)
@Processor('video-processing')
export class VideoProcessingConsumer {
  @Process('process-video')
  async handleVideoProcessing(job: Job<{ videoId: string; publicId: string }>) {
    const { videoId, publicId } = job.data;
    
    // Generate thumbnail
    const thumbnailUrl = await this.generateThumbnail(publicId);
    
    // Extract metadata
    const metadata = await this.extractMetadata(publicId);
    
    // Update database
    await this.prisma.video.update({
      where: { id: videoId },
      data: { thumbnailUrl, duration: metadata.duration },
    });
    
    // Trigger next job (e.g., generate preview)
    await job.queue.add('generate-preview', { videoId });
  }
}
```

### Job Types

**1. Video Processing**:
- Thumbnail generation
- Metadata extraction
- Preview clip generation
- Transcoding (handled by Cloudinary)

**2. Notifications**:
- Push notification delivery (FCM)
- Email notifications
- In-app notification creation

**3. Analytics**:
- View count aggregation
- Trending content calculation
- Recommendation updates

**4. Scheduled Tasks**:
- Story expiration (delete 24-hour stories)
- Session cleanup (remove expired sessions)
- Cache warming (pre-populate popular content)

### Error Handling & Retry Logic

```typescript
await queue.add('send-notification', data, {
  attempts: 3,                                    // Retry up to 3 times
  backoff: { type: 'exponential', delay: 5000 }, // 5s, 25s, 125s
  removeOnComplete: true,                         // Remove completed jobs
  removeOnFail: false,                            // Keep failed jobs for debugging
});
```

---

## API Design

### REST API Conventions

**Base URL**: `https://api.example.com/v1`

**HTTP Methods**:
- `GET` - Retrieve resource(s)
- `POST` - Create resource
- `PATCH` / `PUT` - Update resource
- `DELETE` - Delete resource

**Response Format**:
```json
{
  "success": true,
  "data": { ... },
  "message": "Operation successful",
  "timestamp": "2026-09-25T10:30:00Z"
}
```

**Error Response**:
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": [
      { "field": "email", "message": "Invalid email format" }
    ]
  },
  "timestamp": "2026-09-25T10:30:00Z"
}
```

### API Versioning

**URL versioning**: `/v1/`, `/v2/`

**Benefits**:
- Clear version identification
- Easy to route different versions
- Deprecation path clear

### Pagination

**Cursor-based pagination** (recommended for large datasets):
```typescript
GET /videos?cursor=abc123&limit=20

Response:
{
  "data": [...],
  "pagination": {
    "nextCursor": "xyz789",
    "hasMore": true,
    "limit": 20
  }
}
```

**Offset-based pagination** (simpler, for smaller datasets):
```typescript
GET /posts?page=2&limit=20

Response:
{
  "data": [...],
  "pagination": {
    "page": 2,
    "limit": 20,
    "total": 150,
    "totalPages": 8
  }
}
```

### Rate Limiting

**Throttler Configuration**:
- **Global limit**: 100 requests per 60 seconds per IP
- **Endpoint-specific overrides** possible

```typescript
@Throttle({ default: { limit: 10, ttl: 60000 } })  // 10 req/min
@Post('login')
async login() { ... }
```

### API Documentation

**Swagger/OpenAPI** (auto-generated):
- Accessible at `/api/docs`
- Interactive API explorer
- Type definitions from DTOs

```typescript
@ApiTags('videos')
@Controller('videos')
export class VideosController {
  @ApiOperation({ summary: 'Get all videos' })
  @ApiResponse({ status: 200, description: 'Videos retrieved successfully' })
  @Get()
  async findAll() { ... }
}
```

---

## Security Architecture

### Security Layers

**1. Network Security**:
- HTTPS/TLS encryption for all traffic
- WSS (WebSocket Secure) for real-time connections
- CORS configuration (whitelist allowed origins)
- Helmet middleware (security headers)

**2. Authentication Security**:
- JWT with short expiry (15 min access, 7 day refresh)
- Bcrypt password hashing (cost factor 10)
- Brute force protection (5 attempts, 15 min lockout)
- Session tracking and invalidation

**3. Authorization Security**:
- Role-Based Access Control (RBAC)
- Permission-Based Access Control (PBAC)
- Group-level access control
- Resource ownership verification

**4. Input Validation**:
- class-validator DTOs on all inputs
- SQL injection prevention (Prisma parameterized queries)
- XSS prevention (output escaping)
- File upload validation (type, size)

**5. Rate Limiting**:
- Throttler guard (100 req/60s global)
- Endpoint-specific limits
- IP-based tracking

**6. Data Security**:
- Database encryption at rest (Neon)
- Sensitive data encryption in transit
- PII handling compliance
- Secure token storage (client-side)

### Security Headers (Helmet)

```typescript
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", 'data:', 'https://res.cloudinary.com'],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
  },
}));
```

### Secure Practices

**Environment Variables**:
- Never commit secrets to Git
- Use `.env` file (ignored in .gitignore)
- Rotate secrets regularly

**Logging**:
- Never log sensitive data (passwords, tokens)
- Log security events (failed logins, permission denials)
- Structured logging with Pino

**Error Handling**:
- Don't expose stack traces in production
- Generic error messages to clients
- Detailed logs server-side

---

## Scalability Considerations

### Horizontal Scaling

**Stateless Backend**:
- No server-side session storage (JWT tokens)
- State stored in Redis (shared across servers)
- Enables multiple backend instances

**Load Balancing**:
- Distribute requests across multiple servers
- Health check endpoint (`/health`) for load balancer
- Sticky sessions not required (stateless)

**WebSocket Scaling**:
- Redis adapter for Socket.IO
- Pub/Sub pattern for cross-server communication
- Clients can connect to any server

### Database Scaling

**Read Replicas** (Neon PostgreSQL):
- Read queries distributed to replicas
- Write queries to primary
- Eventual consistency acceptable for most reads

**Connection Pooling**:
- Prisma connection pooling
- Neon serverless driver with connection pooling
- Prevents connection exhaustion

**Caching**:
- Redis cache layer
- Reduces database load
- Faster response times

### Performance Optimization

**Lazy Loading**:
- Pagination on large datasets
- On-demand data fetching
- Infinite scroll on mobile

**Eager Loading** (when needed):
```typescript
// Load user with profile and role in single query
const user = await prisma.user.findUnique({
  where: { id: userId },
  include: {
    profile: true,
    role: { include: { permissions: true } },
  },
});
```

**Query Optimization**:
- Proper indexing
- Avoid N+1 queries
- Use `select` to fetch only needed fields

**CDN for Media**:
- Cloudinary global CDN
- Edge caching
- Reduced latency

---

## Deployment Architecture

### Production Environment

```
┌───────────────────────────────────────────────────────────────┐
│                          USERS                                │
└────────────────────────┬──────────────────────────────────────┘
                         │
                         │ HTTPS/WSS
                         │
┌────────────────────────▼──────────────────────────────────────┐
│                   LOAD BALANCER                               │
│               (Nginx, AWS ALB, etc.)                          │
└────────────┬────────────────────────────┬─────────────────────┘
             │                            │
   ┌─────────▼─────────┐       ┌─────────▼─────────┐
   │  Backend Server 1 │       │  Backend Server 2 │
   │    (NestJS)       │       │    (NestJS)       │
   └─────────┬─────────┘       └─────────┬─────────┘
             │                            │
             └────────────┬───────────────┘
                          │
            ┌─────────────┴──────────────┐
            │                            │
   ┌────────▼─────────┐       ┌─────────▼────────────┐
   │  Redis (Cache,   │       │  Neon PostgreSQL     │
   │  Queue, Pub/Sub) │       │    (Database)        │
   └──────────────────┘       └──────────────────────┘
```

### Deployment Platforms

**Backend Options**:
- **Render**: Easy deployment, auto-scaling, free tier
- **Railway**: Simple, affordable, good for small-medium apps
- **Heroku**: Well-known, extensive add-ons
- **AWS ECS/Fargate**: Enterprise-grade, full control
- **DigitalOcean App Platform**: Balanced simplicity and power

**Database**:
- **Neon PostgreSQL**: Serverless, auto-scaling, branching

**Redis**:
- **Upstash**: Serverless Redis, pay-per-request
- **Redis Cloud**: Managed Redis, free tier available

**Media**:
- **Cloudinary**: Automatic, already integrated

**Mobile Apps**:
- **Google Play Store**: Android distribution
- **Apple App Store**: iOS distribution
- **Web**: Static hosting (Vercel, Netlify, Cloudflare Pages)

### CI/CD Pipeline

**Example with GitHub Actions**:
```yaml
name: Deploy Backend

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '22'
      
      - name: Install dependencies
        run: npm ci
        working-directory: ./backend
      
      - name: Build
        run: npm run build
        working-directory: ./backend
      
      - name: Run tests
        run: npm test
        working-directory: ./backend
      
      - name: Deploy to Render
        run: |
          curl -X POST ${{ secrets.RENDER_DEPLOY_HOOK }}
```

### Environment Configuration

**Backend** (`.env`):
```bash
# Database
DATABASE_URL=postgresql://user:pass@host:5432/db

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT
JWT_SECRET=your-secret-key
JWT_ACCESS_TOKEN_EXPIRY=15m
JWT_REFRESH_TOKEN_EXPIRY=7d

# Cloudinary
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret

# Firebase
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-private-key

# App
NODE_ENV=production
PORT=3000
```

**Flutter** (`.env`):
```bash
API_BASE_URL=https://api.example.com/v1
WS_URL=https://api.example.com
CLOUDINARY_CLOUD_NAME=your-cloud-name
```

---

## Monitoring & Observability

### Logging

**Pino Logger** (high-performance structured logging):
```typescript
private readonly logger = new Logger(VideoService.name);

async uploadVideo(file: Express.Multer.File) {
  this.logger.log('Video upload initiated', { 
    filename: file.originalname,
    size: file.size 
  });
  
  try {
    // ... upload logic ...
    this.logger.log('Video uploaded successfully', { videoId: video.id });
  } catch (error) {
    this.logger.error('Video upload failed', error.stack, { 
      filename: file.originalname 
    });
    throw error;
  }
}
```

### Health Checks

```typescript
@Controller('health')
export class HealthController {
  constructor(
    private health: HealthCheckService,
    private db: PrismaHealthIndicator,
    private redis: RedisHealthIndicator,
  ) {}
  
  @Get()
  @Public()
  @HealthCheck()
  check() {
    return this.health.check([
      () => this.db.pingCheck('database'),
      () => this.redis.pingCheck('redis'),
    ]);
  }
}
```

### Metrics

**Application Metrics** (can integrate Prometheus):
- Request rate (req/sec)
- Response time (p50, p95, p99)
- Error rate
- Active connections (WebSocket)

**Business Metrics**:
- Active users
- Video uploads per day
- Live streams active
- Messages sent per day

### Error Tracking

**Integration Options**:
- **Sentry**: Error tracking and performance monitoring
- **LogRocket**: Session replay and error tracking
- **Datadog**: Full observability platform

---

## Summary

**Zikire Kdusan** is a modern, scalable video streaming and social platform built with:

- **Backend**: NestJS (Node.js/TypeScript) with 50+ modular services
- **Frontend**: Flutter (Dart) for cross-platform mobile and web
- **Database**: Neon PostgreSQL with Prisma ORM (80+ models)
- **Caching**: Redis for sessions, cache, queues, and pub/sub
- **Media**: Cloudinary for video/image storage and live streaming
- **Real-time**: Socket.IO for WebSocket communication
- **Authentication**: JWT with bcrypt, RBAC/PBAC authorization
- **Offline**: SQLite (Drift) with 15-minute background sync

**Key architectural strengths**:
- ✅ Modular and maintainable codebase
- ✅ Scalable horizontally (stateless design)
- ✅ Secure by default (authentication, authorization, validation at every layer)
- ✅ Offline-capable mobile app
- ✅ Real-time features (live streaming, chat, notifications)
- ✅ Type-safe end-to-end (TypeScript + Dart)

---

**Document Version**: 1.0  
**Last Updated**: Based on implementation audit September 2026  
**Related Documentation**: API.md, DATABASE.md, REALTIME_AND_LIVE.md, DEVELOPMENT.md, DEPLOYMENT.md
