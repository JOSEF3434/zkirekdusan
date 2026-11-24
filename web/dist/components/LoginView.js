import { jsx as _jsx, jsxs as _jsxs, Fragment as _Fragment } from "react/jsx-runtime";
// web/src/components/LoginView.tsx
import { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext.js';
import { authApi } from '../services/authApi.js';
import { GoogleSignInButton } from './GoogleSignInButton.js';
import { AccountLinkModal } from './AccountLinkModal.js';
export const LoginView = ({ onSuccess, onForgotPassword, brandTitle = 'Zikre Kedusan', brandSubtitle = 'Sign in to access your spiritual sanctuary', allowGoogleAuth, }) => {
    const { loginWithPassword, isLoading, isGoogleLoading, isAnyLoading, error, clearError, isAuthenticated } = useAuth();
    const [identifier, setIdentifier] = useState('');
    const [password, setPassword] = useState('');
    const [rememberMe, setRememberMe] = useState(true);
    const [effectiveAllowGoogle, setEffectiveAllowGoogle] = useState(allowGoogleAuth ?? true);
    useEffect(() => {
        if (allowGoogleAuth !== undefined) {
            setEffectiveAllowGoogle(allowGoogleAuth);
            return;
        }
        let isMounted = true;
        authApi.getLoginPolicyConfig().then((cfg) => {
            if (isMounted && cfg && typeof cfg.allowGoogleAuth === 'boolean') {
                setEffectiveAllowGoogle(cfg.allowGoogleAuth);
            }
        });
        return () => {
            isMounted = false;
        };
    }, [allowGoogleAuth]);
    if (isAuthenticated && onSuccess) {
        onSuccess();
    }
    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!identifier || !password)
            return;
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
    return (_jsxs("div", { style: {
            maxWidth: '420px',
            margin: '40px auto',
            padding: '32px 28px',
            backgroundColor: '#ffffff',
            borderRadius: '16px',
            boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03)',
            border: '1px solid #E5E7EB',
            fontFamily: 'Inter, system-ui, -apple-system, sans-serif',
        }, children: [_jsxs("div", { style: { textAlign: 'center', marginBottom: '28px' }, children: [_jsx("h1", { style: { margin: '0 0 8px 0', fontSize: '24px', fontWeight: 700, color: '#1E3A8A' }, children: brandTitle }), _jsx("p", { style: { margin: 0, fontSize: '14px', color: '#6B7280' }, children: brandSubtitle })] }), error && (_jsxs("div", { style: {
                    padding: '12px 14px',
                    backgroundColor: '#FEE2E2',
                    color: '#B91C1C',
                    borderRadius: '8px',
                    fontSize: '13px',
                    marginBottom: '20px',
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                }, children: [_jsx("span", { children: error }), _jsx("button", { onClick: clearError, style: { background: 'none', border: 'none', cursor: 'pointer', color: '#B91C1C', fontWeight: 'bold' }, children: "\u2715" })] })), effectiveAllowGoogle && (_jsxs(_Fragment, { children: [_jsx("div", { style: { marginBottom: '20px' }, children: _jsx(GoogleSignInButton, { text: "continue_with", size: "large", width: "100%" }) }), _jsxs("div", { style: {
                            display: 'flex',
                            alignItems: 'center',
                            margin: '20px 0',
                            color: '#9CA3AF',
                            fontSize: '12px',
                            textTransform: 'uppercase',
                            letterSpacing: '0.05em',
                        }, children: [_jsx("div", { style: { flex: 1, height: '1px', backgroundColor: '#E5E7EB' } }), _jsx("span", { style: { padding: '0 12px' }, children: "or continue with credentials" }), _jsx("div", { style: { flex: 1, height: '1px', backgroundColor: '#E5E7EB' } })] })] })), _jsxs("form", { onSubmit: handleSubmit, children: [_jsxs("div", { style: { marginBottom: '16px' }, children: [_jsx("label", { htmlFor: "login-identifier", style: { display: 'block', fontSize: '13px', fontWeight: 500, color: '#374151', marginBottom: '6px' }, children: "Email or Username" }), _jsx("input", { id: "login-identifier", type: "text", value: identifier, onChange: (e) => setIdentifier(e.target.value), placeholder: "you@example.com or username", required: true, disabled: isLoading, style: {
                                    width: '100%',
                                    padding: '10px 14px',
                                    borderRadius: '8px',
                                    border: '1px solid #D1D5DB',
                                    fontSize: '14px',
                                    boxSizing: 'border-box',
                                    outline: 'none',
                                } })] }), _jsxs("div", { style: { marginBottom: '16px' }, children: [_jsxs("div", { style: { display: 'flex', justifyContent: 'space-between', marginBottom: '6px' }, children: [_jsx("label", { htmlFor: "login-password", style: { fontSize: '13px', fontWeight: 500, color: '#374151' }, children: "Password" }), _jsx("a", { href: "#forgot-password", onClick: (e) => {
                                            if (onForgotPassword) {
                                                e.preventDefault();
                                                onForgotPassword();
                                            }
                                        }, style: { fontSize: '12px', color: '#1E3A8A', textDecoration: 'none', fontWeight: 500, cursor: 'pointer' }, children: "Forgot password?" })] }), _jsx("input", { id: "login-password", type: "password", value: password, onChange: (e) => setPassword(e.target.value), placeholder: "\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022", required: true, disabled: isLoading, style: {
                                    width: '100%',
                                    padding: '10px 14px',
                                    borderRadius: '8px',
                                    border: '1px solid #D1D5DB',
                                    fontSize: '14px',
                                    boxSizing: 'border-box',
                                    outline: 'none',
                                } })] }), _jsxs("div", { style: { display: 'flex', alignItems: 'center', marginBottom: '20px' }, children: [_jsx("input", { id: "remember-me", type: "checkbox", checked: rememberMe, onChange: (e) => setRememberMe(e.target.checked), style: { marginRight: '8px', cursor: 'pointer' } }), _jsx("label", { htmlFor: "remember-me", style: { fontSize: '13px', color: '#4B5563', cursor: 'pointer' }, children: "Remember this device" })] }), _jsx("button", { type: "submit", disabled: isAnyLoading || !identifier || !password, style: {
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
                        }, children: isLoading ? 'Signing In...' : 'Sign In' })] }), _jsx(AccountLinkModal, {})] }));
};
//# sourceMappingURL=LoginView.js.map