// ========================================================
// BOARD.JS - Game Board Management
// ========================================================

class Board {
    constructor(levelData) {
        this.blocks = [];
        this.grid = [];
        this.rows = levelData.rows;
        this.cols = levelData.cols;
        this.element = document.getElementById('gameBoard');
        this.container = document.getElementById('boardContainer');
        this.zoom = 1;

        this.initGrid();
        this.createBlocks(levelData.blocks);
        this.render();
    }

    initGrid() {
        this.grid = Array(this.rows).fill(null).map(() =>
            Array(this.cols).fill(false)
        );
    }

    createBlocks(blockData) {
        blockData.forEach((data) => {
            const block = new Block(data.x, data.y, data.direction, data.color);
            this.blocks.push(block);
            this.grid[data.y][data.x] = true;
        });
    }

    render() {
        this.element.innerHTML = '';
        this.element.style.display = 'grid';
        this.element.style.gridTemplateColumns = `repeat(${this.cols}, ${CONFIG.BLOCK_SIZE}px)`;
        this.element.style.gridTemplateRows    = `repeat(${this.rows}, ${CONFIG.BLOCK_SIZE}px)`;
        this.element.style.gap = `${CONFIG.BLOCK_GAP}px`;

        this.blocks.forEach(block => {
            if (!block.removed) {
                const element = block.createElement(CONFIG.BLOCK_SIZE);
                this.element.appendChild(element);
                element.addEventListener('click', () => this.handleBlockClick(block));
            }
        });

        this.applyZoom();
    }

    applyZoom() {
        this.container.style.transform = `translate(-50%, -50%) scale(${this.zoom})`;
    }

    async handleBlockClick(block) {
        if (block.removed || block.isAnimating) return;

        if (!block.canMove(this.grid, this.rows, this.cols)) {
            Sound.playWrong();
            Utils.vibrate([50, 50, 50]);
            block.shake();
            if (window.game) window.game.loseLife();
            return;
        }

        Sound.playPop();
        Utils.vibrate(50);

        // Remove from grid immediately so other blocks can move past this cell
        this.grid[block.y][block.x] = false;
        block.removed = true;       // mark removed NOW so grid stays consistent
        block.isAnimating = true;

        // Fire-and-forget the fly-off animation (don't await — let board stay interactive)
        this.flyBlockOff(block);

        // Check win condition right away (grid is already updated)
        this.checkWinCondition();
    }

    /**
     * Detach block from grid flow and animate it flying off screen, then remove DOM node.
     * No re-render needed — the block simply disappears.
     */
    flyBlockOff(block) {
        const el = block.element;
        if (!el) return;

        // 1. Snapshot the block's current screen position
        const rect       = el.getBoundingClientRect();
        const boardRect  = this.element.getBoundingClientRect();

        // Position relative to the board element
        const startLeft = rect.left - boardRect.left;
        const startTop  = rect.top  - boardRect.top;

        // 2. Pull it out of the grid into absolute positioning (visually same spot)
        el.style.position   = 'absolute';
        el.style.left       = startLeft + 'px';
        el.style.top        = startTop  + 'px';
        el.style.width      = CONFIG.BLOCK_SIZE + 'px';
        el.style.height     = CONFIG.BLOCK_SIZE + 'px';
        el.style.gridColumn = 'unset';
        el.style.gridRow    = 'unset';
        el.style.margin     = '0';
        el.style.zIndex     = '999';
        el.style.pointerEvents = 'none';

        // 3. Force a reflow so the browser registers the starting position
        el.getBoundingClientRect();

        // 4. How far to fly (enough to clear the board + padding)
        const cellSize = CONFIG.BLOCK_SIZE + CONFIG.BLOCK_GAP;
        const flyDist  = {
            up:    -(startTop  + cellSize * 2),
            down:   (boardRect.height - startTop + cellSize * 2),
            left:  -(startLeft + cellSize * 2),
            right:  (boardRect.width  - startLeft + cellSize * 2)
        }[block.direction];

        const axis = (block.direction === 'up' || block.direction === 'down') ? 'Y' : 'X';

        // 5. Animate: fly off + scale down + fade — pure CSS transition, no snap-back possible
        const duration = 380; // fast & snappy
        el.style.transition = `transform ${duration}ms cubic-bezier(0.4, 0, 0.8, 0.6),
                                opacity   ${duration}ms ease-in`;
        el.style.transform  = `translate${axis}(${flyDist}px) scale(0.4)`;
        el.style.opacity    = '0';

        // 6. Spawn particles at block center
        const cx = rect.left + rect.width  / 2;
        const cy = rect.top  + rect.height / 2;
        Effects.createBlockParticles(cx, cy, block.color);

        // 7. Remove DOM node after animation finishes
        setTimeout(() => {
            if (el.parentElement) el.parentElement.removeChild(el);
            block.isAnimating = false;
        }, duration + 50);
    }

    checkWinCondition() {
        const remaining = this.blocks.filter(b => !b.removed);

        if (remaining.length === 0) {
            // Show popup exactly when the last block finishes flying (380ms + tiny buffer)
            setTimeout(() => {
                if (window.game) window.game.levelComplete();
            }, 400);
            return;
        }

        // Safety: deadlock guard
        const anyCanMove = remaining.some(b => b.canMove(this.grid, this.rows, this.cols));
        if (!anyCanMove) {
            console.warn('Deadlock detected — restarting level');
            setTimeout(() => {
                if (window.game) window.game.restartLevel();
            }, 400);
        }
    }

    zoomIn() {
        this.zoom = Utils.clamp(this.zoom + CONFIG.ZOOM_STEP, CONFIG.MIN_ZOOM, CONFIG.MAX_ZOOM);
        this.applyZoom();
        Sound.playButton();
    }

    zoomOut() {
        this.zoom = Utils.clamp(this.zoom - CONFIG.ZOOM_STEP, CONFIG.MIN_ZOOM, CONFIG.MAX_ZOOM);
        this.applyZoom();
        Sound.playButton();
    }

    setZoom(zoom) {
        this.zoom = Utils.clamp(zoom, CONFIG.MIN_ZOOM, CONFIG.MAX_ZOOM);
        this.applyZoom();
    }

    destroy() {
        this.blocks.forEach(block => {
            if (block.element && block.element.parentElement) {
                block.element.parentElement.removeChild(block.element);
            }
        });
        this.blocks = [];
        this.grid   = [];
        this.element.innerHTML = '';
    }
}
