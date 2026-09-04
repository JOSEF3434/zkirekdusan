# Quick Start Guide - ዝክረ ክዱሳን (StreamHub)

**For Developers Getting Started Quickly**

---

## 🚀 30-Second Overview

StreamHub is a full-stack social media + video platform with:
- **Backend:** NestJS + PostgreSQL + Redis
- **Mobile:** Flutter (iOS/Android/Web)
- **Key Feature:** Offline-first architecture with real-time sync

---

## ⚡ Quick Setup (15 Minutes)

### 1. Prerequisites Check

```bash
# Verify installations
node --version    # Need: >= 22
flutter --version # Need: 3.47.2
java -version     # Need: JDK 17
```

### 2. Backend Setup (5 minutes)

```bash
cd backend

# Install
npm install

# Create .env file
cat > .env << EOF
DATABASE_URL="postgresql://user:password@localhost:5432/streamhub"
JWT_ACCESS_SECRET="dev-secret-change-in-production"
JWT_REFRESH_SECRET="dev-refresh-secret-change-in-production"
PORT=3000
EOF

# Setup database
npx prisma migrate dev
npm run db:seed

# Start server
npm run start:dev
```

✅ Backend running at: http://localhost:3000/api  
📚 API Docs: http://localhost:3000/api/docs

### 3. Mobile Setup (5 minutes)

```bash
cd mobile

# Install
flutter pub get

# Create .env file
cat > .env << EOF
API_BASE_URL=http://localhost:3000/api
SOCKET_URL=http://localhost:3000
EOF

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Fix Android Gradle (if needed)
# Edit android/gradle.properties:
# org.gradle.java.home=C:/Program Files/Microsoft/jdk-17.0.18.8-hotspot

# Run app
flutter run
```

### 4. Verify Setup (1 minute)

1. Open mobile app
2. Register new account: `test@example.com` / `password123`
3. Create a post
4. Check Swagger docs: http://localhost:3000/api/docs

---

## 📁 Project Structure (Quick Map)

```
zkirekdusan/
├── backend/                 # NestJS API
│   ├── src/
│   │   ├── modules/         # 43 feature modules
│   │   │   ├── auth/        # Login, JWT, sessions
│   │   │   ├── posts/       # Social posts
│   │   │   ├── messages/    # Real-time chat
│   │   │   ├── videos/      # Video platform
│   │   │   └── ...
│   │   └── main.ts
│   ├── prisma/
│   │   └── schema.prisma    # Database schema
│   └── package.json
│
└── mobile/                  # Flutter app
    ├── lib/
    │   ├── core/            # Foundation
    │   │   ├── database/    # Drift SQLite (offline)
    │   │   ├── network/     # HTTP client
    │   │   ├── storage/     # File storage
    │   │   └── sync/        # Background sync
    │   ├── features/        # 21 feature modules
    │   │   ├── auth/        # Login screens
    │   │   ├── home/        # Main feed
    │   │   ├── chats/       # Messaging UI
    │   │   ├── player/      # Video player
    │   │   └── ...
    │   └── main.dart
    └── pubspec.yaml
```

---

## 🎯 Common Tasks

### Backend

**Add New Endpoint:**
```bash
cd backend
nest g resource my-feature --no-spec
```

**Run Database Migration:**
```bash
npx prisma migrate dev --name my_change
```

**View Database:**
```bash
npx prisma studio
```

**Run Tests:**
```bash
npm run test
```

### Mobile

**Add New Feature:**
```dart
// 1. Create folder: lib/features/my_feature/
// 2. Add presentation/, domain/, data/ subfolders
// 3. Create providers in presentation/providers/
```

**Generate Code (after model changes):**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Run on Different Platforms:**
```bash
flutter run -d android       # Android
flutter run -d ios           # iOS
flutter run -d chrome        # Web
flutter run -d windows       # Windows desktop
```

**Build Release:**
```bash
flutter build apk --release           # Android APK
flutter build appbundle --release     # Android Bundle
flutter build ios --release           # iOS
flutter build web --release           # Web
```

---

## 🔧 Troubleshooting Quick Fixes

### "Cannot find JDK" (Android)

```bash
# Edit mobile/android/gradle.properties
echo 'org.gradle.java.home=C:/Program Files/Microsoft/jdk-17.0.18.8-hotspot' >> android/gradle.properties
```

### "Prisma Client not generated"

```bash
cd backend
npm run prisma:generate
```

### "Port 3000 already in use"

```bash
# Change in backend/.env
PORT=3001
```

### "Socket.IO not connecting"

Check:
1. Backend is running
2. CORS_ORIGINS includes your client URL
3. Authorization header is set

### "Video upload fails"

1. Check Cloudinary credentials in backend/.env
2. Verify file size < 500MB
3. Check upload preset exists

---

## 📚 Key Documentation Files

| File | Purpose |
|------|---------|
| `PROJECT_DOCUMENTATION.md` | Complete technical documentation |
| `OFFLINE_ARCHITECTURE.md` | Offline-first sync design |
| `MESSAGING_SYSTEM_IMPLEMENTATION.md` | Real-time messaging guide |
| `STATUS.md` | Current implementation status |
| `DevelopmentOrder.md` | Feature development phases |
| `backend/README.md` | Backend-specific info |

---

## 🔐 Default Credentials (Development)

After running `npm run db:seed` in backend:

**Super Admin:**
- Email: `superadmin@example.com`
- Password: `Admin123!`

**Regular User:**
- Email: `user@example.com`
- Password: `User123!`

**Test User:**
- Email: `test@example.com`
- Password: `Test123!`

---

## 🌐 Important URLs

| Service | URL | Notes |
|---------|-----|-------|
| Backend API | http://localhost:3000/api | REST endpoints |
| Swagger Docs | http://localhost:3000/api/docs | Interactive API docs |
| Prisma Studio | http://localhost:5555 | Database GUI |
| Flutter Web | http://localhost:8080 | Web app (if running) |
| Redis Commander | http://localhost:8081 | Redis GUI (if installed) |

---

## 📦 Essential Commands Cheat Sheet

### Backend

```bash
# Development
npm run start:dev           # Start with hot reload
npm run build               # Production build
npm run start:prod          # Start production

# Database
npx prisma migrate dev      # Create & apply migration
npx prisma migrate deploy   # Apply in production
npx prisma studio           # Open database GUI
npx prisma generate         # Generate Prisma Client
npm run db:seed             # Seed database

# Code Quality
npm run lint                # Run ESLint
npm run format              # Format with Prettier
npm run test                # Run tests
npm run test:e2e            # Run E2E tests
```

### Mobile

```bash
# Development
flutter run                 # Run app
flutter run --release       # Run release build
flutter clean               # Clean build cache
flutter pub get             # Install dependencies
flutter pub upgrade         # Upgrade dependencies

# Code Generation
flutter pub run build_runner build              # Generate once
flutter pub run build_runner watch              # Watch mode
flutter pub run build_runner build --delete-conflicting-outputs

# Analysis
flutter analyze             # Static analysis
flutter test                # Run tests
flutter drive               # Integration tests

# Build
flutter build apk           # Android APK
flutter build appbundle     # Android Bundle
flutter build ios           # iOS
flutter build web           # Web

# Utilities
flutter devices             # List connected devices
flutter doctor -v           # Check setup
flutter logs                # View logs
```

---

## 🎨 Architecture Quick Reference

### Backend Flow
```
HTTP Request
    ↓
Controller (validate input)
    ↓
Service (business logic)
    ↓
Prisma (database)
    ↓
Response (DTO)
```

### Mobile Flow
```
User Action
    ↓
Presentation (UI) ← Riverpod Provider
    ↓
Repository (data coordination)
    ↓
├─ Local Datasource (SQLite)
└─ Remote Datasource (API)
    ↓
Model (data class)
```

### Real-Time Flow
```
Client: socket.emit('send_message', data)
    ↓
Server: MessagingGateway receives
    ↓
Server: Broadcasts to room
    ↓
Clients: socket.on('new_message', callback)
```

---

## 🚨 Known Issues

1. **Android Build Fails with Java 25**: Use JDK 17 (see troubleshooting above)
2. **Firebase Push Notifications**: Requires proper setup of `google-services.json`
3. **Cloudinary Free Tier**: Limited to 25 GB storage + 25 GB bandwidth/month
4. **Redis Optional**: Backend works without Redis, but Socket.IO won't scale horizontally

---

## 💡 Pro Tips

1. **Use Swagger for API Testing**: Faster than Postman for quick checks
2. **Enable Hot Reload**: Both backend (NestJS watch) and mobile (Flutter) support hot reload
3. **Prisma Studio**: Best way to inspect/edit database during development
4. **Flutter DevTools**: Essential for debugging mobile app (network, performance, state)
5. **Git Hooks**: Consider adding pre-commit hooks for linting/formatting
6. **Environment Files**: Never commit `.env` files to version control

---

## 📞 Need Help?

1. Check `PROJECT_DOCUMENTATION.md` for detailed info
2. Review Swagger docs for API reference
3. Check `STATUS.md` for implementation status
4. Look at code examples in existing modules
5. Search GitHub issues (if repository is shared)

---

**Happy Coding! 🎉**

*Last Updated: September 4, 2026*
