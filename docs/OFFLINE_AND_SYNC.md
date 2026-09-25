# Offline Capabilities & Synchronization

**Document Version:** 1.0  
**Last Updated:** September 25, 2026  
**Project:** Zikire Kdusan (StreamHub)

---

## Table of Contents

1. [Overview](#overview)
2. [Offline Architecture](#offline-architecture)
3. [Local Database](#local-database)
4. [Connectivity Monitoring](#connectivity-monitoring)
5. [Synchronization System](#synchronization-system)
6. [Background Sync](#background-sync)
7. [Download Management](#download-management)
8. [Offline-First Features](#offline-first-features)
9. [Conflict Resolution](#conflict-resolution)
10. [Data Retention & Storage](#data-retention--storage)
11. [Performance & Optimization](#performance--optimization)
12. [User Experience](#user-experience)
13. [Troubleshooting](#troubleshooting)

---

## Overview

Zikire Kdusan provides robust offline capabilities that allow users to continue using core features without an active internet connection. The app automatically synchronizes data when connectivity is restored, ensuring a seamless experience across online and offline states.

### Key Capabilities

✅ **Local Data Persistence** - SQLite database with Drift ORM  
✅ **Automatic Synchronization** - 15-minute background sync when online  
✅ **Offline-First Operations** - Messages, calendar notes, watch history  
✅ **Video Downloads** - Save videos for offline viewing with quality selection  
✅ **Connectivity Monitoring** - Real-time network status detection and reachability probing  
✅ **Retry Strategy** - Exponential backoff with 5 retry attempts  
✅ **Queue Management** - Pending operations stored and replayed automatically  
✅ **Web Fallback** - Safe no-op executor for Flutter Web builds

### What Works Offline

| Feature | Offline Capability | Sync Behavior |
|---------|-------------------|---------------|
| **Messaging** | ✅ Send messages (queued) | Syncs when online, reconciles server IDs |
| **Message Reactions** | ✅ Add/remove reactions | Queued and synced with messages |
| **Read Receipts** | ✅ Mark messages as read | Batched and synced periodically |
| **Video Playback (Downloaded)** | ✅ Full playback from local storage | No sync needed |
| **Video Progress** | ✅ Track watch position | Syncs progress to server when online |
| **Calendar Notes** | ✅ Create/edit Ethiopian calendar notes | Bidirectional sync with conflict detection |
| **Calendar Reminders** | ✅ Offline reminders fire locally | No sync needed for local notifications |
| **Search History** | ✅ Local search history | Read-only, no sync |
| **Video Likes** | ✅ Like/unlike videos | Queued and synced when online |
| **Feed Browsing** | ✅ View cached feed items | Refreshed when online |
| **Profile Viewing** | ✅ View cached user profiles | Refreshed when online |
| **Conversation History** | ✅ View cached messages | New messages loaded when online |

### What Requires Online Connection

❌ **Live Streaming** - RTMP ingestion and HLS playback require active connection  
❌ **Video Uploads** - Multipart uploads to Cloudinary  
❌ **Group Creation** - Real-time validation and permission checks  
❌ **Profile Picture Updates** - Image upload to Cloudinary  
❌ **Search & Discovery** - Server-side search and recommendation engine  
❌ **Video Downloads** - Requires network to fetch video files  
❌ **Notifications** - FCM push notifications require connectivity  
❌ **Real-time Chat** - WebSocket-based live chat requires active connection

---

## Offline Architecture

### Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Local Database** | SQLite with Drift ORM | Persistent storage on device |
| **Database Version** | Schema v4 | Current migration state |
| **Database File** | `zikre_kidusan_local_v1.db` | SQLite file (mobile only) |
| **Web Fallback** | `_SafeWebQueryExecutor` | No-op executor for Flutter Web |
| **Background Worker** | WorkManager (Android) | Periodic 15-minute sync task |
| **Connectivity Monitor** | connectivity_plus + Dio probes | Real-time network status |
| **HTTP Client** | Dio | API communication with retry logic |
| **State Management** | Riverpod | Reactive sync state and connectivity |

### Architectural Layers

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation Layer                       │
│  - Offline Status Banner                                     │
│  - Sync Status Indicator (calendar, messages, downloads)    │
│  - Download UI (progress, quality selection)                │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      Business Logic                          │
│  - SyncManager (orchestrates all sync operations)           │
│  - BackgroundSyncService (WorkManager integration)          │
│  - ConnectivityNotifier (monitors network state)            │
│  - RetryStrategy (exponential backoff logic)                │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                       Data Layer                             │
│  - AppDatabase (Drift SQLite database)                      │
│  - DAOs (SyncQueueDao, MessagesDao, VideosDao, etc.)       │
│  - SyncQueue (pending operations queue table)               │
│  - Local Tables (messages, videos, calendar, etc.)         │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    Persistence Layer                         │
│  - SQLite Engine (with WAL mode and foreign keys)          │
│  - Local File System (downloaded videos, thumbnails)       │
└─────────────────────────────────────────────────────────────┘
```

### Database Configuration

The Drift database is configured with production-ready optimizations:

```dart
// SQLite Pragmas (mobile only)
PRAGMA foreign_keys = ON;    // Enforce referential integrity
PRAGMA journal_mode = WAL;   // Write-Ahead Logging for performance
```

**WAL Mode Benefits:**
- Concurrent readers and writers
- Better performance for write-heavy workloads
- Reduced database lock contention
- Automatic checkpoint management

---

## Local Database

### Schema Version & Migrations

**Current Schema Version:** 4

| Version | Migration | Description |
|---------|-----------|-------------|
| **v1** | Initial | Core tables: users, videos, conversations, messages, sync queue |
| **v2** | Add Calendar | `local_calendar_notes` and `local_calendar_note_media` tables |
| **v3** | Reminder Fields | Added `has_reminder`, `reminder_date_time`, `reminder_notified` |
| **v4** | Recurring Reminders | Added `reminder_repeat`, `reminder_ethiopian_month`, `reminder_ethiopian_day`, `reminder_hour`, `reminder_minute`, `reminder_timezone`, `reminder_next_occurrence` |

### Core Tables

#### 1. SyncQueue Table

The `sync_queue` table stores all pending operations that need to be synchronized with the server when connectivity is restored.

**Columns:**

| Column | Type | Description |
|--------|------|-------------|
| `id` | TEXT (UUID) | Primary key |
| `operationType` | TEXT | Operation enum: `CREATE_MESSAGE`, `EDIT_MESSAGE`, `DELETE_MESSAGE`, `SEND_REACTION`, `REMOVE_REACTION`, `UPDATE_READ_STATE`, `UPDATE_WATCH_HISTORY`, `CREATE_LIKE`, `REMOVE_LIKE` |
| `entityType` | TEXT | Entity enum: `MESSAGE`, `REACTION`, `READ_STATE`, `WATCH_HISTORY`, `LIKE` |
| `entityId` | TEXT | ID of the entity being modified |
| `payload` | TEXT (JSON) | Serialized operation payload |
| `createdAt` | DATETIME | When operation was queued |
| `updatedAt` | DATETIME | Last update timestamp |
| `retryCount` | INTEGER | Number of retry attempts (default: 0) |
| `lastAttemptAt` | DATETIME | Timestamp of last sync attempt |
| `nextRetryAt` | DATETIME | Scheduled next retry time |
| `status` | TEXT | Status: `pending`, `in_progress`, `failed`, `completed` |
| `errorMessage` | TEXT | Last error message (if any) |

**Example Queued Operation:**

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "operationType": "CREATE_MESSAGE",
  "entityType": "MESSAGE",
  "entityId": "local-msg-12345",
  "payload": {
    "conversationId": "conv-abc123",
    "clientId": "local-msg-12345",
    "content": "Hello from offline mode!",
    "type": "TEXT",
    "replyToId": null,
    "fileIds": []
  },
  "status": "pending",
  "retryCount": 0,
  "createdAt": "2026-09-25T10:30:00Z"
}
```

#### 2. LocalVideos Table

Stores video metadata and download state for offline playback.

**Key Columns:**

| Column | Type | Description |
|--------|------|-------------|
| `id` | TEXT | Primary key (local or server ID) |
| `serverId` | TEXT | Server-side video ID (nullable) |
| `title`, `description` | TEXT | Video metadata |
| `thumbnailUrl`, `videoUrl`, `hlsUrl`, `dashUrl` | TEXT | Streaming URLs |
| `duration` | INTEGER | Video duration in seconds |
| `creatorId`, `creatorName`, `creatorAvatar` | TEXT | Creator info |
| **Download State** | | |
| `isDownloaded` | BOOLEAN | Download completed flag |
| `downloadStatus` | TEXT | `none`, `queued`, `downloading`, `paused`, `completed`, `failed`, `cancelled` |
| `localFilePath` | TEXT | Path to downloaded video file |
| `downloadProgress` | REAL | Progress percentage (0.0-1.0) |
| `selectedQuality` | TEXT | Quality: `360p`, `480p`, `720p`, `1080p`, `original` |
| `fileSizeBytes` | INTEGER | Total file size |
| `downloadError` | TEXT | Error message if download failed |
| **Playback Tracking** | | |
| `lastPlayedPosition` | INTEGER | Last watched position (seconds) |
| `lastAccessedAt` | DATETIME | Last time video was opened |
| `isFavorite` | BOOLEAN | User favorite flag |
| `renditionsJson` | TEXT | JSON array of available quality options |

#### 3. LocalMessages Table

Stores conversation messages with local-first architecture.

**Key Columns:**

| Column | Type | Description |
|--------|------|-------------|
| `id` | TEXT | Local message ID (primary key) |
| `serverId` | TEXT | Server-assigned ID after sync (nullable) |
| `conversationId` | TEXT | Parent conversation |
| `senderId` | TEXT | Message author ID |
| `clientId` | TEXT | Unique client-side identifier |
| `type` | TEXT | `TEXT`, `IMAGE`, `VIDEO`, `AUDIO`, `DOCUMENT`, `VOICE_NOTE`, `SYSTEM` |
| `content` | TEXT | Message text content |
| `status` | TEXT | `pending`, `sending`, `sent`, `delivered`, `read`, `failed` |
| `sentAt` | DATETIME | Client send timestamp |
| `replyToId` | TEXT | ID of message being replied to |
| `isEdited` | BOOLEAN | Edit flag |
| `editedAt` | DATETIME | Last edit timestamp |
| `deletedAt` | DATETIME | Soft delete timestamp |
| `isSynced` | BOOLEAN | Sync status flag |

**Message Lifecycle:**

1. **Created Offline** → `status: pending`, `isSynced: false`
2. **Queued for Sync** → Entry added to `sync_queue` table
3. **Sync Successful** → `serverId` populated, `status: sent`, `isSynced: true`
4. **Sync Failed** → `status: failed`, retry scheduled in `sync_queue`

#### 4. LocalConversations Table

Stores conversation metadata and unread counts.

| Column | Type | Description |
|--------|------|-------------|
| `id` | TEXT | Conversation ID |
| `type` | TEXT | `DIRECT`, `GROUP_CHANNEL`, `GROUP_DIRECT` |
| `title` | TEXT | Display name |
| `avatarUrl` | TEXT | Conversation avatar |
| `lastMessageText` | TEXT | Preview of last message |
| `lastMessageAt` | DATETIME | Timestamp of last message |
| `unreadCount` | INTEGER | Number of unread messages |
| `isPinned` | BOOLEAN | Pin status |
| `isMuted` | BOOLEAN | Notification mute status |

#### 5. LocalCalendarNotes Table

Stores Ethiopian calendar notes with offline reminder support.

**Key Columns:**

| Column | Type | Description |
|--------|------|-------------|
| `id` | TEXT | Note ID |
| `serverId` | TEXT | Server-side ID (nullable) |
| `userId` | TEXT | Note owner |
| `title`, `content` | TEXT | Note data |
| `calendarType` | TEXT | `ETHIOPIAN` or `GREGORIAN` |
| `ethiopianDate`, `gregorianDate` | DATETIME | Dual calendar dates |
| **Reminder Fields** | | |
| `hasReminder` | BOOLEAN | Reminder enabled flag |
| `reminderDateTime` | DATETIME | Next reminder time |
| `reminderNotified` | BOOLEAN | Notification sent flag |
| `reminderRepeat` | TEXT | `NONE`, `MONTHLY`, `YEARLY` |
| `reminderEthiopianMonth`, `reminderEthiopianDay` | INTEGER | Ethiopian calendar coordinates |
| `reminderHour`, `reminderMinute` | INTEGER | Time of day |
| `reminderTimezone` | TEXT | User timezone |
| `reminderNextOccurrence` | DATETIME | Computed next occurrence |
| **Sync State** | | |
| `isSynced` | BOOLEAN | Sync status |
| `conflictDetected` | BOOLEAN | Conflict flag |
| `lastSyncedAt` | DATETIME | Last successful sync |

**Offline Reminder Flow:**

1. User creates calendar note with reminder (offline or online)
2. Local notification scheduled based on `reminderDateTime`
3. When reminder fires → notification shown, `reminderNotified: true`
4. If recurring → `reminderNextOccurrence` computed and next alarm scheduled
5. Sync happens in background → server updated with notification status

#### 6. LocalWatchHistory Table

Tracks video watch progress for resumable playback.

| Column | Type | Description |
|--------|------|-------------|
| `id` | TEXT | History entry ID |
| `videoId` | TEXT | Video being watched |
| `userId` | TEXT | Viewer ID |
| `watchedSeconds` | INTEGER | Current watch position |
| `totalSeconds` | INTEGER | Video duration |
| `lastWatchedAt` | DATETIME | Last playback timestamp |
| `isSynced` | BOOLEAN | Sync status |

**Progress Sync Logic:**

- Progress tracked locally every 5 seconds during playback
- Queued for sync when video paused, completed, or app backgrounded
- Exponential backoff if sync fails
- Server progress takes precedence on conflict (last-write-wins)

#### 7. LocalFeedItems Table

Caches home feed and explore content for offline browsing.

| Column | Type | Description |
|--------|------|-------------|
| `id` | TEXT | Feed item ID |
| `type` | TEXT | `VIDEO`, `POST`, `STORY`, `REEL`, `LIVE_STREAM` |
| `contentId` | TEXT | ID of the content entity |
| `rank` | INTEGER | Position in feed |
| `cachedAt` | DATETIME | Cache timestamp |
| `expiresAt` | DATETIME | Cache expiration |
| `metadataJson` | TEXT | JSON snapshot of content |

**Feed Cache Strategy:**

- Last 100 feed items cached when online
- 24-hour expiration for most content
- Stories expire after 24 hours from creation
- Live streams removed when status changes from `LIVE`

#### 8. LocalSearchHistory Table

Stores user search queries for autocomplete.

| Column | Type | Description |
|--------|------|-------------|
| `id` | TEXT | Entry ID |
| `userId` | TEXT | User who searched |
| `query` | TEXT | Search term |
| `searchedAt` | DATETIME | Timestamp |

**Search History Behavior:**

- Local-only (never synced to server)
- Last 50 searches retained per user
- Cleared when user clears app data or logs out

---

## Connectivity Monitoring

### ConnectivityNotifier Architecture

The `ConnectivityNotifier` provides real-time network status monitoring with intelligent reachability probing.

**Key Components:**

| Component | Purpose |
|-----------|---------|
| `Connectivity` (connectivity_plus) | OS-level network interface monitoring (Wi-Fi, mobile, ethernet) |
| `Dio` HTTP probes | Application-layer reachability testing |
| `InternetAddress.lookup` | DNS-based fallback check |

### Connectivity States

```dart
enum ConnectivityStatus { online, offline }

enum NetworkConnectionType {
  wifi,       // Connected to Wi-Fi
  mobile,     // Mobile data (3G, 4G, 5G)
  ethernet,   // Wired connection
  other,      // Bluetooth, VPN, etc.
  none,       // No connection
  unknown     // Initial state
}
```

**ConnectivityState Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `status` | `ConnectivityStatus` | Online or offline |
| `connectionType` | `NetworkConnectionType` | Type of network connection |
| `isInitialized` | `bool` | Has initial check completed? |
| `isReachable` | `bool` | Can reach server or internet? |
| `isOnline` | `bool` | Computed: `status == online && isReachable` |
| `isOffline` | `bool` | Computed: `!isOnline` |
| `isWifi` | `bool` | Connected via Wi-Fi? |
| `isMobile` | `bool` | Connected via mobile data? |

### Reachability Probing

When a network interface becomes available, the system performs a two-tier reachability check:

#### Tier 1: Server Health Probe (Primary)

```dart
// Attempt to reach backend health endpoint
GET https://api.zikrekidusan.com/api/health

Success → status < 500 → Server reachable
Failure → Proceed to Tier 2
```

#### Tier 2: Internet Reachability (Fallback)

```dart
// Cloudflare/Google lightweight probe
GET https://www.google.com/generate_204

Response 204 or < 400 → Internet reachable
Failure → DNS fallback
```

#### Tier 3: DNS Lookup (Final Fallback)

```dart
InternetAddress.lookup('dns.google')
  .timeout(Duration(seconds: 3))

Success → Raw internet connectivity confirmed
Failure → Offline
```

**Debouncing:**

Network change events are debounced by **500ms** to prevent excessive reachability probes during rapid interface transitions (e.g., switching from Wi-Fi to mobile data).

### Connectivity Listeners

The `ConnectivityNotifier` supports application-wide listeners that fire when online/offline status changes:

```dart
// Example: SyncManager auto-triggers sync when going online
_connectivity.addOnlineStatusListener((isOnline) {
  if (isOnline) {
    triggerSync();
  } else {
    state = SyncStatus.offline;
  }
});
```

**Use Cases:**

- Auto-trigger sync when connectivity restored
- Pause downloads when going offline
- Show/hide offline banner in UI
- Disable real-time features (WebSocket) when offline

---

## Synchronization System

### SyncManager Architecture

The `SyncManager` is the central orchestrator for all synchronization operations. It operates as a **StateNotifier** that exposes sync status to the UI layer.

**Sync States:**

```dart
enum SyncStatus {
  idle,      // No active sync, queue empty or sync complete
  syncing,   // Actively processing queue
  success,   // Last sync completed successfully
  failed,    // Last sync encountered errors
  offline    // No connectivity
}
```

**UI Behavior:**

| State | UI Indicator | Duration |
|-------|-------------|----------|
| `idle` | No banner | Persistent |
| `syncing` | "Syncing..." banner with spinner | Until complete or 60s watchdog |
| `success` | "Synced ✓" banner (green) | 2 seconds |
| `failed` | "Sync failed ⚠️" banner (yellow) | 2 seconds |
| `offline` | "Offline" banner (gray) | Until online |

### Sync Triggers

Synchronization can be triggered by multiple events:

1. **App Startup** (2-second delay for UI initialization)
2. **Connectivity Restored** (automatic via listener)
3. **User Manual Trigger** (pull-to-refresh gesture)
4. **Background Task** (15-minute periodic WorkManager task)
5. **Explicit API Call** (`syncManager.triggerSync()`)

### Sync Queue Processing

#### Non-Reentrant Lock

The `SyncManager` uses a **Future-based lock** to prevent concurrent sync passes:

```dart
Future<void>? _syncFuture;

Future<void> triggerSync() {
  // Concurrent callers share the in-flight Future
  if (_syncFuture != null) return _syncFuture!;
  
  _syncFuture = _runSync().whenComplete(() {
    _syncFuture = null;
  });
  return _syncFuture!;
}
```

**Why This Matters:**

- Boolean flags can race (caller 1 checks → caller 2 checks → both proceed)
- Future-sharing ensures only one sync pass executes at a time
- Concurrent callers wait for the active sync to complete

#### Sync Pass Lifecycle

```
1. Check connectivity → offline? → return
2. Fetch pending entries from sync_queue
3. Set status to 'syncing'
4. Start 60-second watchdog timer (safety mechanism)
5. For each entry:
   a. Check connectivity (abort if went offline)
   b. Process entry with 10-second timeout
   c. On success → remove from queue
   d. On failure → apply retry strategy
6. Cleanup completed entries
7. Update status (success/failed)
8. Auto-reset to idle after 2 seconds
9. Cancel watchdog timer
```

**60-Second Watchdog:**

Safety mechanism to prevent banner being stuck in "Syncing..." state indefinitely if sync pass hangs (e.g., database deadlock, infinite loop).

### Supported Operations

The sync system handles 9 types of operations:

#### 1. CREATE_MESSAGE

**Payload:**

```json
{
  "conversationId": "conv-abc123",
  "clientId": "local-msg-12345",
  "content": "Message text",
  "type": "TEXT",
  "replyToId": null,
  "fileIds": []
}
```

**Sync Flow:**

1. POST `/conversations/{conversationId}/messages`
2. Server returns `{ id: "server-msg-xyz789" }`
3. Reconcile local message: `UPDATE local_messages SET serverId = ?, status = 'sent', isSynced = true WHERE clientId = ?`
4. Remove entry from sync queue

**Client ID Reconciliation:**

- Messages created offline have `clientId` (UUID)
- Server assigns canonical `serverId` on sync
- Local database updated to map `clientId → serverId`
- Future operations (edit, delete, react) use `serverId` after reconciliation

#### 2. EDIT_MESSAGE

**Payload:**

```json
{
  "messageId": "local-msg-12345",
  "content": "Updated message text"
}
```

**Sync Flow:**

1. Resolve `messageId` → if local ID, lookup `serverId` from database
2. PATCH `/messages/{serverId}` with `{ content }`
3. On success → remove from queue (local DB already updated)

#### 3. DELETE_MESSAGE

**Payload:**

```json
{
  "messageId": "server-msg-xyz789"
}
```

**Sync Flow:**

1. Resolve `messageId` → lookup `serverId` if local ID
2. DELETE `/messages/{serverId}`
3. On success → remove from queue

#### 4. SEND_REACTION

**Payload:**

```json
{
  "messageId": "server-msg-xyz789",
  "emoji": "👍"
}
```

**Sync Flow:**

1. Resolve `messageId` → lookup `serverId`
2. POST `/messages/{serverId}/reactions` with `{ emoji }`
3. On success → remove from queue

#### 5. REMOVE_REACTION

**Payload:**

```json
{
  "messageId": "server-msg-xyz789",
  "emoji": "👍"
}
```

**Sync Flow:**

1. Resolve `messageId` → lookup `serverId`
2. DELETE `/messages/{serverId}/reactions/{emoji}` (URL-encoded emoji)
3. On success → remove from queue

#### 6. UPDATE_READ_STATE

**Payload (Message-Level):**

```json
{
  "messageId": "server-msg-xyz789",
  "conversationId": null
}
```

**Payload (Conversation-Level):**

```json
{
  "messageId": null,
  "conversationId": "conv-abc123"
}
```

**Sync Flow:**

- If `messageId` provided → POST `/messages/{serverId}/read`
- If `conversationId` provided → POST `/conversations/{conversationId}/read`
- On success → remove from queue

**Read Receipt Batching:**

Read receipts are debounced and batched to reduce API calls:

- Mark read locally immediately (optimistic update)
- Queue sync entry with 5-second debounce
- If multiple messages read in same conversation → coalesce to conversation-level update

#### 7. UPDATE_WATCH_HISTORY

**Payload:**

```json
{
  "videoId": "video-abc123",
  "watchedSeconds": 320
}
```

**Sync Flow:**

1. PATCH `/videos/{videoId}/progress` with `{ watchedSeconds }`
2. On success → mark local watch history entry as synced
3. Remove from queue

**Progress Tracking:**

- Progress saved locally every 5 seconds during playback
- Queued for sync when:
  - Video paused
  - Video completed
  - App backgrounded
  - Every 60 seconds during long playback sessions

#### 8. CREATE_LIKE

**Payload:**

```json
{
  "videoId": "video-abc123"
}
```

**Sync Flow:**

1. POST `/videos/{videoId}/like`
2. On success → remove from queue

#### 9. REMOVE_LIKE

**Payload:**

```json
{
  "videoId": "video-abc123"
}
```

**Sync Flow:**

1. DELETE `/videos/{videoId}/like`
2. On success → remove from queue

### Retry Strategy

**Exponential Backoff with Max Retries:**

| Retry Attempt | Backoff Delay | Cumulative Delay |
|---------------|---------------|------------------|
| 1 | 2 seconds | 2s |
| 2 | 5 seconds | 7s |
| 3 | 15 seconds | 22s |
| 4 | 30 seconds | 52s |
| 5 | 60 seconds | 112s (~2 minutes) |
| 6+ | **Abandoned** | — |

**Retry Decision Tree:**

```
Error occurs during sync
    ↓
Is error recoverable?
    ├─ YES (network timeout, 5xx server error, 429 rate limit)
    │   ↓
    │   retryCount < 5?
    │   ├─ YES → Schedule next retry
    │   │        Update sync_queue: status='failed', retryCount++, nextRetryAt=computed
    │   └─ NO  → Abandon operation
    │             Update sync_queue: status='abandoned', error logged
    │
    └─ NO (4xx client error, validation failure)
        ↓
        Abandon immediately
        Update sync_queue: status='abandoned', error logged
```

**Recoverable Errors:**

- `DioExceptionType.connectionTimeout`
- `DioExceptionType.sendTimeout`
- `DioExceptionType.receiveTimeout`
- `DioExceptionType.connectionError`
- HTTP 5xx (server errors)
- HTTP 429 (rate limit exceeded)

**Non-Recoverable Errors:**

- HTTP 400 (bad request - malformed payload)
- HTTP 401 (unauthorized - token expired, requires re-login)
- HTTP 403 (forbidden - permission denied)
- HTTP 404 (not found - entity deleted on server)
- HTTP 422 (validation error)

**Abandoned Operations:**

Abandoned entries remain in `sync_queue` with `status='abandoned'` for debugging/audit purposes. They are removed when:

1. User explicitly clears failed sync items (Settings > Data & Storage > Clear Failed Syncs)
2. App data cleared
3. User logs out

---

## Background Sync

### WorkManager Integration

**Technology:** `workmanager` Flutter package  
**Platform:** Android (iOS uses background fetch with similar interval)

**Task Configuration:**

```dart
await Workmanager().registerPeriodicTask(
  'zikre_periodic_sync',              // Unique task name
  backgroundSyncTaskName,              // Task identifier
  frequency: Duration(minutes: 15),   // Android minimum
  constraints: Constraints(
    networkType: NetworkType.connected,        // Must be online
    requiresBatteryNotLow: true,              // Battery > 15%
  ),
  existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
);
```

**Constraints:**

| Constraint | Requirement | Reason |
|------------|-------------|--------|
| `networkType: connected` | Active network connection | Sync requires API access |
| `requiresBatteryNotLow` | Battery level > 15% | Avoid draining battery |

**Task Lifecycle:**

1. WorkManager wakes app in background every 15 minutes (if constraints met)
2. `callbackDispatcher()` entry point invoked
3. Sync logic executed (fetch queue, process entries, retry failed)
4. Task returns `true` (success) or `false` (failure)
5. App returns to background

**Android Doze Mode:**

- Background sync may be delayed during Doze mode (screen off, idle)
- Maintenance windows occur periodically where tasks execute
- Critical operations should use foreground service or push notifications

**Battery Optimization Exemption:**

Users can exempt the app from battery optimization in Settings > Apps > Zikire Kdusan > Battery > Unrestricted to ensure more reliable background sync.

---

## Download Management

### Video Download Architecture

**Storage:** Local file system (`/data/data/com.zikrekidusan.app/files/videos/`)  
**Backend:** Signed download URLs with 1-hour expiration  
**Quality Options:** 360p, 480p, 720p, 1080p, Original

### Download Authorization Flow

```
1. User taps "Download" button on video
2. Frontend → POST /downloads/authorize-video
   Payload: { videoId, resolution }
3. Backend checks:
   - Video exists and not deleted
   - User has download permission (see permission model below)
   - Resolution available in renditions
4. Backend generates:
   - Signed download URL with 1-hour expiry
   - Download record in database (audit trail)
5. Backend responds:
   {
     downloadId: "dl-abc123",
     downloadUrl: "https://api.example.com/downloads/file/dl-abc123?token=...",
     expiresAt: "2026-09-25T11:30:00Z",
     resolution: "720p",
     filename: "Video_Title_720p.mp4"
   }
6. Frontend downloads file to local storage
7. Frontend updates local_videos table:
   - downloadStatus: 'completed'
   - isDownloaded: true
   - localFilePath: '/path/to/file.mp4'
8. Video available offline
```

### Download Permission Model

**Permission Levels (DownloadPermission enum):**

| Level | Description | Access |
|-------|-------------|--------|
| `NONE` | Downloads disabled | No one can download |
| `PUBLIC` | Anyone can download | All authenticated users |
| `MEMBERS_ONLY` | Group members only | Must be group member |
| `SUBSCRIBERS_ONLY` | Channel subscribers only | Must be subscribed to channel |

**Permission Hierarchy:**

```
Video.downloadPermission
    ↓ (fallback if null)
VideoChannel.downloadPermission
    ↓ (fallback if null)
NONE (default)
```

**RBAC Overrides:**

- `SUPER_ADMIN` and `ADMIN` roles can download any video regardless of permission level
- Group admins (`GROUP_ADMIN`) can download all videos in their group

**Audit Trail:**

Every download authorization creates a `DownloadRecord` entry:

```typescript
{
  id: string;
  userId: string;
  videoId?: string;
  fileId?: string;
  resolution?: VideoResolution;
  signedUrl: string;
  expiresAt: Date;
  downloadedAt?: Date;
  status: DownloadStatus;  // PENDING, IN_PROGRESS, COMPLETED, FAILED
  ipAddress?: string;
  userAgent?: string;
  fileSize: bigint;
}
```

**Concurrent Download Limit:**

- Maximum 3 active downloads at once
- Downloads auto-pause when going offline
- Downloads auto-resume when connectivity restored (if signed URL not expired)

### Download States

| Status | Description | User Action Available |
|--------|-------------|----------------------|
| `none` | Not downloaded | Download |
| `queued` | Waiting to start | Cancel |
| `downloading` | Actively downloading | Pause, Cancel |
| `paused` | User paused | Resume, Cancel |
| `completed` | Download finished | Delete, Play |
| `failed` | Download error | Retry, Delete |
| `cancelled` | User cancelled | Download (start over) |

### Storage Management

**Settings > Data & Storage > Downloaded Videos:**

| Metric | Description |
|--------|-------------|
| Total Downloads | Count of downloaded videos |
| Storage Used | Total MB/GB consumed |
| Download Quality | Preferred quality (applied to future downloads) |
| Auto-Delete | Delete downloads older than X days |
| Download Over Cellular | Allow/disallow mobile data downloads |

**Auto-Delete Policy:**

- Never (default)
- After 7 days
- After 30 days
- After 90 days
- When storage < 500MB free

**Download History:**

Users can view download history in **Settings > Privacy > Download History** showing:

- Video title
- Download date
- Resolution
- File size
- Status (completed/deleted)

---

## Offline-First Features

### 1. Messaging

**Offline Capabilities:**

✅ Send messages (queued for sync)  
✅ View conversation history (cached)  
✅ Add/remove reactions (queued)  
✅ Mark messages as read (queued)  
✅ Edit/delete messages (queued)  
✅ Reply to messages (queued)  
❌ Send attachments (requires upload)  
❌ Receive new messages (requires WebSocket)

**Local-First Message Flow:**

```
1. User types message in offline mode
2. Message saved to local_messages:
   - id: local-msg-12345 (UUID)
   - clientId: local-msg-12345
   - status: 'pending'
   - isSynced: false
3. Message rendered in UI with "pending" indicator
4. Entry added to sync_queue:
   - operationType: CREATE_MESSAGE
   - entityId: local-msg-12345
   - payload: { conversationId, content, type, clientId }
5. When connectivity restored:
   - SyncManager processes queue
   - POST /conversations/{id}/messages
   - Server assigns serverId: server-msg-xyz789
   - Local DB updated: serverId populated, status='sent', isSynced=true
6. UI updates to show "sent" checkmark
```

**Message Status Indicators:**

| Icon | Status | Description |
|------|--------|-------------|
| 🕐 | Pending | Created offline, awaiting sync |
| ✓ | Sent | Successfully synced to server |
| ✓✓ | Delivered | Server confirmed delivery |
| ✓✓ (blue) | Read | Recipient has read message |
| ⚠️ | Failed | Sync failed, will retry |

### 2. Calendar Notes & Reminders

**Offline Capabilities:**

✅ Create calendar notes  
✅ Edit calendar notes  
✅ Set Ethiopian/Gregorian dates  
✅ Configure offline reminders  
✅ Receive reminder notifications (local)  
✅ Recurring reminders (monthly/yearly)  
✅ Bidirectional sync with conflict detection  

**Calendar Note Sync:**

Calendar notes use a **bidirectional sync** model with conflict detection:

```
Sync Direction: Device ↔ Server

Conflict Detection:
- Compare lastSyncedAt with server updatedAt
- If server.updatedAt > local.lastSyncedAt → server wins
- If local.updatedAt > server.updatedAt → local wins
- Mark conflictDetected = true for user review if both changed
```

**Offline Reminder Scheduling:**

1. User creates calendar note with reminder (offline or online)
2. Local notification alarm registered with OS:
   ```dart
   await AwesomeNotifications().createNotification(
     content: NotificationContent(
       id: noteId,
       channelKey: 'calendar_reminders',
       title: note.title,
       body: note.content,
       notificationLayout: NotificationLayout.Default,
     ),
     schedule: NotificationCalendar(
       year: year,
       month: month,
       day: day,
       hour: hour,
       minute: minute,
       timeZone: timezone,
     ),
   );
   ```
3. When alarm fires → notification shown, `reminderNotified: true`
4. If recurring → next occurrence computed and alarm rescheduled
5. Background sync updates server with notification status

**Recurring Reminder Logic:**

| Repeat Type | Next Occurrence Calculation |
|-------------|----------------------------|
| `NONE` | No recurrence (single reminder) |
| `MONTHLY` | Same day next month (Ethiopian calendar) |
| `YEARLY` | Same date next year (Ethiopian calendar) |

**Ethiopian Calendar Recurring Example:**

```
User creates yearly reminder:
- Date: Meskerem 11 (Ethiopian New Year)
- Time: 9:00 AM
- Repeat: Yearly

Occurrences:
- 2026-09-11 09:00 (Meskerem 11, 2019 EC)
- 2027-09-11 09:00 (Meskerem 11, 2020 EC)
- 2028-09-11 09:00 (Meskerem 11, 2021 EC)
- ... (continues forever or until user deletes)
```

### 3. Video Watch History

**Offline Capabilities:**

✅ Track playback progress  
✅ Resume from last position  
✅ Sync progress to server when online  
✅ Multi-device progress sync (last-write-wins)  

**Progress Tracking:**

- Progress saved locally every **5 seconds** during playback
- Entry added to `local_watch_history` table
- Queued for sync on:
  - Video paused
  - Video completed (watchedSeconds ≈ totalSeconds)
  - App backgrounded
  - 60-second interval during long sessions

**Conflict Resolution:**

Server progress takes precedence (last-write-wins):

```
Device A plays video → progress: 120s
Device B plays video → progress: 200s
Device A syncs first → server: 120s
Device B syncs second → server: 200s (overwrites)
```

**Watch History UI:**

- **Library > History** screen shows watch history
- Videos display progress bar underneath thumbnail
- "Continue Watching" shelf shows incomplete videos
- "Completed" badge shown when watchedSeconds ≥ 95% of totalSeconds

### 4. Feed Caching

**Offline Capabilities:**

✅ View cached home feed  
✅ View cached explore feed  
✅ Browse cached group posts  
✅ View video thumbnails (cached)  
❌ Refresh feed (requires network)  
❌ Load more items (pagination requires network)  

**Cache Strategy:**

- Last **100 feed items** cached when online
- **24-hour expiration** for most content
- Stories expire 24 hours after creation
- Live streams removed when status changes to `ENDED`
- Thumbnails cached separately (persistent until cleared)

**Cache Invalidation:**

Feed cache invalidated when:

- User pulls to refresh (requires online)
- 24 hours elapsed since last refresh
- User explicitly clears cache (Settings > Data & Storage > Clear Cache)
- User logs out

---

## Conflict Resolution

### Message Conflicts

**Scenario:** User edits message on Device A (offline) and Device B (online) simultaneously.

**Resolution Strategy:** **Last-Write-Wins (Server Timestamp)**

```
1. Device A edits message offline:
   - content: "Updated text A"
   - updatedAt: 2026-09-25T10:00:00Z (local)
   - isSynced: false

2. Device B edits same message online:
   - content: "Updated text B"
   - Server accepts immediately
   - updatedAt: 2026-09-25T10:01:00Z (server)

3. Device A syncs:
   - Attempts PATCH /messages/{id} with "Updated text A"
   - Server responds with 409 Conflict or 200 with newer updatedAt
   - Frontend fetches latest version from server
   - Device A now shows "Updated text B" (server version wins)

4. User notified: "Your edits were overwritten by a newer version"
```

**Mitigation:**

- WebSocket real-time sync reduces conflict window
- Optimistic locking with version numbers (future enhancement)
- User can re-apply their changes manually

### Calendar Note Conflicts

**Scenario:** User edits calendar note on Device A (offline) and Device B (online).

**Resolution Strategy:** **Server Wins + Conflict Flag**

```
1. Device A edits note offline:
   - title: "Updated title A"
   - lastSyncedAt: 2026-09-25T09:00:00Z
   - isSynced: false
   - conflictDetected: false

2. Device B edits note online:
   - title: "Updated title B"
   - Server updatedAt: 2026-09-25T10:00:00Z

3. Device A attempts sync:
   - Compares lastSyncedAt (09:00) vs server updatedAt (10:00)
   - server updatedAt > local lastSyncedAt → conflict
   - Mark conflictDetected: true
   - Show conflict UI to user

4. User reviews conflict:
   - Local version: "Updated title A"
   - Server version: "Updated title B"
   - User chooses: Keep Local, Keep Server, or Merge

5. Conflict resolution applied:
   - Chosen version saved to both local and server
   - conflictDetected: false
   - lastSyncedAt: updated
```

**Conflict UI:**

Calendar > Conflicts badge shows number of unresolved conflicts. Tapping opens conflict review screen:

```
┌─────────────────────────────────────────┐
│ 🔶 Conflict Detected                    │
├─────────────────────────────────────────┤
│ Your version (Device A):                │
│ Title: "Updated title A"                │
│ Content: "..."                          │
│                                         │
│ Server version (Device B):              │
│ Title: "Updated title B"                │
│ Content: "..."                          │
├─────────────────────────────────────────┤
│ [Keep Mine] [Keep Server] [Merge ↗]    │
└─────────────────────────────────────────┘
```

### Video Progress Conflicts

**Scenario:** User watches video on multiple devices.

**Resolution Strategy:** **Last-Write-Wins (Server Timestamp)**

```
Device A: watchedSeconds: 120s (synced at 10:00)
Device B: watchedSeconds: 200s (synced at 10:05)

Server stores: 200s (Device B overwrites Device A)

Device A refreshes → fetches progress: 200s (jumps forward)
Device B refreshes → fetches progress: 200s (no change)
```

**User Experience:**

- Progress may jump forward/backward when switching devices
- "Resume from X:XX?" prompt shows server progress
- User can choose to start from beginning if progress seems wrong

---

## Data Retention & Storage

### Local Database Size Management

**Target Size:** < 100 MB (typical usage)  
**Maximum Size:** 500 MB (before aggressive cleanup)

**Size Breakdown:**

| Data Type | Typical Size | Retention Policy |
|-----------|-------------|------------------|
| Messages | 10-50 MB | Last 1000 messages per conversation |
| Watch History | 1-5 MB | Last 500 entries |
| Feed Cache | 5-10 MB | 24-hour rolling window (100 items) |
| Calendar Notes | 1-2 MB | No limit (user data) |
| Search History | < 1 MB | Last 50 queries |
| Sync Queue | 1-5 MB | Pending + failed entries (auto-cleanup) |
| **Total (excluding downloads)** | **20-75 MB** | |

**Downloaded Videos:** Separate from database (file system storage)

- Typical: 50-500 MB per video (depends on quality and duration)
- User controls retention via auto-delete policy

### Storage Limits & Quotas

**Android:**

- App data quota enforced by OS (varies by device and Android version)
- Users with < 500 MB free device storage receive warning
- Auto-delete policy triggered when storage critically low

**iOS:**

- SQLite database can grow up to available device storage
- iOS may purge app cache during low storage conditions
- Downloaded videos marked as "do not purge" to prevent OS deletion

### Data Cleanup Strategies

#### Automatic Cleanup (Daily)

Runs at 3:00 AM local time:

1. **Completed Sync Queue Entries** → Deleted immediately after success
2. **Abandoned Sync Queue Entries > 30 days** → Deleted
3. **Feed Cache Expired Items** → Deleted (expiresAt < now)
4. **Watch History > 500 entries** → Oldest entries deleted
5. **Message Cache > 1000 per conversation** → Oldest messages deleted
6. **Search History > 50 queries** → Oldest queries deleted

#### Manual Cleanup (User-Initiated)

**Settings > Data & Storage > Clear Cache:**

- Clears feed cache
- Clears search history
- Clears expired sync queue entries
- **Does NOT delete:** Messages, calendar notes, downloaded videos, watch history

**Settings > Data & Storage > Clear All Data:**

- Full database wipe (all tables)
- Retains: User session (login state), app preferences
- **Does NOT delete:** Downloaded video files (separate option)

**Settings > Data & Storage > Delete All Downloads:**

- Deletes all downloaded video files from file system
- Updates `local_videos` table: `isDownloaded: false`, `localFilePath: null`, `downloadStatus: 'none'`

---

## Performance & Optimization

### Database Performance

**Write-Ahead Logging (WAL):**

SQLite WAL mode enables concurrent readers and writers:

- Multiple read queries can execute without blocking writes
- Write transactions append to WAL file instead of modifying main DB
- Checkpointing merges WAL into main DB periodically

**Indexing:**

Key indexes for offline queries:

```sql
-- Message queries (conversation timeline)
CREATE INDEX idx_messages_conversation_sent 
  ON local_messages(conversationId, sentAt DESC);

-- Watch history (recent videos)
CREATE INDEX idx_watch_history_user_recent 
  ON local_watch_history(userId, lastWatchedAt DESC);

-- Sync queue (pending operations)
CREATE INDEX idx_sync_queue_status_retry 
  ON sync_queue(status, nextRetryAt);

-- Feed cache (home feed)
CREATE INDEX idx_feed_items_type_rank 
  ON local_feed_items(type, rank);

-- Calendar notes (upcoming reminders)
CREATE INDEX idx_calendar_notes_reminder 
  ON local_calendar_notes(hasReminder, reminderDateTime);
```

**Query Optimization:**

- Limit result sets (e.g., last 50 messages per query)
- Lazy loading for message history (infinite scroll pagination)
- Precomputed aggregates (unread counts, watch progress percentages)

### Network Optimization

**Request Batching:**

- Read receipts batched to conversation-level updates
- Watch progress updates debounced (5-second intervals)
- Sync queue processed in batches of 10 operations

**Compression:**

- JSON payloads gzipped for sync operations
- Video thumbnails fetched in WebP format (smaller than JPEG)

**Caching Headers:**

- Feed API responses include `Cache-Control: max-age=300` (5 minutes)
- Video metadata cached with `ETag` support (conditional requests)

### Battery Optimization

**Background Sync:**

- WorkManager respects battery constraints (`requiresBatteryNotLow`)
- Sync intervals extended during low battery mode (30 minutes instead of 15)
- Aggressive sync (every 5 minutes) only when charging

**Wake Locks:**

- Sync operations acquire partial wake lock (CPU only, screen off)
- Wake lock released immediately after sync completes
- Maximum wake lock duration: 60 seconds (safety timeout)

---

## User Experience

### Offline Status Banner

**Design:**

Persistent banner at top of screen when offline:

```
┌─────────────────────────────────────────┐
│ 📡 Offline • Tap to retry               │
└─────────────────────────────────────────┘
```

**States:**

| Status | Banner Text | Color | Icon | Dismissible |
|--------|------------|-------|------|-------------|
| Offline | "Offline" | Gray | 📡 | No |
| Syncing | "Syncing..." | Blue | 🔄 (animated) | No |
| Success | "Synced ✓" | Green | ✓ | Auto (2s) |
| Failed | "Sync failed • Tap to retry" | Yellow | ⚠️ | Yes |

**User Actions:**

- Tap "Offline" → Opens connectivity troubleshooting dialog
- Tap "Sync failed" → Manually triggers sync retry
- Pull-to-refresh on any screen → Triggers sync (if online)

### Pending Message Indicators

Messages created offline show clear status:

```
┌─────────────────────────────────────────┐
│ You                            10:30 AM │
│ Hello from offline mode! 🕐             │
│ • Sending...                            │
└─────────────────────────────────────────┘
```

**Status Progression:**

```
🕐 Pending → ✓ Sent → ✓✓ Delivered → ✓✓ (blue) Read
```

**Retry Failed Messages:**

```
┌─────────────────────────────────────────┐
│ You                            10:30 AM │
│ Failed to send message ⚠️               │
│ [Retry] [Delete]                        │
└─────────────────────────────────────────┘
```

### Download Progress UI

**Video Card (Download Button):**

```
┌─────────────────────────────────────────┐
│ [Thumbnail]                             │
│ Video Title                             │
│ ┌────────────────────────────────────┐  │
│ │ [↓ Download (720p)]                │  │
│ └────────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

**During Download:**

```
┌─────────────────────────────────────────┐
│ [Thumbnail]                             │
│ Video Title                             │
│ ┌────────────────────────────────────┐  │
│ │ Downloading 720p • 45%             │  │
│ │ ████████████░░░░░░░░░░░░░░░░       │  │
│ │ 23 MB / 51 MB                      │  │
│ │ [⏸ Pause] [✕ Cancel]               │  │
│ └────────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

**Download Complete:**

```
┌─────────────────────────────────────────┐
│ [Thumbnail]                             │
│ Video Title                             │
│ ┌────────────────────────────────────┐  │
│ │ Downloaded (720p) • 51 MB ✓        │  │
│ │ [▶ Play] [🗑 Delete]                │  │
│ └────────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### Offline Capabilities Badge

Features that work offline display a badge:

```
┌─────────────────────────────────────────┐
│ Calendar Notes 📡                       │
│ "Works offline with local reminders"    │
└─────────────────────────────────────────┘
```

---

## Troubleshooting

### Sync Not Happening

**Symptoms:**

- Messages stuck in "pending" state
- "Syncing..." banner never completes
- Sync failed banner appears repeatedly

**Diagnosis:**

1. Check connectivity:
   - Airplane mode off?
   - Wi-Fi/mobile data enabled?
   - Can access other apps/websites?

2. Check sync queue:
   - Settings > Developer Options > View Sync Queue
   - Look for entries with `status: 'failed'` or `status: 'abandoned'`

3. Check logs:
   - Settings > Help & Feedback > Export Logs
   - Search for `[SyncManager]` errors

**Solutions:**

| Issue | Solution |
|-------|----------|
| Offline | Wait for connectivity, sync will auto-trigger |
| Rate limited (429) | Wait 15 minutes, sync will retry |
| Unauthorized (401) | Log out and log back in (token expired) |
| Abandoned operations | Settings > Data & Storage > Clear Failed Syncs |
| Watchdog fired | Force quit app and reopen (rare crash scenario) |

### Downloads Failing

**Symptoms:**

- Download starts but fails after a few seconds
- "Download failed" error message
- `downloadStatus: 'failed'` in local_videos table

**Diagnosis:**

1. Check download error:
   - Long-press video → View Download Error
   - Common errors:
     - "Signed URL expired" (download took > 1 hour)
     - "Insufficient storage" (< 500 MB free space)
     - "Network error" (connection interrupted)

2. Check download permission:
   - Settings > App Permissions > Storage (must be granted)
   - Android: Check if app has "Files and Media" permission

**Solutions:**

| Error | Solution |
|-------|----------|
| Signed URL expired | Retry download (generates new URL) |
| Insufficient storage | Free up space or lower download quality |
| Network interrupted | Resume download (if < 1 hour since start) |
| Permission denied | Grant storage permission in Settings |

### Message Delivery Issues

**Symptoms:**

- Messages show ✓ (sent) but recipient doesn't receive
- Messages stuck at 🕐 (pending) despite being online
- Duplicate messages appear after sync

**Diagnosis:**

1. Check message status in sync_queue:
   - Look for `operationType: CREATE_MESSAGE` with `status: 'failed'`
   - Check `errorMessage` field

2. Common errors:
   - `403 Forbidden` → User is no longer member of group/conversation
   - `404 Not Found` → Conversation deleted on server
   - `422 Validation Error` → Message content invalid (e.g., > 10,000 characters)

**Solutions:**

| Error | Solution |
|-------|----------|
| 403 Forbidden | Verify group membership, may need to rejoin |
| 404 Not Found | Conversation no longer exists, delete local copy |
| 422 Validation | Edit message to fix validation issue, retry |
| Duplicate messages | Clear sync queue, fetch fresh messages from server |

### Calendar Reminders Not Firing

**Symptoms:**

- Reminder time passes but no notification shown
- Reminder shows `reminderNotified: false` after scheduled time

**Diagnosis:**

1. Check notification permissions:
   - Settings > App Permissions > Notifications (must be enabled)
   - Android: Check if "Calendar Reminders" channel enabled

2. Check reminder configuration:
   - Calendar > Note Details > Reminder
   - Verify `hasReminder: true` and `reminderDateTime` is in future

3. Check system notification settings:
   - Android: Settings > Apps > Zikire Kdusan > Notifications
   - Ensure "Calendar Reminders" category not snoozed or blocked

**Solutions:**

| Issue | Solution |
|-------|----------|
| Notifications disabled | Enable in app and system settings |
| Reminder in past | Edit reminder to future time |
| App battery optimized | Exempt app from battery optimization (Settings > Battery) |
| Reminder channel snoozed | Re-enable channel in system notification settings |

### High Storage Usage

**Symptoms:**

- App using > 500 MB storage
- Device shows "Storage almost full" warning
- App performance degraded (slow queries)

**Diagnosis:**

1. Check storage breakdown:
   - Settings > Data & Storage > Storage Usage
   - Shows: Database, Downloads, Cache, Logs

2. Identify largest consumers:
   - Usually downloaded videos (50-500 MB each)
   - Less common: Large message attachment cache

**Solutions:**

| Issue | Solution |
|-------|----------|
| Too many downloads | Settings > Data & Storage > Delete Old Downloads |
| Large database | Settings > Data & Storage > Clear Cache |
| Attachment cache | Settings > Data & Storage > Clear Media Cache |
| Enable auto-delete | Settings > Data & Storage > Auto-Delete After 30 Days |

### Sync Conflicts

**Symptoms:**

- Calendar > Conflicts badge shows number
- "Your changes were overwritten" notification
- Note content different on different devices

**Resolution:**

1. Go to Calendar > View Conflicts
2. Review conflicting versions side-by-side
3. Choose:
   - **Keep Mine** → Local version synced to server
   - **Keep Server** → Server version replaces local
   - **Merge** → Opens editor to manually combine changes
4. Conflict resolved and synced

**Prevention:**

- Always sync before editing (Settings > Sync > Sync Now)
- Avoid editing same note on multiple devices simultaneously
- Enable real-time sync (Settings > Sync > Sync in Background)

---

## Summary

Zikire Kdusan's offline capabilities provide a robust, user-friendly experience that handles connectivity loss gracefully:

✅ **Drift SQLite** local database with 10+ tables and 4 schema migrations  
✅ **SyncManager** orchestrates 9 operation types with exponential backoff retry  
✅ **15-minute background sync** via WorkManager with battery-aware constraints  
✅ **Connectivity monitoring** with 3-tier reachability probing (server → internet → DNS)  
✅ **Video downloads** with signed URLs, quality selection, and audit trail  
✅ **Offline-first features**: messaging, calendar reminders, watch history, feed caching  
✅ **Conflict resolution** strategies for messages, calendar notes, and video progress  
✅ **Storage management** with auto-cleanup, retention policies, and user controls  
✅ **Performance optimizations**: WAL mode, indexing, batching, compression  
✅ **User experience**: status banners, pending indicators, download progress, conflict UI

The system is designed for **reliability** (retry strategy, watchdog timers, audit logging), **performance** (WAL mode, indexing, batching), and **user experience** (clear status indicators, conflict resolution UI, storage management).

---

**Related Documentation:**

- [USER_GUIDE.md](./USER_GUIDE.md) - Feature-by-feature user instructions  
- [ARCHITECTURE.md](./ARCHITECTURE.md) - High-level system architecture  
- [DATABASE.md](./DATABASE.md) - Complete Prisma schema reference  
- [REALTIME_AND_LIVE.md](./REALTIME_AND_LIVE.md) - WebSocket and live streaming architecture  
- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - Common issues and solutions

---

*This document reflects the actual implementation as of September 25, 2026. All features and code references have been verified against the codebase.*
