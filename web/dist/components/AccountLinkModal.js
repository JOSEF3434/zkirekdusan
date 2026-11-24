import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
// web/src/components/AccountLinkModal.tsx
import { useState } from 'react';
import { useAuth } from '../context/AuthContext.js';
export const AccountLinkModal = ({ isOpen, onClose }) => {
    const { pendingGoogleIdToken, linkGoogleAccountWithPassword, cancelLinking, isLoading } = useAuth();
    const [password, setPassword] = useState('');
    const [localError, setLocalError] = useState(null);
    const show = isOpen ?? Boolean(pendingGoogleIdToken);
    if (!show)
        return null;
    const handleClose = () => {
        cancelLinking();
        if (onClose)
            onClose();
    };
    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!password) {
            setLocalError('Please enter your password.');
            return;
        }
        setLocalError(null);
        const success = await linkGoogleAccountWithPassword(password);
        if (success && onClose) {
            onClose();
        }
    };
    return (_jsx("div", { style: {
            position: 'fixed',
            inset: 0,
            backgroundColor: 'rgba(0, 0, 0, 0.55)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '16px',
            zIndex: 9999,
            backdropFilter: 'blur(3px)',
        }, role: "dialog", "aria-modal": "true", "aria-labelledby": "account-link-title", children: _jsxs("div", { style: {
                backgroundColor: '#ffffff',
                borderRadius: '16px',
                padding: '28px',
                maxWidth: '440px',
                width: '100%',
                boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)',
                fontFamily: 'Inter, system-ui, -apple-system, sans-serif',
            }, children: [_jsxs("div", { style: { display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '16px' }, children: [_jsx("div", { style: {
                                width: '42px',
                                height: '42px',
                                borderRadius: '50%',
                                backgroundColor: '#FEF3C7',
                                color: '#D97706',
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                fontSize: '20px',
                            }, children: "\uD83D\uDD17" }), _jsx("h2", { id: "account-link-title", style: { margin: 0, fontSize: '18px', fontWeight: 600, color: '#111827' }, children: "Link Google Account" })] }), _jsx("p", { style: { fontSize: '14px', color: '#4B5563', lineHeight: '1.5', margin: '0 0 20px 0' }, children: "An account with this email address already exists in Zikre Kedusan. To prevent unauthorized access, please verify your account password to link your Google login." }), localError && (_jsx("div", { style: {
                        padding: '10px 14px',
                        backgroundColor: '#FEE2E2',
                        color: '#991B1B',
                        borderRadius: '8px',
                        fontSize: '13px',
                        marginBottom: '16px',
                    }, children: localError })), _jsxs("form", { onSubmit: handleSubmit, children: [_jsxs("div", { style: { marginBottom: '20px' }, children: [_jsx("label", { htmlFor: "link-password-input", style: { display: 'block', fontSize: '13px', fontWeight: 500, color: '#374151', marginBottom: '6px' }, children: "Account Password" }), _jsx("input", { id: "link-password-input", type: "password", value: password, onChange: (e) => setPassword(e.target.value), placeholder: "Enter your existing password", disabled: isLoading, style: {
                                        width: '100%',
                                        padding: '10px 14px',
                                        borderRadius: '8px',
                                        border: '1px solid #D1D5DB',
                                        fontSize: '14px',
                                        boxSizing: 'border-box',
                                        outline: 'none',
                                    }, autoFocus: true })] }), _jsxs("div", { style: { display: 'flex', justifyContent: 'flex-end', gap: '10px' }, children: [_jsx("button", { type: "button", onClick: handleClose, disabled: isLoading, style: {
                                        padding: '10px 16px',
                                        borderRadius: '8px',
                                        border: '1px solid #D1D5DB',
                                        backgroundColor: '#ffffff',
                                        color: '#374151',
                                        fontSize: '14px',
                                        fontWeight: 500,
                                        cursor: isLoading ? 'not-allowed' : 'pointer',
                                    }, children: "Cancel" }), _jsx("button", { type: "submit", disabled: isLoading || !password, style: {
                                        padding: '10px 18px',
                                        borderRadius: '8px',
                                        border: 'none',
                                        backgroundColor: '#1E3A8A', // Zikre Kedusan Primary Brand
                                        color: '#ffffff',
                                        fontSize: '14px',
                                        fontWeight: 500,
                                        cursor: isLoading || !password ? 'not-allowed' : 'pointer',
                                        opacity: isLoading || !password ? 0.6 : 1,
                                    }, children: isLoading ? 'Verifying & Linking...' : 'Confirm & Link' })] })] })] }) }));
};
//# sourceMappingURL=AccountLinkModal.js.map