import React from 'react';
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
    isLoading?: boolean;
    className?: string;
}
declare global {
    interface Window {
        google?: {
            accounts: {
                id: {
                    initialize: (config: {
                        client_id: string;
                        callback: (response: {
                            credential: string;
                        }) => void;
                        auto_select?: boolean;
                        cancel_on_tap_outside?: boolean;
                    }) => void;
                    renderButton: (element: HTMLElement, options: {
                        theme?: string;
                        size?: string;
                        text?: string;
                        shape?: string;
                        width?: number | string;
                        logo_alignment?: 'left' | 'center';
                    }) => void;
                    prompt?: () => void;
                };
            };
        };
    }
}
export declare const GoogleSignInButton: React.FC<GoogleSignInButtonProps>;
//# sourceMappingURL=GoogleSignInButton.d.ts.map