// ========================================================
// EFFECTS.JS - Particle Effects & Visual Effects
// ========================================================

class ParticleSystem {
    constructor(canvas) {
        this.canvas = canvas;
        this.ctx = canvas.getContext('2d');
        this.particles = [];
        this.animationFrame = null;
        
        this.resizeCanvas();
        window.addEventListener('resize', () => this.resizeCanvas());
    }
    
    resizeCanvas() {
        this.canvas.width = window.innerWidth;
        this.canvas.height = window.innerHeight;
    }
    
    createParticle(x, y, options = {}) {
        const particle = {
            x,
            y,
            vx: options.vx || Utils.random(-2, 2),
            vy: options.vy || Utils.random(-5, -2),
            life: options.life || 1,
            maxLife: options.maxLife || 1,
            size: options.size || Utils.random(3, 8),
            color: options.color || `hsl(${Utils.random(0, 360)}, 70%, 60%)`,
            shape: options.shape || 'circle',
            rotation: options.rotation || 0,
            rotationSpeed: options.rotationSpeed || Utils.random(-0.2, 0.2),
            gravity: options.gravity !== undefined ? options.gravity : 0.3,
            friction: options.friction || 0.98
        };
        
        this.particles.push(particle);
    }
    
    update() {
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        
        for (let i = this.particles.length - 1; i >= 0; i--) {
            const p = this.particles[i];
            
            // Update physics
            p.vy += p.gravity;
            p.vx *= p.friction;
            p.vy *= p.friction;
            p.x += p.vx;
            p.y += p.vy;
            p.rotation += p.rotationSpeed;
            p.life -= 1 / 60;
            
            // Remove dead particles
            if (p.life <= 0) {
                this.particles.splice(i, 1);
                continue;
            }
            
            // Draw particle
            const alpha = p.life / p.maxLife;
            this.ctx.save();
            this.ctx.globalAlpha = alpha;
            this.ctx.translate(p.x, p.y);
            this.ctx.rotate(p.rotation);
            
            if (p.shape === 'circle') {
                this.ctx.fillStyle = p.color;
                this.ctx.beginPath();
                this.ctx.arc(0, 0, p.size, 0, Math.PI * 2);
                this.ctx.fill();
            } else if (p.shape === 'square') {
                this.ctx.fillStyle = p.color;
                this.ctx.fillRect(-p.size / 2, -p.size / 2, p.size, p.size);
            } else if (p.shape === 'star') {
                this.drawStar(0, 0, 5, p.size, p.size / 2, p.color);
            }
            
            this.ctx.restore();
        }
        
        // Continue animation if particles exist
        if (this.particles.length > 0) {
            this.animationFrame = requestAnimationFrame(() => this.update());
        } else {
            this.animationFrame = null;
        }
    }
    
    drawStar(cx, cy, spikes, outerRadius, innerRadius, color) {
        let rot = Math.PI / 2 * 3;
        let x = cx;
        let y = cy;
        const step = Math.PI / spikes;
        
        this.ctx.beginPath();
        this.ctx.moveTo(cx, cy - outerRadius);
        
        for (let i = 0; i < spikes; i++) {
            x = cx + Math.cos(rot) * outerRadius;
            y = cy + Math.sin(rot) * outerRadius;
            this.ctx.lineTo(x, y);
            rot += step;
            
            x = cx + Math.cos(rot) * innerRadius;
            y = cy + Math.sin(rot) * innerRadius;
            this.ctx.lineTo(x, y);
            rot += step;
        }
        
        this.ctx.lineTo(cx, cy - outerRadius);
        this.ctx.closePath();
        this.ctx.fillStyle = color;
        this.ctx.fill();
    }
    
    start() {
        if (!this.animationFrame) {
            this.update();
        }
    }
    
    clear() {
        this.particles = [];
        if (this.animationFrame) {
            cancelAnimationFrame(this.animationFrame);
            this.animationFrame = null;
        }
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    }
}

const Effects = {
    particleSystem: null,
    
    /**
     * Initialize effects system
     */
    init() {
        const canvas = document.getElementById('particlesCanvas');
        this.particleSystem = new ParticleSystem(canvas);
    },
    
    /**
     * Create block removal particles
     * @param {number} x - Screen X position
     * @param {number} y - Screen Y position
     * @param {string} color - Block color
     */
    createBlockParticles(x, y, color) {
        if (!this.particleSystem) return;
        
        for (let i = 0; i < CONFIG.PARTICLE_COUNT; i++) {
            const angle = (Math.PI * 2 * i) / CONFIG.PARTICLE_COUNT;
            const speed = Utils.random(2, 5);
            
            this.particleSystem.createParticle(x, y, {
                vx: Math.cos(angle) * speed,
                vy: Math.sin(angle) * speed,
                life: Utils.random(0.5, 1),
                maxLife: 1,
                size: Utils.random(4, 8),
                color: color,
                shape: 'circle',
                gravity: 0.2,
                friction: 0.95
            });
        }
        
        this.particleSystem.start();
    },
    
    /**
     * Create confetti explosion
     * @param {number} x - Screen X position
     * @param {number} y - Screen Y position
     */
    createConfetti(x, y) {
        if (!this.particleSystem) return;
        
        const colors = [
            '#ff6b6b', '#4ecdc4', '#45b7d1', '#f9ca24', 
            '#6c5ce7', '#a29bfe', '#fd79a8', '#fdcb6e'
        ];
        
        for (let i = 0; i < CONFIG.CONFETTI_COUNT; i++) {
            const angle = Utils.random(0, Math.PI * 2);
            const speed = Utils.random(5, 15);
            
            this.particleSystem.createParticle(x, y, {
                vx: Math.cos(angle) * speed,
                vy: Math.sin(angle) * speed - Utils.random(5, 10),
                life: Utils.random(1, 2),
                maxLife: 2,
                size: Utils.random(6, 12),
                color: colors[Math.floor(Math.random() * colors.length)],
                shape: Utils.random(0, 1) > 0.5 ? 'square' : 'circle',
                gravity: 0.5,
                friction: 0.98,
                rotationSpeed: Utils.random(-0.3, 0.3)
            });
        }
        
        this.particleSystem.start();
    },
    
    /**
     * Create coin particles flying upward
     * @param {number} x - Screen X position
     * @param {number} y - Screen Y position
     * @param {number} count - Number of coins
     */
    createCoinParticles(x, y, count = 5) {
        if (!this.particleSystem) return;
        
        for (let i = 0; i < count; i++) {
            const offsetX = Utils.random(-30, 30);
            
            this.particleSystem.createParticle(x + offsetX, y, {
                vx: offsetX * 0.1,
                vy: Utils.random(-10, -15),
                life: Utils.random(1, 1.5),
                maxLife: 1.5,
                size: Utils.random(8, 12),
                color: '#ffd700',
                shape: 'circle',
                gravity: 0.4,
                friction: 0.97
            });
        }
        
        this.particleSystem.start();
    },
    
    /**
     * Create sparkle effect
     * @param {number} x - Screen X position
     * @param {number} y - Screen Y position
     */
    createSparkle(x, y) {
        if (!this.particleSystem) return;
        
        for (let i = 0; i < 8; i++) {
            const angle = (Math.PI * 2 * i) / 8;
            const speed = Utils.random(3, 6);
            
            this.particleSystem.createParticle(x, y, {
                vx: Math.cos(angle) * speed,
                vy: Math.sin(angle) * speed,
                life: 0.5,
                maxLife: 0.5,
                size: Utils.random(3, 6),
                color: '#ffffff',
                shape: 'star',
                gravity: 0,
                friction: 0.9
            });
        }
        
        this.particleSystem.start();
    },
    
    /**
     * Clear all particles
     */
    clearParticles() {
        if (this.particleSystem) {
            this.particleSystem.clear();
        }
    }
};

// Freeze Effects to prevent modifications
Object.freeze(Effects);
