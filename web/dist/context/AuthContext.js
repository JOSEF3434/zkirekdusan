import { jsx as _jsx } from "react/jsx-runtime";
// web/src/context/AuthContext.tsx
import { createContext, useContext, useEffect, useState, useCallback } from 'react';
import { authApi, AuthApiError } from '../services/authApi.js';
const AuthContext = createContext(undefined);
export const AuthProvider = ({ children }) => {
    const [state, setState] = useState({
        user: null,
        tokens: null,
        isAuthenticated: false,
        isLoading: true,
        isGoogleLoading: false,
        error: null,
        pendingGoogleIdToken: null,
    });
    // Restore session from localStorage on initial render
    useEffect(() => {
        const initAuth = async () => {
            const accessToken = authApi.getAccessToken();
            const savedUser = authApi.getSavedUser();
            if (!accessToken) {
                setState((prev) => ({ ...prev, isLoading: false, isAuthenticated: false }));
                return;
            }
            try {
                const currentUser = await authApi.getMe();
                setState({
                    user: currentUser,
                    tokens: {
                        accessToken,
                        refreshToken: authApi.getRefreshToken() || '',
                        tokenType: 'bearer',
                        expiresIn: 3600,
                    },
                    isAuthenticated: true,
                    isLoading: false,
                    error: null,
                    pendingGoogleIdToken: null,
                });
            }
            catch (err) {
                // Attempt refresh
                try {
                    const newTokens = await authApi.refreshTokens();
                    const currentUser = await authApi.getMe();
                    setState({
                        user: currentUser,
                        tokens: newTokens,
                        isAuthenticated: true,
                        isLoading: false,
                        error: null,
                        pendingGoogleIdToken: null,
                    });
                }
                catch {
                    authApi.clearStorage();
                    setState({
                        user: null,
                        tokens: null,
                        isAuthenticated: false,
                        isLoading: false,
                        error: null,
                        pendingGoogleIdToken: null,
                    });
                }
            }
        };
        initAuth();
    }, []);
    const clearError = useCallback(() => {
        setState((prev) => ({ ...prev, error: null }));
    }, []);
    const cancelLinking = useCallback(() => {
        setState((prev) => ({ ...prev, pendingGoogleIdToken: null, error: null }));
    }, []);
    const signInWithGoogle = useCallback(async (idToken) => {
        setState((prev) => ({
            ...prev,
            isGoogleLoading: true,
            isLoading: false,
            error: null,
            pendingGoogleIdToken: null,
        }));
        try {
            const res = await authApi.loginWithGoogle({ idToken });
            setState({
                user: res.user,
                tokens: res,
                isAuthenticated: true,
                isLoading: false,
                isGoogleLoading: false,
                error: null,
                pendingGoogleIdToken: null,
            });
            return true;
        }
        catch (err) {
            if (err instanceof AuthApiError && (err.statusCode === 409 || err.code === 'ACCOUNT_EXISTS_LINK_REQUIRED')) {
                setState((prev) => ({
                    ...prev,
                    isLoading: false,
                    isGoogleLoading: false,
                    pendingGoogleIdToken: idToken,
                    error: 'An account with this email already exists. Please verify your password to link your Google account.',
                }));
                return false;
            }
            const message = err instanceof Error ? err.message : 'Google authentication failed';
            setState((prev) => ({
                ...prev,
                isLoading: false,
                isGoogleLoading: false,
                isAuthenticated: false,
                error: message,
            }));
            return false;
        }
    }, []);
    const linkGoogleAccountWithPassword = useCallback(async (password) => {
        if (!state.pendingGoogleIdToken) {
            setState((prev) => ({
                ...prev,
                error: 'Google session expired. Please sign in with Google again.',
            }));
            return false;
        }
        setState((prev) => ({ ...prev, isLoading: true, isGoogleLoading: false, error: null }));
        try {
            const res = await authApi.linkGoogleAccount({
                idToken: state.pendingGoogleIdToken,
                password,
            });
            setState({
                user: res.user,
                tokens: res,
                isAuthenticated: true,
                isLoading: false,
                isGoogleLoading: false,
                error: null,
                pendingGoogleIdToken: null,
            });
            return true;
        }
        catch (err) {
            const message = err instanceof Error ? err.message : 'Failed to link account with password';
            setState((prev) => ({
                ...prev,
                isLoading: false,
                isGoogleLoading: false,
                error: message,
            }));
            return false;
        }
    }, [state.pendingGoogleIdToken]);
    const loginWithPassword = useCallback(async (credentials) => {
        setState((prev) => ({ ...prev, isLoading: true, isGoogleLoading: false, error: null }));
        try {
            const res = await authApi.loginWithPassword(credentials);
            setState({
                user: res.user,
                tokens: res,
                isAuthenticated: true,
                isLoading: false,
                isGoogleLoading: false,
                error: null,
                pendingGoogleIdToken: null,
            });
            return true;
        }
        catch (err) {
            const message = err instanceof Error ? err.message : 'Invalid login credentials';
            setState((prev) => ({
                ...prev,
                isLoading: false,
                isGoogleLoading: false,
                isAuthenticated: false,
                error: message,
            }));
            return false;
        }
    }, []);
    const logout = useCallback(async () => {
        setState((prev) => ({ ...prev, isLoading: true }));
        try {
            await authApi.logout();
        }
        finally {
            setState({
                user: null,
                tokens: null,
                isAuthenticated: false,
                isLoading: false,
                error: null,
                pendingGoogleIdToken: null,
            });
        }
    }, []);
    const connectGoogle = useCallback(async (idToken) => {
        setState((prev) => ({ ...prev, isLoading: true, error: null }));
        try {
            await authApi.connectGoogle({ idToken });
            setState((prev) => ({ ...prev, isLoading: false }));
            return true;
        }
        catch (err) {
            const message = err instanceof Error ? err.message : 'Failed to connect Google account';
            setState((prev) => ({ ...prev, isLoading: false, error: message }));
            return false;
        }
    }, []);
    const disconnectGoogle = useCallback(async () => {
        setState((prev) => ({ ...prev, isLoading: true, error: null }));
        try {
            await authApi.disconnectGoogle();
            setState((prev) => ({ ...prev, isLoading: false }));
            return true;
        }
        catch (err) {
            const message = err instanceof Error ? err.message : 'Failed to disconnect Google account';
            setState((prev) => ({ ...prev, isLoading: false, error: message }));
            return false;
        }
    }, []);
    const getIdentities = useCallback(async () => {
        try {
            return await authApi.getIdentities();
        }
        catch (err) {
            const message = err instanceof Error ? err.message : 'Failed to fetch identities';
            setState((prev) => ({ ...prev, error: message }));
            return null;
        }
    }, []);
    return (_jsx(AuthContext.Provider, { value: {
            ...state,
            isGoogleLoading: state.isGoogleLoading ?? false,
            isAnyLoading: state.isLoading || (state.isGoogleLoading ?? false),
            signInWithGoogle,
            linkGoogleAccountWithPassword,
            loginWithPassword,
            logout,
            connectGoogle,
            disconnectGoogle,
            getIdentities,
            cancelLinking,
            clearError,
        }, children: children }));
};
export const useAuth = () => {
    const context = useContext(AuthContext);
    if (!context) {
        throw new Error('useAuth must be used within an AuthProvider');
    }
    return context;
};
//# sourceMappingURL=AuthContext.js.map