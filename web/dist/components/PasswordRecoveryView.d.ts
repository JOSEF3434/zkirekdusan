import React from 'react';
export interface PasswordRecoveryViewProps {
    onSuccess?: () => void;
    onBackToLogin?: () => void;
    brandTitle?: string;
    brandSubtitle?: string;
    initialToken?: string;
    allowPasswordReset?: boolean;
}
export declare const PasswordRecoveryView: React.FC<PasswordRecoveryViewProps>;
//# sourceMappingURL=PasswordRecoveryView.d.ts.map