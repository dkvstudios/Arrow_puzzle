# 🎮 Arrow Puzzle Game

A premium, production-ready browser-based directional arrow puzzle game built with pure HTML5, CSS3, and Vanilla JavaScript.

## 🎯 Features

### Core Gameplay
- **Directional Movement**: Blocks move only in their arrow direction
- **Path Validation**: Blocks check entire path to board edge before moving
- **Smart Collision**: Blocked moves trigger shake animation and lose a heart
- **Smooth Animations**: Every interaction has polished animations (60 FPS)
- **Particle Effects**: Confetti, sparkles, coins, dust, and block particles

### Game Systems
- **Lives System**: Start with 3 hearts, lose 1 per wrong move
- **Coin Rewards**: Earn coins for completing levels
- **Level Progression**: 15+ pre-built levels with increasing difficulty
- **Save System**: LocalStorage automatically saves progress, coins, lives, and settings
- **Sound Effects**: Web Audio API generates tap, wrong, pop, victory, coin, and button sounds

### User Interface
- **Premium Mobile Design**: Soft pastel colors, cream panels, rounded corners
- **Responsive Layout**: Works on desktop, tablet, and mobile (portrait/landscape)
- **Zoom Controls**: Mouse wheel, touch pinch, and manual +/- buttons (0.5x to 2x)
- **Settings Panel**: Toggle sound on/off, reset progress
- **Victory/Game Over Popups**: Animated modals with continue/restart options

### Visual Design
- **HSL Color Interpolation**: Smooth gradient bands (brown→cream→blue→purple→pink→lavender)
- **Professional Typography**: Fredoka font family for premium casual game feel
- **Soft Shadows & Gradients**: Depth and polish on all UI elements
- **Button Animations**: Hover, active, and press states with scale/shadow effects

## 🚀 How to Play

1. **Open the Game**: Simply open `index.html` in any modern browser
2. **Click Blocks**: Tap/click on blocks to move them in their arrow direction
3. **Clear the Board**: Remove all blocks to complete the level
4. **Watch Your Hearts**: Wrong moves cost hearts - run out and it's game over!
5. **Earn Coins**: Complete levels to earn coins (future shop feature)
6. **Zoom**: Use mouse wheel, pinch gesture, or +/- buttons to zoom in/out

## 📁 Project Structure

```
d:\Html\Arrow\
├── index.html          # Main HTML structure
├── style.css           # Complete responsive styling
├── README.md           # This file
└── js/
    ├── config.js       # Game configuration constants
    ├── utilities.js    # Helper functions (HSL, animations, localStorage)
    ├── storage.js      # LocalStorage management
    ├── sound.js        # Web Audio API sound system
    ├── effects.js      # Particle system (confetti, sparkles, etc.)
    ├── animation.js    # Animation engine (easing, shake, bounce, etc.)
    ├── level.js        # Level management with JSON level data
    ├── block.js        # Block class (movement, validation, rendering)
    ├── board.js        # Board class (grid, rendering, zoom)
    ├── ui.js           # UI controller (buttons, popups, hearts, coins)
    └── main.js         # Game engine (orchestrates all systems)
```

## 🎨 Technical Highlights

### Architecture
- **Modular Design**: Separated concerns across 11 JavaScript modules
- **ES6 Classes**: Object-oriented structure for maintainability
- **Event Delegation**: Efficient event handling for UI interactions
- **No Dependencies**: Pure vanilla JavaScript - no frameworks or libraries

### Performance
- **Canvas 2D API**: Efficient rendering for grid-based puzzles
- **RequestAnimationFrame**: Smooth 60 FPS animations
- **Optimized Particles**: Physics-based particle systems with culling
- **Debounced Events**: Prevent excessive redraws on resize/zoom

### Responsive Design
- **Viewport Scaling**: Adapts to any screen size
- **Touch Support**: Full touch gesture support (tap, pinch, swipe)
- **Breakpoints**: CSS media queries for mobile/tablet/desktop
- **Orientation Support**: Works in both portrait and landscape

## 🔧 Customization

### Adding New Levels
Edit `js/level.js` and add new level objects to the `LEVELS` array:

```javascript
{
    levelNumber: 16,
    gridSize: 5,
    blocks: [
        { x: 2, y: 2, direction: 'up' },
        { x: 3, y: 2, direction: 'right' },
        // ... more blocks
    ]
}
```

### Changing Colors
Edit `js/config.js` to modify the color palette:

```javascript
COLORS: {
    GRADIENT_START: [25, 45, 50],  // HSL: Brown
    GRADIENT_END: [280, 70, 85],   // HSL: Lavender
    // ... other colors
}
```

### Adjusting Difficulty
Modify starting values in `js/config.js`:

```javascript
GAME: {
    STARTING_LIVES: 3,      // Change number of hearts
    STARTING_COINS: 0,      // Starting coin amount
    COINS_PER_LEVEL: 10,    // Reward per level
    // ...
}
```

## 🎮 Controls

### Desktop
- **Left Click**: Select and move blocks
- **Mouse Wheel**: Zoom in/out
- **+/- Buttons**: Manual zoom controls

### Mobile/Tablet
- **Tap**: Select and move blocks
- **Pinch**: Zoom in/out
- **+/- Buttons**: Manual zoom controls

### Keyboard (Future Enhancement)
- Arrow keys for block selection (not yet implemented)

## 💾 Save System

The game automatically saves:
- Current level progress
- Total coins earned
- Remaining lives
- Sound settings
- Zoom level

Data persists across browser sessions using LocalStorage.

## 🔊 Sound System

All sounds are generated using Web Audio API (no external files):
- **Tap**: Soft click when selecting blocks
- **Wrong**: Error sound for blocked moves
- **Pop**: Success sound for blocks flying off
- **Victory**: Level completion fanfare
- **Coin**: Coin collection jingle
- **Button**: UI button press feedback

Toggle sounds on/off in the settings panel (gear icon).

## 🌐 Browser Compatibility

Tested and working on:
- ✅ Chrome 90+
- ✅ Firefox 88+
- ✅ Safari 14+
- ✅ Edge 90+
- ✅ Mobile browsers (iOS Safari, Chrome Mobile)

Requires modern browser with:
- ES6 support
- Canvas 2D API
- Web Audio API
- LocalStorage API

## 📱 PWA Support (Optional)

The game includes commented-out service worker code in `main.js` for Progressive Web App functionality. Uncomment to enable offline play:

```javascript
navigator.serviceWorker.register('/sw.js')
    .then(registration => console.log('SW registered:', registration))
    .catch(error => console.log('SW registration failed:', error));
```

You'll need to create a `sw.js` service worker file and `manifest.json` for full PWA support.

## 🚧 Future Enhancements

Potential features to add:
- [ ] Tutorial overlay for first-time players
- [ ] Undo button (take back last move)
- [ ] Hint system (highlight movable blocks)
- [ ] Level editor mode
- [ ] Shop system (spend coins on power-ups)
- [ ] Daily challenges
- [ ] Leaderboards
- [ ] More level packs (100+ levels)
- [ ] Achievements system
- [ ] Share/social features

## 📄 License

This project is open source and available for personal and commercial use.

## 🙏 Credits

Inspired by popular mobile puzzle games:
- Tap Away
- Arrow Puzzle
- Arrow Away

Built with ❤️ using pure web technologies.

---

**Enjoy the game! 🎯✨**
