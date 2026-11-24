import type { AuthResponse, AuthTokens, GoogleAuthPayload, GoogleLinkAccountPayload, UserIdentities, UserSummary } from '../types/auth.types.js';
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
     * Logout and clear local tokens
     */
    logout(): Promise<void>;
}
export declare const authApi: AuthApiService;
//# sourceMappingURL=authApi.d.ts.map