// web/src/components/ConnectedAccountsView.tsx
import React, { useEffect, useState, useCallback } from 'react';
import { useAuth } from '../context/AuthContext.js';
import type { UserIdentities } from '../types/auth.types.js';
import { GoogleSignInButton } from './GoogleSignInButton.js';

export const ConnectedAccountsView: React.FC = () => {
  const { getIdentities, disconnectGoogle, connectGoogle, error, clearError, isLoading } = useAuth();
  const [identities, setIdentities] = useState<UserIdentities | null>(null);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);
  const [showConnectModal, setShowConnectModal] = useState(false);

  const fetchIdentitiesData = useCallback(async () => {
    setIsRefreshing(true);
    const data = await getIdentities();
    if (data) {
      setIdentities(data);
    }
    setIsRefreshing(false);
  }, [getIdentities]);

  useEffect(() => {
    fetchIdentitiesData();
  }, [fetchIdentitiesData]);

  const googleIdentity = identities?.identities.find((i) => i.provider === 'google');
  const hasPassword = identities?.hasPassword ?? true;
  const isGoogleConnected = Boolean(googleIdentity);

  // Sole login method rule: Cannot disconnect Google if user does not have a password
  const canDisconnectGoogle = hasPassword;

  const handleDisconnect = async () => {
    if (!canDisconnectGoogle) {
      setActionError(
        'You cannot disconnect your Google account because you have not set a password. Set a password first to preserve account access.',
      );
      return;
    }

    if (!confirm('Are you sure you want to disconnect your Google account from Zikre Kedusan?')) {
      return;
    }

    setActionError(null);
    const success = await disconnectGoogle();
    if (success) {
      await fetchIdentitiesData();
    }
  };

  const handleConnectSuccess = async (idToken: string) => {
    setActionError(null);
    setShowConnectModal(false);
    const success = await connectGoogle(idToken);
    if (success) {
      await fetchIdentitiesData();
    }
  };

  return (
    <div
      style={{
        maxWidth: '600px',
        margin: '0 auto',
        padding: '24px',
        backgroundColor: '#ffffff',
        borderRadius: '12px',
        border: '1px solid #E5E7EB',
        fontFamily: 'Inter, system-ui, -apple-system, sans-serif',
      }}
    >
      <div style={{ marginBottom: '20px' }}>
        <h3 style={{ margin: '0 0 6px 0', fontSize: '18px', fontWeight: 600, color: '#111827' }}>
          Connected Accounts
        </h3>
        <p style={{ margin: 0, fontSize: '14px', color: '#6B7280' }}>
          Manage login providers and federated authentication linked to your Zikre Kedusan profile.
        </p>
      </div>

      {(error || actionError) && (
        <div
          style={{
            padding: '12px 16px',
            backgroundColor: '#FEE2E2',
            color: '#B91C1C',
            borderRadius: '8px',
            fontSize: '13px',
            marginBottom: '16px',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
          }}
        >
          <span>{actionError || error}</span>
          <button
            onClick={() => {
              setActionError(null);
              clearError();
            }}
            style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#B91C1C', fontWeight: 'bold' }}
          >
            ✕
          </button>
        </div>
      )}

      {/* Email / Password Provider Item */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '16px',
          border: '1px solid #E5E7EB',
          borderRadius: '8px',
          marginBottom: '12px',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
          <div
            style={{
              width: '40px',
              height: '40px',
              borderRadius: '8px',
              backgroundColor: '#EFF6FF',
              color: '#2563EB',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: '18px',
            }}
          >
            🔑
          </div>
          <div>
            <div style={{ fontSize: '15px', fontWeight: 500, color: '#111827' }}>Password Authentication</div>
            <div style={{ fontSize: '13px', color: '#6B7280' }}>
              {hasPassword ? 'Active password enabled' : 'No password set (Google login only)'}
            </div>
          </div>
        </div>
        <span
          style={{
            fontSize: '12px',
            fontWeight: 500,
            padding: '4px 8px',
            borderRadius: '6px',
            backgroundColor: hasPassword ? '#ECFDF5' : '#FFFBEB',
            color: hasPassword ? '#065F46' : '#92400E',
          }}
        >
          {hasPassword ? 'Enabled' : 'Not Configured'}
        </span>
      </div>

      {/* Google Identity Provider Item */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '16px',
          border: '1px solid #E5E7EB',
          borderRadius: '8px',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
          {/* Google G Icon */}
          <div
            style={{
              width: '40px',
              height: '40px',
              borderRadius: '8px',
              backgroundColor: '#F3F4F6',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <svg width="20" height="20" viewBox="0 0 24 24">
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
          </div>
          <div>
            <div style={{ fontSize: '15px', fontWeight: 500, color: '#111827' }}>Google Account</div>
            <div style={{ fontSize: '13px', color: '#6B7280' }}>
              {isGoogleConnected
                ? `Connected (${googleIdentity?.email || 'Linked'})`
                : 'Not connected. Link Google for one-tap sign-in.'}
            </div>
          </div>
        </div>

        <div>
          {isGoogleConnected ? (
            <button
              onClick={handleDisconnect}
              disabled={isLoading || !canDisconnectGoogle}
              title={
                !canDisconnectGoogle
                  ? 'Cannot disconnect: Set a password first to avoid losing account access'
                  : 'Disconnect Google'
              }
              style={{
                padding: '8px 14px',
                borderRadius: '6px',
                border: '1px solid #D1D5DB',
                backgroundColor: '#ffffff',
                color: canDisconnectGoogle ? '#DC2626' : '#9CA3AF',
                fontSize: '13px',
                fontWeight: 500,
                cursor: canDisconnectGoogle && !isLoading ? 'pointer' : 'not-allowed',
              }}
            >
              Disconnect
            </button>
          ) : (
            <button
              onClick={() => setShowConnectModal(true)}
              disabled={isLoading}
              style={{
                padding: '8px 14px',
                borderRadius: '6px',
                border: 'none',
                backgroundColor: '#1E3A8A',
                color: '#ffffff',
                fontSize: '13px',
                fontWeight: 500,
                cursor: isLoading ? 'not-allowed' : 'pointer',
              }}
            >
              Connect
            </button>
          )}
        </div>
      </div>

      {/* Connect Modal */}
      {showConnectModal && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            backgroundColor: 'rgba(0, 0, 0, 0.55)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 9999,
            padding: '16px',
          }}
        >
          <div
            style={{
              backgroundColor: '#ffffff',
              borderRadius: '16px',
              padding: '24px',
              maxWidth: '400px',
              width: '100%',
              textAlign: 'center',
            }}
          >
            <h4 style={{ margin: '0 0 10px 0', fontSize: '17px', fontWeight: 600 }}>Link Google Account</h4>
            <p style={{ fontSize: '13px', color: '#6B7280', marginBottom: '20px' }}>
              Sign in with the Google account you wish to link to your Zikre Kedusan profile.
            </p>
            <div style={{ display: 'flex', justifyContent: 'center', marginBottom: '16px' }}>
              <GoogleSignInButton onSuccess={handleConnectSuccess} text="continue_with" width={260} />
            </div>
            <button
              onClick={() => setShowConnectModal(false)}
              style={{
                padding: '8px 16px',
                border: '1px solid #D1D5DB',
                backgroundColor: '#ffffff',
                borderRadius: '6px',
                fontSize: '13px',
                cursor: 'pointer',
              }}
            >
              Cancel
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
