// ADMIN-BRIDGE.JS
// Loads custom levels saved from admin panel into the game at runtime.
// Include this AFTER level.js in index.html.
// ========================================================

(function () {
    const CUSTOM_LEVELS_KEY = 'arrowPuzzle_customLevels';

    function loadCustomLevels() {
        try {
            const raw = localStorage.getItem(CUSTOM_LEVELS_KEY);
            if (!raw) return;
            const customLevels = JSON.parse(raw);
            if (!Array.isArray(customLevels) || customLevels.length === 0) return;

            customLevels.forEach(lvl => {
                // Don't overwrite built-in levels
                const exists = LEVELS.find(l => l.levelNumber === lvl.levelNumber);
                if (exists) return;

                // Convert colorIdx → color string
                const blocks = lvl.blocks.map(b => ({
                    x: b.x,
                    y: b.y,
                    direction: b.direction,
                    color: CONFIG.COLORS[b.colorIdx] || CONFIG.COLORS[0]
                }));

                LEVELS.push({
                    levelNumber: lvl.levelNumber,
                    rows: lvl.rows,
                    cols: lvl.cols,
                    blocks
                });
            });

            // Keep LEVELS sorted by levelNumber
            LEVELS.sort((a, b) => a.levelNumber - b.levelNumber);

            console.log(
                `%c[Admin Bridge] ${customLevels.length} custom level(s) loaded.`,
                'color: #6ec97d; font-weight: bold;'
            );
        } catch (e) {
            console.warn('[Admin Bridge] Failed to load custom levels:', e);
        }
    }

    loadCustomLevels();
})();
