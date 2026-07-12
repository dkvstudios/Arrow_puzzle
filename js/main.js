// ========================================================
// MAIN.JS - Game Controller
// ========================================================

class Game {
    constructor() {
        this.currentLevel = Storage.getCurrentLevel();
        this.lives = Storage.getLives();
        this.board = null;
        this.ui = null;
        
        this.init();
    }
    
    /**
     * Initialize game
     */
    init() {
        // Initialize systems
        Sound.init();
        Effects.init();
        
        // Initialize UI
        this.ui = new UI();
        
        // Update UI — no coins
        this.ui.updateLevel(this.currentLevel);
        this.ui.updateLives(this.lives);
        
        // Load current level
        this.loadLevel(this.currentLevel);
        
        // Handle window resize
        window.addEventListener('resize', Utils.debounce(() => {
            if (this.board) {
                this.board.centerBoard();
            }
        }, 250));
        
        // Prevent context menu on long press (mobile)
        document.addEventListener('contextmenu', (e) => {
            if (e.target.closest('.block')) {
                e.preventDefault();
            }
        });
    }
    
    /**
     * Load a level
     * @param {number} levelNumber
     */
    loadLevel(levelNumber) {
        // Destroy existing board
        if (this.board) {
            this.board.destroy();
        }
        
        // Clear particles
        Effects.clearParticles();
        
        // Get level data
        const levelData = LevelManager.getLevel(levelNumber);
        
        if (!levelData) {
            // All levels completed - loop back to level 1
            levelNumber = 1;
            Storage.setCurrentLevel(1);
            this.currentLevel = 1;
            this.ui.updateLevel(1);
            const fallback = LevelManager.getLevel(1);
            this.board = new Board(fallback);
            return;
        }
        
        // Create new board
        this.board = new Board(levelData);
        
        // Update state
        this.currentLevel = levelNumber;
        Storage.setCurrentLevel(levelNumber);
        
        // Update UI
        this.ui.updateLevel(levelNumber);
        
        // Reset lives if needed
        if (this.lives <= 0) {
            this.lives = CONFIG.INITIAL_LIVES;
            Storage.setLives(this.lives);
            this.ui.updateLives(this.lives);
        }
    }
    
    /**
     * Restart current level
     */
    restartLevel() {
        this.loadLevel(this.currentLevel);
    }
    
    /**
     * Load next level
     */
    nextLevel() {
        this.loadLevel(this.currentLevel + 1);
    }
    
    /**
     * Level complete handler — no coin reward
     */
    levelComplete() {
        Storage.completeLevel(this.currentLevel);

        Sound.playVictory();
        Utils.vibrate([100, 50, 100, 50, 100]);

        // Show immediately — board.js already waited for the last block to fly off
        this.ui.showVictoryPopup();
    }
    
    /**
     * Lose a life
     */
    loseLife() {
        if (this.lives <= 0) return;

        const previousLives = this.lives;
        this.lives = Storage.removeLife();

        // Animate heart loss
        this.ui.animateHeartLoss(previousLives - 1);
        Sound.playHeartLoss();

        // Show game over right after the heart animation (500ms)
        if (this.lives <= 0) {
            setTimeout(() => this.handleGameOver(), 500);
        }
    }
    
    /**
     * Handle game over — show instant popup
     */
    handleGameOver() {
        this.ui.showGameOverPopup();
    }

    /**
     * Retry same level after game over (lives restored)
     */
    retryAfterGameOver() {
        this.lives = CONFIG.INITIAL_LIVES;
        Storage.setLives(this.lives);
        this.ui.updateLives(this.lives);
        this.restartLevel();
    }

    /**
     * Go back to level 1 after game over (lives restored)
     */
    restartFromGameOver() {
        this.lives = CONFIG.INITIAL_LIVES;
        Storage.setLives(this.lives);
        this.ui.updateLives(this.lives);
        this.loadLevel(1);
    }
}

// ========================================================
// INITIALIZE GAME
// ========================================================

// Wait for DOM to be ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initGame);
} else {
    initGame();
}

function initGame() {
    // Create game instance
    window.game = new Game();
    
    // Add to window for debugging
    if (typeof window !== 'undefined') {
        window.CONFIG = CONFIG;
        window.Utils = Utils;
        window.Storage = Storage;
        window.Sound = Sound;
        window.Effects = Effects;
        window.Animation = Animation;
        window.LevelManager = LevelManager;
    }
    
    console.log('%c🎮 Arrow Puzzle Game Loaded! 🎮', 'color: #5b9bd5; font-size: 20px; font-weight: bold;');
    console.log('%cCurrent Level:', 'color: #6ec97d; font-weight: bold;', window.game.currentLevel);
    console.log('%cLives:', 'color: #ff6b6b; font-weight: bold;', window.game.lives);
}

// ========================================================
// SERVICE WORKER (Optional - for PWA)
// ========================================================

if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
        // Uncomment to enable service worker for offline play
        // navigator.serviceWorker.register('/sw.js')
        //     .then(registration => console.log('SW registered:', registration))
        //     .catch(error => console.log('SW registration failed:', error));
    });
}
