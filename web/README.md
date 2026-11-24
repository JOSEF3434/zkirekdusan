# Zikre Kedusan Web Client & Google Identity Services (GIS)

Production-ready authentication package for Zikre Kedusan Web applications, supporting Google Identity Services (GIS), account linking (Scenario C), password authentication, session management, and connected account settings.

## Features

- **Google Identity Services (GIS):** Modern, official Google Sign-In with one-tap and branded "Continue with Google" buttons.
- **Intelligent Account Resolution:**
  - Automatically creates new users with default roles (Scenario A).
  - Logs into existing linked accounts seamlessly (Scenario B).
  - Prevents account takeover by requiring password verification for existing email accounts (Scenario C).
  - Enforces blocked/suspended account status (Scenario D).
- **Connected Accounts Management:** Dedicated view for linking/disconnecting Google credentials with protection against disconnecting the sole login method.
- **Session Management:** Secure token storage in `localStorage` with automatic refresh token rotation.
- **Universal Configuration:** Supports Vite, Next.js, Create React App, and runtime `window.__ENV__`.

## Components

- `<GoogleSignInButton />` - Official branded Google Sign-In button.
- `<AccountLinkModal />` - Modal dialog prompting for password when linking an existing account.
- `<ConnectedAccountsView />` - Security settings view for managing federated identities.
- `<LoginView />` - Complete responsive login view.
- `useAuth()` - React hook providing user state, tokens, and authentication methods.

## Environment Variables

| Variable | Description | Default / Example |
|---|---|---|
| `VITE_API_URL` | Zikre Kedusan Backend API URL | `https://zikrekidusan.onrender.com/api` |
| `VITE_GOOGLE_CLIENT_ID` | Google OAuth Web Client ID | `632083728397-q7bp82rggdpbnl2kqoei443rak4lh1k0.apps.googleusercontent.com` |
