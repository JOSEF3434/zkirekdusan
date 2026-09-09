# Ethiopian Calendar - Quick Start Guide

**⏱️ Estimated Time:** 15 minutes  
**📋 Prerequisites:** Flutter, Node.js, PostgreSQL installed

---

## 🚀 Quick Setup (3 Steps)

### Step 1: Backend Setup (5 min)

```bash
# Navigate to backend
cd backend

# Install dependencies (if not done)
npm install

# Apply database migration
npx prisma migrate deploy
# OR for development with prompt:
npx prisma migrate dev

# Generate Prisma client
npx prisma generate

# Start server
npm run start:dev
```

✅ **Verify:** Open http://localhost:3000/api (should show Swagger docs)

---

### Step 2: Flutter Code Generation (5 min)

```bash
# Navigate to mobile
cd mobile

# Install dependencies (if not done)
flutter pub get

# Generate code (CRITICAL - won't compile without this)
dart run build_runner build --delete-conflicting-outputs
```

⏳ **Wait time:** ~2-5 minutes depending on machine

✅ **Verify:** Check that files like `app_database.g.dart` exist

---

### Step 3: Run App (5 min)

```bash
# Still in mobile directory

# Check available devices
flutter devices

# Run on specific device
flutter run -d chrome
# OR
flutter run -d android
# OR
flutter run -d ios
```

✅ **Verify:** App launches, calendar tab visible, can create notes

---

## 🧪 Quick Test (2 min)

1. **Tap Calendar tab** (second icon in bottom nav)
2. **Long-press any date** → Add note form opens
3. **Type "Test Note" in content** field
4. **Tap "Add Media"** → Select "Take Photo" or "Choose Photos"
5. **Tap "Save"** → Note saves instantly
6. **See badge appear** on the date cell (shows "1")
7. **Tap the date again** → Note appears in list with thumbnail
8. **Turn off WiFi** → Create another note (works offline!)
9. **Turn WiFi back on** → Note syncs automatically

✅ **All working?** Feature is ready!

---

## ⚠️ Common Issues & Quick Fixes

### ❌ "Part file doesn't exist"
```bash
cd mobile
dart run build_runner build --delete-conflicting-outputs
```

### ❌ "Cannot connect to database"
- Check `backend/.env` has correct `DATABASE_URL`
- Ensure PostgreSQL is running
- Test connection: `npx prisma studio`

### ❌ "CalendarNotesDao not found"
- Run build_runner (see above)
- Check `app_database.dart` has correct imports
- Restart VS Code/IDE

### ❌ "401 Unauthorized"
- Log out and log in again in the app
- Check backend is running on correct port
- Verify JWT_SECRET in backend `.env`

### ❌ Calendar tab not visible
- Check `app_router.dart` has `/calendar` route
- Verify `app_shell.dart` has calendar navigation item
- Rebuild app: `flutter clean && flutter run`

---

## 📱 Testing Offline Mode

```bash
# Terminal 1: Watch sync queue
cd mobile
flutter run --verbose | grep -i sync

# Terminal 2: Stop backend
cd backend
# Press Ctrl+C to stop server

# In app:
- Create note → saves locally ✅
- View notes → loads from cache ✅
- Edit note → updates locally ✅

# Terminal 2: Restart backend
npm run start:dev

# In app:
- Notes auto-sync in background ✅
- Check backend logs for sync requests ✅
```

---

## 🎯 Next Steps

1. **Read full docs:** [ETHIOPIAN_CALENDAR_FEATURE.md](./ETHIOPIAN_CALENDAR_FEATURE.md)
2. **Customize UI:** Edit `calendar_screen.dart`
3. **Add features:** See "Future Enhancements" in docs
4. **Deploy:** Configure production `.env` and build for release

---

## 📊 Architecture at a Glance

```
User Action (Create Note)
    ↓
Saves to Local SQLite (Drift)  ← Instant response
    ↓
Adds to Sync Queue
    ↓
Background: Syncs to Server (NestJS)
    ↓
Saves to PostgreSQL (Prisma)
    ↓
Uploads Media to Cloudinary
```

**Key benefit:** Works fully offline, syncs when online!

---

## 🆘 Need Help?

- **Documentation:** `ETHIOPIAN_CALENDAR_FEATURE.md`
- **Troubleshooting:** See "Troubleshooting" section in docs
- **API Docs:** http://localhost:3000/api (when backend running)

---

**✅ Setup Complete! Start building amazing calendar features! 🎉**
