# Google Sign-In & OpenID Connect Integration Guide
**Zikre Kedusan Multi-Platform Authentication System**

This document provides a comprehensive operational guide for the Google Authentication ("Continue with Google") implementation across the Zikre Kedusan technology stack:
- **Backend:** NestJS, Prisma ORM, PostgreSQL (Neon / AWS).
- **Mobile:** Flutter (Android & iOS).
- **Web:** React Web Client & Google Identity Services (GIS).

---

## 1. Overview of Authentication Architecture

The system uses standard **OAuth 2.0 and OpenID Connect (OIDC)** with cryptographic token verification on the backend:

```
[ Client: Flutter / React ]
           │
           │ 1. User taps "Continue with Google"
           ▼
[ Google Identity Services / Play Services ]
           │
           │ 2. Issues cryptographically signed ID Token (JWT)
           ▼
[ Client: Flutter / React ]
           │
           │ 3. POST /api/auth/google { idToken }
           ▼
[ NestJS Backend (GoogleAuthService) ]
           │
           │ 4. Verifies signature, issuer, expiration, audience allowlist, & email_verified
           │ 5. Resolves account via FederatedIdentity model (Scenarios A, B, C, D)
           ▼
[ Zikre Kedusan Database (PostgreSQL) ]
           │
           │ 6. Issues Zikre Kedusan Access Token & Refresh Token
           ▼
[ Client Session Established ]
```

---

## 2. Google Cloud Platform (GCP) Configuration

### 2.1 OAuth Consent Screen
1. In Google Cloud Console, navigate to **APIs & Services > OAuth consent screen**.
2. **User Type:** External.
3. **App Information:**
   - App name: `ዝክረ ክዱሳን (Zikre Kedusan)`
   - User support email: Select authorized administrator email.
4. **App Domain:**
   - Application Home Page: `https://zikire-kdusan.onrender.com`
   - Privacy Policy: `https://zikire-kdusan.onrender.com/privacy`
   - Terms of Service: `https://zikire-kdusan.onrender.com/terms`
5. **Scopes:**
   - `openid`
   - `https://www.googleapis.com/auth/userinfo.email`
   - `https://www.googleapis.com/auth/userinfo.profile`

### 2.2 Client Credentials Configured

| Client Type | Client ID | Purpose |
|---|---|---|
| **Web** | `632083728397-q7bp82rggdpbnl2kqoei443rak4lh1k0.apps.googleusercontent.com` | React Web, Flutter Web, and backend audience verification |
| **Android** | `632083728397-r647raagj7ncuvqd255ca8l9cs2lt75k.apps.googleusercontent.com` | Flutter Android Application (`com.zikrekidusan.mobile`) |

#### Web Client Configuration:
- **Authorized JavaScript Origins:**
  - `http://localhost:3000`
  - `http://localhost:5173`
  - `https://zikire-kdusan.onrender.com`
- **Authorized Redirect URIs:**
  - `http://localhost:3000`
  - `http://localhost:5173`
  - `https://zikire-kdusan.onrender.com`

#### Android Client Configuration:
- **Package name:** `com.zikrekidusan.mobile`
- **Debug SHA-1 Extraction:**
  ```powershell
  keytool -list -v -keystore "$HOME\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
  ```
- **Release SHA-1 Extraction:**
  ```powershell
  keytool -list -v -keystore path\to\your-release-key.jks -alias your-key-alias
  ```
- If deployed via Google Play, copy the SHA-1 from **Play Console > Release > Setup > App Integrity > App signing certificate**.

#### iOS Client Configuration (When adding iOS):
- **Bundle ID:** `com.zikrekidusan.mobile` (from `mobile/ios/Runner.xcodeproj/project.pbxproj`).
- Add the reversed client ID to `mobile/ios/Runner/Info.plist`:
  ```xml
  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleTypeRole</key>
      <string>Editor</string>
      <key>CFBundleURLSchemes</key>
      <array>
        <string>com.googleusercontent.apps.YOUR_IOS_CLIENT_ID</string>
      </array>
    </dict>
  </array>
  ```

---

## 3. Backend Implementation (NestJS + Prisma)

### 3.1 Database Schema (`FederatedIdentity`)
The Prisma schema includes a dedicated, normalized `FederatedIdentity` model:
```prisma
model User {
  id                  String              @id @default(uuid())
  email               String?             @unique
  passwordHash        String?             // Nullable for pure OAuth users
  federatedIdentities FederatedIdentity[]
  ...
}

model FederatedIdentity {
  id         String   @id @default(uuid())
  userId     String   @map("user_id")
  provider   String   // "google"
  providerId String   @map("provider_id") // Google "sub" identifier
  email      String?
  createdAt  DateTime @default(now()) @map("created_at")
  updatedAt  DateTime @updatedAt @map("updated_at")

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([provider, providerId])
  @@index([userId])
  @@map("federated_identities")
}
```

### 3.2 Safe Non-Destructive Migration
Located at `backend/prisma/migrations/20261124100000_add_federated_identities/migration.sql`:
```sql
ALTER TABLE "users" ALTER COLUMN "passwordHash" DROP NOT NULL;

CREATE TABLE IF NOT EXISTS "federated_identities" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "provider_id" TEXT NOT NULL,
    "email" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "federated_identities_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "federated_identities_provider_provider_id_key" ON "federated_identities"("provider", "provider_id");
CREATE INDEX IF NOT EXISTS "federated_identities_user_id_idx" ON "federated_identities"("user_id");

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'federated_identities_user_id_fkey'
    ) THEN
        ALTER TABLE "federated_identities" ADD CONSTRAINT "federated_identities_user_id_fkey"
        FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$;
```

To apply to production:
```bash
cd backend
npx prisma migrate deploy
```

### 3.3 Account Resolution Rules (Scenarios A - D)
- **Scenario A (New Google User):** Creates user with role `USER`, creates profile, and links Google `sub`. Does not grant administrator privileges.
- **Scenario B (Existing Linked User):** Finds `FederatedIdentity` by `(provider: 'google', providerId: sub)`. Issues tokens for existing account, preserving all roles, history, and settings.
- **Scenario C (Existing Password User with Same Email):**
  - **Account Takeover Protection:** Prevents automatic merge.
  - Returns `409 Conflict` with `code: 'ACCOUNT_EXISTS_LINK_REQUIRED'`.
  - User is prompted to confirm their password via `POST /api/auth/google/link-account`.
- **Scenario D (Suspended / Blocked Accounts):** Respects existing status checks (`status === 'BANNED' || status === 'SUSPENDED'`), rejecting authentication immediately.

### 3.4 API Endpoints

| Method | Endpoint | Protection | Description |
|---|---|---|---|
| `POST` | `/api/auth/google` | Public (Throttled) | Authenticate with Google ID token |
| `POST` | `/api/auth/google/link-account` | Public (Throttled) | Confirm password to link Google identity (Scenario C) |
| `POST` | `/api/auth/google/connect` | Bearer Auth | Connect Google identity to current logged-in profile |
| `POST` | `/api/auth/google/disconnect` | Bearer Auth | Disconnect Google identity (guarded against sole login removal) |
| `GET` | `/api/auth/identities` | Bearer Auth | List user's connected providers and password status |

---

## 4. Mobile Implementation (Flutter)

### 4.1 Dependency
- `google_sign_in: ^6.2.2` added to `mobile/pubspec.yaml`.

### 4.2 Server Client ID Configuration
In `mobile/lib/features/auth/data/services/google_sign_in_service.dart`:
```dart
GoogleSignIn(
  scopes: const ['email', 'profile'],
  clientId: kIsWeb ? _getEnv('GOOGLE_CLIENT_ID_WEB') : null,
  serverClientId: _getEnv('GOOGLE_CLIENT_ID_WEB') ?? _getEnv('GOOGLE_SERVER_CLIENT_ID'),
)
```
> [!NOTE]
> On Android, Google Play Services requires `serverClientId` set to the **Web Client ID**. This instructs Google to issue an ID token with the Web client ID as the audience, which the backend verifies.

### 4.3 UI & Localization
- Branded `GoogleSignInButton` widget complying with Google brand guidelines with vector Google "G" logo.
- Responsive layout preventing text overflow on narrow devices.
- Localized in English and Amharic in `mobile/assets/lang/language_togle.json`:
  - English: `"continueWithGoogle": "Continue with Google"`, `"connectedAccounts": "Connected Accounts"`
  - Amharic: `"continueWithGoogle": "በGoogle ይቀጥሉ"`, `"connectedAccounts": "የተገናኙ መለያዎች"`
- Security settings screen provides identity overview, connect dialog, and disconnect protection.

---

## 5. Web Implementation (React Web Package)

Located at `web/`:
- **Package:** `@zikrekidusan/web`
- **Google Identity Services (GIS):** Dynamically loads `https://accounts.google.com/gsi/client`.
- **Components:**
  - `GoogleSignInButton`: Renders the official GIS button or responsive branded fallback.
  - `AccountLinkModal`: Handles Scenario C password prompt seamlessly.
  - `ConnectedAccountsView`: Embedded in user profile / security settings.
  - `LoginView`: Complete sign-in card supporting credentials and Google.
  - `AuthProvider` & `useAuth()`: React state management and storage persistence.

---

## 6. Verification and Regression Testing

### 6.1 Backend Tests
```bash
cd backend
npx jest src/modules/auth
```
- **Results:** 6 test suites passed, 59/59 tests passed.

### 6.2 Mobile Tests
```bash
cd mobile
flutter test test/features/auth test/core/network/auth_endpoint_regression_test.dart
```
- **Results:** 38/38 tests passed.

### 6.3 Web Tests
```bash
cd web
npm test
```
- **Results:** 3/3 tests passed.

---

## 7. Production Deployment Checklist (Render)

1. **Backend Environment Variables on Render:**
   - `GOOGLE_CLIENT_ID_WEB`: `632083728397-q7bp82rggdpbnl2kqoei443rak4lh1k0.apps.googleusercontent.com`
   - `GOOGLE_CLIENT_ID_ANDROID`: `632083728397-r647raagj7ncuvqd255ca8l9cs2lt75k.apps.googleusercontent.com`
   - `GOOGLE_ALLOWED_CLIENT_IDS`: `632083728397-q7bp82rggdpbnl2kqoei443rak4lh1k0.apps.googleusercontent.com,632083728397-r647raagj7ncuvqd255ca8l9cs2lt75k.apps.googleusercontent.com`
2. **Apply Database Migration:**
   ```bash
   npx prisma migrate deploy
   ```
3. **Web Environment Variables:**
   - `VITE_API_URL`: `https://zikrekidusan.onrender.com/api`
   - `VITE_GOOGLE_CLIENT_ID`: `632083728397-q7bp82rggdpbnl2kqoei443rak4lh1k0.apps.googleusercontent.com`
4. **Mobile Release Build:**
   - Build signed APK / App Bundle with Google Play signing certificate registered in Google Cloud Console.
