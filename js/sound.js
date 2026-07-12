// ========================================================
// SOUND.JS - Sound Effects Management
// ========================================================

const Sound = {
    // Audio context for generating sounds
    audioContext: null,
    
    /**
     * Initialize audio context
     */
    init() {
        if (!this.audioContext) {
            try {
                this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
            } catch (e) {
                console.warn('Web Audio API not supported');
            }
        }
    },
    
    /**
     * Play a tone
     * @param {number} frequency - Hz
     * @param {number} duration - seconds
     * @param {number} volume - 0 to 1
     * @param {string} type - 'sine', 'square', 'sawtooth', 'triangle'
     */
    playTone(frequency, duration, volume = 0.3, type = 'sine') {
        if (!Storage.getSettings().soundEnabled) return;
        
        this.init();
        if (!this.audioContext) return;
        
        const oscillator = this.audioContext.createOscillator();
        const gainNode = this.audioContext.createGain();
        
        oscillator.connect(gainNode);
        gainNode.connect(this.audioContext.destination);
        
        oscillator.frequency.value = frequency;
        oscillator.type = type;
        
        gainNode.gain.setValueAtTime(volume, this.audioContext.currentTime);
        gainNode.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + duration);
        
        oscillator.start(this.audioContext.currentTime);
        oscillator.stop(this.audioContext.currentTime + duration);
    },
    
    /**
     * Play tap sound
     */
    playTap() {
        this.playTone(400, 0.1, 0.2, 'sine');
    },
    
    /**
     * Play wrong/blocked sound
     */
    playWrong() {
        this.playTone(200, 0.2, 0.3, 'square');
        setTimeout(() => this.playTone(150, 0.2, 0.3, 'square'), 100);
    },
    
    /**
     * Play pop/success sound
     */
    playPop() {
        this.playTone(600, 0.1, 0.25, 'sine');
        setTimeout(() => this.playTone(800, 0.1, 0.2, 'sine'), 50);
    },
    
    /**
     * Play coin sound
     */
    playCoin() {
        this.playTone(800, 0.1, 0.2, 'square');
        setTimeout(() => this.playTone(1000, 0.1, 0.2, 'square'), 50);
        setTimeout(() => this.playTone(1200, 0.15, 0.15, 'square'), 100);
    },
    
    /**
     * Play victory sound
     */
    playVictory() {
        const notes = [523, 587, 659, 784, 880];
        notes.forEach((note, i) => {
            setTimeout(() => this.playTone(note, 0.3, 0.2, 'sine'), i * 100);
        });
    },
    
    /**
     * Play button click sound
     */
    playButton() {
        this.playTone(500, 0.08, 0.15, 'sine');
    },
    
    /**
     * Play heart loss sound
     */
    playHeartLoss() {
        this.playTone(300, 0.15, 0.25, 'sawtooth');
        setTimeout(() => this.playTone(250, 0.15, 0.25, 'sawtooth'), 80);
        setTimeout(() => this.playTone(200, 0.2, 0.25, 'sawtooth'), 160);
    },
    
    /**
     * Play level complete fanfare
     */
    playLevelComplete() {
        const melody = [
            { freq: 523, time: 0 },
            { freq: 659, time: 150 },
            { freq: 784, time: 300 },
            { freq: 1047, time: 450 }
        ];
        
        melody.forEach(note => {
            setTimeout(() => this.playTone(note.freq, 0.3, 0.2, 'sine'), note.time);
        });
    }
};

// Freeze Sound to prevent modifications
Object.freeze(Sound);
