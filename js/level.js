// ========================================================
// LEVEL.JS - Level Data (All levels verified solvable)
// ========================================================

const LEVELS = [
    // Level 1 (3x3, 3 blocks)
    {
        levelNumber: 1,
        rows: 3,
        cols: 3,
        blocks: [
            { x: 2, y: 1, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[0] },
            { x: 1, y: 0, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[1] },
            { x: 2, y: 0, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[2] }
        ]
    },

    // Level 2 (3x3, 4 blocks)
    {
        levelNumber: 2,
        rows: 3,
        cols: 3,
        blocks: [
            { x: 0, y: 1, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[0] },
            { x: 0, y: 2, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[1] },
            { x: 1, y: 0, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[2] },
            { x: 2, y: 1, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[3] }
        ]
    },

    // Level 3 (3x3, 5 blocks)
    {
        levelNumber: 3,
        rows: 3,
        cols: 3,
        blocks: [
            { x: 0, y: 2, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[0] },
            { x: 1, y: 2, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[1] },
            { x: 2, y: 1, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[2] },
            { x: 1, y: 0, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[3] },
            { x: 0, y: 1, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[4] }
        ]
    },

    // Level 4 (4x4, 5 blocks)
    {
        levelNumber: 4,
        rows: 4,
        cols: 4,
        blocks: [
            { x: 0, y: 3, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[0] },
            { x: 2, y: 0, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[1] },
            { x: 1, y: 0, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[2] },
            { x: 3, y: 2, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[3] },
            { x: 2, y: 1, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[4] }
        ]
    },

    // Level 5 (4x4, 6 blocks)
    {
        levelNumber: 5,
        rows: 4,
        cols: 4,
        blocks: [
            { x: 2, y: 2, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[0] },
            { x: 3, y: 3, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[1] },
            { x: 0, y: 1, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[2] },
            { x: 0, y: 3, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[3] },
            { x: 1, y: 0, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[4] },
            { x: 1, y: 1, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[5] }
        ]
    },

    // Level 6 (4x4, 7 blocks)
    {
        levelNumber: 6,
        rows: 4,
        cols: 4,
        blocks: [
            { x: 2, y: 3, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[0] },
            { x: 2, y: 1, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[1] },
            { x: 3, y: 3, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[2] },
            { x: 1, y: 0, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[3] },
            { x: 0, y: 1, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[4] },
            { x: 3, y: 0, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[5] },
            { x: 2, y: 2, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[6] }
        ]
    },

    // Level 7 (4x4, 8 blocks)
    {
        levelNumber: 7,
        rows: 4,
        cols: 4,
        blocks: [
            { x: 0, y: 2, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[0] },
            { x: 1, y: 3, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[1] },
            { x: 0, y: 0, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[2] },
            { x: 3, y: 2, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[3] },
            { x: 3, y: 0, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[4] },
            { x: 2, y: 1, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[5] },
            { x: 2, y: 0, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[6] },
            { x: 3, y: 1, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[7] }
        ]
    },

    // Level 8 (5x5, 8 blocks)
    {
        levelNumber: 8,
        rows: 5,
        cols: 5,
        blocks: [
            { x: 2, y: 2, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[0] },
            { x: 3, y: 0, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[1] },
            { x: 4, y: 4, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[2] },
            { x: 2, y: 4, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[3] },
            { x: 1, y: 2, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[4] },
            { x: 0, y: 4, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[5] },
            { x: 1, y: 4, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[6] },
            { x: 0, y: 1, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[7] }
        ]
    },

    // Level 9 (5x5, 10 blocks)
    {
        levelNumber: 9,
        rows: 5,
        cols: 5,
        blocks: [
            { x: 0, y: 1, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[0] },
            { x: 1, y: 1, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[1] },
            { x: 1, y: 3, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[2] },
            { x: 4, y: 4, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[3] },
            { x: 2, y: 3, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[4] },
            { x: 3, y: 1, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[5] },
            { x: 4, y: 3, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[6] },
            { x: 4, y: 0, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[7] },
            { x: 0, y: 2, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[8] },
            { x: 0, y: 3, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[9] }
        ]
    },

    // Level 10 (5x5, 12 blocks)
    {
        levelNumber: 10,
        rows: 5,
        cols: 5,
        blocks: [
            { x: 0, y: 0, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[0] },
            { x: 3, y: 3, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[1] },
            { x: 1, y: 4, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[2] },
            { x: 1, y: 1, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[3] },
            { x: 2, y: 4, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[4] },
            { x: 4, y: 3, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[5] },
            { x: 1, y: 2, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[6] },
            { x: 4, y: 4, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[7] },
            { x: 2, y: 1, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[8] },
            { x: 0, y: 3, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[9] },
            { x: 4, y: 2, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[0] },
            { x: 1, y: 0, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[1] }
        ]
    },

    // Level 11 (5x5, 14 blocks)
    {
        levelNumber: 11,
        rows: 5,
        cols: 5,
        blocks: [
            { x: 2, y: 3, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[0] },
            { x: 4, y: 2, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[1] },
            { x: 1, y: 2, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[2] },
            { x: 3, y: 0, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[3] },
            { x: 1, y: 4, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[4] },
            { x: 2, y: 0, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[5] },
            { x: 0, y: 1, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[6] },
            { x: 4, y: 0, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[7] },
            { x: 1, y: 0, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[8] },
            { x: 0, y: 0, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[9] },
            { x: 3, y: 1, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[0] },
            { x: 2, y: 4, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[1] },
            { x: 0, y: 4, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[2] },
            { x: 3, y: 3, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[3] }
        ]
    },

    // Level 12 (6x6, 12 blocks)
    {
        levelNumber: 12,
        rows: 6,
        cols: 6,
        blocks: [
            { x: 0, y: 3, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[0] },
            { x: 2, y: 1, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[1] },
            { x: 5, y: 5, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[2] },
            { x: 4, y: 2, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[3] },
            { x: 4, y: 3, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[4] },
            { x: 5, y: 0, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[5] },
            { x: 3, y: 5, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[6] },
            { x: 3, y: 4, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[7] },
            { x: 1, y: 3, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[8] },
            { x: 0, y: 0, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[9] },
            { x: 5, y: 2, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[0] },
            { x: 3, y: 1, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[1] }
        ]
    },

    // Level 13 (6x6, 15 blocks)
    {
        levelNumber: 13,
        rows: 6,
        cols: 6,
        blocks: [
            { x: 3, y: 4, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[0] },
            { x: 3, y: 0, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[1] },
            { x: 5, y: 2, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[2] },
            { x: 4, y: 0, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[3] },
            { x: 1, y: 4, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[4] },
            { x: 4, y: 5, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[5] },
            { x: 5, y: 3, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[6] },
            { x: 0, y: 5, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[7] },
            { x: 0, y: 1, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[8] },
            { x: 0, y: 4, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[9] },
            { x: 4, y: 2, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[0] },
            { x: 5, y: 5, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[1] },
            { x: 5, y: 0, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[2] },
            { x: 2, y: 4, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[3] },
            { x: 2, y: 2, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[4] }
        ]
    },

    // Level 14 (6x6, 18 blocks)
    {
        levelNumber: 14,
        rows: 6,
        cols: 6,
        blocks: [
            { x: 3, y: 4, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[0] },
            { x: 1, y: 0, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[1] },
            { x: 5, y: 2, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[2] },
            { x: 0, y: 1, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[3] },
            { x: 5, y: 1, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[4] },
            { x: 2, y: 3, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[5] },
            { x: 3, y: 0, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[6] },
            { x: 5, y: 0, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[7] },
            { x: 5, y: 3, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[8] },
            { x: 5, y: 4, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[9] },
            { x: 1, y: 4, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[0] },
            { x: 0, y: 5, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[1] },
            { x: 2, y: 0, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[2] },
            { x: 4, y: 5, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[3] },
            { x: 4, y: 0, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[4] },
            { x: 0, y: 0, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[5] },
            { x: 2, y: 2, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[6] },
            { x: 0, y: 2, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[7] }
        ]
    },

    // Level 15 (6x6, 20 blocks)
    {
        levelNumber: 15,
        rows: 6,
        cols: 6,
        blocks: [
            { x: 5, y: 2, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[0] },
            { x: 0, y: 1, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[1] },
            { x: 1, y: 2, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[2] },
            { x: 0, y: 2, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[3] },
            { x: 1, y: 3, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[4] },
            { x: 3, y: 3, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[5] },
            { x: 1, y: 4, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[6] },
            { x: 3, y: 0, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[7] },
            { x: 0, y: 5, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[8] },
            { x: 2, y: 4, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[9] },
            { x: 2, y: 2, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[0] },
            { x: 2, y: 0, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[1] },
            { x: 1, y: 5, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[2] },
            { x: 1, y: 0, direction: CONFIG.DIRECTIONS.UP, color: CONFIG.COLORS[3] },
            { x: 5, y: 4, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[4] },
            { x: 2, y: 1, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[5] },
            { x: 4, y: 1, direction: CONFIG.DIRECTIONS.RIGHT, color: CONFIG.COLORS[6] },
            { x: 5, y: 5, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[7] },
            { x: 0, y: 3, direction: CONFIG.DIRECTIONS.LEFT, color: CONFIG.COLORS[8] },
            { x: 4, y: 2, direction: CONFIG.DIRECTIONS.DOWN, color: CONFIG.COLORS[9] }
        ]
    }
];

// ========================================================
// LEVEL MANAGER
// ========================================================

const LevelManager = {
    /**
     * Get level data by number.
     * Returns null if level doesn't exist.
     */
    getLevel(levelNumber) {
        return LEVELS.find(l => l.levelNumber === levelNumber) || null;
    },

    getTotalLevels() {
        return LEVELS.length;
    },

    levelExists(levelNumber) {
        return LEVELS.some(l => l.levelNumber === levelNumber);
    },

    getAllLevels() {
        return LEVELS;
    }
};

// Freeze LevelManager to prevent modifications
Object.freeze(LevelManager);
