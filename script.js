let CONFIG = window.CodeDetectorConfig || {};

function ensureConfig() {
    if (CONFIG.apiUrl && CONFIG.apiKey) return true;
    showNotification("Configuration missing! Please check config.js.", "error");
    return false;
}

async function detectCode() {
    const code = document.getElementById("codeInput").value.trim();
    const btn = document.getElementById("detectBtn");
    const resultContainer = document.getElementById("resultContainer");
    const label = document.getElementById("label");
    const confidence = document.getElementById("confidence");
    const confidenceBar = document.getElementById("confidenceBar");
    const raw = document.getElementById("raw");

    if (!code) {
        showNotification("Please enter some code to analyze!", "warning");
        return;
    }

    if (!ensureConfig()) {
        return;
    }

    setLoadingState(true);
    resultContainer.style.display = "none";

    try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 30000); // 30 second timeout

        const response = await fetch(CONFIG.apiUrl, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "x-api-key": CONFIG.apiKey
            },
            body: JSON.stringify({ 
                code: code,
                timestamp: new Date().toISOString(),
                userAgent: navigator.userAgent
            }),
            signal: controller.signal
        });

        clearTimeout(timeoutId);

        if (!response.ok) {
            const errorText = await response.text();
            throw new Error(errorText || `HTTP Error ${response.status}: ${response.statusText}`);
        }

        
        let data;
        try {
            data = await response.json();
        } catch (jsonError) {
            const rawResponse = await response.text();
            throw new Error(`Invalid JSON response: ${rawResponse.substring(0, 200)}...`);
        }
        
        if (!data || !data.result) {
            throw new Error("Invalid response format from server");
        }

        displayResults(data.result);
        showNotification("Analysis completed successfully!", "success");

    } catch (error) {
        console.error("Detection error:", error);

        let errorMessage = "An unexpected error occurred";
        
        if (error.name === 'AbortError') {
            errorMessage = "Request timeout - please try again";
        } else if (error.message.includes('fetch')) {
            errorMessage = "Network error - please check your connection";
        } else {
            errorMessage = error.message;
        }
        displayError(errorMessage);
        showNotification(`Error: ${errorMessage}`, "error");
        
    } finally {
        setLoadingState(false);
    }
}

function displayResults(result) {
    const label = document.getElementById("label");
    const confidence = document.getElementById("confidence");
    const confidenceBar = document.getElementById("confidenceBar");
    const raw = document.getElementById("raw");
    const resultContainer = document.getElementById("resultContainer");

    const labelText = result.label || "Unknown";
    const labelIcon = getLabelIcon(labelText);
    label.innerHTML = `${labelIcon} ${labelText}`;

    const confidenceValue = Math.max(0, Math.min(100, result.confidence ?? 0));
    confidence.textContent = `${confidenceValue}%`;

    setTimeout(() => {
        confidenceBar.style.width = `${confidenceValue}%`;
    }, 100);

    const rawOutput = result.raw || "No additional data available";
    raw.textContent = typeof rawOutput === 'object' ? 
        JSON.stringify(rawOutput, null, 2) : rawOutput;

    resultContainer.style.display = "block";
    resultContainer.scrollIntoView({ 
        behavior: 'smooth', 
        block: 'start',
        inline: 'nearest'
    });
}

function displayError(errorMessage) {
    const label = document.getElementById("label");
    const confidence = document.getElementById("confidence");
    const confidenceBar = document.getElementById("confidenceBar");
    const raw = document.getElementById("raw");
    const resultContainer = document.getElementById("resultContainer");

    label.innerHTML = "Error";
    confidence.textContent = "0%";
    confidenceBar.style.width = "0%";
    raw.textContent = `Error Details:\n${errorMessage}\n\nTimestamp: ${new Date().toLocaleString()}`;
    
    resultContainer.style.display = "block";
}

function getLabelIcon(label) {
    const icons = {
        'safe': '✅',
        'suspicious': '⚠️',
        'malicious': '🚨',
        'unknown': '❓',
        'clean': '✅',
        'infected': '🦠',
        'error': '❌'
    };
    
    return icons[label.toLowerCase()] || '🔍';
}

function setLoadingState(loading) {
    const btn = document.getElementById("detectBtn");
    
    if (loading) {
        btn.disabled = true;
        btn.innerHTML = '<span class="loading-spinner"></span>Analyzing...';
    } else {
        btn.disabled = false;
        btn.innerHTML = "🔍 Analyze Code";
    }
}

function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.textContent = message;
    
    Object.assign(notification.style, {
        position: 'fixed',
        top: '100px',
        right: '20px',
        padding: '12px 20px',
        borderRadius: '8px',
        color: 'white',
        fontWeight: '500',
        zIndex: '9999',
        transform: 'translateX(100%)',
        transition: 'transform 0.3s ease',
        maxWidth: '300px',
        wordWrap: 'break-word'
    });

    const colors = {
        success: '#10b981',
        error: '#ef4444',
        warning: '#f59e0b',
        info: '#3b82f6'
    };
    notification.style.backgroundColor = colors[type] || colors.info;

    document.body.appendChild(notification);

    setTimeout(() => {
        notification.style.transform = 'translateX(0)';
    }, 100);
    
    setTimeout(() => {
        notification.style.transform = 'translateX(100%)';
        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
            }
        }, 300);
    }, 5000);
}

function initializeApp() {
    const textarea = document.getElementById("codeInput");
    const detectBtn = document.getElementById("detectBtn");

    textarea.addEventListener("keydown", function(event) {
        if (event.ctrlKey && event.key === "Enter") {
            event.preventDefault();
            detectCode();
        }
    });

    textarea.addEventListener("input", function() {
        this.style.height = "auto";
        this.style.height = Math.max(300, this.scrollHeight) + "px";
    });

    textarea.addEventListener("focus", function() {
        this.parentElement.style.transform = "scale(1.01)";
    });

    textarea.addEventListener("blur", function() {
        this.parentElement.style.transform = "scale(1)";
    });

    detectBtn.addEventListener("click", function() {
        if (!this.disabled) {
            this.style.transform = "scale(0.98)";
            setTimeout(() => {
                this.style.transform = "";
            }, 150);
        }
    });

    if (!ensureConfig()) {
        showNotification("Warning: Environment variables not configured properly!", "warning");
    }

    console.log("🚀 CopyGuard Code Detector initialized successfully!");
}

function copyResults() {
    const label = document.getElementById("label").textContent;
    const confidence = document.getElementById("confidence").textContent;
    const raw = document.getElementById("raw").textContent;
    
    const results = `CopyGuard Analysis Results:
Label: ${label}
Confidence: ${confidence}
Raw Output: ${raw}
Generated: ${new Date().toLocaleString()}`;

    navigator.clipboard.writeText(results).then(() => {
        showNotification("Results copied to clipboard!", "success");
    }).catch(() => {
        showNotification("Failed to copy results", "error");
    });
}

document.addEventListener('DOMContentLoaded', initializeApp);

document.addEventListener('visibilitychange', function() {
    if (document.hidden) {
        console.log('Page hidden - pausing operations');
    } else {
        console.log('Page visible - resuming operations');
    }
});

window.addEventListener('error', function(event) {
    console.error('Global error:', event.error);
    showNotification("An unexpected error occurred", "error");
});

window.addEventListener('unhandledrejection', function(event) {
    console.error('Unhandled promise rejection:', event.reason);
    showNotification("An unexpected error occurred", "error");
});