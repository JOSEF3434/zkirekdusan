# Ethiopian Calendar Feature - Complete Implementation Guide

**Status:** ✅ IMPLEMENTATION COMPLETE (Phases 1-5)  
**Version:** 1.0.0  
**Date:** September 8, 2026  

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Architecture](#architecture)
4. [Setup Instructions](#setup-instructions)
5. [User Guide](#user-guide)
6. [Developer Guide](#developer-guide)
7. [API Documentation](#api-documentation)
8. [Troubleshooting](#troubleshooting)
9. [Future Enhancements](#future-enhancements)

---

## Overview

A fully-featured **Ethiopian Calendar** with offline-first note-taking capabilities. Users can create, view, edit, and delete notes tied to specific Ethiopian calendar dates, attach media (photos, videos, audio), and sync seamlessly across devices.

### Key Highlights

- ✅ **Authentic Ethiopian Calendar** using `abushakir` package
- ✅ **Offline-First** with automatic background sync
- ✅ **Media Support** for images, videos, and audio files
- ✅ **Real-Time Sync** with conflict resolution
- ✅ **Clean Architecture** with proper separation of concerns
- ✅ **Type-Safe Database** using Drift
- ✅ **RESTful API** with JWT authentication

---

## Features

### Calendar View
- 📅 Ethiopian month grid with proper weekday names (Segno, Maksegno, etc.)
- 📆 Month navigation (previous/next/today)
- 🔢 Gregorian date equivalents displayed
- 📍 Today indicator with border highlight
- 🎯 Selected date with background color
- 🔔 Note count badges on days (e.g., "3", "9+")

### Notes Management
- ✍️ **Create Notes**: Tap any day or long-press for quick add
- 👁️ **View Notes**: Tap days with notes to see full list
- ✏️ **Edit Notes**: Tap any note to edit title/content
- 🗑️ **Delete Notes**: Soft delete with confirmation dialog
- 📂 **Multiple Notes per Day**: No limit on notes per date

### Media Attachments
- 📷 **Take Photo**: Capture photo directly from camera
- 🖼️ **Choose Photos**: Select multiple from gallery
- 🎥 **Record Video**: Record video from camera
- 📹 **Choose Video**: Select from gallery
- 🎵 **Audio Files**: Attach audio recordings
- 📎 **Any File Type**: PDFs, documents, etc.
- 🔄 **Upload Progress**: Visual progress indicator
- 🖼️ **Thumbnail Previews**: Grid display in notes list

### Offline Capabilities
- 💾 **Instant Saves**: All operations work without internet
- 🔄 **Auto-Sync**: Background sync when online
- 📊 **Sync Queue**: Queued operations processed in order
- ⚡ **Fast Performance**: Reads from local SQLite cache
- 🔐 **Data Integrity**: Conflict resolution with server precedence

---

## Architecture

### Tech Stack

#### Backend
- **Framework**: NestJS (TypeScript)
- **Database**: PostgreSQL via Prisma ORM
- **File Storage**: Cloudinary
- **Authentication**: JWT with refresh tokens
- **API Style**: RESTful with OpenAPI/Swagger docs

#### Frontend
- **Framework**: Flutter
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Local Database**: Drift (SQLite)
- **Ethiopian Calendar**: abushakir package
- **HTTP Client**: Dio with interceptors

### Data Flow

```
┌─────────────┐
│   Flutter   │
│     UI      │
└──────┬──────┘
       │
       ▼
┌─────────────────────┐
│ Offline Repository  │  ← Riverpod Providers
└──────┬──────────────┘
       │
       ├──────────────┐
       │              │
       ▼              ▼
┌──────────┐   ┌─────────────┐
│  Drift   │   │   Remote    │
│ Database │   │ Repository  │
│ (SQLite) │   │   (API)     │
└──────────┘   └─────┬───────┘
                     │
                     ▼
              ┌─────────────┐
              │   NestJS    │
              │   Backend   │
              └─────┬───────┘
                    │
                    ▼
              ┌─────────────┐
              │  PostgreSQL │
              │   + Prisma  │
              └─────────────┘
```

### Database Schema

#### Prisma (Backend - PostgreSQL)
```prisma
model CalendarNote {
  id             String   @id @default(uuid())
  userId         String
  ethiopianYear  Int
  ethiopianMonth Int
  ethiopianDay   Int
  gregorianDate  DateTime
  title          String?
  content        String?  @db.Text
  media          CalendarNoteMedia[]
  createdAt      DateTime @default(now())
  updatedAt      DateTime @updatedAt
  deletedAt      DateTime?
}

model CalendarNoteMedia {
  id      String @id @default(uuid())
  noteId  String
  fileId  String
  order   Int
  caption String?
  createdAt DateTime @default(now())
}
```

#### Drift (Frontend - SQLite)
```dart
class LocalCalendarNotes extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  IntColumn get ethiopianYear => integer()();
  IntColumn get ethiopianMonth => integer()();
  IntColumn get ethiopianDay => integer()();
  DateTimeColumn get gregorianDate => dateTime()();
  TextColumn get title => text().nullable()();
  TextColumn get content => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isPendingDelete => boolean().withDefault(const Constant(false))();
}
```

---

## Setup Instructions

### Prerequisites

- **Flutter SDK**: 3.8.0 or higher
- **Dart SDK**: 3.8.0 or higher
- **Node.js**: 18+ with npm
- **PostgreSQL**: 13+ (for backend database)
- **Cloudinary Account**: For media storage

### Backend Setup

#### 1. Install Dependencies
```bash
cd backend
npm install
```

#### 2. Configure Environment
Create/update `backend/.env`:
```env
DATABASE_URL="postgresql://user:password@host:5432/dbname"
JWT_SECRET="your-jwt-secret"
JWT_REFRESH_SECRET="your-refresh-secret"
CLOUDINARY_CLOUD_NAME="your-cloud-name"
CLOUDINARY_API_KEY="your-api-key"
CLOUDINARY_API_SECRET="your-api-secret"
```

#### 3. Run Database Migration
```bash
npx prisma migrate deploy
# OR for development:
npx prisma migrate dev
```

#### 4. Generate Prisma Client
```bash
npx prisma generate
```

#### 5. Build & Start Server
```bash
npm run build
npm run start:prod
# OR for development:
npm run start:dev
```

**Backend will be available at:** `http://localhost:3000`  
**API Docs (Swagger):** `http://localhost:3000/api`

---

### Frontend Setup

#### 1. Install Dependencies
```bash
cd mobile
flutter pub get
```

#### 2. Generate Code (CRITICAL)
```bash
dart run build_runner build --delete-conflicting-outputs
```

**This generates:**
- Drift database code (`*.g.dart`)
- Freezed models (`*.freezed.dart`, `*.g.dart`)
- All code-generated files

**⚠️ App will not compile without this step!**

#### 3. Configure API Endpoint
Update `mobile/lib/app/env/env.dart`:
```dart
abstract class Env {
  static const String apiBaseUrl = 'http://localhost:3000';
  // OR your production URL
}
```

#### 4. Run the App
```bash
flutter run
# OR for specific device:
flutter run -d chrome
flutter run -d android
flutter run -d ios
```

---

## User Guide

### Navigating the Calendar

#### Opening the Calendar
1. Launch the app
2. Tap the **Calendar** tab in the bottom navigation (second icon)
3. The current Ethiopian month displays

#### Month Navigation
- **Previous Month**: Tap left arrow `◀` in app bar
- **Next Month**: Tap right arrow `▶` in app bar
- **Jump to Today**: Tap calendar icon `📅` in app bar

#### Understanding the Display
- **Bold border**: Today's date
- **Blue background**: Selected date
- **Number badge**: Count of notes for that day (e.g., "3", "9+")
- **Gregorian range**: Shown below month name

---

### Creating Notes

#### Method 1: Tap Day First
1. Tap any date on the calendar
2. Bottom sheet opens showing existing notes (if any)
3. Tap **"Add Note"** button at bottom
4. Fill in title (optional) and content
5. Optionally add media
6. Tap **"Save"**

#### Method 2: Long Press (Quick Add)
1. **Long press** any date on the calendar
2. Add note form opens directly
3. Fill in details
4. Tap **"Save"**

---

### Adding Media to Notes

1. While creating/editing a note, tap **"Add Media"**
2. Select media type:
   - **Take Photo**: Opens camera
   - **Choose Photos**: Gallery picker (multi-select)
   - **Record Video**: Camera in video mode
   - **Choose Video**: Video from gallery
   - **Choose Audio**: Audio file picker
   - **Choose File**: Any file type
3. Selected media appears as thumbnails
4. Tap **X** on thumbnail to remove
5. Upload happens automatically when you save

**Upload Progress:**
- Circular indicator overlays thumbnail
- Shows percentage complete
- Cannot close until upload finishes

---

### Viewing Notes

1. Tap any day with a note badge
2. Bottom sheet opens with scrollable list
3. Each note shows:
   - Title (bold) if present
   - Content preview (2-3 lines)
   - Media thumbnails (horizontal scroll)
4. Tap any note to edit
5. Tap **⋮** menu for edit/delete options

---

### Editing Notes

1. Tap the note from the day's notes list
2. Edit form opens with existing content
3. Modify title, content, or add/remove media
4. Tap **"Save"** to update
5. Changes sync automatically when online

---

### Deleting Notes

1. Tap **⋮** menu on a note
2. Select **"Delete"**
3. Confirm deletion in dialog
4. Note disappears immediately
5. Deletion syncs to server when online

---

### Offline Usage

**The app works fully offline!**

#### What Works Offline:
✅ View all previously synced notes  
✅ Create new notes  
✅ Edit existing notes  
✅ Delete notes  
✅ Add media (uploads queue for later)  
✅ Browse calendar  
✅ All navigation

#### What Happens When You Go Back Online:
- Pending notes sync to server automatically
- Media uploads complete
- Notes from other devices download
- Sync happens in background (no interruption)

#### Sync Status:
- No visual indicator currently (Phase 8 enhancement)
- Check sync by refreshing from another device

---

## Developer Guide

### Project Structure

```
mobile/lib/features/calendar/
├── domain/
│   └── calendar_note_model.dart          # Freezed models
├── data/
│   ├── calendar_repository.dart          # Remote API client
│   ├── calendar_offline_repository.dart  # Offline-first repo
│   └── calendar_media_service.dart       # Media upload service
└── presentation/
    ├── calendar_screen.dart              # Main calendar UI
    ├── providers/
    │   ├── calendar_state_provider.dart  # Month navigation state
    │   └── calendar_notes_provider.dart  # Notes data providers
    └── widgets/
        ├── add_note_sheet.dart           # Create/edit form
        ├── day_notes_sheet.dart          # Notes list for date
        └── media_picker_sheet.dart       # Media type selector
```

### Adding a New Feature

#### Example: Add Note Sharing

**1. Update Domain Model**
```dart
// calendar_note_model.dart
@freezed
class CalendarNoteModel with _$CalendarNoteModel {
  const factory CalendarNoteModel({
    // ...existing fields...
    List<String>? sharedWithUserIds,  // NEW
  }) = _CalendarNoteModel;
}
```

**2. Update Backend Schema**
```prisma
// schema.prisma
model CalendarNote {
  // ...existing fields...
  sharedWith UserNoteShare[]
}

model UserNoteShare {
  noteId String
  userId String
  // ...
}
```

**3. Add API Endpoint**
```typescript
// calendar.controller.ts
@Post(':noteId/share')
shareNote(@Param('noteId') noteId: string, @Body() dto: ShareNoteDto) {
  return this.calendarService.shareNote(noteId, dto.userIds);
}
```

**4. Update UI**
```dart
// add_note_sheet.dart
// Add "Share" button
// Show shared users list
// Handle sharing logic
```

**5. Run Code Generation**
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

### Testing

#### Unit Tests
```bash
# Backend
cd backend
npm run test

# Frontend
cd mobile
flutter test
```

#### Integration Tests
```bash
# Backend
npm run test:e2e

# Frontend
flutter test integration_test/
```

#### Manual Testing Checklist
See [TESTING SCENARIOS](#testing-scenarios) section.

---

## API Documentation

### Authentication
All calendar endpoints require JWT authentication.

**Header:**
```
Authorization: Bearer <jwt_token>
```

---

### Endpoints

#### `GET /calendar/notes`
**Query all notes with optional filters**

**Query Parameters:**
- `year` (optional): Ethiopian year (e.g., 2017)
- `month` (optional): Ethiopian month (1-13)
- `day` (optional): Ethiopian day (1-30)

**Response:** `200 OK`
```json
{
  "data": [
    {
      "id": "uuid",
      "userId": "uuid",
      "ethiopianYear": 2017,
      "ethiopianMonth": 1,
      "ethiopianDay": 15,
      "gregorianDate": "2024-09-25T00:00:00.000Z",
      "title": "My Note",
      "content": "Note content here",
      "media": [
        {
          "id": "uuid",
          "fileId": "uuid",
          "order": 0,
          "caption": "Photo caption",
          "file": {
            "id": "uuid",
            "url": "https://cloudinary.../image.jpg",
            "mimeType": "image/jpeg"
          }
        }
      ],
      "createdAt": "2024-09-25T10:00:00.000Z",
      "updatedAt": "2024-09-25T10:00:00.000Z"
    }
  ]
}
```

---

#### `POST /calendar/notes`
**Create a new calendar note**

**Body:**
```json
{
  "ethiopianYear": 2017,
  "ethiopianMonth": 1,
  "ethiopianDay": 15,
  "gregorianDate": "2024-09-25T00:00:00.000Z",
  "title": "My Note",
  "content": "Note content here"
}
```

**Response:** `201 Created`
```json
{
  "data": {
    "id": "uuid",
    "userId": "uuid",
    "ethiopianYear": 2017,
    "ethiopianMonth": 1,
    "ethiopianDay": 15,
    "gregorianDate": "2024-09-25T00:00:00.000Z",
    "title": "My Note",
    "content": "Note content here",
    "media": [],
    "createdAt": "2024-09-25T10:00:00.000Z",
    "updatedAt": "2024-09-25T10:00:00.000Z"
  }
}
```

---

#### `PATCH /calendar/notes/:id`
**Update an existing note**

**Body:**
```json
{
  "title": "Updated Title",
  "content": "Updated content"
}
```

**Response:** `200 OK`
```json
{
  "data": {
    "id": "uuid",
    // ...updated note data...
  }
}
```

---

#### `DELETE /calendar/notes/:id`
**Delete a note (soft delete)**

**Response:** `200 OK`
```json
{
  "data": {
    "id": "uuid",
    "deletedAt": "2024-09-25T11:00:00.000Z"
  }
}
```

---

#### `POST /calendar/notes/:noteId/media`
**Add media to a note**

**Body:**
```json
{
  "fileId": "uuid",
  "order": 0,
  "caption": "Optional caption"
}
```

**Response:** `201 Created`
```json
{
  "data": {
    "id": "uuid",
    "noteId": "uuid",
    "fileId": "uuid",
    "order": 0,
    "caption": "Optional caption",
    "file": {
      "id": "uuid",
      "url": "https://cloudinary.../image.jpg"
    }
  }
}
```

---

#### `DELETE /calendar/notes/:noteId/media/:mediaId`
**Remove media from a note**

**Response:** `204 No Content`

---

#### `POST /uploads`
**Upload a file (images, videos, audio, etc.)**

**Body:** `multipart/form-data`
- `file`: File binary

**Response:** `200 OK`
```json
{
  "data": {
    "id": "uuid",
    "originalName": "photo.jpg",
    "fileName": "uuid.jpg",
    "mimeType": "image/jpeg",
    "size": 1024000,
    "url": "https://res.cloudinary.com/.../uuid.jpg",
    "thumbnailUrl": "https://res.cloudinary.com/.../thumb_uuid.jpg",
    "uploadedById": "uuid",
    "createdAt": "2024-09-25T10:00:00.000Z"
  }
}
```

---

## Troubleshooting

### Build Errors

#### "Part file doesn't exist"
**Problem:** Drift or Freezed generated files missing

**Solution:**
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

#### "CalendarNotesDao not found"
**Problem:** Database code not generated

**Solution:**
1. Ensure `app_database.dart` has `part 'app_database.g.dart';`
2. Run build_runner (see above)
3. Check for syntax errors in table definitions

---

#### "Table does not exist"
**Problem:** Database migration not applied

**Solution:**
```bash
# Backend
npx prisma migrate deploy

# Frontend - delete old database
flutter clean
flutter run  # Will recreate with schema v2
```

---

### Runtime Errors

#### "Cannot connect to server"
**Problem:** API endpoint incorrect or server not running

**Solution:**
1. Check `mobile/lib/app/env/env.dart` has correct URL
2. Verify backend is running: `curl http://localhost:3000/health`
3. Check network connectivity (Android emulator uses `10.0.2.2` for localhost)

---

#### "Unauthorized 401"
**Problem:** JWT token expired or invalid

**Solution:**
1. Log out and log in again
2. Check token refresh logic in `auth_interceptor.dart`
3. Verify JWT_SECRET matches between backend and stored tokens

---

#### Notes not syncing
**Problem:** Sync queue not processing

**Solution:**
1. Check `SyncQueueDao.getPendingEntries()` returns items
2. Verify `pushUnsyncedNotes()` is being called
3. Check network connection
4. Look for error logs in backend

---

### Performance Issues

#### Slow calendar rendering
**Problem:** Too many notes loading at once

**Solution:**
- Implement pagination in `getNotesForMonth()`
- Add lazy loading for media thumbnails
- Use `ListView.builder` instead of `ListView` in `day_notes_sheet.dart`

---

#### Large media uploads failing
**Problem:** File size exceeds limits

**Solution:**
1. Backend: Increase `sendTimeout` in Dio options
2. Add file size validation before upload
3. Consider image compression before upload

---

## Future Enhancements

### Phase 6: Background Sync Worker
- **Goal**: Automatic sync every 15 minutes
- **Package**: `workmanager` (already in pubspec.yaml)
- **Features**:
  - Battery-optimized periodic sync
  - Network-aware (WiFi vs. mobile data)
  - Retry logic for failed syncs
  - User-configurable sync frequency

**Implementation:**
```dart
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final repo = CalendarOfflineRepository(/* ... */);
    await repo.pushUnsyncedNotes();
    await repo.syncNotesFromServer();
    return Future.value(true);
  });
}

void main() {
  Workmanager().initialize(callbackDispatcher);
  Workmanager().registerPeriodicTask(
    "calendar-sync",
    "syncCalendarNotes",
    frequency: Duration(minutes: 15),
  );
}
```

---

### Phase 7: Notifications & Reminders
- **Features**:
  - Set reminder time for specific Ethiopian dates
  - Local notifications using `flutter_local_notifications`
  - Recurring reminders (daily, weekly, yearly)
  - Snooze functionality

**Schema Addition:**
```prisma
model CalendarNote {
  // ...existing fields...
  reminderAt DateTime?
  reminderRecurrence String? // DAILY, WEEKLY, MONTHLY, YEARLY
}
```

---

### Phase 8: UI/UX Polish
- ✨ **Pull-to-refresh** on calendar screen
- 📊 **Sync status indicator** in app bar
- ⚠️ **Conflict resolution UI** when server/local differ
- 🔄 **Retry failed syncs** button
- 🗑️ **Clear cache** option in settings
- 🎨 **Animations** for note creation/deletion
- ♿ **Accessibility** improvements (screen reader support)
- 🌙 **Dark mode** optimization

---

### Phase 9: Collaborative Features
- 👥 **Share notes** with other users
- 💬 **Comments** on shared notes
- 🔔 **Notifications** when shared notes are edited
- 👀 **Read receipts** for shared notes
- 🔒 **Permission levels** (view, edit, delete)

---

### Phase 10: Advanced Features
- 🔍 **Search** notes by content/title
- 🏷️ **Tags** for categorizing notes
- 📍 **Location tagging** for notes
- 📊 **Statistics** (notes per month, media usage)
- 📤 **Export** notes to PDF/CSV
- ☁️ **Backup & Restore** functionality
- 🌐 **Web version** (PWA)

---

## Testing Scenarios

### Functional Tests

#### Create Note
- [ ] Create note with title only
- [ ] Create note with content only
- [ ] Create note with both title and content
- [ ] Create note without either → should show validation error
- [ ] Create note offline → saves locally
- [ ] Create note online → syncs immediately

#### View Notes
- [ ] Tap day with no notes → shows empty state
- [ ] Tap day with 1 note → shows note
- [ ] Tap day with 10+ notes → shows "9+" badge
- [ ] Scroll long note list → smooth scrolling
- [ ] View notes offline → loads from cache

#### Edit Note
- [ ] Edit title → updates
- [ ] Edit content → updates
- [ ] Edit offline → queues sync
- [ ] Edit from note list tap → opens edit form
- [ ] Edit from menu → opens edit form

#### Delete Note
- [ ] Delete note → shows confirmation
- [ ] Confirm delete → note disappears
- [ ] Cancel delete → note remains
- [ ] Delete offline → marks for deletion
- [ ] Delete syncs to server when online

#### Media Management
- [ ] Take photo → appears in preview
- [ ] Choose multiple photos → all appear
- [ ] Remove photo from preview → disappears
- [ ] Upload progress shows → completes
- [ ] Large video upload → shows progress correctly
- [ ] Offline media add → queues for upload

### Non-Functional Tests

#### Performance
- [ ] Calendar renders in < 1 second
- [ ] Month navigation is instant
- [ ] Notes list loads in < 500ms
- [ ] Smooth 60fps scrolling
- [ ] No memory leaks after extended use

#### Reliability
- [ ] App doesn't crash on network loss
- [ ] Database transactions are atomic
- [ ] Sync retry works after failure
- [ ] No data loss on app termination
- [ ] Graceful degradation without server

#### Security
- [ ] JWT authentication required
- [ ] Users can only access own notes
- [ ] 403 on unauthorized access attempts
- [ ] SQL injection prevention (Prisma handles this)
- [ ] XSS prevention in note content

---

## Credits

**Developed by:** Kiro AI Agent  
**Date:** September 8, 2026  
**Ethiopian Calendar Package:** [abushakir](https://pub.dev/packages/abushakir) by [Nabute](https://github.com/Nabute)  
**License:** MIT (adjust as needed)

---

## Support

For issues, questions, or feature requests:
1. Check this documentation first
2. Review [Troubleshooting](#troubleshooting) section
3. Search existing GitHub issues
4. Create new issue with detailed description

---

**🎉 Happy Ethiopian Calendar Note-Taking! 🎉**
