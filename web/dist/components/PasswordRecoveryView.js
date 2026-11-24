import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
// web/src/components/PasswordRecoveryView.tsx
import { useState, useEffect, useRef } from 'react';
import { authApi } from '../services/authApi.js';
export const PasswordRecoveryView = ({ onSuccess, onBackToLogin, brandTitle = 'Zikre Kedusan', brandSubtitle = 'Spiritual Sanctuary Account Recovery', initialToken, }) => {
    const [method, setMethod] = useState('EMAIL');
    const [step, setStep] = useState('INPUT');
    const [identifier, setIdentifier] = useState('');
    const [otpCode, setOtpCode] = useState('');
    const [resetToken, setResetToken] = useState(initialToken || '');
    const [newPassword, setNewPassword] = useState('');
    const [confirmPassword, setConfirmPassword] = useState('');
    const [showPassword, setShowPassword] = useState(false);
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState(null);
    const [successInfo, setSuccessInfo] = useState(null);
    const [maskedDestination, setMaskedDestination] = useState(null);
    const [cooldown, setCooldown] = useState(0);
    const timerRef = useRef(null);
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
                    if (res.email)
                        setMaskedDestination(res.email);
                }
                else {
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
            if (timerRef.current)
                clearTimeout(timerRef.current);
        };
    }, [cooldown]);
    // Validation rules
    const hasMinLength = newPassword.length >= 8;
    const hasUppercase = /[A-Z]/.test(newPassword);
    const hasLowercase = /[a-z]/.test(newPassword);
    const hasNumber = /[0-9]/.test(newPassword);
    const hasSpecial = /[@$!%*?&_\-#]/.test(newPassword);
    const passwordsMatch = newPassword.length > 0 && newPassword === confirmPassword;
    const isPasswordValid = hasMinLength && hasUppercase && hasLowercase && hasNumber && hasSpecial && passwordsMatch;
    // Step 1: Request Recovery
    const handleRequestSubmit = async (e) => {
        e.preventDefault();
        if (!identifier.trim())
            return;
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
        }
        catch (err) {
            setError(err?.message || 'Unable to request password recovery. Please try again.');
        }
        finally {
            setIsLoading(false);
        }
    };
    // Step 2: Verify Phone OTP
    const handleVerifyOtp = async (e) => {
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
        }
        catch (err) {
            setError(err?.message || 'Invalid or expired verification code.');
        }
        finally {
            setIsLoading(false);
        }
    };
    // Resend code or email
    const handleResend = async () => {
        if (cooldown > 0 || isLoading)
            return;
        setError(null);
        setIsLoading(true);
        try {
            const res = await authApi.resendRecoveryCode({
                method,
                identifier: identifier.trim(),
            });
            setSuccessInfo(res.message);
            setCooldown(res.resendCooldownSeconds || 60);
        }
        catch (err) {
            setError(err?.message || 'Failed to resend recovery code.');
        }
        finally {
            setIsLoading(false);
        }
    };
    // Step 3: Complete Password Reset
    const handleResetSubmit = async (e) => {
        e.preventDefault();
        if (!isPasswordValid)
            return;
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
        }
        catch (err) {
            setError(err?.message || 'Failed to reset password. Please request a new recovery link.');
        }
        finally {
            setIsLoading(false);
        }
    };
    return (_jsxs("div", { style: {
            maxWidth: '440px',
            margin: '40px auto',
            padding: '32px 28px',
            backgroundColor: '#ffffff',
            borderRadius: '16px',
            boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03)',
            border: '1px solid #E5E7EB',
            fontFamily: 'Inter, system-ui, -apple-system, sans-serif',
        }, children: [_jsxs("div", { style: { textAlign: 'center', marginBottom: '24px' }, children: [_jsx("h1", { style: { margin: '0 0 6px 0', fontSize: '22px', fontWeight: 700, color: '#1E3A8A' }, children: brandTitle }), _jsx("p", { style: { margin: 0, fontSize: '13px', color: '#6B7280' }, children: brandSubtitle })] }), error && (_jsxs("div", { style: {
                    padding: '12px 14px',
                    backgroundColor: '#FEE2E2',
                    color: '#B91C1C',
                    borderRadius: '8px',
                    fontSize: '13px',
                    marginBottom: '20px',
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                }, children: [_jsx("span", { children: error }), _jsx("button", { onClick: () => setError(null), style: {
                            background: 'none',
                            border: 'none',
                            cursor: 'pointer',
                            color: '#B91C1C',
                            fontWeight: 'bold',
                        }, children: "\u2715" })] })), step === 'INPUT' && (_jsxs("div", { children: [_jsx("h2", { style: { fontSize: '18px', fontWeight: 600, color: '#111827', margin: '0 0 8px 0' }, children: "Account Recovery" }), _jsx("p", { style: { fontSize: '13px', color: '#6B7280', margin: '0 0 20px 0' }, children: "Select how you would like to recover your password." }), _jsxs("div", { style: {
                            display: 'flex',
                            backgroundColor: '#F3F4F6',
                            borderRadius: '8px',
                            padding: '4px',
                            marginBottom: '20px',
                        }, children: [_jsx("button", { type: "button", onClick: () => {
                                    setMethod('EMAIL');
                                    setIdentifier('');
                                    setError(null);
                                }, style: {
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
                                }, children: "\u2709\uFE0F Email Address" }), _jsx("button", { type: "button", onClick: () => {
                                    setMethod('PHONE');
                                    setIdentifier('');
                                    setError(null);
                                }, style: {
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
                                }, children: "\uD83D\uDCF1 Phone (SMS OTP)" })] }), _jsxs("form", { onSubmit: handleRequestSubmit, children: [_jsxs("div", { style: { marginBottom: '20px' }, children: [_jsx("label", { htmlFor: "recovery-identifier", style: {
                                            display: 'block',
                                            fontSize: '13px',
                                            fontWeight: 500,
                                            color: '#374151',
                                            marginBottom: '6px',
                                        }, children: method === 'EMAIL' ? 'Registered Email Address' : 'Ethiopian Phone Number' }), _jsx("input", { id: "recovery-identifier", type: method === 'EMAIL' ? 'email' : 'tel', value: identifier, onChange: (e) => setIdentifier(e.target.value), placeholder: method === 'EMAIL' ? 'you@example.com' : '+251911223344 or 0911223344', required: true, disabled: isLoading, style: {
                                            width: '100%',
                                            padding: '10px 14px',
                                            borderRadius: '8px',
                                            border: '1px solid #D1D5DB',
                                            fontSize: '14px',
                                            boxSizing: 'border-box',
                                            outline: 'none',
                                        } }), method === 'PHONE' && (_jsx("div", { style: { fontSize: '11px', color: '#6B7280', marginTop: '6px' }, children: "Supports Ethio Telecom (+2519...) and Safaricom Ethiopia (+2517...)" }))] }), _jsx("button", { type: "submit", disabled: isLoading || !identifier.trim(), style: {
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
                                }, children: isLoading
                                    ? 'Processing...'
                                    : method === 'EMAIL'
                                        ? 'Send Recovery Link'
                                        : 'Send 6-Digit Code' }), method === 'EMAIL' && successInfo && (_jsxs("div", { style: {
                                    padding: '12px',
                                    backgroundColor: '#EFF6FF',
                                    border: '1px solid #BFDBFE',
                                    borderRadius: '8px',
                                    fontSize: '13px',
                                    color: '#1E40AF',
                                    marginBottom: '16px',
                                    lineHeight: 1.5,
                                }, children: [successInfo, _jsxs("div", { style: { marginTop: '8px', fontSize: '12px', color: '#4B5563' }, children: ["Didn't receive an email? Check your spam folder or", ' ', _jsx("button", { type: "button", onClick: handleResend, disabled: cooldown > 0 || isLoading, style: {
                                                    background: 'none',
                                                    border: 'none',
                                                    color: cooldown > 0 ? '#9CA3AF' : '#1E3A8A',
                                                    cursor: cooldown > 0 ? 'default' : 'pointer',
                                                    padding: 0,
                                                    fontWeight: 600,
                                                    textDecoration: 'underline',
                                                }, children: cooldown > 0 ? `resend in ${cooldown}s` : 'click here to resend' }), "."] })] }))] }), onBackToLogin && (_jsx("div", { style: { textAlign: 'center', marginTop: '16px' }, children: _jsx("button", { type: "button", onClick: onBackToLogin, style: {
                                background: 'none',
                                border: 'none',
                                color: '#4B5563',
                                fontSize: '13px',
                                cursor: 'pointer',
                                fontWeight: 500,
                            }, children: "\u2190 Back to Sign In" }) }))] })), step === 'VERIFY_OTP' && (_jsxs("div", { children: [_jsx("h2", { style: { fontSize: '18px', fontWeight: 600, color: '#111827', margin: '0 0 8px 0' }, children: "Enter Verification Code" }), _jsxs("p", { style: { fontSize: '13px', color: '#6B7280', margin: '0 0 20px 0' }, children: ["We sent a 6-digit code to", ' ', _jsx("strong", { style: { color: '#111827' }, children: maskedDestination || identifier }), "."] }), _jsxs("form", { onSubmit: handleVerifyOtp, children: [_jsx("div", { style: { marginBottom: '20px' }, children: _jsx("input", { id: "otp-input", type: "text", inputMode: "numeric", maxLength: 6, value: otpCode, onChange: (e) => setOtpCode(e.target.value.replace(/\D/g, '')), placeholder: "123456", required: true, disabled: isLoading, style: {
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
                                    } }) }), _jsx("button", { type: "submit", disabled: isLoading || otpCode.length !== 6, style: {
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
                                }, children: isLoading ? 'Verifying...' : 'Verify Code' })] }), _jsxs("div", { style: { textAlign: 'center', fontSize: '13px', color: '#6B7280' }, children: ["Didn't receive the SMS code?", ' ', _jsx("button", { type: "button", onClick: handleResend, disabled: cooldown > 0 || isLoading, style: {
                                    background: 'none',
                                    border: 'none',
                                    color: cooldown > 0 ? '#9CA3AF' : '#1E3A8A',
                                    fontWeight: 600,
                                    cursor: cooldown > 0 ? 'default' : 'pointer',
                                    padding: 0,
                                }, children: cooldown > 0 ? `Resend code in ${cooldown}s` : 'Resend Code' })] }), _jsx("div", { style: { textAlign: 'center', marginTop: '16px' }, children: _jsx("button", { type: "button", onClick: () => {
                                setStep('INPUT');
                                setOtpCode('');
                                setError(null);
                            }, style: {
                                background: 'none',
                                border: 'none',
                                color: '#4B5563',
                                fontSize: '13px',
                                cursor: 'pointer',
                            }, children: "\u2190 Change phone number" }) })] })), step === 'RESET_PASSWORD' && (_jsxs("div", { children: [_jsx("h2", { style: { fontSize: '18px', fontWeight: 600, color: '#111827', margin: '0 0 8px 0' }, children: "Create New Password" }), _jsx("p", { style: { fontSize: '13px', color: '#6B7280', margin: '0 0 20px 0' }, children: "Choose a strong new password for your account." }), _jsxs("form", { onSubmit: handleResetSubmit, children: [_jsxs("div", { style: { marginBottom: '16px' }, children: [_jsxs("div", { style: { display: 'flex', justifyContent: 'space-between', marginBottom: '6px' }, children: [_jsx("label", { htmlFor: "new-password", style: { fontSize: '13px', fontWeight: 500, color: '#374151' }, children: "New Password" }), _jsx("button", { type: "button", onClick: () => setShowPassword(!showPassword), style: {
                                                    background: 'none',
                                                    border: 'none',
                                                    fontSize: '12px',
                                                    color: '#1E3A8A',
                                                    cursor: 'pointer',
                                                    padding: 0,
                                                }, children: showPassword ? 'Hide' : 'Show' })] }), _jsx("input", { id: "new-password", type: showPassword ? 'text' : 'password', value: newPassword, onChange: (e) => setNewPassword(e.target.value), placeholder: "\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022", required: true, disabled: isLoading, style: {
                                            width: '100%',
                                            padding: '10px 14px',
                                            borderRadius: '8px',
                                            border: '1px solid #D1D5DB',
                                            fontSize: '14px',
                                            boxSizing: 'border-box',
                                            outline: 'none',
                                        } })] }), _jsxs("div", { style: { marginBottom: '16px' }, children: [_jsx("label", { htmlFor: "confirm-password", style: {
                                            display: 'block',
                                            fontSize: '13px',
                                            fontWeight: 500,
                                            color: '#374151',
                                            marginBottom: '6px',
                                        }, children: "Confirm New Password" }), _jsx("input", { id: "confirm-password", type: showPassword ? 'text' : 'password', value: confirmPassword, onChange: (e) => setConfirmPassword(e.target.value), placeholder: "\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022", required: true, disabled: isLoading, style: {
                                            width: '100%',
                                            padding: '10px 14px',
                                            borderRadius: '8px',
                                            border: '1px solid #D1D5DB',
                                            fontSize: '14px',
                                            boxSizing: 'border-box',
                                            outline: 'none',
                                        } })] }), _jsxs("div", { style: {
                                    backgroundColor: '#F9FAFB',
                                    padding: '12px 14px',
                                    borderRadius: '8px',
                                    marginBottom: '20px',
                                    fontSize: '12px',
                                    color: '#4B5563',
                                }, children: [_jsx("div", { style: { fontWeight: 600, marginBottom: '6px', color: '#374151' }, children: "Password Requirements:" }), _jsxs("div", { style: { color: hasMinLength ? '#059669' : '#6B7280', marginBottom: '2px' }, children: [hasMinLength ? '✓' : '○', " At least 8 characters"] }), _jsxs("div", { style: { color: hasUppercase ? '#059669' : '#6B7280', marginBottom: '2px' }, children: [hasUppercase ? '✓' : '○', " Uppercase letter (A-Z)"] }), _jsxs("div", { style: { color: hasLowercase ? '#059669' : '#6B7280', marginBottom: '2px' }, children: [hasLowercase ? '✓' : '○', " Lowercase letter (a-z)"] }), _jsxs("div", { style: { color: hasNumber ? '#059669' : '#6B7280', marginBottom: '2px' }, children: [hasNumber ? '✓' : '○', " Number (0-9)"] }), _jsxs("div", { style: { color: hasSpecial ? '#059669' : '#6B7280', marginBottom: '2px' }, children: [hasSpecial ? '✓' : '○', " Special character (@$!%*?&_-#)"] }), _jsxs("div", { style: { color: passwordsMatch ? '#059669' : '#6B7280' }, children: [passwordsMatch ? '✓' : '○', " Passwords match"] })] }), _jsx("button", { type: "submit", disabled: isLoading || !isPasswordValid, style: {
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
                                }, children: isLoading ? 'Updating Password...' : 'Save New Password' })] })] })), step === 'SUCCESS' && (_jsxs("div", { style: { textAlign: 'center', padding: '16px 0' }, children: [_jsx("div", { style: {
                            width: '56px',
                            height: '56px',
                            backgroundColor: '#D1FAE5',
                            borderRadius: '50%',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            margin: '0 auto 16px auto',
                            fontSize: '28px',
                        }, children: "\u2713" }), _jsx("h2", { style: { fontSize: '20px', fontWeight: 700, color: '#111827', margin: '0 0 8px 0' }, children: "Password Reset Complete" }), _jsx("p", { style: { fontSize: '14px', color: '#4B5563', margin: '0 0 24px 0', lineHeight: 1.5 }, children: "Your password has been securely updated. You can now log in using your new credentials." }), _jsx("button", { type: "button", onClick: () => {
                            if (onSuccess)
                                onSuccess();
                            else if (onBackToLogin)
                                onBackToLogin();
                        }, style: {
                            width: '100%',
                            padding: '12px',
                            borderRadius: '8px',
                            border: 'none',
                            backgroundColor: '#1E3A8A',
                            color: '#ffffff',
                            fontSize: '14px',
                            fontWeight: 600,
                            cursor: 'pointer',
                        }, children: "Sign In with New Password" })] }))] }));
};
//# sourceMappingURL=PasswordRecoveryView.js.map