const CONFIG = {
    DETECTOR_URL: getEnvVar('DETECTOR_URL', 'https://ey3x589rgd.execute-api.us-east-1.amazonaws.com/detect'), // API endpoint
    DETECTOR_KEY: getEnvVar('DETECTOR_KEY', 'super-secret-api-key-1234567890'),

    APP_NAME: 'CopyGuard',
    APP_VERSION: '1.0.0',
    
    REQUEST_TIMEOUT: 30000, 
    MAX_CODE_LENGTH: 100000, 
    
    NOTIFICATION_DURATION: 5000, 
    ANIMATION_DURATION: 300, 
    
    DEBUG_MODE: getEnvVar('DEBUG_MODE', 'false') === 'true',
    
    ANALYTICS_ID: getEnvVar('ANALYTICS_ID', ''),
    
    RATE_LIMIT_REQUESTS: 10,
    RATE_LIMIT_WINDOW: 60000, 
};


function getEnvVar(name, defaultValue = '') {
    
    if (typeof process !== 'undefined' && process.env) {
        return process.env[name] || defaultValue;
    }
    
    if (typeof window !== 'undefined' && window.env) {
        return window.env[name] || defaultValue;
    }

    if (typeof localStorage !== 'undefined') {
        const stored = localStorage.getItem(`COPYGUARD_${name}`);
        if (stored) return stored;
    }
    
    const devConfig = {
        'DETECTOR_URL': 'https://ey3x589rgd.execute-api.us-east-1.amazonaws.com/detect',  // API endpoiny
        'DETECTOR_KEY': 'super-secret-api-key-1234567890',
        'DEBUG_MODE': 'true'
    };
    
    return devConfig[name] || defaultValue;
}

function validateConfig() {
    const errors = [];
    
    if (!CONFIG.DETECTOR_URL) {
        errors.push('DETECTOR_URL is required');
    }
    
    if (!CONFIG.DETECTOR_KEY) {
        errors.push('DETECTOR_KEY is required');
    }
    
    if (!isValidUrl(CONFIG.DETECTOR_URL)) {
        errors.push('DETECTOR_URL must be a valid URL');
    }
    
    if (errors.length > 0) {
        console.error('Configuration errors:', errors);
        if (CONFIG.DEBUG_MODE) {
            alert('Configuration errors found. Check console for details.');
        }
    }
    
    return errors.length === 0;
}

function isValidUrl(string) {
    try {
        new URL(string);
        return true;
    } catch (_) {
        return false;
    }
}

function logConfig() {
    if (CONFIG.DEBUG_MODE) {
        console.group('🔧 CopyGuard Configuration');
        console.log('App Name:', CONFIG.APP_NAME);
        console.log('Version:', CONFIG.APP_VERSION);
        console.log('API URL:', CONFIG.DETECTOR_URL);
        console.log('API Key:', CONFIG.DETECTOR_KEY ? '***hidden***' : 'NOT SET');
        console.log('Debug Mode:', CONFIG.DEBUG_MODE);
        console.log('Request Timeout:', CONFIG.REQUEST_TIMEOUT + 'ms');
        console.log('Max Code Length:', CONFIG.MAX_CODE_LENGTH + ' chars');
        console.groupEnd();
    }
}

validateConfig();
logConfig();

if (typeof module !== 'undefined' && module.exports) {
    module.exports = CONFIG;
}