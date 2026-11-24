// web/src/components/PasswordRecoveryView.tsx
import React, { useState, useEffect, useRef } from 'react';
import { authApi } from '../services/authApi.js';
import type { RecoveryMethod } from '../types/auth.types.js';

export interface PasswordRecoveryViewProps {
  onSuccess?: () => void;
  onBackToLogin?: () => void;
  brandTitle?: string;
  brandSubtitle?: string;
  initialToken?: string;
}

type RecoveryStep = 'INPUT' | 'VERIFY_OTP' | 'RESET_PASSWORD' | 'SUCCESS';

export const PasswordRecoveryView: React.FC<PasswordRecoveryViewProps> = ({
  onSuccess,
  onBackToLogin,
  brandTitle = 'Zikre Kedusan',
  brandSubtitle = 'Spiritual Sanctuary Account Recovery',
  initialToken,
}) => {
  const [method, setMethod] = useState<RecoveryMethod>('EMAIL');
  const [step, setStep] = useState<RecoveryStep>('INPUT');
  const [identifier, setIdentifier] = useState('');
  const [otpCode, setOtpCode] = useState('');
  const [resetToken, setResetToken] = useState(initialToken || '');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);

  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successInfo, setSuccessInfo] = useState<string | null>(null);
  const [maskedDestination, setMaskedDestination] = useState<string | null>(null);
  const [cooldown, setCooldown] = useState(0);

  const timerRef = useRef<NodeJS.Timeout | null>(null);

  // Check URL query parameter for token on mount
  useEffect(() => {
    let token = initialToken;
    if (!token && typeof window !== 'undefined') {
      const params = new URLSearchParams(window.location.search);
      token = params.get('token') || undefined;
    }

    if (token) {
      setResetToken(token);
      setIsLoading(true);
      authApi
        .validateRecoveryToken(token)
        .then((res) => {
          if (res.valid) {
            setStep('RESET_PASSWORD');
            if (res.email) setMaskedDestination(res.email);
          } else {
            setError(res.message || 'This recovery link has expired or is invalid.');
          }
        })
        .catch((err) => {
          setError(err?.message || 'Failed to validate recovery token.');
        })
        .finally(() => {
          setIsLoading(false);
        });
    }
  }, [initialToken]);

  // Cooldown countdown timer
  useEffect(() => {
    if (cooldown > 0) {
      timerRef.current = setTimeout(() => {
        setCooldown((prev) => prev - 1);
      }, 1000);
    }
    return () => {
      if (timerRef.current) clearTimeout(timerRef.current);
    };
  }, [cooldown]);

  // Validation rules
  const hasMinLength = newPassword.length >= 8;
  const hasUppercase = /[A-Z]/.test(newPassword);
  const hasLowercase = /[a-z]/.test(newPassword);
  const hasNumber = /[0-9]/.test(newPassword);
  const hasSpecial = /[@$!%*?&_\-#]/.test(newPassword);
  const passwordsMatch = newPassword.length > 0 && newPassword === confirmPassword;
  const isPasswordValid =
    hasMinLength && hasUppercase && hasLowercase && hasNumber && hasSpecial && passwordsMatch;

  // Step 1: Request Recovery
  const handleRequestSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!identifier.trim()) return;

    setError(null);
    setIsLoading(true);

    try {
      const res = await authApi.requestPasswordRecovery({
        method,
        identifier: identifier.trim(),
      });

      setSuccessInfo(res.message);
      setMaskedDestination(res.destinationMasked || identifier);
      setCooldown(res.resendCooldownSeconds || 60);

      if (res.method === 'PHONE') {
        setStep('VERIFY_OTP');
      }
    } catch (err: any) {
      setError(err?.message || 'Unable to request password recovery. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  // Step 2: Verify Phone OTP
  const handleVerifyOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!otpCode.trim() || otpCode.length < 6) {
      setError('Please enter the complete 6-digit verification code.');
      return;
    }

    setError(null);
    setIsLoading(true);

    try {
      const res = await authApi.verifyRecoveryCode({
        method: 'PHONE',
        destination: identifier.trim(),
        code: otpCode.trim(),
      });

      if (res.valid) {
        setResetToken(res.resetToken);
        setStep('RESET_PASSWORD');
      }
    } catch (err: any) {
      setError(err?.message || 'Invalid or expired verification code.');
    } finally {
      setIsLoading(false);
    }
  };

  // Resend code or email
  const handleResend = async () => {
    if (cooldown > 0 || isLoading) return;

    setError(null);
    setIsLoading(true);

    try {
      const res = await authApi.resendRecoveryCode({
        method,
        identifier: identifier.trim(),
      });

      setSuccessInfo(res.message);
      setCooldown(res.resendCooldownSeconds || 60);
    } catch (err: any) {
      setError(err?.message || 'Failed to resend recovery code.');
    } finally {
      setIsLoading(false);
    }
  };

  // Step 3: Complete Password Reset
  const handleResetSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!isPasswordValid) return;

    setError(null);
    setIsLoading(true);

    try {
      const res = await authApi.resetPassword({
        method,
        destination: method === 'PHONE' ? identifier.trim() : undefined,
        code: method === 'PHONE' ? otpCode.trim() : undefined,
        token: resetToken || undefined,
        resetToken: resetToken || undefined,
        password: newPassword,
      });

      if (res.success) {
        setStep('SUCCESS');
      }
    } catch (err: any) {
      setError(err?.message || 'Failed to reset password. Please request a new recovery link.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div
      style={{
        maxWidth: '440px',
        margin: '40px auto',
        padding: '32px 28px',
        backgroundColor: '#ffffff',
        borderRadius: '16px',
        boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03)',
        border: '1px solid #E5E7EB',
        fontFamily: 'Inter, system-ui, -apple-system, sans-serif',
      }}
    >
      {/* Brand Header */}
      <div style={{ textAlign: 'center', marginBottom: '24px' }}>
        <h1 style={{ margin: '0 0 6px 0', fontSize: '22px', fontWeight: 700, color: '#1E3A8A' }}>
          {brandTitle}
        </h1>
        <p style={{ margin: 0, fontSize: '13px', color: '#6B7280' }}>{brandSubtitle}</p>
      </div>

      {/* Global Error Banner */}
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
            onClick={() => setError(null)}
            style={{
              background: 'none',
              border: 'none',
              cursor: 'pointer',
              color: '#B91C1C',
              fontWeight: 'bold',
            }}
          >
            ✕
          </button>
        </div>
      )}

      {/* STEP 1: Method selection & Identifier input */}
      {step === 'INPUT' && (
        <div>
          <h2 style={{ fontSize: '18px', fontWeight: 600, color: '#111827', margin: '0 0 8px 0' }}>
            Account Recovery
          </h2>
          <p style={{ fontSize: '13px', color: '#6B7280', margin: '0 0 20px 0' }}>
            Select how you would like to recover your password.
          </p>

          {/* Recovery Method Tabs */}
          <div
            style={{
              display: 'flex',
              backgroundColor: '#F3F4F6',
              borderRadius: '8px',
              padding: '4px',
              marginBottom: '20px',
            }}
          >
            <button
              type="button"
              onClick={() => {
                setMethod('EMAIL');
                setIdentifier('');
                setError(null);
              }}
              style={{
                flex: 1,
                padding: '8px',
                border: 'none',
                borderRadius: '6px',
                fontSize: '13px',
                fontWeight: 600,
                cursor: 'pointer',
                backgroundColor: method === 'EMAIL' ? '#ffffff' : 'transparent',
                color: method === 'EMAIL' ? '#1E3A8A' : '#6B7280',
                boxShadow: method === 'EMAIL' ? '0 1px 3px rgba(0,0,0,0.1)' : 'none',
                transition: 'all 0.15s ease',
              }}
            >
              ✉️ Email Address
            </button>
            <button
              type="button"
              onClick={() => {
                setMethod('PHONE');
                setIdentifier('');
                setError(null);
              }}
              style={{
                flex: 1,
                padding: '8px',
                border: 'none',
                borderRadius: '6px',
                fontSize: '13px',
                fontWeight: 600,
                cursor: 'pointer',
                backgroundColor: method === 'PHONE' ? '#ffffff' : 'transparent',
                color: method === 'PHONE' ? '#1E3A8A' : '#6B7280',
                boxShadow: method === 'PHONE' ? '0 1px 3px rgba(0,0,0,0.1)' : 'none',
                transition: 'all 0.15s ease',
              }}
            >
              📱 Phone (SMS OTP)
            </button>
          </div>

          <form onSubmit={handleRequestSubmit}>
            <div style={{ marginBottom: '20px' }}>
              <label
                htmlFor="recovery-identifier"
                style={{
                  display: 'block',
                  fontSize: '13px',
                  fontWeight: 500,
                  color: '#374151',
                  marginBottom: '6px',
                }}
              >
                {method === 'EMAIL' ? 'Registered Email Address' : 'Ethiopian Phone Number'}
              </label>
              <input
                id="recovery-identifier"
                type={method === 'EMAIL' ? 'email' : 'tel'}
                value={identifier}
                onChange={(e) => setIdentifier(e.target.value)}
                placeholder={
                  method === 'EMAIL' ? 'you@example.com' : '+251911223344 or 0911223344'
                }
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
              {method === 'PHONE' && (
                <div style={{ fontSize: '11px', color: '#6B7280', marginTop: '6px' }}>
                  Supports Ethio Telecom (+2519...) and Safaricom Ethiopia (+2517...)
                </div>
              )}
            </div>

            <button
              type="submit"
              disabled={isLoading || !identifier.trim()}
              style={{
                width: '100%',
                padding: '12px',
                borderRadius: '8px',
                border: 'none',
                backgroundColor: '#1E3A8A',
                color: '#ffffff',
                fontSize: '14px',
                fontWeight: 600,
                cursor: isLoading || !identifier.trim() ? 'not-allowed' : 'pointer',
                opacity: isLoading || !identifier.trim() ? 0.7 : 1,
                marginBottom: '16px',
              }}
            >
              {isLoading
                ? 'Processing...'
                : method === 'EMAIL'
                  ? 'Send Recovery Link'
                  : 'Send 6-Digit Code'}
            </button>

            {/* Email Success info & check inbox message */}
            {method === 'EMAIL' && successInfo && (
              <div
                style={{
                  padding: '12px',
                  backgroundColor: '#EFF6FF',
                  border: '1px solid #BFDBFE',
                  borderRadius: '8px',
                  fontSize: '13px',
                  color: '#1E40AF',
                  marginBottom: '16px',
                  lineHeight: 1.5,
                }}
              >
                {successInfo}
                <div style={{ marginTop: '8px', fontSize: '12px', color: '#4B5563' }}>
                  Didn't receive an email? Check your spam folder or{' '}
                  <button
                    type="button"
                    onClick={handleResend}
                    disabled={cooldown > 0 || isLoading}
                    style={{
                      background: 'none',
                      border: 'none',
                      color: cooldown > 0 ? '#9CA3AF' : '#1E3A8A',
                      cursor: cooldown > 0 ? 'default' : 'pointer',
                      padding: 0,
                      fontWeight: 600,
                      textDecoration: 'underline',
                    }}
                  >
                    {cooldown > 0 ? `resend in ${cooldown}s` : 'click here to resend'}
                  </button>
                  .
                </div>
              </div>
            )}
          </form>

          {onBackToLogin && (
            <div style={{ textAlign: 'center', marginTop: '16px' }}>
              <button
                type="button"
                onClick={onBackToLogin}
                style={{
                  background: 'none',
                  border: 'none',
                  color: '#4B5563',
                  fontSize: '13px',
                  cursor: 'pointer',
                  fontWeight: 500,
                }}
              >
                ← Back to Sign In
              </button>
            </div>
          )}
        </div>
      )}

      {/* STEP 2: Phone OTP Verification */}
      {step === 'VERIFY_OTP' && (
        <div>
          <h2 style={{ fontSize: '18px', fontWeight: 600, color: '#111827', margin: '0 0 8px 0' }}>
            Enter Verification Code
          </h2>
          <p style={{ fontSize: '13px', color: '#6B7280', margin: '0 0 20px 0' }}>
            We sent a 6-digit code to{' '}
            <strong style={{ color: '#111827' }}>{maskedDestination || identifier}</strong>.
          </p>

          <form onSubmit={handleVerifyOtp}>
            <div style={{ marginBottom: '20px' }}>
              <input
                id="otp-input"
                type="text"
                inputMode="numeric"
                maxLength={6}
                value={otpCode}
                onChange={(e) => setOtpCode(e.target.value.replace(/\D/g, ''))}
                placeholder="123456"
                required
                disabled={isLoading}
                style={{
                  width: '100%',
                  padding: '12px',
                  textAlign: 'center',
                  letterSpacing: '8px',
                  fontSize: '24px',
                  fontWeight: 700,
                  borderRadius: '8px',
                  border: '2px solid #D1D5DB',
                  boxSizing: 'border-box',
                  outline: 'none',
                }}
              />
            </div>

            <button
              type="submit"
              disabled={isLoading || otpCode.length !== 6}
              style={{
                width: '100%',
                padding: '12px',
                borderRadius: '8px',
                border: 'none',
                backgroundColor: '#1E3A8A',
                color: '#ffffff',
                fontSize: '14px',
                fontWeight: 600,
                cursor: isLoading || otpCode.length !== 6 ? 'not-allowed' : 'pointer',
                opacity: isLoading || otpCode.length !== 6 ? 0.7 : 1,
                marginBottom: '16px',
              }}
            >
              {isLoading ? 'Verifying...' : 'Verify Code'}
            </button>
          </form>

          {/* Resend OTP */}
          <div style={{ textAlign: 'center', fontSize: '13px', color: '#6B7280' }}>
            Didn't receive the SMS code?{' '}
            <button
              type="button"
              onClick={handleResend}
              disabled={cooldown > 0 || isLoading}
              style={{
                background: 'none',
                border: 'none',
                color: cooldown > 0 ? '#9CA3AF' : '#1E3A8A',
                fontWeight: 600,
                cursor: cooldown > 0 ? 'default' : 'pointer',
                padding: 0,
              }}
            >
              {cooldown > 0 ? `Resend code in ${cooldown}s` : 'Resend Code'}
            </button>
          </div>

          <div style={{ textAlign: 'center', marginTop: '16px' }}>
            <button
              type="button"
              onClick={() => {
                setStep('INPUT');
                setOtpCode('');
                setError(null);
              }}
              style={{
                background: 'none',
                border: 'none',
                color: '#4B5563',
                fontSize: '13px',
                cursor: 'pointer',
              }}
            >
              ← Change phone number
            </button>
          </div>
        </div>
      )}

      {/* STEP 3: Reset Password */}
      {step === 'RESET_PASSWORD' && (
        <div>
          <h2 style={{ fontSize: '18px', fontWeight: 600, color: '#111827', margin: '0 0 8px 0' }}>
            Create New Password
          </h2>
          <p style={{ fontSize: '13px', color: '#6B7280', margin: '0 0 20px 0' }}>
            Choose a strong new password for your account.
          </p>

          <form onSubmit={handleResetSubmit}>
            <div style={{ marginBottom: '16px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px' }}>
                <label
                  htmlFor="new-password"
                  style={{ fontSize: '13px', fontWeight: 500, color: '#374151' }}
                >
                  New Password
                </label>
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  style={{
                    background: 'none',
                    border: 'none',
                    fontSize: '12px',
                    color: '#1E3A8A',
                    cursor: 'pointer',
                    padding: 0,
                  }}
                >
                  {showPassword ? 'Hide' : 'Show'}
                </button>
              </div>
              <input
                id="new-password"
                type={showPassword ? 'text' : 'password'}
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
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

            <div style={{ marginBottom: '16px' }}>
              <label
                htmlFor="confirm-password"
                style={{
                  display: 'block',
                  fontSize: '13px',
                  fontWeight: 500,
                  color: '#374151',
                  marginBottom: '6px',
                }}
              >
                Confirm New Password
              </label>
              <input
                id="confirm-password"
                type={showPassword ? 'text' : 'password'}
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
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

            {/* Password Requirements Checklist */}
            <div
              style={{
                backgroundColor: '#F9FAFB',
                padding: '12px 14px',
                borderRadius: '8px',
                marginBottom: '20px',
                fontSize: '12px',
                color: '#4B5563',
              }}
            >
              <div style={{ fontWeight: 600, marginBottom: '6px', color: '#374151' }}>
                Password Requirements:
              </div>
              <div style={{ color: hasMinLength ? '#059669' : '#6B7280', marginBottom: '2px' }}>
                {hasMinLength ? '✓' : '○'} At least 8 characters
              </div>
              <div style={{ color: hasUppercase ? '#059669' : '#6B7280', marginBottom: '2px' }}>
                {hasUppercase ? '✓' : '○'} Uppercase letter (A-Z)
              </div>
              <div style={{ color: hasLowercase ? '#059669' : '#6B7280', marginBottom: '2px' }}>
                {hasLowercase ? '✓' : '○'} Lowercase letter (a-z)
              </div>
              <div style={{ color: hasNumber ? '#059669' : '#6B7280', marginBottom: '2px' }}>
                {hasNumber ? '✓' : '○'} Number (0-9)
              </div>
              <div style={{ color: hasSpecial ? '#059669' : '#6B7280', marginBottom: '2px' }}>
                {hasSpecial ? '✓' : '○'} Special character (@$!%*?&_-#)
              </div>
              <div style={{ color: passwordsMatch ? '#059669' : '#6B7280' }}>
                {passwordsMatch ? '✓' : '○'} Passwords match
              </div>
            </div>

            <button
              type="submit"
              disabled={isLoading || !isPasswordValid}
              style={{
                width: '100%',
                padding: '12px',
                borderRadius: '8px',
                border: 'none',
                backgroundColor: '#1E3A8A',
                color: '#ffffff',
                fontSize: '14px',
                fontWeight: 600,
                cursor: isLoading || !isPasswordValid ? 'not-allowed' : 'pointer',
                opacity: isLoading || !isPasswordValid ? 0.7 : 1,
              }}
            >
              {isLoading ? 'Updating Password...' : 'Save New Password'}
            </button>
          </form>
        </div>
      )}

      {/* STEP 4: Success View */}
      {step === 'SUCCESS' && (
        <div style={{ textAlign: 'center', padding: '16px 0' }}>
          <div
            style={{
              width: '56px',
              height: '56px',
              backgroundColor: '#D1FAE5',
              borderRadius: '50%',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              margin: '0 auto 16px auto',
              fontSize: '28px',
            }}
          >
            ✓
          </div>
          <h2 style={{ fontSize: '20px', fontWeight: 700, color: '#111827', margin: '0 0 8px 0' }}>
            Password Reset Complete
          </h2>
          <p style={{ fontSize: '14px', color: '#4B5563', margin: '0 0 24px 0', lineHeight: 1.5 }}>
            Your password has been securely updated. You can now log in using your new credentials.
          </p>
          <button
            type="button"
            onClick={() => {
              if (onSuccess) onSuccess();
              else if (onBackToLogin) onBackToLogin();
            }}
            style={{
              width: '100%',
              padding: '12px',
              borderRadius: '8px',
              border: 'none',
              backgroundColor: '#1E3A8A',
              color: '#ffffff',
              fontSize: '14px',
              fontWeight: 600,
              cursor: 'pointer',
            }}
          >
            Sign In with New Password
          </button>
        </div>
      )}
    </div>
  );
};
