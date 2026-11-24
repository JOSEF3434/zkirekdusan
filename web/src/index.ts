// web/src/index.ts

// Context and Hook
export { AuthProvider, useAuth, type AuthContextType } from './context/AuthContext.js';

// Components
export { GoogleSignInButton, type GoogleSignInButtonProps } from './components/GoogleSignInButton.js';
export { AccountLinkModal, type AccountLinkModalProps } from './components/AccountLinkModal.js';
export { ConnectedAccountsView } from './components/ConnectedAccountsView.js';
export { LoginView, type LoginViewProps } from './components/LoginView.js';

// API Service & Errors
export { authApi, AuthApiService, AuthApiError } from './services/authApi.js';

// Configuration
export { authConfig, type AuthConfig } from './config/auth.config.js';

// Types
export type {
  UserRole,
  UserProfile,
  UserSummary,
  AuthTokens,
  AuthResponse,
  FederatedIdentity,
  UserIdentities,
  GoogleAuthPayload,
  GoogleLinkAccountPayload,
  AuthError,
  AuthState,
} from './types/auth.types.js';
