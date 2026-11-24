import React from 'react';
import type { AuthState, UserIdentities } from '../types/auth.types.js';
export interface AuthContextType extends AuthState {
    isGoogleLoading: boolean;
    isAnyLoading: boolean;
    signInWithGoogle: (idToken: string) => Promise<boolean>;
    linkGoogleAccountWithPassword: (password: string) => Promise<boolean>;
    loginWithPassword: (credentials: {
        email?: string;
        phoneNumber?: string;
        username?: string;
        password: string;
    }) => Promise<boolean>;
    logout: () => Promise<void>;
    connectGoogle: (idToken: string) => Promise<boolean>;
    disconnectGoogle: () => Promise<boolean>;
    getIdentities: () => Promise<UserIdentities | null>;
    cancelLinking: () => void;
    clearError: () => void;
}
export declare const AuthProvider: React.FC<{
    children: React.ReactNode;
}>;
export declare const useAuth: () => AuthContextType;
//# sourceMappingURL=AuthContext.d.ts.map