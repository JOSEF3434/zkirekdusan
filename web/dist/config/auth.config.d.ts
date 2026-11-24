/**
 * Universal configuration provider for Web (supports Vite, Next.js, CRA, and runtime windows)
 */
export interface AuthConfig {
    apiUrl: string;
    googleClientId: string;
    tokenStorageKey: string;
    refreshTokenStorageKey: string;
    userStorageKey: string;
}
declare global {
    interface Window {
        __ENV__?: {
            API_URL?: string;
            GOOGLE_CLIENT_ID?: string;
        };
    }
}
export declare const authConfig: AuthConfig;
//# sourceMappingURL=auth.config.d.ts.map