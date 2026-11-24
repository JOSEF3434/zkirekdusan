// web/src/services/authApi.ts
import { authConfig } from '../config/auth.config.js';
import type {
  AuthResponse,
  AuthTokens,
  GoogleAuthPayload,
  GoogleLinkAccountPayload,
  UserIdentities,
  UserSummary,
} from '../types/auth.types.js';

export class AuthApiError extends Error {
  statusCode: number;
  code?: string;
  details?: unknown;

  constructor(message: string, statusCode: number, code?: string, details?: unknown) {
    super(message);
    this.name = 'AuthApiError';
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
  }
}

export class AuthApiService {
  private baseUrl: string;

  constructor(baseUrl: string = authConfig.apiUrl) {
    // Ensure no trailing slash
    this.baseUrl = baseUrl.replace(/\/$/, '');
  }

  public setBaseUrl(url: string) {
    this.baseUrl = url.replace(/\/$/, '');
  }

  public getAccessToken(): string | null {
    if (typeof window === 'undefined') return null;
    return localStorage.getItem(authConfig.tokenStorageKey);
  }

  public getRefreshToken(): string | null {
    if (typeof window === 'undefined') return null;
    return localStorage.getItem(authConfig.refreshTokenStorageKey);
  }

  public getSavedUser(): UserSummary | null {
    if (typeof window === 'undefined') return null;
    const raw = localStorage.getItem(authConfig.userStorageKey);
    if (!raw) return null;
    try {
      return JSON.parse(raw) as UserSummary;
    } catch {
      return null;
    }
  }

  public saveTokens(tokens: AuthTokens, user?: UserSummary): void {
    if (typeof window === 'undefined') return;
    localStorage.setItem(authConfig.tokenStorageKey, tokens.accessToken);
    localStorage.setItem(authConfig.refreshTokenStorageKey, tokens.refreshToken);
    if (user) {
      localStorage.setItem(authConfig.userStorageKey, JSON.stringify(user));
    }
  }

  public clearStorage(): void {
    if (typeof window === 'undefined') return;
    localStorage.removeItem(authConfig.tokenStorageKey);
    localStorage.removeItem(authConfig.refreshTokenStorageKey);
    localStorage.removeItem(authConfig.userStorageKey);
  }

  private async request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
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
    let data: any = null;
    if (contentType.includes('application/json')) {
      data = await response.json();
    } else {
      data = await response.text();
    }

    if (!response.ok) {
      const message =
        (data && typeof data === 'object' && (data.message || data.error)) ||
        response.statusText ||
        'An error occurred during authentication';
      const code = (data && typeof data === 'object' && (data.code || data.error)) || undefined;
      throw new AuthApiError(
        Array.isArray(message) ? message.join(', ') : String(message),
        response.status,
        code,
        data,
      );
    }

    return data as T;
  }

  // --- Core Authentication Methods ---

  /**
   * Authenticate with Google ID Token (GIS)
   */
  async loginWithGoogle(payload: GoogleAuthPayload): Promise<AuthResponse> {
    const res = await this.request<AuthResponse>('/auth/google', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
    this.saveTokens(res, res.user);
    return res;
  }

  /**
   * Link Google identity to existing account using password verification (Scenario C)
   */
  async linkGoogleAccount(payload: GoogleLinkAccountPayload): Promise<AuthResponse> {
    const res = await this.request<AuthResponse>('/auth/google/link-account', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
    this.saveTokens(res, res.user);
    return res;
  }

  /**
   * Connect Google to current authenticated account
   */
  async connectGoogle(payload: GoogleAuthPayload): Promise<void> {
    await this.request<void>('/auth/google/connect', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  }

  /**
   * Disconnect Google from current authenticated account
   */
  async disconnectGoogle(): Promise<void> {
    await this.request<void>('/auth/google/disconnect', {
      method: 'POST',
    });
  }

  /**
   * Get federated identities for current user
   */
  async getIdentities(): Promise<UserIdentities> {
    return this.request<UserIdentities>('/auth/identities', {
      method: 'GET',
    });
  }

  /**
   * Email/password standard login
   */
  async loginWithPassword(credentials: {
    email?: string;
    phoneNumber?: string;
    username?: string;
    password: string;
  }): Promise<AuthResponse> {
    const res = await this.request<AuthResponse>('/auth/login', {
      method: 'POST',
      body: JSON.stringify(credentials),
    });
    this.saveTokens(res, res.user);
    return res;
  }

  /**
   * Fetch current user profile
   */
  async getMe(): Promise<UserSummary> {
    return this.request<UserSummary>('/auth/me', {
      method: 'GET',
    });
  }

  /**
   * Refresh tokens
   */
  async refreshTokens(): Promise<AuthTokens> {
    const refreshToken = this.getRefreshToken();
    if (!refreshToken) {
      throw new AuthApiError('No refresh token available', 401);
    }

    const res = await this.request<AuthTokens>('/auth/refresh', {
      method: 'POST',
      body: JSON.stringify({ refreshToken }),
    });
    this.saveTokens(res);
    return res;
  }

  /**
   * Get public login policy configuration
   */
  async getLoginPolicyConfig(): Promise<{ allowGoogleAuth?: boolean; activePolicy?: string }> {
    try {
      return await this.request<{ allowGoogleAuth?: boolean; activePolicy?: string }>('/auth-policy/config', {
        method: 'GET',
      });
    } catch {
      return { allowGoogleAuth: true };
    }
  }

  /**
   * Logout and clear local tokens
   */
  async logout(): Promise<void> {
    try {
      const refreshToken = this.getRefreshToken();
      if (refreshToken) {
        await this.request<void>('/auth/logout', {
          method: 'POST',
          body: JSON.stringify({ refreshToken }),
        });
      }
    } finally {
      this.clearStorage();
    }
  }
}

export const authApi = new AuthApiService();
