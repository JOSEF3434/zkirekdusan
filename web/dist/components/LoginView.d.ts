import React from 'react';
export interface LoginViewProps {
    onSuccess?: () => void;
    onForgotPassword?: () => void;
    brandTitle?: string;
    brandSubtitle?: string;
    allowGoogleAuth?: boolean;
    allowPasswordReset?: boolean;
}
export declare const LoginView: React.FC<LoginViewProps>;
//# sourceMappingURL=LoginView.d.ts.map