export type UserRole = 'USER' | 'ADMIN' | 'MODERATOR' | 'SUPER_ADMIN';
export interface UserProfile {
    id: string;
    userId: string;
    firstName?: string | null;
    lastName?: string | null;
    displayName?: string | null;
    avatarUrl?: string | null;
    bio?: string | null;
    createdAt?: string;
    updatedAt?: string;
}
export interface UserSummary {
    id: string;
    email: string | null;
    username: string | null;
    phoneNumber: string | null;
    role: UserRole;
    profile?: UserProfile | null;
}
export interface AuthTokens {
    accessToken: string;
    refreshToken: string;
    tokenType: string;
    expiresIn: number;
}
export interface AuthResponse extends AuthTokens {
    user: UserSummary;
}
export interface FederatedIdentity {
    id: string;
    provider: string;
    providerId: string;
    email?: string | null;
    createdAt: string;
    updatedAt: string;
}
export interface UserIdentities {
    hasPassword: boolean;
    identities: FederatedIdentity[];
}
export interface GoogleAuthPayload {
    idToken: string;
}
export interface GoogleLinkAccountPayload {
    idToken: string;
    password: string;
}
export interface AuthError {
    message: string;
    statusCode?: number;
    code?: string;
    details?: unknown;
}
export interface AuthState {
    user: UserSummary | null;
    tokens: AuthTokens | null;
    isAuthenticated: boolean;
    isLoading: boolean;
    isGoogleLoading?: boolean;
    error: string | null;
    pendingGoogleIdToken: string | null;
}
//# sourceMappingURL=auth.types.d.ts.map