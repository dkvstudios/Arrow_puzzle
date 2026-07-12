// ========================================================
// CONFIG.JS - Game Configuration
// ========================================================

const CONFIG = {
    // Game Settings
    INITIAL_LIVES: 3,
    
    // Block Settings
    BLOCK_SIZE: 80,
    BLOCK_GAP: 8,
    
    // Animation Durations (ms)
    BLOCK_MOVE_DURATION: 380,     // fly-off animation
    BLOCK_REMOVE_DURATION: 380,   // same
    SHAKE_DURATION: 400,
    POPUP_DURATION: 300,
    
    // Zoom Settings
    MIN_ZOOM: 0.6,
    MAX_ZOOM: 1.4,
    ZOOM_STEP: 0.1,
    
    // Particle Settings
    PARTICLE_COUNT: 30,
    CONFETTI_COUNT: 60,
    PARTICLE_LIFETIME: 1500,
    
    // Sound Settings
    SOUND_ENABLED: true,
    VIBRATION_ENABLED: true,
    
    // Directions
    DIRECTIONS: {
        UP: 'up',
        DOWN: 'down',
        LEFT: 'left',
        RIGHT: 'right'
    },
    
    // Colors - Using HSL for better variety
    COLORS: [
        'hsl(10, 80%, 60%)',   // Red-Orange
        'hsl(45, 85%, 55%)',   // Orange
        'hsl(60, 80%, 60%)',   // Yellow
        'hsl(120, 60%, 55%)',  // Green
        'hsl(180, 70%, 50%)',  // Cyan
        'hsl(210, 75%, 55%)',  // Blue
        'hsl(270, 70%, 60%)',  // Purple
        'hsl(330, 75%, 60%)',  // Pink
        'hsl(0, 0%, 50%)',     // Gray
        'hsl(30, 70%, 50%)'    // Brown
    ],
    
    // Storage Keys
    STORAGE_KEYS: {
        CURRENT_LEVEL: 'arrowPuzzle_currentLevel',
        COINS: 'arrowPuzzle_coins',
        LIVES: 'arrowPuzzle_lives',
        COMPLETED_LEVELS: 'arrowPuzzle_completedLevels',
        SETTINGS: 'arrowPuzzle_settings'
    }
};

// Freeze config to prevent modifications
Object.freeze(CONFIG);
Object.freeze(CONFIG.DIRECTIONS);
Object.freeze(CONFIG.COLORS);
Object.freeze(CONFIG.STORAGE_KEYS);
