import type { AuthResponse, AuthTokens, GoogleAuthPayload, GoogleLinkAccountPayload, UserIdentities, UserSummary, RecoveryMethod, RecoveryRequestPayload, RecoveryRequestResponse, RecoveryVerifyPayload, RecoveryVerifyResponse, ValidateTokenResponse, RecoveryResetPayload, RecoveryResetResponse, LoginPolicyConfig } from '../types/auth.types.js';
export declare class AuthApiError extends Error {
    statusCode: number;
    code?: string;
    details?: unknown;
    constructor(message: string, statusCode: number, code?: string, details?: unknown);
}
export declare class AuthApiService {
    private baseUrl;
    constructor(baseUrl?: string);
    setBaseUrl(url: string): void;
    getAccessToken(): string | null;
    getRefreshToken(): string | null;
    getSavedUser(): UserSummary | null;
    saveTokens(tokens: AuthTokens, user?: UserSummary): void;
    clearStorage(): void;
    private request;
    /**
     * Authenticate with Google ID Token (GIS)
     */
    loginWithGoogle(payload: GoogleAuthPayload): Promise<AuthResponse>;
    /**
     * Link Google identity to existing account using password verification (Scenario C)
     */
    linkGoogleAccount(payload: GoogleLinkAccountPayload): Promise<AuthResponse>;
    /**
     * Connect Google to current authenticated account
     */
    connectGoogle(payload: GoogleAuthPayload): Promise<void>;
    /**
     * Disconnect Google from current authenticated account
     */
    disconnectGoogle(): Promise<void>;
    /**
     * Get federated identities for current user
     */
    getIdentities(): Promise<UserIdentities>;
    /**
     * Email/password standard login
     */
    loginWithPassword(credentials: {
        email?: string;
        phoneNumber?: string;
        username?: string;
        password: string;
    }): Promise<AuthResponse>;
    /**
     * Fetch current user profile
     */
    getMe(): Promise<UserSummary>;
    /**
     * Refresh tokens
     */
    refreshTokens(): Promise<AuthTokens>;
    /**
     * Get public login policy configuration
     */
    getLoginPolicyConfig(): Promise<Partial<LoginPolicyConfig>>;
    /**
     * Logout and clear local tokens
     */
    logout(): Promise<void>;
    /**
     * Request password recovery for Email or Ethiopian phone number
     */
    requestPasswordRecovery(payload: RecoveryRequestPayload): Promise<RecoveryRequestResponse>;
    /**
     * Verify an SMS OTP code or email recovery token
     */
    verifyRecoveryCode(payload: RecoveryVerifyPayload): Promise<RecoveryVerifyResponse>;
    /**
     * Validate email reset token before showing password change form
     */
    validateRecoveryToken(token: string): Promise<ValidateTokenResponse>;
    /**
     * Resend recovery OTP or email link (respects 60s cooldown)
     */
    resendRecoveryCode(payload: {
        method: RecoveryMethod;
        identifier: string;
    }): Promise<RecoveryRequestResponse>;
    /**
     * Complete password reset
     */
    resetPassword(payload: RecoveryResetPayload): Promise<RecoveryResetResponse>;
}
export declare const authApi: AuthApiService;
//# sourceMappingURL=authApi.d.ts.map