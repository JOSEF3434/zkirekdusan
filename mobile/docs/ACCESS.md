# ACCESS.md — Zikre Kdusan / StreamHub Mobile

## Role-Based Access Control (RBAC)

### User Roles (defined by backend JWT `role` claim)

| Role | Access Level |
|------|-------------|
| `USER` | Standard authenticated user — browse, upload, comment, like, join groups |
| `ADMIN` | All USER permissions + access to Admin Settings screen |
| `SUPER_ADMIN` | All ADMIN permissions + unrestricted moderation powers |

---

## Route-Level Protection (GoRouter)

All protection is enforced in `app_router.dart` via a top-level `redirect` callback that checks `authProvider`.

### Unauthenticated Redirect
- If no valid session → redirect to `/login`
- First launch (`isFirstLaunch == true`) → redirect to `/onboarding`

### Admin-Only Routes

```dart
// Route: /settings/admin
redirect: (context, state) {
  final role = ref.read(authProvider).user?.role;
  if (role != 'ADMIN' && role != 'SUPER_ADMIN') return '/settings';
  return null; // allow
}
```

**Protected route:** `/settings/admin` → `AdminSettingsScreen`

---

## Group Governance

### Group Status: `PENDING_APPROVAL`

When a group is in `PENDING_APPROVAL` status (returned from API as `group.status`):

1. **Upload blocked** — The channel list for the group is hidden and replaced with an orange warning banner:
   > *"This group is pending admin approval. You cannot upload videos yet."*

2. **UI implementation:** `upload_screen.dart` — `_ChannelSelectorWidget`

```dart
if (group.status == 'PENDING_APPROVAL')
  // Show orange warning container
else if (groupChannels.isEmpty)
  // Show "no channels" message
```

---

## Library & Content Access

| Section | Path | Access |
|---------|------|--------|
| Library Home | `/library` | Authenticated |
| Watch History | `/library/history` | Authenticated |
| Downloads | `/library/downloads` | Authenticated (local device data) |
| Playlists | `/library/playlists` | Authenticated |

---

## Localization System

**Central file:** `assets/lang/language_togle.json`

### Supported Languages

| Code | Name | Status |
|------|------|--------|
| `en` | English | Full — all keys translated |
| `am` | Amharic | Full — all keys translated |
| `gez` | Ge'ez | Scaffold — empty values fall back to `en` |

### Fallback Chain

```
Ge'ez value (if non-empty) → English value → raw key
```

### Provider

```dart
final trProvider = Provider<String Function(String)>((ref) {
  final service = ref.watch(localizationServiceProvider);
  final langCode = ref.watch(preferencesProvider.select((s) => s.languageCode));
  service.updateLanguage(langCode);
  return service.translate;
});
```

Usage in any widget:
```dart
final tr = ref.watch(trProvider);
Text(tr('library.title')) // "Library" | "ቤተ መጻሕፍት" | fallback
```

---

## Preferences Persistence

| Preference | Storage Key | Default |
|------------|-------------|---------|
| Theme | `themeMode` | `system` |
| Language | `languageCode` | `en` |
| First Launch | `isFirstLaunch` | `true` |

All persisted via `SharedPreferences`. On first launch the user is directed to `/onboarding` to choose language and theme before entering the app.

---

## Playlist Integration

Videos can optionally be added to a playlist during upload:

1. User picks a playlist (or "None") in the upload form
2. After transcoding completes (status `READY`), the video is automatically added via:
   ```
   POST /video-playlists/:id/items { videoId }
   ```
3. Non-fatal — if the playlist add fails, the upload is still marked completed.
