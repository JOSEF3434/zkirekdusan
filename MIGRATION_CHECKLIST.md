# Ethiopian Calendar - Pre-Production Checklist

Use this checklist before deploying to production or merging to main branch.

---

## 📋 Code Quality

### Backend

- [ ] **All TypeScript files compile** without errors
  ```bash
  cd backend && npm run build
  ```

- [ ] **Linting passes** without errors
  ```bash
  npm run lint
  ```

- [ ] **Unit tests pass**
  ```bash
  npm run test
  ```

- [ ] **Migration file exists** at `prisma/migrations/20260908000000_add_calendar_notes/`

- [ ] **Prisma schema validated**
  ```bash
  npx prisma validate
  ```

- [ ] **API endpoints documented** in Swagger (visit `/api` route)

- [ ] **Environment variables** documented in `.env.example`

### Frontend

- [ ] **Flutter analyze** passes (ignore pre-existing errors)
  ```bash
  cd mobile && flutter analyze
  ```

- [ ] **Build runner** executed successfully
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

- [ ] **Debug build** compiles
  ```bash
  flutter build apk --debug
  ```

- [ ] **No console errors** during normal usage

- [ ] **Database schema version** updated to 2 in `app_database.dart`

---

## 🧪 Functional Testing

### Create Operations

- [ ] Create note with title + content → saves
- [ ] Create note with content only → saves
- [ ] Create note without content → shows validation error
- [ ] Create note offline → saves locally, syncs when online
- [ ] Create note with media → uploads successfully
- [ ] Upload progress indicator works

### Read Operations

- [ ] View notes for empty day → shows "No notes" message
- [ ] View notes for day with notes → displays all notes
- [ ] Note count badge shows correct number (1-9, "9+")
- [ ] Media thumbnails display correctly
- [ ] Gregorian date conversion is accurate

### Update Operations

- [ ] Edit note title → updates
- [ ] Edit note content → updates
- [ ] Edit offline → queues for sync
- [ ] Add media to existing note → attaches
- [ ] Remove media from note → deletes

### Delete Operations

- [ ] Delete note → shows confirmation dialog
- [ ] Confirm deletion → note disappears
- [ ] Deletion offline → marks for deletion, syncs later
- [ ] Deletion syncs to server

### Media Operations

- [ ] Take photo → saves to note
- [ ] Choose multiple photos → all attach
- [ ] Record video → uploads
- [ ] Choose audio → attaches
- [ ] Remove media → deletes from note
- [ ] Large file (>10MB) uploads with progress

### Offline Sync

- [ ] Create note offline → syncs when online
- [ ] Edit note offline → syncs when online
- [ ] Delete note offline → syncs when online
- [ ] View cached notes while offline
- [ ] Sync queue processes in order
- [ ] No duplicate notes after sync

---

## 🔒 Security

- [ ] **JWT authentication** required for all calendar endpoints
- [ ] **Users can only access** their own notes (ownership check)
- [ ] **403 Forbidden** returned when accessing other user's notes
- [ ] **SQL injection** prevented (Prisma handles this)
- [ ] **File upload size limits** enforced
- [ ] **File type validation** on uploads
- [ ] **CORS** configured correctly for production
- [ ] **Environment variables** not committed to git

---

## 🚀 Performance

- [ ] Calendar screen renders in **< 1 second**
- [ ] Month navigation is **instant**
- [ ] Notes list loads in **< 500ms**
- [ ] Smooth **60fps scrolling** on calendar
- [ ] No **memory leaks** after 10 minutes of use
- [ ] Database queries **use indexes** (check `@@index` in schema)
- [ ] Media thumbnails **lazy load** (not all at once)

---

## 📱 Cross-Platform

- [ ] **Android**: App runs without crashes
- [ ] **iOS**: App runs without crashes (if applicable)
- [ ] **Web**: Calendar displays correctly (if applicable)
- [ ] **Tablet**: Layout adapts (responsive)
- [ ] **Dark mode**: UI looks good (if implemented)

---

## 📚 Documentation

- [ ] **README.md** mentions calendar feature
- [ ] **ETHIOPIAN_CALENDAR_FEATURE.md** exists and is accurate
- [ ] **API endpoints** documented with examples
- [ ] **Database schema** documented in Prisma comments
- [ ] **Code comments** explain complex logic
- [ ] **TODO comments** removed or tracked in issues

---

## 🔄 Database

### Backend Migration

- [ ] Migration file **does not modify** existing tables destructively
- [ ] Migration **adds indexes** for performance
- [ ] Migration **tested on staging** environment
- [ ] Rollback plan exists (if needed)
- [ ] `schema.prisma` matches production database

### Frontend Migration

- [ ] Drift schema version **incremented** (`schemaVersion = 2`)
- [ ] Migration logic **creates new tables** in `onUpgrade`
- [ ] Old data **preserved** during migration
- [ ] Migration **tested on different devices** (Android, iOS)

---

## 🌐 Deployment

### Backend

- [ ] **Environment variables** set in production
- [ ] **Database URL** points to production database
- [ ] **Cloudinary credentials** configured
- [ ] **JWT secrets** are strong and unique
- [ ] **CORS origins** restricted to app domain
- [ ] **Rate limiting** enabled
- [ ] **Health check endpoint** returns 200

### Frontend

- [ ] **API base URL** points to production backend
- [ ] **Release build** tested
  ```bash
  flutter build apk --release  # Android
  flutter build ios --release  # iOS
  ```
- [ ] **App icons** set correctly
- [ ] **Splash screen** configured
- [ ] **Version number** updated in `pubspec.yaml`
- [ ] **Store listing** prepared (if publishing)

---

## 📊 Monitoring (Post-Deploy)

- [ ] **Backend logs** show no errors
- [ ] **Database queries** complete in < 100ms
- [ ] **API response times** < 500ms
- [ ] **Error rate** < 1%
- [ ] **User reports** tracked
- [ ] **Crash reports** integrated (Firebase Crashlytics, Sentry, etc.)

---

## ✅ Final Verification

Run this command to verify everything:

```bash
# Backend
cd backend
npm run build && npm run test && npx prisma validate

# Frontend
cd mobile
flutter analyze && dart run build_runner build --delete-conflicting-outputs && flutter build apk --debug
```

**All passing?** ✅ Ready for production!

---

## 🚨 Rollback Plan

If issues occur after deployment:

### Backend Rollback

```bash
# Revert to previous migration
npx prisma migrate resolve --rolled-back 20260908000000_add_calendar_notes

# Deploy previous code version
git checkout <previous-commit>
npm run build
npm run start:prod
```

### Frontend Rollback

```bash
# Revert to previous commit
git checkout <previous-commit>

# Rebuild
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build apk --release
```

### Database Rollback

**⚠️ CAUTION:** Only if absolutely necessary

```sql
-- Drop calendar tables
DROP TABLE IF EXISTS calendar_note_media CASCADE;
DROP TABLE IF EXISTS calendar_notes CASCADE;
```

---

## 📞 Support Contacts

- **Technical Lead:** [Name]
- **DevOps:** [Name]
- **Database Admin:** [Name]
- **On-Call:** [Contact Method]

---

**Last Updated:** September 8, 2026  
**Review Date:** _________  
**Approved By:** _________

---

**✅ Checklist Complete? Deploy with confidence! 🚀**
