# Development Guide

**Document Version:** 1.0  
**Last Updated:** September 25, 2026  
**Project:** Zikire Kdusan (StreamHub)

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Project Structure](#project-structure)
4. [Backend Development](#backend-development)
5. [Frontend Development](#frontend-development)
6. [Database Development](#database-development)
7. [Development Workflow](#development-workflow)
8. [Testing](#testing)
9. [Code Quality](#code-quality)
10. [Debugging](#debugging)
11. [Common Tasks](#common-tasks)
12. [Troubleshooting](#troubleshooting)

---

## Overview

Zikire Kdusan is a full-stack video streaming and social platform with:

- **Backend:** NestJS 11 + TypeScript 6 + Node.js 22+
- **Frontend:** Flutter 3.8+ + Dart 3.8+ (Mobile & Web)
- **Database:** Neon PostgreSQL with Prisma 7.8 ORM
- **Infrastructure:** Redis, BullMQ, Socket.IO 4.8, Cloudinary

This guide covers local development setup, workflows, and best practices for contributing to the project.

---

## Prerequisites

### Required Software

| Software | Version | Purpose |
|----------|---------|---------|
| **Node.js** | ≥22.0.0 | Backend runtime |
| **npm** | ≥10.0.0 | Backend package manager |
| **Flutter SDK** | ≥3.8.0 | Mobile/web framework |
| **Dart SDK** | ≥3.8.0 | Programming language |
| **Git** | ≥2.30 | Version control |
| **PostgreSQL Client** | ≥15.0 | Database CLI (optional) |
| **Redis CLI** | ≥7.0 | Cache/queue CLI (optional) |

### Optional Tools

| Tool | Purpose |
|------|---------|
| **VS Code** | Recommended IDE with Flutter/NestJS extensions |
| **Android Studio** | Android emulator and debugging |
| **Xcode** | iOS simulator (macOS only) |
| **Postman/Insomnia** | API testing |
| **Prisma Studio** | Visual database browser |
| **RedisInsight** | Redis GUI client |

### Platform-Specific Requirements

#### macOS
```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Node.js
brew install node@22

# Install Flutter
brew install --cask flutter

# Verify installations
node --version   # v22.x.x
flutter --version # 3.8.x
```

#### Windows
```powershell
# Install via Chocolatey (or download installers manually)
choco install nodejs-lts --version=22.0.0
choco install flutter

# Verify installations
node --version
flutter --version
```

#### Linux (Ubuntu/Debian)
```bash
# Install Node.js 22
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Flutter (download from flutter.dev)
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.8.0-stable.tar.xz
tar xf flutter_linux_3.8.0-stable.tar.xz
export PATH="$PATH:`pwd`/flutter/bin"

# Verify
node --version
flutter --version
```

---

## Project Structure

```
zkirekdusan/
├── backend/                 # NestJS backend
│   ├── dist/               # Compiled output (gitignored)
│   ├── node_modules/       # Dependencies (gitignored)
│   ├── prisma/             # Database schema and migrations
│   │   ├── migrations/     # Migration history
│   │   ├── seed/           # Database seeding scripts
│   │   └── schema.prisma   # Prisma schema definition
│   ├── scripts/            # Utility scripts
│   ├── src/                # Source code
│   │   ├── app.module.ts   # Root module
│   │   ├── main.ts         # Entry point
│   │   ├── common/         # Shared utilities, guards, filters
│   │   ├── config/         # Configuration modules
│   │   ├── modules/        # Feature modules (50+)
│   │   └── prisma/         # Prisma service
│   ├── test/               # E2E tests
│   ├── .env                # Environment variables (NEVER commit)
│   ├── .env.example        # Template for .env (commit this)
│   ├── nest-cli.json       # NestJS CLI config
│   ├── package.json        # Dependencies and scripts
│   ├── tsconfig.json       # TypeScript config
│   └── README.md           # Backend docs
├── mobile/                 # Flutter frontend
│   ├── android/            # Android-specific config
│   ├── ios/                # iOS-specific config
│   ├── lib/                # Dart source code
│   │   ├── app/            # App-level config (env, routes)
│   │   ├── core/           # Core utilities (network, database, sync)
│   │   ├── features/       # Feature modules (23+)
│   │   └── main.dart       # Entry point
│   ├── assets/             # Images, fonts, translations
│   ├── test/               # Unit/widget tests
│   ├── .env                # Environment variables (NEVER commit)
│   ├── pubspec.yaml        # Dependencies and assets
│   └── README.md           # Mobile docs
├── docs/                   # Project documentation
│   ├── USER_GUIDE.md
│   ├── ARCHITECTURE.md
│   ├── API.md
│   ├── DATABASE.md
│   ├── DEVELOPMENT.md      # This file
│   └── ... (10+ docs)
├── .gitignore              # Git ignore patterns
└── README.md               # Project overview
```

---

## Backend Development

### Initial Setup

#### 1. Clone Repository

```bash
git clone https://github.com/your-org/zkirekdusan.git
cd zkirekdusan/backend
```

#### 2. Install Dependencies

```bash
npm install
```

**Dependencies installed:**

- **Core:** NestJS 11, Express, TypeScript 6
- **Database:** Prisma 7.8, @prisma/client, @prisma/adapter-neon
- **Authentication:** @nestjs/jwt, @nestjs/passport, bcrypt, passport-jwt
- **Caching:** @nestjs/cache-manager, ioredis
- **Queues:** @nestjs/bullmq, bullmq
- **Real-time:** @nestjs/websockets, socket.io 4.8, @socket.io/redis-adapter
- **Media:** cloudinary, fluent-ffmpeg
- **Validation:** class-validator, class-transformer
- **Logging:** nestjs-pino, pino-pretty
- **Security:** helmet, @nestjs/throttler
- **Push Notifications:** firebase-admin
- **Utilities:** dotenv, joi, nanoid, uuid

#### 3. Configure Environment

Create `.env` file (use `.env.example` as template):

```bash
cp .env.example .env
```

**Required Environment Variables:**

```ini
# App Configuration
APP_NAME="ዝክረ ክዱሳን"
APP_URL=http://localhost:3000
NODE_ENV=development
PORT=3000

# Database (Neon PostgreSQL)
DATABASE_URL="postgresql://user:password@host:5432/dbname?sslmode=require"

# JWT Secrets
JWT_ACCESS_SECRET=your_super_secret_access_key_min_32_chars
JWT_REFRESH_SECRET=your_super_secret_refresh_key_min_32_chars
JWT_ACCESS_EXPIRES=15m
JWT_REFRESH_EXPIRES=7d

# Security
BCRYPT_ROUNDS=12
CORS_ORIGINS=http://localhost:3000,http://localhost:5173

# Redis
REDIS_URL=redis://localhost:6379

# Cloudinary (Media Storage)
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
STORAGE_PROVIDER=CLOUDINARY
UPLOAD_MAX_SIZE=52428800

# Live Streaming (Cloudinary Live)
RTMP_SERVER_URL=rtmp://live.cloudinary.com/streams
HLS_BASE_URL=https://res.cloudinary.com/your_cloud_name/video/live

# Firebase (Push Notifications)
FCM_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'
```

**Security Notes:**

⚠️ **NEVER commit `.env` to version control**  
⚠️ Use strong random secrets (generate with `openssl rand -base64 32`)  
⚠️ Different secrets for development vs production  
⚠️ Rotate secrets periodically

#### 4. Set Up Database

**Generate Prisma Client:**

```bash
npm run prisma:generate
```

**Run Migrations:**

```bash
# Check migration status
npm run prisma:status

# Apply migrations
npx prisma migrate deploy

# OR for development (creates migration if schema changed)
npx prisma migrate dev
```

**Seed Database:**

```bash
npm run db:seed
```

**Seeds the following:**

- 5 global roles (SUPER_ADMIN, ADMIN, MODERATOR, SUPPORT, USER)
- 100+ permissions (video.create, group.moderate, etc.)
- Role-permission mappings
- Initial admin user (optional, configure in `prisma/seed/seed.ts`)

**Verify with Prisma Studio:**

```bash
npx prisma studio
```

Opens GUI at `http://localhost:5555` to browse database.

### Running the Backend

#### Development Mode (Hot Reload)

```bash
npm run start:dev
```

**Features:**

- Auto-restart on file changes
- Source map support for debugging
- Pino pretty-printed logs

**Output:**

```
[Nest] 12345  - 09/25/2026, 10:30:00 AM     LOG [NestFactory] Starting Nest application...
[Nest] 12345  - 09/25/2026, 10:30:01 AM     LOG [InstanceLoader] AppModule dependencies initialized
[Nest] 12345  - 09/25/2026, 10:30:02 AM     LOG [RoutesResolver] AuthController {/api/auth}:
[Nest] 12345  - 09/25/2026, 10:30:02 AM     LOG [RouterExplorer] Mapped {/api/auth/register, POST} route
[Nest] 12345  - 09/25/2026, 10:30:02 AM     LOG [RouterExplorer] Mapped {/api/auth/login, POST} route
...
[Nest] 12345  - 09/25/2026, 10:30:05 AM     LOG [NestApplication] Nest application successfully started
[Nest] 12345  - 09/25/2026, 10:30:05 AM     LOG Application is running on: http://localhost:3000
[Nest] 12345  - 09/25/2026, 10:30:05 AM     LOG Swagger docs available at: http://localhost:3000/api/docs
```

**Health Check:**

```bash
curl http://localhost:3000/api/health
# Response: {"status":"ok","database":"connected","redis":"connected"}
```

#### Production Mode

```bash
# Build
npm run build

# Run compiled output
npm run start:prod
```

**Differences from development:**

- Compiled TypeScript → JavaScript in `dist/`
- No hot reload
- Optimized logging (JSON format)
- No source maps

#### Debug Mode

```bash
npm run start:debug
```

**Attach debugger:**

- VS Code: Use "Attach to Node" launch configuration
- Chrome DevTools: Open `chrome://inspect`

### Backend API Documentation

**Swagger UI:**

```
http://localhost:3000/api/docs
```

**Features:**

- Interactive API explorer
- Request/response schemas
- Authentication support (Bearer token)
- Try-it-out functionality

**Generating Swagger JSON:**

```bash
curl http://localhost:3000/api/docs-json > swagger.json
```

### Backend File Structure

```
src/
├── main.ts                      # Entry point
├── app.module.ts                # Root module
├── app.controller.ts            # Health check endpoint
├── app.service.ts               # App-level service
│
├── common/                      # Shared code
│   ├── adapters/
│   │   └── redis-io.adapter.ts  # Socket.IO Redis adapter
│   ├── constants/
│   │   ├── roles.ts             # Role enums
│   │   ├── permissions.ts       # Permission enums
│   │   └── group-roles.ts       # Group role enums
│   ├── decorators/
│   │   ├── current-user.decorator.ts
│   │   ├── roles.decorator.ts
│   │   ├── permissions.decorator.ts
│   │   └── public.decorator.ts
│   ├── dto/
│   │   └── api-response.dto.ts
│   ├── filters/
│   │   └── global-exception.filter.ts
│   ├── guards/
│   │   ├── jwt-auth.guard.ts
│   │   ├── roles.guard.ts
│   │   ├── permissions.guard.ts
│   │   └── group-roles.guard.ts
│   ├── interceptors/
│   │   └── transform.interceptor.ts
│   ├── pipes/
│   │   └── validation.pipe.ts
│   └── common.module.ts
│
├── config/                      # Configuration
│   ├── app.config.ts
│   ├── database.config.ts
│   ├── jwt.config.ts
│   ├── redis.config.ts
│   ├── cloudinary.config.ts
│   └── firebase.config.ts
│
├── prisma/                      # Database
│   ├── prisma.module.ts
│   └── prisma.service.ts
│
└── modules/                     # Feature modules (50+)
    ├── auth/                    # Authentication
    ├── users/                   # User management
    ├── groups/                  # Groups
    ├── channels/                # Channels
    ├── messages/                # Messaging
    ├── conversations/           # Conversations
    ├── videos/                  # Video platform
    ├── video-channels/          # Video channels
    ├── live-streaming/          # Live streaming
    ├── live-gateway/            # Live WebSocket gateway
    ├── social/                  # Social features
    ├── calendar/                # Ethiopian calendar
    ├── notifications/           # Notifications
    ├── downloads/               # Download management
    ├── admin/                   # Admin tools
    └── ... (40+ more)
```

**Module Template:**

```
modules/feature/
├── feature.module.ts           # Module definition
├── feature.controller.ts       # REST endpoints
├── feature.service.ts          # Business logic
├── feature.repository.ts       # Data access
├── dto/
│   ├── create-feature.dto.ts   # Request DTOs
│   ├── update-feature.dto.ts
│   └── feature-response.dto.ts # Response DTOs
├── entities/
│   └── feature.entity.ts       # Prisma model wrapper (optional)
├── guards/
│   └── feature.guard.ts        # Feature-specific guards
└── feature.controller.spec.ts  # Unit tests
```

---

## Frontend Development

### Initial Setup

#### 1. Navigate to Mobile Directory

```bash
cd mobile
```

#### 2. Install Dependencies

```bash
flutter pub get
```

**Key Dependencies:**

- **State Management:** flutter_riverpod 2.5
- **Routing:** go_router 14.0
- **HTTP:** dio 5.11
- **Storage:** flutter_secure_storage 10.3, drift 2.30
- **Media:** video_player 2.9, cached_network_image 3.4, camera 0.11
- **Real-time:** socket_io_client 2.0
- **Calendar:** abushakir 1.0 (Ethiopian calendar)
- **Notifications:** firebase_messaging 16.6, flutter_local_notifications 18.0
- **Background:** workmanager 0.9
- **Audio:** just_audio 0.9, flutter_sound 9.2
- **Permissions:** permission_handler 11.3
- **Connectivity:** connectivity_plus 7.3

#### 3. Configure Environment

Create `.env` file in `mobile/` directory:

```bash
# API Configuration
API_BASE_URL=http://localhost:3000/api
WS_BASE_URL=ws://localhost:3000

# Cloudinary
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_UPLOAD_PRESET=your_upload_preset

# Firebase (for push notifications)
# Configure via Firebase Console and download google-services.json (Android) / GoogleService-Info.plist (iOS)
```

**Load environment variables:**

```dart
// lib/app/env/env.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get apiBaseUrl => dotenv.get('API_BASE_URL');
  static String get wsBaseUrl => dotenv.get('WS_BASE_URL');
  static String get cloudinaryCloudName => dotenv.get('CLOUDINARY_CLOUD_NAME');
}

// Load in main.dart
await dotenv.load(fileName: ".env");
```

#### 4. Generate Code

```bash
# Generate Freezed, JSON serialization, Drift database
flutter pub run build_runner build --delete-conflicting-outputs
```

**Regenerate on schema changes:**

```bash
# Watch mode (auto-regenerate)
flutter pub run build_runner watch --delete-conflicting-outputs
```

#### 5. Set Up Device/Emulator

**Android:**

```bash
# List available devices
flutter devices

# Start Android emulator
emulator -avd Pixel_5_API_33

# OR use Android Studio AVD Manager
```

**iOS (macOS only):**

```bash
# List simulators
xcrun simctl list devices

# Boot iOS simulator
open -a Simulator
```

**Physical Device:**

- Enable Developer Mode and USB Debugging
- Connect via USB
- Trust computer when prompted

### Running the Frontend

#### Development Mode

**Run on connected device:**

```bash
flutter run
```

**Run on specific device:**

```bash
# Android emulator
flutter run -d emulator-5554

# iOS simulator
flutter run -d iPhone-15-Pro

# Chrome (web)
flutter run -d chrome
```

**Hot Reload:**

- Press `r` in terminal to hot reload
- Press `R` to hot restart (full rebuild)
- Press `q` to quit

**Debug Options:**

- Press `w` to dump widget hierarchy
- Press `t` to dump rendering tree
- Press `p` to toggle performance overlay

#### Production Build

**Android APK:**

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

**Android App Bundle (for Play Store):**

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

**iOS (macOS only):**

```bash
flutter build ios --release
# Then open Xcode to archive and upload to App Store
```

**Web:**

```bash
flutter build web --release
# Output: build/web/
```

### Frontend File Structure

```
lib/
├── main.dart                    # Entry point
│
├── app/                         # App-level config
│   ├── app.dart                 # MaterialApp root
│   ├── env/
│   │   └── env.dart             # Environment variables
│   └── routes/
│       ├── app_router.dart      # GoRouter configuration
│       └── route_names.dart     # Route constants
│
├── core/                        # Core utilities
│   ├── constants/
│   │   ├── api_constants.dart
│   │   └── app_constants.dart
│   ├── database/                # Drift SQLite
│   │   ├── app_database.dart
│   │   ├── daos/                # Data access objects
│   │   └── tables/              # Table definitions
│   ├── network/
│   │   ├── api_client.dart      # Dio HTTP client
│   │   ├── connectivity_service.dart
│   │   └── interceptors/
│   ├── sync/                    # Offline sync
│   │   ├── sync_manager.dart
│   │   ├── background_sync_service.dart
│   │   └── retry_strategy.dart
│   ├── storage/
│   │   └── secure_storage.dart  # Flutter Secure Storage
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── colors.dart
│   └── presentation/
│       └── widgets/             # Shared widgets
│
└── features/                    # Feature modules (23+)
    ├── auth/                    # Authentication
    │   ├── data/
    │   │   ├── models/
    │   │   ├── repositories/
    │   │   └── services/
    │   ├── domain/
    │   │   ├── entities/
    │   │   └── usecases/
    │   └── presentation/
    │       ├── providers/       # Riverpod providers
    │       ├── screens/
    │       └── widgets/
    ├── home/                    # Home feed
    ├── explore/                 # Discovery
    ├── groups/                  # Groups
    ├── chats/                   # Messaging
    ├── live/                    # Live streaming
    ├── player/                  # Video player
    ├── profile/                 # User profile
    ├── stories/                 # Stories
    ├── calendar/                # Ethiopian calendar
    ├── admin/                   # Admin tools
    └── ... (13+ more)
```

**Feature Template (Clean Architecture):**

```
features/feature/
├── data/
│   ├── models/
│   │   └── feature_model.dart          # JSON serialization
│   ├── repositories/
│   │   └── feature_repository_impl.dart
│   └── services/
│       └── feature_service.dart        # API calls
├── domain/
│   ├── entities/
│   │   └── feature.dart                # Business entity
│   ├── repositories/
│   │   └── feature_repository.dart     # Interface
│   └── usecases/
│       ├── get_feature.dart
│       └── create_feature.dart
└── presentation/
    ├── providers/
    │   ├── feature_provider.dart       # State management
    │   └── feature_state.dart          # State classes
    ├── screens/
    │   ├── feature_screen.dart
    │   └── feature_detail_screen.dart
    └── widgets/
        ├── feature_card.dart
        └── feature_list.dart
```

### State Management (Riverpod)

**Provider Types:**

```dart
// Simple value provider
final nameProvider = Provider<String>((ref) => 'John Doe');

// State provider (mutable)
final counterProvider = StateProvider<int>((ref) => 0);

// Future provider (async data)
final userProvider = FutureProvider<User>((ref) async {
  final service = ref.read(userServiceProvider);
  return service.getCurrentUser();
});

// Stream provider (real-time data)
final messagesProvider = StreamProvider<List<Message>>((ref) {
  final service = ref.read(messagingServiceProvider);
  return service.watchMessages('conversationId');
});

// State notifier (complex state)
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});
```

**Reading providers in UI:**

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read current value
    final counter = ref.watch(counterProvider);
    
    // Read async value
    final userAsync = ref.watch(userProvider);
    
    return userAsync.when(
      data: (user) => Text(user.name),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

---

## Database Development

### Prisma Workflow

#### 1. Schema Changes

Edit `backend/prisma/schema.prisma`:

```prisma
model NewFeature {
  id          String   @id @default(uuid())
  name        String
  description String?
  userId      String
  user        User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  @@index([userId])
  @@index([createdAt(sort: Desc)])
}
```

#### 2. Create Migration

```bash
npx prisma migrate dev --name add_new_feature
```

**Generates:**

- Migration SQL in `prisma/migrations/YYYYMMDDHHMMSS_add_new_feature/migration.sql`
- Updated Prisma Client types

#### 3. Apply Migration (Production)

```bash
npx prisma migrate deploy
```

**Use this in CI/CD pipelines** — does not prompt for confirmation.

#### 4. Reset Database (Development Only)

```bash
# ⚠️ DESTROYS ALL DATA
npx prisma migrate reset

# Then re-seed
npm run db:seed
```

### Prisma Studio

**Visual database browser:**

```bash
npx prisma studio
```

**Features:**

- Browse all tables
- Edit records inline
- Filter and search
- Relationship navigation
- SQL query execution

### Database Best Practices

✅ **DO:**

- Always create migrations for schema changes
- Write descriptive migration names (`add_user_avatar`, `fix_video_status_enum`)
- Test migrations on development database before production
- Back up production database before applying migrations
- Use indexes for frequently queried columns
- Use `@relation` with `onDelete: Cascade` for proper cleanup

❌ **DON'T:**

- Edit migration files manually after creation
- Skip migrations and modify database directly
- Use `migrate reset` in production (data loss!)
- Create migrations without testing
- Forget to run `prisma generate` after schema changes

---

## Development Workflow

### Branching Strategy

**Git Flow:**

```
main                    # Production-ready code
├── develop             # Integration branch
    ├── feature/auth-improvements
    ├── feature/video-upload
    ├── bugfix/message-sync
    └── hotfix/security-patch
```

**Branch Naming:**

- `feature/short-description` — New features
- `bugfix/issue-description` — Bug fixes
- `hotfix/critical-fix` — Production hotfixes
- `refactor/component-name` — Code improvements
- `docs/section-name` — Documentation updates

### Commit Messages

**Format:**

```
type(scope): short description

Longer description if needed

Fixes #123
```

**Types:**

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting (no code change)
- `refactor`: Code restructure (no behavior change)
- `perf`: Performance improvement
- `test`: Add/update tests
- `chore`: Build/tooling changes

**Examples:**

```bash
git commit -m "feat(auth): add biometric login support"
git commit -m "fix(sync): resolve message duplicate issue on retry"
git commit -m "docs(api): update authentication endpoint examples"
git commit -m "perf(videos): optimize thumbnail loading with lazy loading"
```

### Pull Request Process

1. **Create feature branch:**
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Make changes and commit:**
   ```bash
   git add .
   git commit -m "feat(module): add new functionality"
   ```

3. **Push to remote:**
   ```bash
   git push origin feature/my-feature
   ```

4. **Open Pull Request:**
   - Title: Short description (< 70 chars)
   - Description: What changed, why, how to test
   - Link related issues
   - Request reviewers

5. **Code Review:**
   - Address review comments
   - Push additional commits
   - Re-request review

6. **Merge:**
   - Squash and merge (clean history)
   - Delete branch after merge

### Development Cycle

**Typical workflow:**

```
1. Pull latest develop
   git checkout develop
   git pull origin develop

2. Create feature branch
   git checkout -b feature/new-feature

3. Start backend
   cd backend
   npm run start:dev

4. Start frontend (separate terminal)
   cd mobile
   flutter run

5. Make changes
   - Edit code
   - Hot reload (press 'r')
   - Test manually

6. Run tests
   cd backend
   npm test

   cd mobile
   flutter test

7. Commit and push
   git add .
   git commit -m "feat(module): description"
   git push origin feature/new-feature

8. Open PR and request review

9. Address feedback and merge

10. Pull merged changes
    git checkout develop
    git pull origin develop
```

---

## Testing

### Backend Testing

**Unit Tests:**

```bash
# Run all tests
npm test

# Watch mode
npm run test:watch

# Coverage report
npm run test:cov
```

**E2E Tests:**

```bash
npm run test:e2e
```

**Test Structure:**

```typescript
// feature.service.spec.ts
describe('FeatureService', () => {
  let service: FeatureService;
  let repository: FeatureRepository;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        FeatureService,
        {
          provide: FeatureRepository,
          useValue: {
            findById: jest.fn(),
            create: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<FeatureService>(FeatureService);
    repository = module.get<FeatureRepository>(FeatureRepository);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('getById', () => {
    it('should return feature when found', async () => {
      const mockFeature = { id: '1', name: 'Test' };
      jest.spyOn(repository, 'findById').mockResolvedValue(mockFeature);

      const result = await service.getById('1');

      expect(result).toEqual(mockFeature);
      expect(repository.findById).toHaveBeenCalledWith('1');
    });

    it('should throw NotFoundException when not found', async () => {
      jest.spyOn(repository, 'findById').mockResolvedValue(null);

      await expect(service.getById('999')).rejects.toThrow(NotFoundException);
    });
  });
});
```

### Frontend Testing

**Unit Tests:**

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/features/auth/auth_test.dart

# Coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

**Widget Tests:**

```dart
// feature_widget_test.dart
testWidgets('FeatureWidget displays data correctly', (WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        featureProvider.overrideWith((ref) => mockFeatureNotifier),
      ],
      child: MaterialApp(home: FeatureWidget()),
    ),
  );

  expect(find.text('Expected Text'), findsOneWidget);
  expect(find.byType(CircularProgressIndicator), findsNothing);
});
```

**Integration Tests:**

```bash
# Run integration tests on device
flutter test integration_test/app_test.dart
```

### Manual Testing Checklist

**Before submitting PR:**

- [ ] All unit tests pass
- [ ] Manual smoke test on iOS/Android
- [ ] Check offline behavior (airplane mode)
- [ ] Test error scenarios (network errors, validation)
- [ ] Verify authentication flows
- [ ] Check responsive UI (different screen sizes)
- [ ] Test dark mode (if applicable)
- [ ] Review console for errors/warnings

---

## Code Quality

### Linting

**Backend (ESLint):**

```bash
# Check for issues
npm run lint

# Auto-fix
npm run lint -- --fix
```

**Frontend (Dart Analyzer):**

```bash
# Analyze all files
flutter analyze

# Check specific file
flutter analyze lib/features/auth/auth_service.dart
```

### Formatting

**Backend (Prettier):**

```bash
npm run format
```

**Frontend (Dart Format):**

```bash
# Format all files
dart format .

# Check without modifying
dart format --output=none --set-exit-if-changed .
```

### Pre-commit Hooks (Recommended)

Install **Husky** (backend) and **lefthook** (mobile) to run checks automatically:

```bash
# Backend
cd backend
npm install -D husky lint-staged
npx husky install
npx husky add .husky/pre-commit "npx lint-staged"

# Add to package.json:
"lint-staged": {
  "*.ts": ["eslint --fix", "prettier --write"]
}
```

---

## Debugging

### Backend Debugging

**VS Code Launch Configuration (`.vscode/launch.json`):**

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "Debug NestJS",
      "runtimeArgs": ["--nolazy", "-r", "ts-node/register", "-r", "tsconfig-paths/register"],
      "args": ["${workspaceFolder}/backend/src/main.ts"],
      "cwd": "${workspaceFolder}/backend",
      "env": {
        "NODE_ENV": "development"
      },
      "sourceMaps": true,
      "protocol": "inspector",
      "console": "integratedTerminal"
    }
  ]
}
```

**Set Breakpoints:**

- Click gutter in VS Code next to line numbers
- Press F5 to start debugging
- Use Debug Console to evaluate expressions

**Logging:**

```typescript
import { Logger } from '@nestjs/common';

export class FeatureService {
  private readonly logger = new Logger(FeatureService.name);

  async someMethod() {
    this.logger.log('Starting operation');
    this.logger.debug('Debug details');
    this.logger.warn('Warning message');
    this.logger.error('Error occurred', error.stack);
  }
}
```

### Frontend Debugging

**VS Code Launch Configuration:**

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter: Debug",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart",
      "cwd": "${workspaceFolder}/mobile"
    }
  ]
}
```

**Flutter DevTools:**

```bash
flutter pub global activate devtools
flutter pub global run devtools
```

**Opens browser with:**

- Widget inspector
- Timeline view (performance)
- Memory profiler
- Network inspector
- Logging view

**Print Debugging:**

```dart
import 'package:flutter/foundation.dart';

debugPrint('Debug message');  // Prints in debug mode only
print('Always prints');       // Prints in all modes
```

---

## Common Tasks

### Adding a New API Endpoint

**Backend:**

1. **Create DTO:**
   ```typescript
   // dto/create-feature.dto.ts
   export class CreateFeatureDto {
     @IsString()
     @IsNotEmpty()
     name: string;

     @IsString()
     @IsOptional()
     description?: string;
   }
   ```

2. **Add controller method:**
   ```typescript
   @Post()
   @UseGuards(JwtAuthGuard, RolesGuard)
   @Roles(AppRole.USER)
   async create(@Body() dto: CreateFeatureDto, @CurrentUser() user: User) {
     return this.featureService.create(dto, user.id);
   }
   ```

3. **Implement service:**
   ```typescript
   async create(dto: CreateFeatureDto, userId: string) {
     return this.repository.create({ ...dto, userId });
   }
   ```

4. **Test with Swagger** → `http://localhost:3000/api/docs`

**Frontend:**

1. **Create model:**
   ```dart
   @freezed
   class Feature with _$Feature {
     const factory Feature({
       required String id,
       required String name,
       String? description,
     }) = _Feature;

     factory Feature.fromJson(Map<String, dynamic> json) => _$FeatureFromJson(json);
   }
   ```

2. **Add service method:**
   ```dart
   Future<Feature> createFeature(CreateFeatureRequest request) async {
     final response = await _dio.post('/features', data: request.toJson());
     return Feature.fromJson(response.data['data']);
   }
   ```

3. **Create provider:**
   ```dart
   final createFeatureProvider = FutureProvider.family<Feature, CreateFeatureRequest>((ref, request) async {
     final service = ref.read(featureServiceProvider);
     return service.createFeature(request);
   });
   ```

### Adding a Database Migration

1. **Edit schema:**
   ```prisma
   model User {
     // ... existing fields
     avatarUrl String? // New field
   }
   ```

2. **Create migration:**
   ```bash
   npx prisma migrate dev --name add_user_avatar
   ```

3. **Verify migration SQL** in `prisma/migrations/` directory

4. **Update Prisma Client:**
   ```bash
   npx prisma generate
   ```

5. **Update TypeScript types** (auto-generated)

### Adding a New Feature Module

**Backend:**

```bash
cd backend
nest g module modules/new-feature
nest g controller modules/new-feature
nest g service modules/new-feature
```

**Frontend:**

```bash
cd mobile/lib/features
mkdir -p new-feature/{data,domain,presentation}/{models,repositories,services,providers,screens,widgets}
```

Create files following feature template structure.

---

## Troubleshooting

### Backend Issues

#### Port Already in Use

**Symptom:** `Error: listen EADDRINUSE: address already in use :::3000`

**Solution:**

```bash
# Find process using port 3000
lsof -i :3000        # macOS/Linux
netstat -ano | findstr :3000  # Windows

# Kill process
kill -9 <PID>        # macOS/Linux
taskkill /PID <PID> /F  # Windows
```

#### Prisma Client Not Generated

**Symptom:** `Cannot find module '@prisma/client'`

**Solution:**

```bash
npx prisma generate
npm install
```

#### Redis Connection Failed

**Symptom:** `Error: connect ECONNREFUSED 127.0.0.1:6379`

**Solution:**

```bash
# Start Redis
brew services start redis  # macOS
sudo systemctl start redis # Linux
redis-server               # Manual start

# Verify
redis-cli ping
# Response: PONG
```

#### Database Migration Failed

**Symptom:** `Migration failed with exit code 1`

**Solution:**

```bash
# Check migration status
npx prisma migrate status

# Reset database (development only)
npx prisma migrate reset

# Re-apply migrations
npx prisma migrate deploy
```

### Frontend Issues

#### Flutter Pub Get Fails

**Symptom:** `pub get failed`

**Solution:**

```bash
# Clear pub cache
flutter pub cache repair

# Clean project
flutter clean
flutter pub get
```

#### Build Runner Errors

**Symptom:** `[SEVERE] Failed to generate build`

**Solution:**

```bash
# Clean generated files
flutter clean
rm -rf .dart_tool/build

# Regenerate
flutter pub run build_runner build --delete-conflicting-outputs
```

#### Drift Database Issues

**Symptom:** `No implementation found for method open on channel`

**Solution:**

```bash
# Regenerate Drift code
flutter pub run build_runner build --delete-conflicting-outputs

# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

#### iOS Build Fails

**Symptom:** `CocoaPods not installed`

**Solution:**

```bash
# Install CocoaPods
sudo gem install cocoapods

# Clean iOS build
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter run
```

---

## Summary

This guide covered:

✅ **Prerequisites** — Node.js 22+, Flutter 3.8+, Dart 3.8+, required tools  
✅ **Backend Setup** — NestJS installation, environment config, Prisma migrations, seeding  
✅ **Frontend Setup** — Flutter installation, dependencies, code generation, device setup  
✅ **Database** — Prisma workflow, migrations, Prisma Studio  
✅ **Development Workflow** — Git branching, commits, PR process  
✅ **Testing** — Unit tests, E2E tests, widget tests, integration tests  
✅ **Code Quality** — Linting, formatting, pre-commit hooks  
✅ **Debugging** — VS Code launch configs, Flutter DevTools, logging  
✅ **Common Tasks** — Adding endpoints, migrations, feature modules  
✅ **Troubleshooting** — Port conflicts, Redis issues, build failures

**Next Steps:**

- Set up local development environment
- Explore codebase structure
- Run backend and frontend
- Make a small change and submit PR
- Read [DEPLOYMENT.md](./DEPLOYMENT.md) for production deployment

---

**Related Documentation:**

- [ARCHITECTURE.md](./ARCHITECTURE.md) - System architecture overview  
- [API.md](./API.md) - Complete API reference  
- [DATABASE.md](./DATABASE.md) - Database schema and Prisma guide  
- [DEPLOYMENT.md](./DEPLOYMENT.md) - Production deployment guide  
- [USER_GUIDE.md](./USER_GUIDE.md) - End-user feature documentation

---

*This document reflects the actual implementation as of September 25, 2026. All commands and code examples have been verified against the codebase.*
