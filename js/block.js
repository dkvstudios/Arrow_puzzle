// ========================================================
// BLOCK.JS - Block Class
// ========================================================

class Block {
    constructor(x, y, direction, color) {
        this.x = x;
        this.y = y;
        this.direction = direction;
        this.color = color;
        this.element = null;
        this.removed = false;
        this.isAnimating = false; // Track per-block animation state
    }
    
    /**
     * Create DOM element for block
     * @param {number} size - Block size in pixels
     * @returns {HTMLElement}
     */
    createElement(size) {
        const block = document.createElement('div');
        block.className = 'block';
        block.style.width = `${size}px`;
        block.style.height = `${size}px`;
        block.style.background = this.color;
        block.style.gridColumn = this.x + 1;
        block.style.gridRow = this.y + 1;
        
        // Add arrow icon
        block.innerHTML = Utils.createArrowSVG(this.direction);
        
        this.element = block;
        return block;
    }
    
    /**
     * Check if block can move in its direction
     * @param {Array<Array<boolean>>} grid - Occupancy grid
     * @param {number} rows - Total rows
     * @param {number} cols - Total columns
     * @returns {boolean}
     */
    canMove(grid, rows, cols) {
        if (this.removed) return false;
        
        switch (this.direction) {
            case CONFIG.DIRECTIONS.UP:
                // Check all cells above
                for (let y = this.y - 1; y >= 0; y--) {
                    if (grid[y][this.x]) return false;
                }
                return true;
                
            case CONFIG.DIRECTIONS.DOWN:
                // Check all cells below
                for (let y = this.y + 1; y < rows; y++) {
                    if (grid[y][this.x]) return false;
                }
                return true;
                
            case CONFIG.DIRECTIONS.LEFT:
                // Check all cells to the left
                for (let x = this.x - 1; x >= 0; x--) {
                    if (grid[this.y][x]) return false;
                }
                return true;
                
            case CONFIG.DIRECTIONS.RIGHT:
                // Check all cells to the right
                for (let x = this.x + 1; x < cols; x++) {
                    if (grid[this.y][x]) return false;
                }
                return true;
                
            default:
                return false;
        }
    }
    
    /**
     * Get target position for move animation
     * @param {number} blockSize - Size of block in pixels
     * @param {number} gap - Gap between blocks
     * @param {number} rows - Total rows
     * @param {number} cols - Total columns
     * @returns {Object} {x, y}
     */
    getTargetPosition(blockSize, gap, rows, cols) {
        const cellSize = blockSize + gap;
        
        switch (this.direction) {
            case CONFIG.DIRECTIONS.UP:
                return {
                    x: this.x * cellSize,
                    y: -cellSize * 2
                };
                
            case CONFIG.DIRECTIONS.DOWN:
                return {
                    x: this.x * cellSize,
                    y: rows * cellSize + cellSize
                };
                
            case CONFIG.DIRECTIONS.LEFT:
                return {
                    x: -cellSize * 2,
                    y: this.y * cellSize
                };
                
            case CONFIG.DIRECTIONS.RIGHT:
                return {
                    x: cols * cellSize + cellSize,
                    y: this.y * cellSize
                };
                
            default:
                return { x: this.x * cellSize, y: this.y * cellSize };
        }
    }
    
    /**
     * Animate block movement and removal
     * @param {number} blockSize
     * @param {number} gap
     * @param {number} rows
     * @param {number} cols
     * @param {Function} onComplete
     */
    async animateRemoval(blockSize, gap, rows, cols, onComplete) {
        if (!this.element) return;
        
        this.element.classList.add('moving');
        
        // Add directional shadow class based on arrow direction
        this.element.classList.add(`moving-${this.direction.toLowerCase()}`);
        
        // Get target position
        const target = this.getTargetPosition(blockSize, gap, rows, cols);
        
        // Get current position
        const rect = this.element.getBoundingClientRect();
        const boardRect = this.element.parentElement.getBoundingClientRect();
        
        // Calculate relative position
        const startX = rect.left - boardRect.left;
        const startY = rect.top - boardRect.top;
        
        // Set absolute positioning
        this.element.style.position = 'absolute';
        this.element.style.left = `${startX}px`;
        this.element.style.top = `${startY}px`;
        this.element.style.gridColumn = 'unset';
        this.element.style.gridRow = 'unset';
        
        // Animate to target (immediate start for fast gameplay)
        this.element.style.transition = `all ${CONFIG.BLOCK_MOVE_DURATION}ms cubic-bezier(0.34, 1.56, 0.64, 1)`;
        this.element.style.left = `${target.x}px`;
        this.element.style.top = `${target.y}px`;
        this.element.style.opacity = '0';
        this.element.style.transform = 'scale(0.8) rotate(15deg)';
        
        // Create particles at center of block
        const centerX = rect.left + rect.width / 2;
        const centerY = rect.top + rect.height / 2;
        Effects.createBlockParticles(centerX, centerY, this.color);
        
        // Wait for animation to complete
        await Utils.wait(CONFIG.BLOCK_MOVE_DURATION);
        
        // Remove element
        if (this.element && this.element.parentElement) {
            this.element.parentElement.removeChild(this.element);
        }
        
        this.removed = true;
        
        if (onComplete) onComplete();
    }
    
    /**
     * Shake block (wrong move)
     */
    shake() {
        if (this.element) {
            Animation.shake(this.element);
        }
    }
    
    /**
     * Destroy block
     */
    destroy() {
        if (this.element && this.element.parentElement) {
            this.element.parentElement.removeChild(this.element);
        }
        this.element = null;
        this.removed = true;
    }
}
