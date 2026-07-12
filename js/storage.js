// ========================================================
// STORAGE.JS - LocalStorage Management
// ========================================================

const Storage = {
    /**
     * Get current level
     * @returns {number}
     */
    getCurrentLevel() {
        const level = localStorage.getItem(CONFIG.STORAGE_KEYS.CURRENT_LEVEL);
        return level ? parseInt(level) : 1;
    },
    
    /**
     * Set current level
     * @param {number} level
     */
    setCurrentLevel(level) {
        localStorage.setItem(CONFIG.STORAGE_KEYS.CURRENT_LEVEL, level.toString());
    },
    
    /**
     * Get coins
     * @returns {number}
     */
    getCoins() {
        const coins = localStorage.getItem(CONFIG.STORAGE_KEYS.COINS);
        return coins ? parseInt(coins) : CONFIG.INITIAL_COINS;
    },
    
    /**
     * Set coins
     * @param {number} coins
     */
    setCoins(coins) {
        localStorage.setItem(CONFIG.STORAGE_KEYS.COINS, coins.toString());
    },
    
    /**
     * Add coins
     * @param {number} amount
     */
    addCoins(amount) {
        const current = this.getCoins();
        this.setCoins(current + amount);
    },
    
    /**
     * Remove coins
     * @param {number} amount
     * @returns {boolean} Success
     */
    removeCoins(amount) {
        const current = this.getCoins();
        if (current >= amount) {
            this.setCoins(current - amount);
            return true;
        }
        return false;
    },
    
    /**
     * Get lives
     * @returns {number}
     */
    getLives() {
        const lives = localStorage.getItem(CONFIG.STORAGE_KEYS.LIVES);
        return lives ? parseInt(lives) : CONFIG.INITIAL_LIVES;
    },
    
    /**
     * Set lives
     * @param {number} lives
     */
    setLives(lives) {
        localStorage.setItem(CONFIG.STORAGE_KEYS.LIVES, Math.max(0, lives).toString());
    },
    
    /**
     * Remove a life
     * @returns {number} Remaining lives
     */
    removeLife() {
        const current = this.getLives();
        const newLives = Math.max(0, current - 1);
        this.setLives(newLives);
        return newLives;
    },
    
    /**
     * Add a life
     * @returns {number} New lives count
     */
    addLife() {
        const current = this.getLives();
        const newLives = Math.min(CONFIG.INITIAL_LIVES, current + 1);
        this.setLives(newLives);
        return newLives;
    },
    
    /**
     * Get completed levels
     * @returns {Array<number>}
     */
    getCompletedLevels() {
        const levels = localStorage.getItem(CONFIG.STORAGE_KEYS.COMPLETED_LEVELS);
        return levels ? JSON.parse(levels) : [];
    },
    
    /**
     * Mark level as completed
     * @param {number} level
     */
    completeLevel(level) {
        const completed = this.getCompletedLevels();
        if (!completed.includes(level)) {
            completed.push(level);
            localStorage.setItem(CONFIG.STORAGE_KEYS.COMPLETED_LEVELS, JSON.stringify(completed));
        }
    },
    
    /**
     * Check if level is completed
     * @param {number} level
     * @returns {boolean}
     */
    isLevelCompleted(level) {
        return this.getCompletedLevels().includes(level);
    },
    
    /**
     * Get settings
     * @returns {Object}
     */
    getSettings() {
        const settings = localStorage.getItem(CONFIG.STORAGE_KEYS.SETTINGS);
        return settings ? JSON.parse(settings) : {
            soundEnabled: CONFIG.SOUND_ENABLED,
            musicEnabled: CONFIG.MUSIC_ENABLED,
            vibrationEnabled: CONFIG.VIBRATION_ENABLED
        };
    },
    
    /**
     * Set settings
     * @param {Object} settings
     */
    setSettings(settings) {
        localStorage.setItem(CONFIG.STORAGE_KEYS.SETTINGS, JSON.stringify(settings));
    },
    
    /**
     * Update a single setting
     * @param {string} key
     * @param {any} value
     */
    updateSetting(key, value) {
        const settings = this.getSettings();
        settings[key] = value;
        this.setSettings(settings);
    },
    
    /**
     * Get high score
     * @returns {number}
     */
    getHighScore() {
        const score = localStorage.getItem(CONFIG.STORAGE_KEYS.HIGH_SCORE);
        return score ? parseInt(score) : 0;
    },
    
    /**
     * Set high score
     * @param {number} score
     */
    setHighScore(score) {
        const current = this.getHighScore();
        if (score > current) {
            localStorage.setItem(CONFIG.STORAGE_KEYS.HIGH_SCORE, score.toString());
        }
    },
    
    /**
     * Reset all progress
     */
    resetProgress() {
        localStorage.removeItem(CONFIG.STORAGE_KEYS.CURRENT_LEVEL);
        localStorage.removeItem(CONFIG.STORAGE_KEYS.COINS);
        localStorage.removeItem(CONFIG.STORAGE_KEYS.LIVES);
        localStorage.removeItem(CONFIG.STORAGE_KEYS.COMPLETED_LEVELS);
        localStorage.removeItem(CONFIG.STORAGE_KEYS.HIGH_SCORE);
    },
    
    /**
     * Clear all storage
     */
    clearAll() {
        Object.values(CONFIG.STORAGE_KEYS).forEach(key => {
            localStorage.removeItem(key);
        });
    }
};

// Freeze Storage to prevent modifications
Object.freeze(Storage);
