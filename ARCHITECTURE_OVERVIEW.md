# Architecture Overview - ዝክረ ክዱሳን (StreamHub)

**Enterprise-Grade Social Media & Video Streaming Platform**

---

## 🏗️ System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CLIENT LAYER                                    │
│                                                                              │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐  ┌──────────────┐│
│  │   Flutter     │  │   Flutter     │  │   Flutter     │  │   Flutter    ││
│  │   Mobile      │  │   Tablet      │  │     Web       │  │   Desktop    ││
│  │   (iOS/Android│  │               │  │    (PWA)      │  │  (Win/Mac)   ││
│  └───────┬───────┘  └───────┬───────┘  └───────┬───────┘  └──────┬───────┘│
│          │                  │                  │                  │         │
│          └──────────────────┴──────────────────┴──────────────────┘         │
│                                     │                                        │
│                        ┌────────────▼────────────┐                          │
│                        │  Offline-First Layer    │                          │
│                        │  ┌────────────────────┐ │                          │
│                        │  │  Drift SQLite DB   │ │                          │
│                        │  │  - 9 Local Tables  │ │                          │
│                        │  │  - Sync Queue      │ │                          │
│                        │  │  - WAL Mode        │ │                          │
│                        │  └────────────────────┘ │                          │
│                        │  ┌────────────────────┐ │                          │
│                        │  │   Sync Manager     │ │                          │
│                        │  │  - Delta Sync      │ │                          │
│                        │  │  - Retry Logic     │ │                          │
│                        │  │  - Workmanager     │ │                          │
│                        │  └────────────────────┘ │                          │
│                        └─────────────────────────┘                          │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                         ┌─────────────▼─────────────┐
                         │      NETWORK LAYER        │
                         │  ┌────────┐  ┌─────────┐ │
                         │  │  HTTPS │  │WebSocket│ │
                         │  │  REST  │  │Socket.IO│ │
                         │  └────────┘  └─────────┘ │
                         └─────────────┬─────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                            APPLICATION LAYER                                 │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                        NestJS Backend Server                           │ │
│  │                                                                        │ │
│  │  ┌──────────────────────────────────────────────────────────────────┐ │ │
│  │  │                     API Gateway & Middleware                     │ │ │
│  │  │  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐   │ │ │
│  │  │  │ Helmet │  │ CORS   │  │ Rate   │  │ Authen │  │Validate│   │ │ │
│  │  │  │Security│  │ Policy │  │ Limit  │  │ JWT    │  │  Pipe  │   │ │ │
│  │  │  └────────┘  └────────┘  └────────┘  └────────┘  └────────┘   │ │ │
│  │  └──────────────────────────────────────────────────────────────────┘ │ │
│  │                                                                        │ │
│  │  ┌──────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    REST API Controllers (43 Modules)              │ │ │
│  │  │                                                                   │ │ │
│  │  │  ┌────────┐ ┌────────┐ ┌─────────┐ ┌────────┐ ┌──────────┐     │ │ │
│  │  │  │  Auth  │ │ Posts  │ │Messages │ │ Videos │ │  Groups  │ ... │ │ │
│  │  │  │        │ │        │ │         │ │        │ │          │     │ │ │
│  │  │  └────┬───┘ └────┬───┘ └────┬────┘ └────┬───┘ └────┬─────┘     │ │ │
│  │  │       │          │          │           │          │            │ │ │
│  │  │       └──────────┴──────────┴───────────┴──────────┘            │ │ │
│  │  └───────────────────────────────┬──────────────────────────────────┘ │ │
│  │                                  │                                     │ │
│  │  ┌───────────────────────────────▼─────────────────────────────────┐  │ │
│  │  │                      Business Logic Layer                        │  │ │
│  │  │                        (Services)                                │  │ │
│  │  │  - Domain Logic                                                  │  │ │
│  │  │  - Use Cases                                                     │  │ │
│  │  │  - Data Validation                                               │  │ │
│  │  │  - Business Rules                                                │  │ │
│  │  └───────────────────────────────┬─────────────────────────────────┘  │ │
│  │                                  │                                     │ │
│  │  ┌───────────────────────────────▼─────────────────────────────────┐  │ │
│  │  │                       Data Access Layer                          │  │ │
│  │  │                         (Prisma ORM)                             │  │ │
│  │  │  - Query Building                                                │  │ │
│  │  │  - Transaction Management                                        │  │ │
│  │  │  - Relationships                                                 │  │ │
│  │  │  - Type Safety                                                   │  │ │
│  │  └───────────────────────────────┬─────────────────────────────────┘  │ │
│  └──────────────────────────────────┼────────────────────────────────────┘ │
│                                     │                                       │
│  ┌──────────────────────────────────▼────────────────────────────────────┐ │
│  │                    WebSocket Gateway (Socket.IO)                      │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │ │
│  │  │  Messaging   │  │    Live      │  │   Presence   │               │ │
│  │  │   Gateway    │  │  Stream      │  │   Gateway    │               │ │
│  │  │              │  │  Gateway     │  │              │               │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘               │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                    Background Job Processing                          │  │
│  │  ┌──────────────────────────────────────────────────────────────────┐│  │
│  │  │                         BullMQ Queue                             ││  │
│  │  │  ┌─────────────────┐  ┌──────────────────┐  ┌────────────────┐ ││  │
│  │  │  │ Video Transcode │  │ Push Notification│  │  Email Queue   │ ││  │
│  │  │  │     Worker      │  │     Worker       │  │    Worker      │ ││  │
│  │  │  └─────────────────┘  └──────────────────┘  └────────────────┘ ││  │
│  │  └──────────────────────────────────────────────────────────────────┘│  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                              DATA LAYER                                      │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                      PostgreSQL Database (Neon)                        │ │
│  │                                                                        │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │ │
│  │  │    Users     │  │    Posts     │  │  Messages    │               │ │
│  │  │    Roles     │  │   Stories    │  │Conversations │               │ │
│  │  │  Sessions    │  │    Reels     │  │   Channels   │               │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘               │ │
│  │                                                                        │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │ │
│  │  │   Videos     │  │    Groups    │  │    Reports   │               │ │
│  │  │  Channels    │  │   Members    │  │    Blocks    │               │ │
│  │  │  Playlists   │  │ Permissions  │  │Notifications │               │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘               │ │
│  │                                                                        │ │
│  │  40+ Tables | Complex Relationships | Full ACID Compliance            │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                      Redis Cache & Pub/Sub                             │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                │ │
│  │  │  Session     │  │   Socket.IO  │  │    Queue     │                │ │
│  │  │   Cache      │  │   Adapter    │  │   Results    │                │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘                │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                          EXTERNAL SERVICES                                   │
│                                                                              │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐               │
│  │   Cloudinary   │  │    Firebase    │  │      S3        │               │
│  │   Media CDN    │  │      FCM       │  │   (Optional)   │               │
│  │   Transcoding  │  │Push Notification│  │  File Storage  │               │
│  └────────────────┘  └────────────────┘  └────────────────┘               │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Data Flow Patterns

### 1. User Authentication Flow

```
┌──────────┐                 ┌──────────┐                 ┌──────────┐
│  Mobile  │                 │ Backend  │                 │PostgreSQL│
│   App    │                 │   API    │                 │ Database │
└────┬─────┘                 └────┬─────┘                 └────┬─────┘
     │                            │                            │
     │ POST /auth/register        │                            │
     │ {email, password}          │                            │
     ├───────────────────────────►│                            │
     │                            │                            │
     │                            │ Hash password (bcrypt)     │
     │                            │                            │
     │                            │ INSERT user                │
     │                            ├───────────────────────────►│
     │                            │                            │
     │                            │◄───────────────────────────┤
     │                            │ user record                │
     │                            │                            │
     │                            │ Generate JWT tokens        │
     │                            │ - Access (15m)             │
     │                            │ - Refresh (7d)             │
     │                            │                            │
     │                            │ INSERT session             │
     │                            ├───────────────────────────►│
     │                            │                            │
     │◄───────────────────────────┤                            │
     │ {accessToken, refreshToken,│                            │
     │  user}                     │                            │
     │                            │                            │
     │ Store tokens securely      │                            │
     │ (FlutterSecureStorage)     │                            │
     │                            │                            │
     │                            │                            │
     │ GET /users/me              │                            │
     │ Authorization: Bearer xxx  │                            │
     ├───────────────────────────►│                            │
     │                            │                            │
     │                            │ Verify JWT signature       │
     │                            │ Check expiry               │
     │                            │                            │
     │                            │ SELECT user WHERE id=      │
     │                            ├───────────────────────────►│
     │                            │                            │
     │                            │◄───────────────────────────┤
     │◄───────────────────────────┤                            │
     │ {user profile data}        │                            │
     │                            │                            │
```

---

### 2. Offline-First Post Creation Flow

```
┌──────────┐         ┌──────────┐         ┌──────────┐         ┌──────────┐
│   UI     │         │ Provider │         │  Local   │         │ Backend  │
│  Layer   │         │ (Riverpod│         │   DB     │         │   API    │
└────┬─────┘         └────┬─────┘         └────┬─────┘         └────┬─────┘
     │                    │                    │                    │
     │ User taps "Post"   │                    │                    │
     ├───────────────────►│                    │                    │
     │                    │                    │                    │
     │                    │ Generate clientId  │                    │
     │                    │ (UUID v4)          │                    │
     │                    │                    │                    │
     │                    │ INSERT post        │                    │
     │                    │ isPendingSync=true │                    │
     │                    ├───────────────────►│                    │
     │                    │                    │                    │
     │◄───────────────────┤                    │                    │
     │ Show post instantly│                    │                    │
     │ (with pending icon)│                    │                    │
     │                    │                    │                    │
     │                    │                    │ INSERT sync_queue  │
     │                    │                    │ operationType:     │
     │                    │                    │ 'CREATE_POST'      │
     │                    ├───────────────────►│                    │
     │                    │                    │                    │
     │                    │ SyncManager        │                    │
     │                    │ processes queue    │                    │
     │                    │                    │                    │
     │                    │                    │ SELECT pending     │
     │                    │                    │ operations         │
     │                    │◄───────────────────┤                    │
     │                    │                    │                    │
     │                    │ POST /posts        │                    │
     │                    │ {clientId, ...}    │                    │
     │                    ├───────────────────────────────────────►│
     │                    │                    │                    │
     │                    │                    │                    │ Check
     │                    │                    │                    │ existing
     │                    │                    │                    │ clientId
     │                    │                    │                    │
     │                    │◄───────────────────────────────────────┤
     │                    │ {serverId, ...}    │                    │
     │                    │                    │                    │
     │                    │ UPDATE post        │                    │
     │                    │ serverId = response│                    │
     │                    │ isPendingSync=false│                    │
     │                    ├───────────────────►│                    │
     │                    │                    │                    │
     │                    │ DELETE from        │                    │
     │                    │ sync_queue         │                    │
     │                    ├───────────────────►│                    │
     │                    │                    │                    │
     │◄───────────────────┤                    │                    │
     │ Update UI          │                    │                    │
     │ (remove pending)   │                    │                    │
     │                    │                    │                    │
```

---

### 3. Real-Time Messaging Flow

```
┌──────────┐         ┌──────────┐         ┌──────────┐         ┌──────────┐
│ User A   │         │Socket.IO │         │ Backend  │         │ User B   │
│ Client   │         │ Gateway  │         │ Service  │         │ Client   │
└────┬─────┘         └────┬─────┘         └────┬─────┘         └────┬─────┘
     │                    │                    │                    │
     │ connect()          │                    │                    │
     ├───────────────────►│                    │                    │
     │                    │                    │                    │
     │                    │ Verify JWT         │                    │
     │                    │                    │                    │
     │                    │ Join room          │                    │
     │                    │ "conversation:123" │                    │
     │                    │                    │                    │
     │ emit('send_message'│                    │                    │
     │ {conversationId,   │                    │                    │
     │  content})         │                    │                    │
     ├───────────────────►│                    │                    │
     │                    │                    │                    │
     │                    │ Save to DB         │                    │
     │                    ├───────────────────►│                    │
     │                    │                    │                    │
     │                    │◄───────────────────┤                    │
     │                    │ message record     │                    │
     │                    │                    │                    │
     │                    │ to("conversation:123")                  │
     │                    │ emit('new_message')│                    │
     │                    ├────────────────────────────────────────►│
     │◄───────────────────┤                    │                    │
     │ on('new_message')  │                    │                    │
     │                    │                    │                    │◄─────┐
     │                    │                    │                    │ Save to
     │                    │                    │                    │ local DB
     │                    │                    │                    │
     │                    │                    │                    │ Update UI
     │                    │                    │                    │
     │ emit('message_read'│                    │                    │
     │ {messageId})       │                    │                    │
     ├───────────────────►│                    │                    │
     │                    │                    │                    │
     │                    │ UPDATE message     │                    │
     │                    │ status='read'      │                    │
     │                    ├───────────────────►│                    │
     │                    │                    │                    │
     │                    │ emit('message_read')                    │
     │                    ├────────────────────────────────────────►│
     │                    │                    │                    │
     │                    │                    │                    │◄─────┐
     │                    │                    │                    │ Show
     │                    │                    │                    │ read
     │                    │                    │                    │ receipt
```

---

### 4. Video Upload & Processing Flow

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  Mobile  │    │ Backend  │    │ BullMQ   │    │Cloudinary│    │PostgreSQL│
└────┬─────┘    └────┬─────┘    └────┬─────┘    └────┬─────┘    └────┬─────┘
     │               │               │               │               │
     │ Select video  │               │               │               │
     │ from gallery  │               │               │               │
     │               │               │               │               │
     │ POST /videos  │               │               │               │
     │ multipart/    │               │               │               │
     │ form-data     │               │               │               │
     ├──────────────►│               │               │               │
     │               │               │               │               │
     │               │ Validate:     │               │               │
     │               │ - File type   │               │               │
     │               │ - File size   │               │               │
     │               │ - MIME type   │               │               │
     │               │               │               │               │
     │               │ Upload to     │               │               │
     │               │ Cloudinary    │               │               │
     │               ├───────────────────────────────►│               │
     │               │               │               │               │
     │               │◄──────────────────────────────┤               │
     │               │ {url, publicId}               │               │
     │               │               │               │               │
     │               │ INSERT video  │               │               │
     │               │ status='UPLOADING'            │               │
     │               ├───────────────────────────────────────────────►│
     │               │               │               │               │
     │◄──────────────┤               │               │               │
     │ {videoId, url}│               │               │               │
     │               │               │               │               │
     │ Show progress │               │               │               │
     │               │               │               │               │
     │               │ Enqueue       │               │               │
     │               │ transcode job │               │               │
     │               ├──────────────►│               │               │
     │               │               │               │               │
     │               │               │ Worker picks  │               │
     │               │               │ job           │               │
     │               │               │               │               │
     │               │               │ Request       │               │
     │               │               │ transformations               │
     │               │               ├───────────────►│               │
     │               │               │               │               │
     │               │               │ Generate:     │               │
     │               │               │ - 360p MP4    │               │
     │               │               │ - 480p MP4    │               │
     │               │               │ - 720p MP4    │               │
     │               │               │ - 1080p MP4   │               │
     │               │               │ - HLS playlist│               │
     │               │               │ - Thumbnails  │               │
     │               │               │               │               │
     │               │               │◄──────────────┤               │
     │               │               │ {urls}        │               │
     │               │               │               │               │
     │               │               │ UPDATE video  │               │
     │               │               │ status='READY'│               │
     │               │               ├───────────────────────────────►│
     │               │               │               │               │
     │               │ Emit Socket   │               │               │
     │               │ event         │               │               │
     │◄──────────────┤               │               │               │
     │ 'video_ready' │               │               │               │
     │               │               │               │               │
     │ Navigate to   │               │               │               │
     │ video player  │               │               │               │
     │               │               │               │               │
```

---

## 🗄️ Database Schema Design

### Entity Relationship Diagram (Simplified)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          CORE ENTITIES                                       │
└─────────────────────────────────────────────────────────────────────────────┘

                           ┌──────────────┐
                           │     User     │
                           ├──────────────┤
                           │ id           │
                           │ email        │
                           │ username     │
                           │ passwordHash │
                           │ displayName  │
                           │ avatarUrl    │
                           │ bio          │
                           │ status       │
                           │ createdAt    │
                           └──────┬───────┘
                                  │
              ┌───────────────────┼───────────────────┐
              │                   │                   │
              ▼                   ▼                   ▼
      ┌──────────────┐    ┌──────────────┐   ┌──────────────┐
      │   Profile    │    │   Session    │   │   UserRole   │
      ├──────────────┤    ├──────────────┤   ├──────────────┤
      │ userId       │    │ userId       │   │ userId       │
      │ visibility   │    │ refreshToken │   │ roleId       │
      │ phoneNumber  │    │ userAgent    │   └──────┬───────┘
      │ dateOfBirth  │    │ ipAddress    │          │
      │ gender       │    │ expiresAt    │          ▼
      │ location     │    │ status       │   ┌──────────────┐
      └──────────────┘    └──────────────┘   │     Role     │
                                              ├──────────────┤
                                              │ id           │
       ┌──────────────────────────────────────┤ name         │
       │                                      │ description  │
       ▼                                      └──────────────┘
┌─────────────────────────────────────────────────────────────────────────────┐
│                          SOCIAL FEATURES                                     │
└─────────────────────────────────────────────────────────────────────────────┘

    ┌──────────────┐         ┌──────────────┐         ┌──────────────┐
    │     Post     │────────►│  PostMedia   │         │   Comment    │
    ├──────────────┤         ├──────────────┤         ├──────────────┤
    │ id           │         │ postId       │         │ id           │
    │ authorId     │────┐    │ mediaUrl     │    ┌────┤ postId       │
    │ content      │    │    │ mediaType    │    │    │ authorId     │
    │ type         │    │    │ order        │    │    │ content      │
    │ visibility   │    │    └──────────────┘    │    │ parentId     │
    │ status       │    │                        │    │ createdAt    │
    │ createdAt    │    │    ┌──────────────┐    │    └──────────────┘
    └──────┬───────┘    │    │     Like     │    │
           │            └───►├──────────────┤◄───┘
           │                 │ userId       │
           │                 │ targetId     │
           │                 │ targetType   │
           │                 │ reactionType │
           │                 └──────────────┘
           │
           │         ┌──────────────┐         ┌──────────────┐
           │         │    Story     │         │     Reel     │
           └────────►├──────────────┤         ├──────────────┤
                     │ id           │         │ id           │
                     │ userId       │         │ userId       │
                     │ mediaUrl     │         │ videoUrl     │
                     │ type         │         │ thumbnailUrl │
                     │ expiresAt    │         │ title        │
                     └──────────────┘         │ viewCount    │
                                              └──────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                          MESSAGING                                           │
└─────────────────────────────────────────────────────────────────────────────┘

    ┌──────────────────┐                    ┌──────────────────┐
    │  Conversation    │◄───────────────────┤ConversationMember│
    ├──────────────────┤                    ├──────────────────┤
    │ id               │                    │ conversationId   │
    │ type             │                    │ userId           │
    │ title            │                    │ role             │
    │ avatarUrl        │                    │ joinedAt         │
    │ lastMessageAt    │                    └──────────────────┘
    │ createdAt        │
    └────────┬─────────┘
             │
             │
             ▼
    ┌──────────────────┐                    ┌──────────────────┐
    │     Message      │───────────────────►│MessageAttachment │
    ├──────────────────┤                    ├──────────────────┤
    │ id               │                    │ messageId        │
    │ conversationId   │                    │ fileUrl          │
    │ senderId         │                    │ fileName         │
    │ content          │                    │ fileSize         │
    │ type             │                    │ mimeType         │
    │ clientId         │                    │ thumbnailUrl     │
    │ status           │                    └──────────────────┘
    │ replyToId        │
    │ reactions (JSON) │
    │ createdAt        │
    └──────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                          VIDEO PLATFORM                                      │
└─────────────────────────────────────────────────────────────────────────────┘

    ┌──────────────────┐                    ┌──────────────────┐
    │  VideoChannel    │                    │      Video       │
    ├──────────────────┤                    ├──────────────────┤
    │ id               │◄───────────────────┤ id               │
    │ ownerId          │                    │ channelId        │
    │ groupId          │                    │ title            │
    │ name             │                    │ description      │
    │ description      │                    │ videoUrl         │
    │ bannerUrl        │                    │ thumbnailUrl     │
    │ subscriberCount  │                    │ duration         │
    └────────┬─────────┘                    │ viewCount        │
             │                              │ status           │
             │                              │ visibility       │
             │                              │ createdAt        │
             │                              └────────┬─────────┘
             │                                       │
             │         ┌──────────────────┐          │
             └────────►│  Subscription    │          │
                       ├──────────────────┤          │
                       │ userId           │          │
                       │ channelId        │          │
                       │ subscribedAt     │          │
                       └──────────────────┘          │
                                                     │
                       ┌──────────────────┐          │
                       │    Playlist      │◄─────────┤
                       ├──────────────────┤          │
                       │ id               │          │
                       │ userId           │          │
                       │ title            │          │
                       │ description      │          │
                       │ visibility       │          │
                       └────────┬─────────┘          │
                                │                    │
                                │                    │
                       ┌────────▼─────────┐          │
                       │  PlaylistItem    │◄─────────┘
                       ├──────────────────┤
                       │ playlistId       │
                       │ videoId          │
                       │ order            │
                       └──────────────────┘
```

---

## 🔐 Security Architecture

### Authentication & Authorization Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     AUTHENTICATION LAYERS                                    │
└─────────────────────────────────────────────────────────────────────────────┘

 Request arrives
      │
      ▼
┌──────────────────────────────────────────────┐
│    1. Global Middleware Stack                │
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │  Helmet.js (Security Headers)          │ │
│  │  - X-Frame-Options: DENY               │ │
│  │  - X-Content-Type-Options: nosniff     │ │
│  │  - Strict-Transport-Security           │ │
│  └────────────────────────────────────────┘ │
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │  CORS Policy                           │ │
│  │  - Check origin whitelist              │ │
│  │  - Verify credentials flag             │ │
│  └────────────────────────────────────────┘ │
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │  Rate Limiting (Throttler)             │ │
│  │  - Default: 100 requests/min           │ │
│  │  - Per IP tracking                     │ │
│  └────────────────────────────────────────┘ │
└──────────────────┬───────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────┐
│    2. Route Guards                           │
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │  JwtAuthGuard (Optional)               │ │
│  │                                        │ │
│  │  IF route has @Public() decorator:    │ │
│  │    → Skip authentication              │ │
│  │  ELSE:                                │ │
│  │    → Verify Authorization header      │ │
│  │    → Extract Bearer token             │ │
│  │    → Validate JWT signature           │ │
│  │    → Check expiry                     │ │
│  │    → Attach user to request object    │ │
│  └────────────────────────────────────────┘ │
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │  RolesGuard                            │ │
│  │                                        │ │
│  │  IF route has @Roles() decorator:     │ │
│  │    → Check user.roles array           │ │
│  │    → Verify required role match       │ │
│  │    → Allow or deny access             │ │
│  └────────────────────────────────────────┘ │
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │  GroupMembershipGuard                  │ │
│  │                                        │ │
│  │  IF route requires group access:       │ │
│  │    → Extract groupId from params      │ │
│  │    → Check user membership            │ │
│  │    → Verify group role permissions    │ │
│  └────────────────────────────────────────┘ │
└──────────────────┬───────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────┐
│    3. Input Validation Pipeline              │
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │  class-validator                       │ │
│  │                                        │ │
│  │  - Validate DTO decorators            │ │
│  │  - Type checking                      │ │
│  │  - Length constraints                 │ │
│  │  - Format validation (email, URL)     │ │
│  │  - Custom validators                  │ │
│  └────────────────────────────────────────┘ │
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │  class-transformer                     │ │
│  │                                        │ │
│  │  - Transform types (string → number)  │ │
│  │  - Strip unknown properties           │ │
│  │  - Sanitize input                     │ │
│  └────────────────────────────────────────┘ │
└──────────────────┬───────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────┐
│    4. Controller Handler                     │
│    (Business logic executes)                 │
└──────────────────────────────────────────────┘
```

### Two-Level RBAC System

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        GLOBAL PERMISSIONS                                    │
│                                                                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐            │
│  │  SUPER_ADMIN    │  │     ADMIN       │  │      USER       │            │
│  ├─────────────────┤  ├─────────────────┤  ├─────────────────┤            │
│  │ - All access    │  │ - Moderate      │  │ - Basic access  │            │
│  │ - Manage admins │  │ - Manage users  │  │ - Create posts  │            │
│  │ - System config │  │ - View reports  │  │ - Join groups   │            │
│  │ - Delete anyone │  │ - Ban users     │  │ - Send messages │            │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘            │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ Inside specific group:
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        GROUP PERMISSIONS                                     │
│                                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ GROUP_ADMIN  │  │  MODERATOR   │  │    MEMBER    │  │     GUEST    │  │
│  ├──────────────┤  ├──────────────┤  ├──────────────┤  ├──────────────┤  │
│  │ - All group  │  │ - Delete     │  │ - Post       │  │ - View only  │  │
│  │   operations │  │   messages   │  │   messages   │  │ - No write   │  │
│  │ - Add/remove │  │ - Warn users │  │ - Upload     │  │ - No upload  │  │
│  │   members    │  │ - Edit posts │  │   files      │  │              │  │
│  │ - Delete     │  │              │  │              │  │              │  │
│  │   group      │  │              │  │              │  │              │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘

Permission Check Logic:
1. Extract user from JWT
2. Check global role (SUPER_ADMIN → Allow all)
3. If group resource, check group membership
4. Verify group role has required permission
5. Allow or 403 Forbidden
```

---

## 📊 Scalability Strategy

### Horizontal Scaling Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          LOAD BALANCER (NGINX)                               │
│                         Round-robin / Least connections                      │
└────────────────┬────────────────────────────────────┬───────────────────────┘
                 │                                    │
     ┌───────────▼──────────┐           ┌────────────▼─────────┐
     │  NestJS Instance 1   │           │  NestJS Instance 2   │
     │  ┌────────────────┐  │           │  ┌────────────────┐  │
     │  │ HTTP Handlers  │  │           │  │ HTTP Handlers  │  │
     │  └────────────────┘  │           │  └────────────────┘  │
     │  ┌────────────────┐  │           │  ┌────────────────┐  │
     │  │Socket.IO Server│  │◄─────────►│  │Socket.IO Server│  │
     │  │(Redis Adapter) │  │   Redis   │  │(Redis Adapter) │  │
     │  └────────────────┘  │  Pub/Sub  │  └────────────────┘  │
     └──────────┬───────────┘           └──────────┬───────────┘
                │                                  │
                └────────────┬─────────────────────┘
                             │
              ┌──────────────▼──────────────┐
              │  Shared Redis Cluster       │
              │  ┌────────┐  ┌────────┐    │
              │  │ Cache  │  │ Pub/Sub│    │
              │  └────────┘  └────────┘    │
              └──────────────┬──────────────┘
                             │
              ┌──────────────▼──────────────┐
              │   PostgreSQL Primary        │
              │   ┌───────────────────────┐ │
              │   │  Read Replicas        │ │
              │   │  (Neon auto-scale)    │ │
              │   └───────────────────────┘ │
              └─────────────────────────────┘
```

### Performance Optimization Strategies

1. **Database Query Optimization:**
   - Proper indexing on foreign keys
   - Pagination for large datasets
   - Eager loading with Prisma `.include()`
   - Query result caching in Redis

2. **API Response Caching:**
   ```typescript
   @UseInterceptors(CacheInterceptor)
   @CacheTTL(300) // 5 minutes
   @Get('/trending')
   async getTrendingPosts() { ... }
   ```

3. **CDN Offloading:**
   - All media served via Cloudinary CDN
   - Adaptive streaming reduces server load
   - Edge caching for global delivery

4. **Connection Pooling:**
   - Prisma connection pool (default: 10)
   - Redis connection pool
   - HTTP keep-alive

5. **Lazy Loading (Mobile):**
   - Images loaded on-demand
   - Infinite scroll pagination
   - Video thumbnails pre-fetched
   - Skeleton screens for UX

---

**Document Version:** 1.0  
**Last Updated:** September 4, 2026  
**Architecture Review Date:** Q4 2026

---
