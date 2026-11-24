// web/src/config/auth.config.ts
function getEnvVar(key, defaultValue = '') {
    // 1. Check window.__ENV__ (injected runtime config)
    if (typeof window !== 'undefined' && window.__ENV__ && window.__ENV__[key]) {
        return window.__ENV__[key];
    }
    // 2. Check process.env (Webpack / Next.js / Create React App)
    if (typeof process !== 'undefined' && process.env) {
        if (process.env[`REACT_APP_${key}`])
            return process.env[`REACT_APP_${key}`];
        if (process.env[`NEXT_PUBLIC_${key}`])
            return process.env[`NEXT_PUBLIC_${key}`];
        if (process.env[key])
            return process.env[key];
    }
    // 3. Check import.meta.env (Vite)
    try {
        // @ts-ignore
        if (typeof import.meta !== 'undefined' && import.meta.env) {
            // @ts-ignore
            const val = import.meta.env[`VITE_${key}`] || import.meta.env[key];
            if (val)
                return val;
        }
    }
    catch {
        // Ignore environments where import.meta is unavailable
    }
    return defaultValue;
}
export const authConfig = {
    apiUrl: getEnvVar('API_URL', 'https://zikrekidusan.onrender.com/api'),
    googleClientId: getEnvVar('GOOGLE_CLIENT_ID', '632083728397-q7bp82rggdpbnl2kqoei443rak4lh1k0.apps.googleusercontent.com'),
    tokenStorageKey: 'zk_access_token',
    refreshTokenStorageKey: 'zk_refresh_token',
    userStorageKey: 'zk_user_summary',
};
//# sourceMappingURL=auth.config.js.map