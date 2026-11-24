# Zikre Kedusan — Modern Password Recovery & Account Recovery System

## 1. Architectural Overview

The **Zikre Kedusan** password-reset and account-recovery system provides production-grade security for user authentication across web and mobile platforms. The system supports two primary recovery channels:

1. **Email-Based Recovery (Magic Link / Single-Use Token)**
   - 256-bit cryptographically secure random reset token.
   - One-way SHA-256 hash stored in PostgreSQL (`password_recovery_challenges`).
   - Configurable 15-minute token expiration.
   - Branded HTML and plain-text email with direct web and deep-linking mobile support.
   - Automatic token validation on link opening.

2. **Phone-Number Recovery (SMS OTP for Ethiopian Carriers)**
   - Normalized E.164 Ethiopian phone numbers (`+2519...` for Ethio Telecom, `+2517...` for Safaricom Ethiopia).
   - Cryptographically secure 6-digit OTP.
   - Keyed HMAC-SHA256 hash with server pepper (`RECOVERY_HMAC_SECRET`) to protect against low-entropy dictionary and rainbow-table attacks.
   - Constant-time verification (`crypto.timingSafeEqual`) to prevent timing side channels.
   - Configurable 5-minute expiration, max 5 failed attempts lockout, 60-second resend cooldown, and hourly limit (5 requests/hour).

---

## 2. Security Architecture & Threat Mitigation

| Threat | Mitigation Mechanism |
| :--- | :--- |
| **Account Enumeration** | All recovery endpoints return identical generic responses (`"If an account with that contact information exists, recovery instructions have been sent."`) with simulated constant-time delay for unregistered addresses. |
| **Token / OTP Database Leak** | Raw reset tokens and OTP codes are **never** stored in the database. Tokens use SHA-256; low-entropy OTPs use a server-secret keyed HMAC-SHA256 (`RECOVERY_HMAC_SECRET`). |
| **Brute-Force OTP Guessing** | Each challenge enforces a maximum of 5 failed attempts (`maxAttempts`). Upon 5 failed attempts, the code is permanently deactivated. |
| **Replay & Concurrency Attacks** | Database transactions (`prisma.$transaction`) atomically mark challenges as consumed (`consumedAt = new Date()`), update user passwords, and invalidate all other active challenges for the user. |
| **Session Hijacking / Stale Sessions** | Upon successful password reset, active refresh tokens (`usersService.revokeRefreshTokens(userId)`) and sessions (`usersService.revokeSessions(userId)`) are immediately revoked. |
| **SMS Gateway Flooding & Abuse** | Destination-based and IP-based rate limiting: strict 60-second resend cooldown per destination + max 5 requests per hour. |
| **Unauthorized Password Modification** | Advisory notification email is automatically dispatched to the user's registered email address upon password change. |

---

## 3. Database Schema

Migration: `20261124150000_add_password_recovery_challenges`

```prisma
enum RecoveryMethod {
  EMAIL
  PHONE
}

model PasswordRecoveryChallenge {
  id                String         @id @default(uuid())
  userId            String
  user              User           @relation(fields: [userId], references: [id], onDelete: Cascade)

  method            RecoveryMethod
  tokenHash         String
  destination       String

  expiresAt         DateTime
  consumedAt        DateTime?
  failedAttempts    Int            @default(0)
  maxAttempts       Int            @default(5)
  resendAvailableAt DateTime?

  requestIp         String?
  userAgent         String?

  createdAt         DateTime       @default(now())
  updatedAt         DateTime       @updatedAt

  @@index([userId])
  @@index([destination, method])
  @@index([tokenHash])
  @@map("password_recovery_challenges")
}
```

---

## 4. Ethiopian Phone Number Normalization

Ethiopian mobile phone numbers are normalized using `parseEthiopianPhoneNumber`:

- **Ethio Telecom**:
  - Valid formats: `+2519XXXXXXXX`, `2519XXXXXXXX`, `09XXXXXXXX`, `9XXXXXXXX`
  - Normalized: `+2519XXXXXXXX`
  - National format: `09XXXXXXXX`
- **Safaricom Ethiopia**:
  - Valid formats: `+2517XXXXXXXX`, `2517XXXXXXXX`, `07XXXXXXXX`, `7XXXXXXXX`
  - Normalized: `+2517XXXXXXXX`
  - National format: `07XXXXXXXX`

Database queries match both normalized E.164 and local national formats to seamlessly support existing legacy account records.

---

## 5. API Endpoints Reference

All recovery endpoints reside under `/auth`:

### 1. `POST /auth/forgot-password` (or `POST /auth/recovery/request`)
Initiates password recovery.

**Request Body:**
```json
{
  "method": "EMAIL", // or "PHONE" (optional, auto-inferred if omitted)
  "identifier": "user@example.com" // or "+251911223344" / "0911223344"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "If an account associated with this email exists, recovery instructions have been sent.",
  "method": "EMAIL",
  "destinationMasked": "u***@example.com",
  "resendCooldownSeconds": 60
}
```

### 2. `POST /auth/recovery/verify`
Verifies phone OTP code or validates email token.

**Request Body (Phone):**
```json
{
  "method": "PHONE",
  "destination": "+251911223344",
  "code": "123456"
}
```

**Response (200 OK):**
```json
{
  "valid": true,
  "message": "Code verified successfully.",
  "resetToken": "c1f7b889-8d82-4ef8-a401-dc3a9e623190",
  "method": "PHONE"
}
```

### 3. `GET /auth/recovery/validate-token?token=...`
Validates email reset token status when user opens the recovery link.

**Response (200 OK):**
```json
{
  "valid": true,
  "email": "u***@example.com",
  "message": "Recovery link is valid."
}
```

### 4. `POST /auth/recovery/resend`
Resends OTP or recovery link subject to 60-second cooldown and hourly rate limit.

**Request Body:**
```json
{
  "method": "PHONE",
  "identifier": "+251911223344"
}
```

### 5. `POST /auth/reset-password`
Completes password reset using verified token or code.

**Request Body:**
```json
{
  "token": "c1f7b889-8d82-4ef8-a401-dc3a9e623190",
  "password": "NewStrongP@ssw0rd!"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Your password has been successfully reset. Please sign in with your new password."
}
```

---

## 6. Email & SMS Provider Integration

### A. Brevo SMTP Setup
Brevo (formerly Sendinblue) provides reliable transactional SMTP delivery:

1. Create a Brevo account at [brevo.com](https://brevo.com).
2. Go to **Transactional** > **Settings** > **Configuration**.
3. Generate a new SMTP Master Key.
4. Verify your sender domain with SPF, DKIM, and DMARC DNS records.
5. Configure environment variables on Render:
   ```env
   SMTP_HOST=smtp-relay.brevo.com
   SMTP_PORT=587
   SMTP_SECURE=false
   SMTP_USER=your_brevo_account_email@example.com
   SMTP_PASSWORD=your_brevo_smtp_key
   MAIL_FROM=noreply@zikrekidusan.com
   MAIL_FROM_NAME="ዝክረ ክዱሳን | Zikre Kedusan"
   RECOVERY_WEB_URL=https://zikire-kdusan.onrender.com
   ```

### B. AfroMessage SMS Setup (Ethio Telecom & Safaricom Ethiopia)
AfroMessage is Ethiopia's leading commercial SMS gateway:

1. Register an account at [afromessage.com](https://afromessage.com).
2. Complete KYC and register your Sender ID (`ZikreKedusan`).
3. Generate an API Key under **Developer Settings** > **Tokens**.
4. Configure environment variables on Render:
   ```env
   SMS_PROVIDER=afromessage
   AFROMESSAGE_API_KEY=your_afromessage_api_bearer_token
   AFROMESSAGE_API_URL=https://api.afromessage.com/api/send
   AFROMESSAGE_SENDER_ID=ZikreKedusan
   ```
5. **Safe Disabled Behavior**: If `AFROMESSAGE_API_KEY` is omitted or `SMS_PROVIDER=disabled`, the system automatically enters disabled mode. It logs a clean warning and rejects SMS requests gracefully without claiming successful delivery.

---

## 7. Render Deployment Checklist

1. **Environment Variables**: Add all required variables in the Render Dashboard under **Environment**.
2. **Database Migration**: The build script executes:
   ```bash
   npx prisma migrate deploy
   ```
   Ensuring table `password_recovery_challenges` is created automatically.
3. **CORS Origins**: Ensure `CORS_ORIGINS` includes your web application domain (e.g. `https://zikire-kdusan.onrender.com`).
4. **Deep Linking Verification**: Verify that mobile deep links for `https://zikire-kdusan.onrender.com/reset-password` route directly to `ResetPasswordScreen`.

---

## 8. Administrative Policy & Kill-Switch Control

Administrators have granular control over the password recovery subsystem through the centralized platform `LoginPolicy`:

- **Field**: `allowPasswordReset` (boolean, defaults to `true`).
- **Enforcement Layer**:
  - **Backend (`PasswordRecoveryService`)**: Rejects all recovery requests (`/auth/forgot-password`, `/auth/recovery/request`, `/auth/recovery/verify`, `/auth/reset-password`) with `403 ForbiddenException` when disabled.
  - **Token Validation**: `validateEmailToken` immediately reports `valid: false` with administrator advisory text.
  - **Flutter Mobile**:
    - `AdminAuthPolicyScreen`: Admin switch toggle under *Password Recovery & Account Reset* section with audit trail.
    - `LoginScreen`: Automatically hides the *Forgot password?* button when disabled.
    - `ForgotPasswordScreen`: Shows a clear advisory card and disables the submission button if accessed directly.
  - **React Web**:
    - `LoginView`: Hides *Forgot password?* link if `allowPasswordReset === false`.
    - `PasswordRecoveryView`: Renders a friendly administrator notice informing users that recovery is disabled and offering navigation back to sign in.

