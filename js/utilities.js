// ========================================================
// UTILITIES.JS - Helper Functions
// ========================================================

const Utils = {
    /**
     * Interpolate between two HSL colors
     * @param {Object} color1 - {h, s, l}
     * @param {Object} color2 - {h, s, l}
     * @param {number} factor - 0 to 1
     * @returns {string} HSL color string
     */
    interpolateColor(color1, color2, factor) {
        const h = color1.h + (color2.h - color1.h) * factor;
        const s = color1.s + (color2.s - color1.s) * factor;
        const l = color1.l + (color2.l - color1.l) * factor;
        return `hsl(${h}, ${s}%, ${l}%)`;
    },
    
    /**
     * Get color for a block based on its row position
     * @param {number} row - Row index
     * @param {number} totalRows - Total number of rows
     * @returns {string} HSL color string
     */
    getBlockColor(row, totalRows) {
        const bands = CONFIG.COLORS.bands;
        const position = row / (totalRows - 1);
        const scaledPosition = position * (bands.length - 1);
        const index = Math.floor(scaledPosition);
        const factor = scaledPosition - index;
        
        if (index >= bands.length - 1) {
            return this.interpolateColor(bands[bands.length - 1], bands[bands.length - 1], 0);
        }
        
        return this.interpolateColor(bands[index], bands[index + 1], factor);
    },
    
    /**
     * Clamp a value between min and max
     * @param {number} value
     * @param {number} min
     * @param {number} max
     * @returns {number}
     */
    clamp(value, min, max) {
        return Math.min(Math.max(value, min), max);
    },
    
    /**
     * Linear interpolation
     * @param {number} start
     * @param {number} end
     * @param {number} factor
     * @returns {number}
     */
    lerp(start, end, factor) {
        return start + (end - start) * factor;
    },
    
    /**
     * Ease out cubic
     * @param {number} t - 0 to 1
     * @returns {number}
     */
    easeOutCubic(t) {
        return 1 - Math.pow(1 - t, 3);
    },
    
    /**
     * Ease in out cubic
     * @param {number} t - 0 to 1
     * @returns {number}
     */
    easeInOutCubic(t) {
        return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
    },
    
    /**
     * Random number between min and max
     * @param {number} min
     * @param {number} max
     * @returns {number}
     */
    random(min, max) {
        return Math.random() * (max - min) + min;
    },
    
    /**
     * Random integer between min and max (inclusive)
     * @param {number} min
     * @param {number} max
     * @returns {number}
     */
    randomInt(min, max) {
        return Math.floor(Math.random() * (max - min + 1)) + min;
    },
    
    /**
     * Shuffle array
     * @param {Array} array
     * @returns {Array}
     */
    shuffle(array) {
        const shuffled = [...array];
        for (let i = shuffled.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
        }
        return shuffled;
    },
    
    /**
     * Debounce function
     * @param {Function} func
     * @param {number} wait
     * @returns {Function}
     */
    debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    },
    
    /**
     * Throttle function
     * @param {Function} func
     * @param {number} limit
     * @returns {Function}
     */
    throttle(func, limit) {
        let inThrottle;
        return function(...args) {
            if (!inThrottle) {
                func.apply(this, args);
                inThrottle = true;
                setTimeout(() => inThrottle = false, limit);
            }
        };
    },
    
    /**
     * Format number with commas
     * @param {number} num
     * @returns {string}
     */
    formatNumber(num) {
        return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    },
    
    /**
     * Vibrate device if supported
     * @param {number|Array} pattern
     */
    vibrate(pattern) {
        if (CONFIG.VIBRATION_ENABLED && 'vibrate' in navigator) {
            navigator.vibrate(pattern);
        }
    },
    
    /**
     * Check if touch device
     * @returns {boolean}
     */
    isTouchDevice() {
        return 'ontouchstart' in window || navigator.maxTouchPoints > 0;
    },
    
    /**
     * Get element position
     * @param {HTMLElement} element
     * @returns {Object} {x, y, width, height}
     */
    getElementPosition(element) {
        const rect = element.getBoundingClientRect();
        return {
            x: rect.left,
            y: rect.top,
            width: rect.width,
            height: rect.height,
            centerX: rect.left + rect.width / 2,
            centerY: rect.top + rect.height / 2
        };
    },
    
    /**
     * Wait for specified milliseconds
     * @param {number} ms
     * @returns {Promise}
     */
    wait(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    },
    
    /**
     * Create SVG arrow based on direction
     * @param {string} direction
     * @returns {string} SVG string
     */
    createArrowSVG(direction) {
        const arrows = {
            UP: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="19" x2="12" y2="5"></line><polyline points="5 12 12 5 19 12"></polyline></svg>',
            DOWN: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"></line><polyline points="19 12 12 19 5 12"></polyline></svg>',
            LEFT: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><line x1="19" y1="12" x2="5" y2="12"></line><polyline points="12 19 5 12 12 5"></polyline></svg>',
            RIGHT: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><line x1="5" y1="12" x2="19" y2="12"></line><polyline points="12 5 19 12 12 19"></polyline></svg>'
        };
        return arrows[direction.toUpperCase()] || arrows.UP;
    }
};

// Freeze Utils to prevent modifications
Object.freeze(Utils);
