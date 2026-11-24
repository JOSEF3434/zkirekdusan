// web/src/services/authApi.ts
import { authConfig } from '../config/auth.config.js';
export class AuthApiError extends Error {
    statusCode;
    code;
    details;
    constructor(message, statusCode, code, details) {
        super(message);
        this.name = 'AuthApiError';
        this.statusCode = statusCode;
        this.code = code;
        this.details = details;
    }
}
export class AuthApiService {
    baseUrl;
    constructor(baseUrl = authConfig.apiUrl) {
        // Ensure no trailing slash
        this.baseUrl = baseUrl.replace(/\/$/, '');
    }
    setBaseUrl(url) {
        this.baseUrl = url.replace(/\/$/, '');
    }
    getAccessToken() {
        if (typeof window === 'undefined')
            return null;
        return localStorage.getItem(authConfig.tokenStorageKey);
    }
    getRefreshToken() {
        if (typeof window === 'undefined')
            return null;
        return localStorage.getItem(authConfig.refreshTokenStorageKey);
    }
    getSavedUser() {
        if (typeof window === 'undefined')
            return null;
        const raw = localStorage.getItem(authConfig.userStorageKey);
        if (!raw)
            return null;
        try {
            return JSON.parse(raw);
        }
        catch {
            return null;
        }
    }
    saveTokens(tokens, user) {
        if (typeof window === 'undefined')
            return;
        localStorage.setItem(authConfig.tokenStorageKey, tokens.accessToken);
        localStorage.setItem(authConfig.refreshTokenStorageKey, tokens.refreshToken);
        if (user) {
            localStorage.setItem(authConfig.userStorageKey, JSON.stringify(user));
        }
    }
    clearStorage() {
        if (typeof window === 'undefined')
            return;
        localStorage.removeItem(authConfig.tokenStorageKey);
        localStorage.removeItem(authConfig.refreshTokenStorageKey);
        localStorage.removeItem(authConfig.userStorageKey);
    }
    async request(endpoint, options = {}) {
        const url = `${this.baseUrl}${endpoint.startsWith('/') ? endpoint : `/${endpoint}`}`;
        const headers = new Headers(options.headers || {});
        if (!headers.has('Content-Type') && !(options.body instanceof FormData)) {
            headers.set('Content-Type', 'application/json');
        }
        const token = this.getAccessToken();
        if (token && !headers.has('Authorization')) {
            headers.set('Authorization', `Bearer ${token}`);
        }
        const response = await fetch(url, {
            ...options,
            headers,
        });
        const contentType = response.headers.get('content-type') || '';
        let data = null;
        if (contentType.includes('application/json')) {
            data = await response.json();
        }
        else {
            data = await response.text();
        }
        if (!response.ok) {
            const message = (data && typeof data === 'object' && (data.message || data.error)) ||
                response.statusText ||
                'An error occurred during authentication';
            const code = (data && typeof data === 'object' && (data.code || data.error)) || undefined;
            throw new AuthApiError(Array.isArray(message) ? message.join(', ') : String(message), response.status, code, data);
        }
        return data;
    }
    // --- Core Authentication Methods ---
    /**
     * Authenticate with Google ID Token (GIS)
     */
    async loginWithGoogle(payload) {
        const res = await this.request('/auth/google', {
            method: 'POST',
            body: JSON.stringify(payload),
        });
        this.saveTokens(res, res.user);
        return res;
    }
    /**
     * Link Google identity to existing account using password verification (Scenario C)
     */
    async linkGoogleAccount(payload) {
        const res = await this.request('/auth/google/link-account', {
            method: 'POST',
            body: JSON.stringify(payload),
        });
        this.saveTokens(res, res.user);
        return res;
    }
    /**
     * Connect Google to current authenticated account
     */
    async connectGoogle(payload) {
        await this.request('/auth/google/connect', {
            method: 'POST',
            body: JSON.stringify(payload),
        });
    }
    /**
     * Disconnect Google from current authenticated account
     */
    async disconnectGoogle() {
        await this.request('/auth/google/disconnect', {
            method: 'POST',
        });
    }
    /**
     * Get federated identities for current user
     */
    async getIdentities() {
        return this.request('/auth/identities', {
            method: 'GET',
        });
    }
    /**
     * Email/password standard login
     */
    async loginWithPassword(credentials) {
        const res = await this.request('/auth/login', {
            method: 'POST',
            body: JSON.stringify(credentials),
        });
        this.saveTokens(res, res.user);
        return res;
    }
    /**
     * Fetch current user profile
     */
    async getMe() {
        return this.request('/auth/me', {
            method: 'GET',
        });
    }
    /**
     * Refresh tokens
     */
    async refreshTokens() {
        const refreshToken = this.getRefreshToken();
        if (!refreshToken) {
            throw new AuthApiError('No refresh token available', 401);
        }
        const res = await this.request('/auth/refresh', {
            method: 'POST',
            body: JSON.stringify({ refreshToken }),
        });
        this.saveTokens(res);
        return res;
    }
    /**
     * Logout and clear local tokens
     */
    async logout() {
        try {
            const refreshToken = this.getRefreshToken();
            if (refreshToken) {
                await this.request('/auth/logout', {
                    method: 'POST',
                    body: JSON.stringify({ refreshToken }),
                });
            }
        }
        finally {
            this.clearStorage();
        }
    }
}
export const authApi = new AuthApiService();
//# sourceMappingURL=authApi.js.map