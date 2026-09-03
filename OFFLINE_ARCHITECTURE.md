# ዝክረ ክዱሳን (Zikre Kidusan) — Offline-First Architecture & Synchronization Guide

This document specifies the production-grade **offline-first data architecture**, synchronization engine, download management, and idempotency guarantees for the **ዝክረ ክዱሳን (Stream Hub)** mobile application and backend services.

---

## 1. System Architecture Overview

```
+-----------------------------------------------------------------------------------+
|                                 MOBILE APPLICATION                                 |
|                                                                                   |
|  [ Flutter UI / Riverpod ]                                                        |
|         │                                                                         |
|         ├─────────► Local Cache First (Instant Render)                            |
|         │                    │                                                    |
|         ▼                    ▼                                                    |
|  [ Repositories ] ◄───► [ Drift / SQLite Database (WAL Mode) ]                    |
|         │               - local_videos                                            |
|         │               - local_conversations                                     |
|         │               - local_messages                                          |
|         │               - local_message_attachments                               |
|         │               - local_watch_history                                     |
|         │               - local_search_history                                    |
|         │               - local_feed_items                                        |
|         │               - local_users                                             |
|         │               - sync_queue                                              |
|         │                                                                         |
|         ├─────────────────────────────────────────┐                               |
|         ▼                                         ▼                               |
|  [ VideoDownloadManager ]                  [ SyncManager ]                        |
|  - Cloudinary MP4 rendition                - Non-reentrant queue processor        |
|  - Resumable Range HTTP                    - Exponential backoff (2s->60s)        |
|  - Deterministic disk hierarchy            - Atomic SQLite transactions           |
|  - Free space validation                   - Background Workmanager periodic sync |
|  - Separate from SyncManager               - Delta sync reconciliation            |
+─────────┬─────────────────────────────────────────┬───────────────────────────────+
          │                                         │
          │ (Large Media / Video)                   │ (API / Delta Sync / Messages)
          ▼                                         ▼
+───────────────────────────+             +─────────────────────────────────────────+
|     Cloudinary CDN        |             |         NestJS Backend Engine           |
|  - MP4 progressive        |             |  - ClientId Idempotency check           |
|  - Adaptive HLS / DASH    |             |  - Delta endpoints (/updates)           |
|                           |             |  - PostgreSQL / Neon authoritative DB   |
+───────────────────────────+             +─────────────────────────────────────────+
```

---

## 2. Local Database Schema (Drift / SQLite)

The local database is located at `<app_documents>/zikre_kidusan_local_v1.db`, running with **WAL (Write-Ahead Logging)** mode and foreign keys enabled.

### Database Tables Summary

| Table | File | Purpose |
|---|---|---|
| `local_users` | `lib/core/database/tables/local_users_table.dart` | Stores user profiles, display names, avatars, and presence data. |
| `local_videos` | `lib/core/database/tables/local_videos_table.dart` | Caches video metadata, playback progress, download state, local file path, and quality renditions. |
| `local_conversations` | `lib/core/database/tables/local_conversations_table.dart` | Chat conversations list, unread counters, pinned and muted states. |
| `local_messages` | `lib/core/database/tables/local_messages_table.dart` | Chat messages with client UUIDs (`clientId`), server IDs (`serverId`), pending sync indicators, and JSON-encoded reactions/attachments. |
| `local_message_attachments` | `lib/core/database/tables/local_message_attachments_table.dart` | Local file paths, MIME types, upload progress, and download statuses for attachments. |
| `local_watch_history` | `lib/core/database/tables/local_watch_history_table.dart` | Tracks video watch positions in seconds, completion flags, and debounced synchronization states. |
| `local_search_history` | `lib/core/database/tables/local_search_history_table.dart` | Offline search queries and categories with LRU eviction. |
| `local_feed_items` | `lib/core/database/tables/local_feed_items_table.dart` | Pre-cached home and trending feed cards ensuring instant cold start without internet. |
| `sync_queue` | `lib/core/database/tables/sync_queue_table.dart` | Persistent FIFO queue of pending mutations to be synced with the server. |

---

## 3. Synchronization Algorithm & Retry Strategy

### Queue Processor (`SyncManager`)
- **Non-reentrant Execution**: A mutex flag ensures that only one synchronization pass runs at any given time.
- **Trigger Points**:
  1. Instant connectivity restoration (`ConnectivityService` transition to `online`).
  2. Immediate user mutation (optimistic local save + attempt immediate sync).
  3. App launch (`main.dart` after database initialization).
  4. App resume from background.
  5. OS background execution (`Workmanager` periodic task every 15 minutes).

### Exponential Backoff Strategy
```
Attempt 0: 2 seconds
Attempt 1: 5 seconds
Attempt 2: 15 seconds
Attempt 3: 30 seconds
Attempt 4: 60 seconds
Attempt >= 5: Marked as failed. Retained in queue for manual retry or next connection transition.
```

### Delta Synchronization Endpoints
- **Conversations Delta**: `GET /conversations/updates?since=<ISO8601>`
  Returns all conversations modified or with new messages since the last sync cursor.
- **Messages Delta**: `GET /conversations/:id/messages/updates?since=<ISO8601>&limit=100`
  Returns:
  - `messages`: Newly created or updated messages (edits, read receipts, reactions).
  - `deletedIds`: Message IDs soft-deleted or purged with tombstones (`deletedForEveryoneAt`).
  - `serverTimestamp`: Authoritative server time to advance the client's high-water mark.

---

## 4. Message Idempotency & Reconciliation Guarantees

### The Offline Message Flow
1. **User sends message while offline**:
   - Client generates a UUID v4: `clientId = "550e8400-e29b-41d4-a716-446655440000"`.
   - Message is saved in Drift SQLite `local_messages`:
     - `localId = clientId`
     - `serverId = null`
     - `status = 'pending'`
     - `isPendingSync = true`
   - Mutation is inserted into `sync_queue` (`operationType = 'SEND_MESSAGE'`).
   - UI renders message instantly with pending icon (clock).

2. **Device goes online**:
   - `SyncManager` picks up the item and posts to `POST /conversations/:id/messages` with `{ ..., clientId: "550e8400..." }`.
   - **Backend Idempotency Check**:
     ```typescript
     const existing = await this.prisma.message.findFirst({
       where: { senderId, clientId: dto.clientId },
     });
     if (existing) return existing; // Safe return, no duplication
     ```
   - Server returns authoritative `MessageResponseDto` with server ID (e.g. `srv_msg_123`).
   - Client reconciles in SQLite:
     - `local_messages.serverId = 'srv_msg_123'`
     - `local_messages.status = 'sent'`
     - `local_messages.isPendingSync = false`
   - Sync queue item is deleted.

3. **Network Drops Mid-Flight / Request Retried**:
   - If the server processed the message before the connection dropped, the retried request sends the **SAME `clientId`**.
   - Server detects the existing record and returns it immediately.
   - Client reconciles safely without duplicate messages in either database.

---

## 5. Video Storage & Download Management

### Strict Architecture Separation
`VideoDownloadManager` is **completely decoupled** from `SyncManager`:
- `SyncManager` handles lightweight metadata, chat messages, reactions, and history.
- `VideoDownloadManager` handles heavy media streams, disk validation, chunked downloads, pause, resume, and cancellation.
- **Videos are NEVER automatically downloaded during sync**. Downloads are strictly user-initiated.

### Cloudinary Rendition Strategy
1. Cloudinary video URLs are inspected for MP4 renditions.
2. The manager targets progressive MP4 URLs formatted for device resolution (e.g., `720p`, `480p`, `360p`) rather than raw remote HLS playlists.
3. If an HLS URL is supplied, the resolver checks for Cloudinary transformation flags (`/so_0/sp_auto/` or `/q_auto,f_mp4/`) to request a self-contained MP4 rendition for complete offline playback.

### Deterministic Storage Directory Hierarchy
```
<ApplicationDocumentsDirectory>/
  videos/
    video_<videoId>/
      720p.mp4                <-- Completed, verified video file
      720p.mp4.tmp            <-- Partial download with HTTP Range resume support
      metadata.json           <-- Video title, duration, author, downloadedAt
  chat/
    conversation_<convId>/
      message_<msgId>/
        attachment_<fileId>.jpg
```

### Disk Space Protection
Before enqueueing or starting a download, the manager validates available free storage. If available space is below `estimatedSize * 1.5` or below 200MB, the download fails gracefully with `DiskSpaceException`.

### Cache vs. Download Safety
- **Clear Cache** (`cacheManager.clearCache()`):
  Purges temporary files, thumbnail disk caches, and `.tmp` chunks. **Downloaded videos are strictly preserved**.
- **Delete Downloads** (`cacheManager.clearDownloads()`):
  Only executed when the user explicitly confirms via the Storage Settings modal.

---

## 6. Startup Sequence & Offline-First UI

### Initialization (`lib/main.dart`)
1. `WidgetsFlutterBinding.ensureInitialized()`
2. `Env.init()`
3. Eager SQLite Initialization: `final appDatabase = AppDatabase();` (Never blocks on network).
4. `BackgroundSyncService.initialize()`
5. `runApp(ProviderScope(overrides: [appDatabaseProvider.overrideWithValue(appDatabase)]))`

### UI Behavior
- **Zero Blocking**: The app opens instantly to cached data (`local_feed_items`, `local_conversations`, `local_watch_history`).
- **Global Banner**: `OfflineStatusBanner` smoothly slides down from app shell during offline mode or active sync without obstructing user actions.
- **Settings Screen**: `StorageSettingsScreen` (`/settings/storage`) provides live storage breakdowns (Videos, Chat Media, Cache, Temp) and space recovery tools.

---

## 7. Maintenance & Engineering Guidelines

1. **Schema Migrations**:
   - Drift: Increment `schemaVersion` in `lib/core/database/app_database.dart` and define step-by-step migrations using `MigrationStrategy.onUpgrade`.
   - Never call `deleteDatabase()` as a recovery fallback.
2. **Adding New Offline Sync Entities**:
   - Define entity in `sync_types.dart`.
   - Add table and DAO in `lib/core/database/`.
   - Register mutation handler in `SyncManager._processOperation()`.
3. **Backend Idempotency Rule**:
   - Any new mutable sync endpoint must accept an optional `clientId` and perform an idempotency lookup before executing inserts.
