// web/src/components/GoogleSignInButton.tsx
import React, { useEffect, useRef, useState } from 'react';
import { authConfig } from '../config/auth.config.js';
import { useAuth } from '../context/AuthContext.js';

export interface GoogleSignInButtonProps {
  clientId?: string;
  theme?: 'outline' | 'filled_blue' | 'filled_black';
  size?: 'large' | 'medium' | 'small';
  text?: 'signin_with' | 'signup_with' | 'continue_with';
  shape?: 'rectangular' | 'pill' | 'circle' | 'square';
  width?: number | string;
  onSuccess?: (idToken: string) => void;
  onError?: (error: Error) => void;
  disabled?: boolean;
  className?: string;
}

declare global {
  interface Window {
    google?: {
      accounts: {
        id: {
          initialize: (config: {
            client_id: string;
            callback: (response: { credential: string }) => void;
            auto_select?: boolean;
            cancel_on_tap_outside?: boolean;
          }) => void;
          renderButton: (
            element: HTMLElement,
            options: {
              theme?: string;
              size?: string;
              text?: string;
              shape?: string;
              width?: number | string;
              logo_alignment?: 'left' | 'center';
            },
          ) => void;
          prompt?: () => void;
        };
      };
    };
  }
}

export const GoogleSignInButton: React.FC<GoogleSignInButtonProps> = ({
  clientId = authConfig.googleClientId,
  theme = 'outline',
  size = 'large',
  text = 'continue_with',
  shape = 'rectangular',
  width = '100%',
  onSuccess,
  onError,
  disabled = false,
  className = '',
}) => {
  const btnContainerRef = useRef<HTMLDivElement>(null);
  const [gisLoaded, setGisLoaded] = useState(false);
  const [fallbackLoading, setFallbackLoading] = useState(false);
  const { signInWithGoogle, isLoading } = useAuth();

  // Load Google Identity Services (GIS) client script if not already present
  useEffect(() => {
    if (typeof window === 'undefined') return;

    if (window.google?.accounts?.id) {
      setGisLoaded(true);
      return;
    }

    const existingScript = document.getElementById('google-client-script');
    if (existingScript) {
      existingScript.addEventListener('load', () => setGisLoaded(true));
      return;
    }

    const script = document.createElement('script');
    script.id = 'google-client-script';
    script.src = 'https://accounts.google.com/gsi/client';
    script.async = true;
    script.defer = true;
    script.onload = () => setGisLoaded(true);
    script.onerror = () => {
      console.warn('Google Identity Services script failed to load.');
    };
    document.head.appendChild(script);
  }, []);

  // Initialize and render GIS button once script is ready and element is mounted
  useEffect(() => {
    if (!gisLoaded || !btnContainerRef.current || !clientId) return;

    try {
      window.google?.accounts.id.initialize({
        client_id: clientId,
        callback: async (response) => {
          if (response?.credential) {
            if (onSuccess) {
              onSuccess(response.credential);
            } else {
              await signInWithGoogle(response.credential);
            }
          }
        },
      });

      // Clear any previous renders in container
      btnContainerRef.current.innerHTML = '';

      window.google?.accounts.id.renderButton(btnContainerRef.current, {
        theme,
        size,
        text,
        shape,
        width: typeof width === 'number' ? width : 280,
      });
    } catch (err) {
      if (onError && err instanceof Error) onError(err);
    }
  }, [gisLoaded, clientId, theme, size, text, shape, width, onSuccess, onError, signInWithGoogle]);

  // If clientId is missing or GIS fails to load, render compliant styled button
  return (
    <div
      style={{
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        width: '100%',
        minHeight: 44,
      }}
      className={className}
    >
      {/* Official GIS container */}
      <div
        ref={btnContainerRef}
        style={{
          display: clientId && gisLoaded ? 'block' : 'none',
          pointerEvents: disabled || isLoading ? 'none' : 'auto',
          opacity: disabled || isLoading ? 0.6 : 1,
        }}
      />

      {/* High-fidelity Fallback / Direct Styled Button (matching Google Branding Guidelines) */}
      {(!clientId || !gisLoaded) && (
        <button
          type="button"
          disabled={disabled || isLoading || fallbackLoading}
          onClick={async () => {
            if (!clientId) {
              const err = new Error('Google Client ID is not configured.');
              if (onError) onError(err);
              else alert('Google Client ID is not configured.');
              return;
            }
            if (window.google?.accounts?.id?.prompt) {
              setFallbackLoading(true);
              window.google.accounts.id.prompt();
              setFallbackLoading(false);
            }
          }}
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '12px',
            width: typeof width === 'number' ? `${width}px` : width,
            padding: '10px 16px',
            backgroundColor: '#ffffff',
            color: '#1f1f1f',
            border: '1px solid #747775',
            borderRadius: shape === 'pill' ? '24px' : '4px',
            fontSize: '14px',
            fontWeight: 500,
            fontFamily: 'Roboto, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
            cursor: disabled || isLoading ? 'not-allowed' : 'pointer',
            boxShadow: '0 1px 2px rgba(0,0,0,0.08)',
            transition: 'background-color 0.2s, box-shadow 0.2s',
          }}
        >
          {/* Official Google G Logo */}
          <svg width="18" height="18" viewBox="0 0 24 24">
            <path
              fill="#4285F4"
              d="M23.745 12.27c0-.79-.07-1.54-.195-2.27H12v4.51h6.59c-.28 1.51-1.15 2.78-2.45 3.64v3.08h3.94c2.31-2.13 3.665-5.25 3.665-8.96z"
            />
            <path
              fill="#34A853"
              d="M12 24c3.24 0 5.96-1.08 8.08-3.02l-3.94-3.08c-1.09.73-2.51 1.17-4.14 1.17-3.13 0-5.78-2.11-6.73-4.95H1.2v3.15C3.28 21.39 7.31 24 12 24z"
            />
            <path
              fill="#FBBC05"
              d="M5.27 14.12c-.24-.71-.37-1.4-.37-2.12s.13-1.41.37-2.12V6.73H1.2C.44 8.24 0 9.94 0 12s.44 3.76 1.2 5.27l4.07-3.15z"
            />
            <path
              fill="#EA4335"
              d="M12 4.93c1.76 0 3.34.61 4.59 1.79l3.58-3.58C18.03 1.15 15.24 0 12 0 7.31 0 3.28 2.61 1.2 6.73l4.07 3.15c.95-2.84 3.6-4.95 6.73-4.95z"
            />
          </svg>
          <span>Continue with Google</span>
        </button>
      )}
    </div>
  );
};
