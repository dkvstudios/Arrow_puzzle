// ========================================================
// TILE.JS - 3D Tile Class for Sort Tiles: Tap Away
// ========================================================

class Tile {
    constructor(x, y, z, colorIndex) {
        this.x = x;           // Grid X position
        this.y = y;           // Grid Y position  
        this.z = z;           // Height/layer (0 = bottom)
        this.colorIndex = colorIndex;
        this.color = this.getColorFromIndex(colorIndex);
        this.element = null;
        this.removed = false;
        this.isAnimating = false;
        this.isExposed = false; // Can be tapped
    }
    
    /**
     * Get HSL color from color index
     */
    getColorFromIndex(index) {
        const colorData = CONFIG.TILE_COLORS[index % CONFIG.TILE_COLORS.length];
        return `hsl(${colorData.h}, ${colorData.s}%, ${colorData.l}%)`;
    }
    
    /**
     * Get darker shade for 3D faces
     */
    getDarkerShade(multiplier) {
        const colorData = CONFIG.TILE_COLORS[this.colorIndex % CONFIG.TILE_COLORS.length];
        const newL = Math.max(10, colorData.l * multiplier);
        return `hsl(${colorData.h}, ${colorData.s}%, ${newL}%)`;
    }
    
    /**
     * Create 3D isometric tile element
     */
    createElement(size, rotation = 0) {
        const tile = document.createElement('div');
        tile.className = 'tile-3d';
        tile.dataset.x = this.x;
        tile.dataset.y = this.y;
        tile.dataset.z = this.z;
        
        // Calculate isometric position
        const isoPos = this.calculateIsometricPosition(size, rotation);
        
        tile.style.width = `${size}px`;
        tile.style.height = `${size}px`;
        tile.style.left = `${isoPos.x}px`;
        tile.style.top = `${isoPos.y}px`;
        tile.style.zIndex = isoPos.zIndex;
        
        // Create 3D cube faces with proper lighting
        const topColor = this.color; // Full brightness for top
        const frontColor = this.getDarkerShade(CONFIG.LIGHT_FRONT);
        const sideColor = this.getDarkerShade(CONFIG.LIGHT_SIDE);
        
        tile.innerHTML = `
            <div class="tile-face tile-top" style="background: ${topColor};"></div>
            <div class="tile-face tile-front" style="background: ${frontColor};"></div>
            <div class="tile-face tile-side" style="background: ${sideColor};"></div>
        `;
        
        // Add glow if exposed
        if (this.isExposed && CONFIG.HINT_GLOW) {
            tile.classList.add('exposed');
        }
        
        this.element = tile;
        return tile;
    }
    
    /**
     * Calculate isometric 2D position from 3D coordinates
     */
    calculateIsometricPosition(size, rotation = 0) {
        const tileSize = size + CONFIG.TILE_GAP;
        
        // Apply rotation transformation
        const rad = (rotation * Math.PI) / 180;
        const cos = Math.cos(rad);
        const sin = Math.sin(rad);
        
        const rotatedX = this.x * cos - this.y * sin;
        const rotatedY = this.x * sin + this.y * cos;
        
        // Isometric projection
        const isoX = (rotatedX - rotatedY) * (tileSize * 0.866); // sqrt(3)/2
        const isoY = (rotatedX + rotatedY) * (tileSize * 0.5) - (this.z * CONFIG.TILE_DEPTH);
        
        // Z-index for proper layering (back to front)
        const zIndex = Math.floor((rotatedX + rotatedY) * 100 + this.z * 10);
        
        return { x: isoX, y: isoY, zIndex };
    }
    
    /**
     * Check if tile is exposed (can be tapped)
     * A tile is exposed if no other tile is directly above it
     */
    checkIfExposed(allTiles) {
        // Check if any tile is at same x,y but higher z
        const blocked = allTiles.some(tile => 
            !tile.removed && 
            tile !== this &&
            tile.x === this.x && 
            tile.y === this.y && 
            tile.z > this.z
        );
        
        this.isExposed = !blocked;
        return this.isExposed;
    }
    
    /**
     * Animate tile flying away
     */
    async animateFlyAway() {
        if (!this.element) return;
        
        this.isAnimating = true;
        this.element.classList.add('flying');
        
        // Calculate fly-away direction (towards camera/viewer)
        const flyDistance = 800;
        const currentLeft = parseFloat(this.element.style.left);
        const currentTop = parseFloat(this.element.style.top);
        
        // Fly towards top-right (away from isometric view)
        const targetX = currentLeft + flyDistance * 0.5;
        const targetY = currentTop - flyDistance * 0.8;
        
        // Apply animation
        this.element.style.transition = `all ${CONFIG.TILE_FLY_DURATION}ms cubic-bezier(0.25, 0.46, 0.45, 0.94)`;
        this.element.style.left = `${targetX}px`;
        this.element.style.top = `${targetY}px`;
        this.element.style.opacity = '0';
        this.element.style.transform = 'scale(0.5) rotate3d(1, 1, 0, 360deg)';
        
        // Wait for animation
        await Utils.wait(CONFIG.TILE_FLY_DURATION);
        
        // Remove element
        if (this.element && this.element.parentElement) {
            this.element.parentElement.removeChild(this.element);
        }
        
        this.removed = true;
        this.isAnimating = false;
    }
    
    /**
     * Shake tile (wrong tap)
     */
    shake() {
        if (this.element) {
            this.element.classList.add('shake');
            setTimeout(() => {
                this.element.classList.remove('shake');
            }, CONFIG.SHAKE_DURATION);
        }
    }
    
    /**
     * Highlight as tappable
     */
    highlight(enable = true) {
        if (this.element) {
            if (enable) {
                this.element.classList.add('exposed');
            } else {
                this.element.classList.remove('exposed');
            }
        }
    }
    
    /**
     * Destroy tile
     */
    destroy() {
        if (this.element && this.element.parentElement) {
            this.element.parentElement.removeChild(this.element);
        }
        this.element = null;
        this.removed = true;
    }
}
