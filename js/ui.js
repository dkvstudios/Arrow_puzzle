// ========================================================
// UI.JS - User Interface Management
// ========================================================

class UI {
    constructor() {
        this.elements = {
            levelNumber: document.getElementById('levelNumber'),
            livesPanel: document.getElementById('livesPanel'),
            hearts: document.querySelectorAll('.heart'),

            // Buttons
            backBtn: null,
            settingsBtn: document.getElementById('settingsBtn'),
            zoomInBtn: document.getElementById('zoomInBtn'),
            zoomOutBtn: document.getElementById('zoomOutBtn'),

            // Popups
            victoryPopup: document.getElementById('victoryPopup'),
            settingsPopup: document.getElementById('settingsPopup'),

            // Game Over popup elements
            gameOverPopup: document.getElementById('gameOverPopup'),
            retryBtn: document.getElementById('retryBtn'),
            restartBtn: document.getElementById('restartBtn'),

            // Settings popup elements
            closeSettingsBtn: document.getElementById('closeSettingsBtn'),
            soundToggle: document.getElementById('soundToggle'),
            musicToggle: document.getElementById('musicToggle'),
            vibrationToggle: document.getElementById('vibrationToggle')
        };
        
        this.initializeEventListeners();
        this.loadSettings();
    }
    
    /**
     * Initialize all event listeners
     */
    initializeEventListeners() {
        // Top bar buttons
        this.elements.settingsBtn.addEventListener('click', () => this.handleSettingsClick());
        
        // Zoom buttons
        this.elements.zoomInBtn.addEventListener('click', () => this.handleZoomIn());
        this.elements.zoomOutBtn.addEventListener('click', () => this.handleZoomOut());

        // Game Over popup buttons
        this.elements.retryBtn.addEventListener('click', () => this.handleRetry());
        this.elements.restartBtn.addEventListener('click', () => this.handleRestart());
        
        // Settings popup
        this.elements.closeSettingsBtn.addEventListener('click', () => this.hideSettingsPopup());
        this.elements.soundToggle.addEventListener('change', (e) => this.handleSoundToggle(e));
        this.elements.musicToggle.addEventListener('change', (e) => this.handleMusicToggle(e));
        this.elements.vibrationToggle.addEventListener('change', (e) => this.handleVibrationToggle(e));
        
        // Close popups on background click
        this.elements.victoryPopup.addEventListener('click', (e) => {
            if (e.target === this.elements.victoryPopup) {
                this.hideVictoryPopup();
            }
        });
        
        this.elements.settingsPopup.addEventListener('click', (e) => {
            if (e.target === this.elements.settingsPopup) {
                this.hideSettingsPopup();
            }
        });
        // Mouse wheel zoom
        document.addEventListener('wheel', (e) => {
            if (e.ctrlKey) {
                e.preventDefault();
                if (e.deltaY < 0) {
                    this.handleZoomIn();
                } else {
                    this.handleZoomOut();
                }
            }
        }, { passive: false });
        
        // Touch gestures for zoom (pinch)
        this.initializeTouchZoom();
    }
    
    /**
     * Initialize touch zoom gestures
     */
    initializeTouchZoom() {
        let initialDistance = 0;
        let currentZoom = 1;
        
        const boardContainer = document.getElementById('boardContainer');
        
        boardContainer.addEventListener('touchstart', (e) => {
            if (e.touches.length === 2) {
                const touch1 = e.touches[0];
                const touch2 = e.touches[1];
                initialDistance = Math.hypot(
                    touch2.clientX - touch1.clientX,
                    touch2.clientY - touch1.clientY
                );
                if (window.game && window.game.board) {
                    currentZoom = window.game.board.zoom;
                }
            }
        });
        
        boardContainer.addEventListener('touchmove', (e) => {
            if (e.touches.length === 2) {
                e.preventDefault();
                const touch1 = e.touches[0];
                const touch2 = e.touches[1];
                const currentDistance = Math.hypot(
                    touch2.clientX - touch1.clientX,
                    touch2.clientY - touch1.clientY
                );
                
                const scale = currentDistance / initialDistance;
                const newZoom = currentZoom * scale;
                
                if (window.game && window.game.board) {
                    window.game.board.setZoom(newZoom);
                }
            }
        }, { passive: false });
    }
    
    /**
     * Load settings from storage
     */
    loadSettings() {
        const settings = Storage.getSettings();
        this.elements.soundToggle.checked = settings.soundEnabled;
        this.elements.musicToggle.checked = settings.musicEnabled;
        this.elements.vibrationToggle.checked = settings.vibrationEnabled;
    }
    
    /**
     * Update level display
     */
    updateLevel(level) {
        this.elements.levelNumber.textContent = level;
    }

    /**
     * Update lives display
     */
    updateLives(lives) {
        this.elements.hearts.forEach((heart, index) => {
            if (index < lives) {
                heart.classList.remove('empty');
                heart.classList.remove('lost');
            } else {
                heart.classList.add('empty');
            }
        });
    }

    /**
     * Animate heart loss
     */
    animateHeartLoss(heartIndex) {
        const heart = this.elements.hearts[heartIndex];
        if (heart) {
            heart.classList.add('lost');
            setTimeout(() => heart.classList.add('empty'), 500);
        }
    }

    /**
     * Show victory popup then auto-advance to next level after 1 second
     */
    showVictoryPopup() {
        this.elements.victoryPopup.classList.add('active');
        Sound.playLevelComplete();

        const rect = this.elements.victoryPopup.getBoundingClientRect();
        Effects.createConfetti(rect.left + rect.width / 2, rect.top + rect.height / 2);

        const stars = this.elements.victoryPopup.querySelectorAll('.star');
        stars.forEach((star, i) => setTimeout(() => Animation.pulse(star), i * 80));

        this._nextLevelTimer = setTimeout(() => {
            this.hideVictoryPopup();
            if (window.game) window.game.nextLevel();
        }, 1000);
    }

    hideVictoryPopup() {
        clearTimeout(this._nextLevelTimer);
        this.elements.victoryPopup.classList.remove('active');
    }

    showSettingsPopup() {
        this.elements.settingsPopup.classList.add('active');
        Sound.playButton();
    }

    hideSettingsPopup() {
        this.elements.settingsPopup.classList.remove('active');
        Sound.playButton();
    }

    handleSettingsClick() {
        this.showSettingsPopup();
    }

    handleZoomIn() {
        if (window.game && window.game.board) window.game.board.zoomIn();
    }

    handleZoomOut() {
        if (window.game && window.game.board) window.game.board.zoomOut();
    }

    handleSoundToggle(e) {
        Storage.updateSetting('soundEnabled', e.target.checked);
        Sound.playButton();
    }

    handleMusicToggle(e) {
        Storage.updateSetting('musicEnabled', e.target.checked);
        Sound.playButton();
    }

    handleVibrationToggle(e) {
        Storage.updateSetting('vibrationEnabled', e.target.checked);
        CONFIG.VIBRATION_ENABLED = e.target.checked;
        Sound.playButton();
    }

    showGameOverPopup() {
        this.elements.gameOverPopup.classList.add('active');
        Sound.playWrong();
        Utils.vibrate([100, 50, 100, 50, 200]);
    }

    hideGameOverPopup() {
        this.elements.gameOverPopup.classList.remove('active');
    }

    handleRetry() {
        Sound.playButton();
        this.hideGameOverPopup();
        if (window.game) window.game.retryAfterGameOver();
    }

    handleRestart() {
        Sound.playButton();
        this.hideGameOverPopup();
        if (window.game) window.game.restartFromGameOver();
    }
}
