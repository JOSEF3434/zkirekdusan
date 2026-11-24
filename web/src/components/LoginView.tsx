// web/src/components/LoginView.tsx
import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext.js';
import { authApi } from '../services/authApi.js';
import { GoogleSignInButton } from './GoogleSignInButton.js';
import { AccountLinkModal } from './AccountLinkModal.js';

export interface LoginViewProps {
  onSuccess?: () => void;
  onForgotPassword?: () => void;
  brandTitle?: string;
  brandSubtitle?: string;
  allowGoogleAuth?: boolean;
  allowPasswordReset?: boolean;
}

export const LoginView: React.FC<LoginViewProps> = ({
  onSuccess,
  onForgotPassword,
  brandTitle = 'Zikre Kedusan',
  brandSubtitle = 'Sign in to access your spiritual sanctuary',
  allowGoogleAuth,
  allowPasswordReset,
}) => {
  const { loginWithPassword, isLoading, isGoogleLoading, isAnyLoading, error, clearError, isAuthenticated } = useAuth();
  const [identifier, setIdentifier] = useState('');
  const [password, setPassword] = useState('');
  const [rememberMe, setRememberMe] = useState(true);
  const [effectiveAllowGoogle, setEffectiveAllowGoogle] = useState<boolean>(
    allowGoogleAuth ?? true
  );
  const [effectiveAllowPasswordReset, setEffectiveAllowPasswordReset] = useState<boolean>(
    allowPasswordReset ?? true
  );

  useEffect(() => {
    if (allowGoogleAuth !== undefined) {
      setEffectiveAllowGoogle(allowGoogleAuth);
    }
    if (allowPasswordReset !== undefined) {
      setEffectiveAllowPasswordReset(allowPasswordReset);
    }
    if (allowGoogleAuth !== undefined && allowPasswordReset !== undefined) {
      return;
    }
    let isMounted = true;
    authApi.getLoginPolicyConfig().then((cfg) => {
      if (isMounted && cfg) {
        if (allowGoogleAuth === undefined && typeof cfg.allowGoogleAuth === 'boolean') {
          setEffectiveAllowGoogle(cfg.allowGoogleAuth);
        }
        if (allowPasswordReset === undefined && typeof cfg.allowPasswordReset === 'boolean') {
          setEffectiveAllowPasswordReset(cfg.allowPasswordReset);
        }
      }
    });
    return () => {
      isMounted = false;
    };
  }, [allowGoogleAuth, allowPasswordReset]);

  if (isAuthenticated && onSuccess) {
    onSuccess();
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!identifier || !password) return;

    // Detect if identifier is email or username
    const isEmail = identifier.includes('@');
    const success = await loginWithPassword({
      email: isEmail ? identifier : undefined,
      username: !isEmail ? identifier : undefined,
      password,
    });

    if (success && onSuccess) {
      onSuccess();
    }
  };

  return (
    <div
      style={{
        maxWidth: '420px',
        margin: '40px auto',
        padding: '32px 28px',
        backgroundColor: '#ffffff',
        borderRadius: '16px',
        boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03)',
        border: '1px solid #E5E7EB',
        fontFamily: 'Inter, system-ui, -apple-system, sans-serif',
      }}
    >
      <div style={{ textAlign: 'center', marginBottom: '28px' }}>
        <h1 style={{ margin: '0 0 8px 0', fontSize: '24px', fontWeight: 700, color: '#1E3A8A' }}>
          {brandTitle}
        </h1>
        <p style={{ margin: 0, fontSize: '14px', color: '#6B7280' }}>{brandSubtitle}</p>
      </div>

      {error && (
        <div
          style={{
            padding: '12px 14px',
            backgroundColor: '#FEE2E2',
            color: '#B91C1C',
            borderRadius: '8px',
            fontSize: '13px',
            marginBottom: '20px',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
          }}
        >
          <span>{error}</span>
          <button
            onClick={clearError}
            style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#B91C1C', fontWeight: 'bold' }}
          >
            ✕
          </button>
        </div>
      )}

      {/* Continue with Google */}
      {effectiveAllowGoogle && (
        <>
          <div style={{ marginBottom: '20px' }}>
            <GoogleSignInButton text="continue_with" size="large" width="100%" />
          </div>

          {/* Divider */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              margin: '20px 0',
              color: '#9CA3AF',
              fontSize: '12px',
              textTransform: 'uppercase',
              letterSpacing: '0.05em',
            }}
          >
            <div style={{ flex: 1, height: '1px', backgroundColor: '#E5E7EB' }} />
            <span style={{ padding: '0 12px' }}>or continue with credentials</span>
            <div style={{ flex: 1, height: '1px', backgroundColor: '#E5E7EB' }} />
          </div>
        </>
      )}

      {/* Password Login Form */}
      <form onSubmit={handleSubmit}>
        <div style={{ marginBottom: '16px' }}>
          <label
            htmlFor="login-identifier"
            style={{ display: 'block', fontSize: '13px', fontWeight: 500, color: '#374151', marginBottom: '6px' }}
          >
            Email or Username
          </label>
          <input
            id="login-identifier"
            type="text"
            value={identifier}
            onChange={(e) => setIdentifier(e.target.value)}
            placeholder="you@example.com or username"
            required
            disabled={isLoading}
            style={{
              width: '100%',
              padding: '10px 14px',
              borderRadius: '8px',
              border: '1px solid #D1D5DB',
              fontSize: '14px',
              boxSizing: 'border-box',
              outline: 'none',
            }}
          />
        </div>

        <div style={{ marginBottom: '16px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px' }}>
            <label
              htmlFor="login-password"
              style={{ fontSize: '13px', fontWeight: 500, color: '#374151' }}
            >
              Password
            </label>
            {effectiveAllowPasswordReset && onForgotPassword && (
              <a
                href="#forgot-password"
                onClick={(e) => {
                  e.preventDefault();
                  onForgotPassword();
                }}
                style={{ fontSize: '12px', color: '#1E3A8A', textDecoration: 'none', fontWeight: 500, cursor: 'pointer' }}
              >
                Forgot password?
              </a>
            )}
          </div>
          <input
            id="login-password"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="••••••••"
            required
            disabled={isLoading}
            style={{
              width: '100%',
              padding: '10px 14px',
              borderRadius: '8px',
              border: '1px solid #D1D5DB',
              fontSize: '14px',
              boxSizing: 'border-box',
              outline: 'none',
            }}
          />
        </div>

        <div style={{ display: 'flex', alignItems: 'center', marginBottom: '20px' }}>
          <input
            id="remember-me"
            type="checkbox"
            checked={rememberMe}
            onChange={(e) => setRememberMe(e.target.checked)}
            style={{ marginRight: '8px', cursor: 'pointer' }}
          />
          <label htmlFor="remember-me" style={{ fontSize: '13px', color: '#4B5563', cursor: 'pointer' }}>
            Remember this device
          </label>
        </div>

        <button
          type="submit"
          disabled={isAnyLoading || !identifier || !password}
          style={{
            width: '100%',
            padding: '12px',
            borderRadius: '8px',
            border: 'none',
            backgroundColor: '#1E3A8A',
            color: '#ffffff',
            fontSize: '14px',
            fontWeight: 600,
            cursor: isAnyLoading ? 'not-allowed' : 'pointer',
            opacity: isAnyLoading || !identifier || !password ? 0.7 : 1,
            transition: 'opacity 0.2s',
          }}
        >
          {isLoading ? 'Signing In...' : 'Sign In'}
        </button>
      </form>

      {/* Account Linking Modal (Scenario C) */}
      <AccountLinkModal />
    </div>
  );
};
