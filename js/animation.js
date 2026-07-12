// ========================================================
// ANIMATION.JS - Animation Utilities
// ========================================================

const Animation = {
    /**
     * Animate a number value
     * @param {Object} options
     * @param {number} options.from - Start value
     * @param {number} options.to - End value
     * @param {number} options.duration - Duration in ms
     * @param {Function} options.onUpdate - Callback with current value
     * @param {Function} options.onComplete - Callback when complete
     * @param {Function} options.easing - Easing function
     */
    animate(options) {
        const {
            from,
            to,
            duration,
            onUpdate,
            onComplete,
            easing = Utils.easeOutCubic
        } = options;
        
        const startTime = performance.now();
        
        const step = (currentTime) => {
            const elapsed = currentTime - startTime;
            const progress = Math.min(elapsed / duration, 1);
            const easedProgress = easing(progress);
            const currentValue = from + (to - from) * easedProgress;
            
            if (onUpdate) onUpdate(currentValue);
            
            if (progress < 1) {
                requestAnimationFrame(step);
            } else {
                if (onComplete) onComplete();
            }
        };
        
        requestAnimationFrame(step);
    },
    
    /**
     * Animate element to position
     * @param {HTMLElement} element
     * @param {Object} options
     */
    animateToPosition(element, options) {
        const {
            x,
            y,
            duration = 500,
            onComplete,
            easing = Utils.easeInOutCubic
        } = options;
        
        const startX = parseFloat(element.style.left) || 0;
        const startY = parseFloat(element.style.top) || 0;
        const startTime = performance.now();
        
        const step = (currentTime) => {
            const elapsed = currentTime - startTime;
            const progress = Math.min(elapsed / duration, 1);
            const easedProgress = easing(progress);
            
            const currentX = startX + (x - startX) * easedProgress;
            const currentY = startY + (y - startY) * easedProgress;
            
            element.style.left = `${currentX}px`;
            element.style.top = `${currentY}px`;
            
            if (progress < 1) {
                requestAnimationFrame(step);
            } else {
                if (onComplete) onComplete();
            }
        };
        
        requestAnimationFrame(step);
    },
    
    /**
     * Shake element
     * @param {HTMLElement} element
     * @param {number} intensity
     * @param {number} duration
     */
    shake(element, intensity = 5, duration = 400) {
        element.classList.add('shake');
        
        setTimeout(() => {
            element.classList.remove('shake');
        }, duration);
    },
    
    /**
     * Bounce element
     * @param {HTMLElement} element
     */
    bounce(element) {
        element.style.animation = 'none';
        setTimeout(() => {
            element.style.animation = '';
        }, 10);
    },
    
    /**
     * Pulse element
     * @param {HTMLElement} element
     * @param {number} scale
     * @param {number} duration
     */
    pulse(element, scale = 1.2, duration = 300) {
        const originalTransform = element.style.transform;
        
        this.animate({
            from: 1,
            to: scale,
            duration: duration / 2,
            onUpdate: (value) => {
                element.style.transform = `scale(${value})`;
            },
            onComplete: () => {
                this.animate({
                    from: scale,
                    to: 1,
                    duration: duration / 2,
                    onUpdate: (value) => {
                        element.style.transform = `scale(${value})`;
                    },
                    onComplete: () => {
                        element.style.transform = originalTransform;
                    }
                });
            }
        });
    },
    
    /**
     * Fade in element
     * @param {HTMLElement} element
     * @param {number} duration
     * @param {Function} onComplete
     */
    fadeIn(element, duration = 300, onComplete) {
        element.style.opacity = '0';
        element.style.display = 'block';
        
        this.animate({
            from: 0,
            to: 1,
            duration,
            onUpdate: (value) => {
                element.style.opacity = value;
            },
            onComplete
        });
    },
    
    /**
     * Fade out element
     * @param {HTMLElement} element
     * @param {number} duration
     * @param {Function} onComplete
     */
    fadeOut(element, duration = 300, onComplete) {
        this.animate({
            from: 1,
            to: 0,
            duration,
            onUpdate: (value) => {
                element.style.opacity = value;
            },
            onComplete: () => {
                element.style.display = 'none';
                element.style.opacity = '1';
                if (onComplete) onComplete();
            }
        });
    },
    
    /**
     * Count up animation
     * @param {HTMLElement} element
     * @param {number} from
     * @param {number} to
     * @param {number} duration
     */
    countUp(element, from, to, duration = 1000) {
        this.animate({
            from,
            to,
            duration,
            onUpdate: (value) => {
                element.textContent = Math.floor(value);
            },
            onComplete: () => {
                element.textContent = to;
            }
        });
    },
    
    /**
     * Scale in element
     * @param {HTMLElement} element
     * @param {number} duration
     * @param {Function} onComplete
     */
    scaleIn(element, duration = 300, onComplete) {
        element.style.transform = 'scale(0)';
        element.style.display = 'block';
        
        this.animate({
            from: 0,
            to: 1,
            duration,
            easing: (t) => {
                // Bounce easing
                const c4 = (2 * Math.PI) / 3;
                return t === 0 ? 0 : t === 1 ? 1 : 
                    Math.pow(2, -10 * t) * Math.sin((t * 10 - 0.75) * c4) + 1;
            },
            onUpdate: (value) => {
                element.style.transform = `scale(${value})`;
            },
            onComplete: () => {
                element.style.transform = 'scale(1)';
                if (onComplete) onComplete();
            }
        });
    },
    
    /**
     * Scale out element
     * @param {HTMLElement} element
     * @param {number} duration
     * @param {Function} onComplete
     */
    scaleOut(element, duration = 300, onComplete) {
        this.animate({
            from: 1,
            to: 0,
            duration,
            onUpdate: (value) => {
                element.style.transform = `scale(${value})`;
            },
            onComplete: () => {
                element.style.display = 'none';
                element.style.transform = 'scale(1)';
                if (onComplete) onComplete();
            }
        });
    },
    
    /**
     * Slide in from bottom
     * @param {HTMLElement} element
     * @param {number} duration
     * @param {Function} onComplete
     */
    slideInUp(element, duration = 400, onComplete) {
        element.style.transform = 'translateY(100px)';
        element.style.opacity = '0';
        element.style.display = 'block';
        
        const startTime = performance.now();
        
        const step = (currentTime) => {
            const elapsed = currentTime - startTime;
            const progress = Math.min(elapsed / duration, 1);
            const easedProgress = Utils.easeOutCubic(progress);
            
            const y = 100 - (100 * easedProgress);
            element.style.transform = `translateY(${y}px)`;
            element.style.opacity = easedProgress;
            
            if (progress < 1) {
                requestAnimationFrame(step);
            } else {
                element.style.transform = 'translateY(0)';
                element.style.opacity = '1';
                if (onComplete) onComplete();
            }
        };
        
        requestAnimationFrame(step);
    }
};

// Freeze Animation to prevent modifications
Object.freeze(Animation);
