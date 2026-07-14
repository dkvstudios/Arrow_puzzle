import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:vibration/vibration.dart';
import '../models/block.dart';
import '../data/levels.dart';
import '../utils/config.dart';
import '../utils/ad_service.dart';
import '../utils/progress_service.dart';
import '../widgets/block_widget.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/shiny_button.dart';
import 'manage_levels_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // Game state
  int currentLevel = 1;
  int lives = GameConfig.initialLives;
  int coins = 0;
  List<Block> blocks = [];
  late List<List<bool>> grid;
  int rows = 0;
  int cols = 0;
  final TransformationController _transformationController = TransformationController();
  
  // Game status
  bool isVictory = false;
  bool isGameOver = false;
  bool isSettingsOpen = false;
  
  // Settings
  bool isVibrationEnabled = true;
  bool isSoundEnabled = true;
  
  // Layout
  bool _needsCentering = true;
  
  // Cached grid dots (rebuilt only when rows/cols change)
  List<Widget> _cachedGridDots = [];
  
  // Continue mechanics
  int _continueCost = 900;
  
  // Track active animation controllers for cleanup
  final Set<AnimationController> _activeControllers = {};

  // Admin access
  int _levelTapCount = 0;
  Timer? _tapTimer;

  // Ad state
  bool _isAdLoading = false;

  // Loading state — true while SQLite progress is being read
  bool _isLoadingProgress = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    // Ads are preloaded in SplashScreen after AdConfig.loadAndSync()
    // No need to reload here unless you want a safety net
  }

  /// Load saved progress from SQLite then start the correct level.
  Future<void> _loadProgress() async {
    final progress = await ProgressService.instance.loadAll();
    setState(() {
      currentLevel       = progress['level']     ?? 1;
      coins              = progress['coins']      ?? 0;
      isVibrationEnabled = (progress['vibration'] ?? 1) == 1;
      isSoundEnabled     = (progress['sound']     ?? 1) == 1;
      _isLoadingProgress = false;
    });
    _loadLevel(currentLevel);
  }

  @override
  void dispose() {
    // Cancel admin tap timer
    _tapTimer?.cancel();
    // Clean up all active animation controllers
    for (var controller in _activeControllers.toList()) {
      controller.dispose();
    }
    _activeControllers.clear();
    // Dispose transformation controller
    _transformationController.dispose();
    super.dispose();
  }

  void _loadLevel(int levelNumber) {
    print('📋 Loading level $levelNumber');
    final levelData = Levels.getLevel(levelNumber);
    if (levelData == null) {
      // All levels complete - restart from level 1
      setState(() {
        currentLevel = 1;
        lives = GameConfig.initialLives;
      });
      // Reset saved progress so next launch also starts from 1
      ProgressService.instance.saveCurrentLevel(1);
      _loadLevel(1);
      return;
    }

    setState(() {
      _needsCentering = true;
      rows = levelData.rows;
      cols = levelData.cols;
      grid = List.generate(rows, (_) => List.filled(cols, false));
      blocks = levelData.blocks.map((data) {
        grid[data.y][data.x] = true;
        return Block(
          x: data.x,
          y: data.y,
          direction: data.direction,
          color: data.color,
        );
      }).toList();
      isVictory = false;
      isGameOver = false;
      _continueCost = 900;
      // Rebuild grid dots cache for new level dimensions
      _cachedGridDots = _buildGridDots(levelData.rows, levelData.cols);
    });
  }

  void _handleBlockTap(Block block) {
    // Prevent interaction during animations or if already removed
    if (block.removed || block.isAnimating || block.isShaking) return;
    
    // Prevent interaction during game over or victory
    if (isGameOver || isVictory) return;

    // Print tap information to console
    print('🎯 ARROW TAPPED:');
    print('   Position: (${block.x}, ${block.y})');
    print('   Direction: ${block.direction}');
    print('   Color: ${block.color}');
    
    final canMove = block.canMove(grid, rows, cols);
    print('   Can Move: $canMove');

    // Check if block can move (path must be clear in arrow direction)
    if (!canMove) {
      print('❌ BLOCKED - Shaking! Lives: $lives → ${lives - 1}');
      
      // Mark as shaking immediately to prevent double-tap
      setState(() {
        final index = blocks.indexWhere((b) => b.id == block.id);
        if (index >= 0) {
          blocks[index] = blocks[index].copyWith(isShaking: true);
        }
      });
      
      _shakeBlock(block);
      _loseLife();
      return;
    }

    print('✅ VALID MOVE - Flying off!');
    
    // Play haptic feedback — short single buzz on correct tap
    if (isVibrationEnabled) {
      Vibration.vibrate(duration: 60, amplitude: 180);
    }

    // Mark as animating immediately to prevent double-tap
    setState(() {
      final index = blocks.indexWhere((b) => b.id == block.id);
      if (index >= 0) {
        blocks[index] = blocks[index].copyWith(isAnimating: true);
      }
    });

    // Remove from grid immediately so other blocks can move
    grid[block.y][block.x] = false;
    
    // Start fly-off animation
    _animateBlockRemoval(block);
    
    // Check win after animation completes
    Future.delayed(GameConfig.blockMoveDuration + const Duration(milliseconds: 50), () {
      if (mounted) {
        _checkWinCondition();
      }
    });
  }

  void _animateBlockRemoval(Block block) {
    print('🚀 Starting fly-off animation for block at (${block.x}, ${block.y}) [ID: ${block.id}]');

    final controller = AnimationController(
      vsync: this,
      duration: GameConfig.blockMoveDuration,
    );

    // Track controller for cleanup
    _activeControllers.add(controller);

    final targetPos = block.getTargetPosition(rows, cols);
    print('   Target position: $targetPos');
    
    final animation = CurvedAnimation(
      parent: controller,
      curve: GameConfig.blockMoveCurve,
    );

    animation.addListener(() {
      if (!mounted) return;
      setState(() {
        final currentIndex = blocks.indexWhere((b) => b.id == block.id);
        if (currentIndex >= 0) {
          // Only fade and shrink at the very end of the animation (last 20% of time)
          final destroyProgress = controller.value > 0.8 
              ? (controller.value - 0.8) / 0.2 
              : 0.0;
              
          blocks[currentIndex] = blocks[currentIndex].copyWith(
            isAnimating: true,
            animProgress: animation.value,
            targetPosition: targetPos,
            opacity: 1.0 - destroyProgress,
            scale: 1.0 - destroyProgress,
          );
        }
      });
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        print('✨ Fly-off animation completed');
        if (!mounted) return;
        setState(() {
          final currentIndex = blocks.indexWhere((b) => b.id == block.id);
          if (currentIndex >= 0) {
            blocks[currentIndex] = blocks[currentIndex].copyWith(
              removed: true,
              isAnimating: false,
            );
            print('   Block marked as removed: ${blocks[currentIndex].removed}');
            print('   Block isAnimating: ${blocks[currentIndex].isAnimating}');
          } else {
            print('   ⚠️ Block not found in list!');
          }
        });
        
        // Clean up controller
        _activeControllers.remove(controller);
        animation.dispose();
        controller.dispose();
      }
    });

    controller.forward();
  }

  void _shakeBlock(Block block) {
    // Wrong tap — strong buzz-pause-buzz-pause-buzz pattern
    if (isVibrationEnabled) {
      Vibration.vibrate(
        pattern: [0, 120, 80, 120, 80, 120],
        intensities: [0, 255, 0, 255, 0, 255],
      );
    }

    final controller = AnimationController(
      vsync: this,
      duration: GameConfig.shakeDuration,
    );

    // Track controller for cleanup
    _activeControllers.add(controller);

    controller.addListener(() {
      if (!mounted) return;
      setState(() {
        final currentIndex = blocks.indexWhere((b) => b.id == block.id);
        if (currentIndex >= 0) {
          blocks[currentIndex] = blocks[currentIndex].copyWith(
            isShaking: true,
            animProgress: controller.value,
            shakeOffset: 8.0,
          );
        }
      });
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        if (!mounted) return;
        setState(() {
          final currentIndex = blocks.indexWhere((b) => b.id == block.id);
          if (currentIndex >= 0) {
            blocks[currentIndex] = blocks[currentIndex].copyWith(
              isShaking: false,
              animProgress: 0.0,
              shakeOffset: 0.0,
            );
          }
        });
        
        // Clean up controller
        _activeControllers.remove(controller);
        controller.dispose();
      }
    });

    controller.forward();
  }

  void _checkWinCondition() {
    final remainingBlocks = blocks.where((b) => !b.removed).length;
    
    if (remainingBlocks == 0) {
      // Victory — long strong buzz
      if (isVibrationEnabled) {
        Vibration.vibrate(duration: 400, amplitude: 255);
      }

      // Give coins immediately
      setState(() => coins += 100);
      ProgressService.instance.saveCoins(coins);

      // Show interstitial only after level 3, then show victory popup when done
      if (currentLevel > 3) {
        AdService.instance.showInterstitialAd(
          onDone: () {
            if (mounted) setState(() => isVictory = true);
          },
        );
      } else {
        setState(() => isVictory = true);
      }
    }
  }

  void _loseLife() {
    setState(() {
      lives--;
      print('💔 Life lost! Remaining lives: $lives');
      if (lives <= 0) {
        print('☠️ GAME OVER!');
        isGameOver = true;
      }
    });
  }

  void _nextLevel() {
    setState(() {
      currentLevel++;
    });
    ProgressService.instance.saveCurrentLevel(currentLevel);
    _loadLevel(currentLevel);
  }

  void _restartLevel() {
    setState(() {
      lives = GameConfig.initialLives;
    });
    _loadLevel(currentLevel);
  }

  void _zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = math.min(2.5, currentScale + 0.2);
    final matrix = _transformationController.value.clone();
    // To scale around center, ideally we'd use a focal point, but scaling the matrix works too.
    // ignore: deprecated_member_use
    matrix.scale(newScale / currentScale);
    _transformationController.value = matrix;
  }

  void _zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = math.max(0.5, currentScale - 0.2);
    final matrix = _transformationController.value.clone();
    // ignore: deprecated_member_use
    matrix.scale(newScale / currentScale);
    _transformationController.value = matrix;
  }

  /// Resets the board back to the centered fitted position — same as initial load.
  void _resetView() {
    final cellSize = GameConfig.blockSize + GameConfig.blockGap;
    final boardW   = cols * cellSize - GameConfig.blockGap;
    final boardH   = rows * cellSize - GameConfig.blockGap;
    final size     = MediaQuery.of(context).size;

    // Approximate available height (subtract top bar ~90 and bottom bar ~130)
    final availW = size.width.toDouble();
    final availH = size.height - 90 - 130;

    const padding = 80.0;
    final scaleX  = availW / (boardW + padding);
    final scaleY  = availH / (boardH + padding);
    final scale   = math.min(scaleX, scaleY).clamp(0.2, 1.5);

    final dx = (availW - boardW * scale) / 2;
    final dy = (availH - boardH * scale) / 2;

    // ignore: deprecated_member_use
    _transformationController.value = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale);
  }

  /// Builds the static grid dot widgets for the given dimensions.
  /// Called once per level load and cached in [_cachedGridDots].
  List<Widget> _buildGridDots(int r, int c) {
    final cellSize = GameConfig.blockSize + GameConfig.blockGap;
    final List<Widget> dots = [];
    for (int y = 0; y < r; y++) {
      for (int x = 0; x < c; x++) {
        dots.add(
          Positioned(
            left: x * cellSize + (GameConfig.blockSize / 2) - 3,
            top: y * cellSize + (GameConfig.blockSize / 2) - 3,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }
    }
    return dots;
  }

  @override
  Widget build(BuildContext context) {
    // Show loader while reading SQLite progress to avoid negative constraint crash
    if (_isLoadingProgress) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F4F4),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF5BA3E0)),
        ),
      );
    }

    final cellSize = GameConfig.blockSize + GameConfig.blockGap;
    final boardWidth = cols * cellSize - GameConfig.blockGap;
    final boardHeight = rows * cellSize - GameConfig.blockGap;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              GameConfig.bgGradientStart,
              GameConfig.bgGradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main game area
              Column(
                children: [
                  // Top bar with hearts
                  _buildTopBar(),
                  
                  // Game board with Zoom controls
                  Expanded(
                    child: Stack(
                      children: [
                        // Game Board (first in stack so it's behind controls)
                        Positioned.fill(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              if (_needsCentering) {
                                _needsCentering = false;
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (!mounted) return;
                                  // 80 padding on all sides for the board (includes space for controls)
                                  final double padding = 80.0;
                                  final double scaleX = constraints.maxWidth / (boardWidth + padding);
                                  final double scaleY = constraints.maxHeight / (boardHeight + padding);
                                  
                                  // Cap max scale at 1.5, min scale at 0.2
                                  final double scale = math.min(scaleX, scaleY).clamp(0.2, 1.5);
                                  
                                  final double dx = (constraints.maxWidth - (boardWidth * scale)) / 2;
                                  final double dy = (constraints.maxHeight - (boardHeight * scale)) / 2;
                                  
                                  // ignore: deprecated_member_use
                                  _transformationController.value = Matrix4.identity()
                                    ..translate(dx, dy)
                                    ..scale(scale);
                                });
                              }
                              return InteractiveViewer(
                                transformationController: _transformationController,
                                minScale: 0.2,
                                maxScale: 3.0,
                                constrained: false,
                                boundaryMargin: const EdgeInsets.all(2000),
                            child: SizedBox(
                              width: boardWidth,
                              height: boardHeight,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // Grid dots
                                  ..._cachedGridDots,
                                  // Blocks
                                  ...blocks.map((block) {
                                    return BlockWidget(
                                      key: ValueKey(block.id),
                                      block: block,
                                      onTap: () => _handleBlockTap(block),
                                      cellSize: cellSize,
                                    );
                                  }),
                                ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                        
                        // Zoom controls on the left
                        Positioned(
                          left: 16,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Reset / re-center button (separate)
                                  Container(
                                    width: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.center_focus_strong_rounded, color: Color(0xFF6EBD75)),
                                      onPressed: _resetView,
                                      tooltip: 'Reset View',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Zoom in / out together
                                  Container(
                                    width: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.add, color: Color(0xFF5BA3E0)),
                                          onPressed: _zoomIn,
                                        ),
                                        Container(
                                          height: 2,
                                          width: 24,
                                          color: Colors.grey.withValues(alpha: 0.2),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.remove, color: Color(0xFF5BA3E0)),
                                          onPressed: _zoomOut,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Bottom bar with level
                  _buildBottomBar(),
                ],
              ),
              
              // Victory popup
              if (isVictory) _buildVictoryPopup(),
              
              // Game over popup
              if (isGameOver) _buildGameOverPopup(),
              
              // Settings popup
              if (isSettingsOpen) _buildSettingsPopup(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Coin Panel
          GestureDetector(
            onTap: _showStoreDialog,
            child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD700),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.home_rounded, color: Colors.white, size: 18),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF6EBD75),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 12),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Text(
                  '$coins',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513),
                  ),
                ),
              ],
            ),
          ),
          ),
          
          // Center: Hearts Panel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: const Color(0xFF5BA3E0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF4A8CCC), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(GameConfig.initialLives, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Icon(
                      index < lives ? Icons.favorite : Icons.favorite_border,
                      key: ValueKey<bool>(index < lives),
                      color: index < lives ? const Color(0xFFE06652) : const Color(0xFFD4B895),
                      size: 28,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          offset: const Offset(0, 2),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          // Right: Settings
          _buildTopBtn(
            icon: Icons.settings, 
            color: const Color(0xFF6EBD75),
            onTap: () => setState(() => isSettingsOpen = true),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBtn({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              offset: const Offset(0, 3),
              blurRadius: 2,
            ),
          ],
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
        ),
        child: Center(
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: GestureDetector(
          onTap: _onLevelTap,
          child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF5BA3E0),
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'LEVEL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  '$currentLevel',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5BA3E0),
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildVictoryPopup() {
    return CustomDialog(
      title: 'Level Complete',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          const Text(
            'AWESOME!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFFB35522),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          // Stars - one by one with zoom-out bounce
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              // Each star starts after the previous one finishes
              // delay: index * 300ms, duration: 500ms each
              final delayMs = index * 300;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: delayMs + 500),
                  curve: Curves.linear,
                  builder: (context, rawValue, child) {
                    // Only animate during this star's window
                    final double progress = ((rawValue * (delayMs + 500)) - delayMs)
                        .clamp(0.0, 500.0) / 500.0;

                    // Zoom from big (1.8x) down to normal (1.0x) with elastic bounce
                    // scale: starts at 0, overshoots to 1.8, settles at 1.0
                    double scale;
                    double opacity;
                    if (progress <= 0.0) {
                      scale = 0.0;
                      opacity = 0.0;
                    } else if (progress < 0.3) {
                      // Pop in: 0 → 1.8
                      scale = (progress / 0.3) * 1.8;
                      opacity = 1.0;
                    } else if (progress < 0.6) {
                      // Zoom out: 1.8 → 0.85
                      scale = 1.8 - ((progress - 0.3) / 0.3) * 0.95;
                      opacity = 1.0;
                    } else if (progress < 0.8) {
                      // Bounce back: 0.85 → 1.1
                      scale = 0.85 + ((progress - 0.6) / 0.2) * 0.25;
                      opacity = 1.0;
                    } else {
                      // Settle: 1.1 → 1.0
                      scale = 1.1 - ((progress - 0.8) / 0.2) * 0.1;
                      opacity = 1.0;
                    }

                    return Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        child: child,
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFFFD13B),
                    size: 60,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(0, 4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          ShinyButton(
            onPressed: () {
              // Usually go to next level here
              _nextLevel();
            },
            gradientColors: const [Color(0xFF77D328), Color(0xFF59B113)],
            borderColor: const Color(0xFFF4C127),
            child: const Text(
              'Next Level',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverPopup() {
    return CustomDialog(
      title: 'Out of moves',
      onClose: _restartLevel,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hearts container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE4CD),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.favorite, color: Color(0xFFE33A3A), size: 36),
                SizedBox(width: 8),
                Icon(Icons.favorite, color: Color(0xFFE33A3A), size: 36),
                SizedBox(width: 8),
                Icon(Icons.favorite, color: Color(0xFFE33A3A), size: 36),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Subtitle
          const Text(
            'Continue with full lives',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF8B4513),
            ),
          ),
          const SizedBox(height: 16),
          
          // Green Continue Button
          if (coins >= _continueCost)
            ShinyButton(
              onPressed: () {
                setState(() {
                  coins -= _continueCost;
                  _continueCost *= 2;
                  lives = GameConfig.initialLives;
                  isGameOver = false;
                });
                ProgressService.instance.saveCoins(coins);
              },
              height: 70,
              gradientColors: const [Color(0xFF77D328), Color(0xFF59B113)],
              borderColor: const Color(0xFFF4C127),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFD13B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.home_rounded, color: Colors.white, size: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_continueCost',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          
          // Blue +3 Lives Button
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              ShinyButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  AdService.instance.showRewardedAd(
                    onRewarded: (_) {
                      if (!mounted) return;
                      setState(() {
                        lives = GameConfig.initialLives;
                        isGameOver = false;
                      });
                    },
                    onFailed: () {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ad not available. Try again later.')),
                      );
                    },
                  );
                },
                height: 60,
                gradientColors: const [Color(0xFF5EA1F8), Color(0xFF246DF1)],
                borderColor: const Color(0xFF1B55C0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF246DF1), size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '+3 Lives',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              // Daily Limit badge
              Positioned(
                bottom: -16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAD1B6),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                  ),
                  child: const Text(
                    'Daily Limit: 10/10',
                    style: TextStyle(
                      color: Color(0xFF8B4513),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Red Restart Button
          ShinyButton(
            onPressed: _restartLevel,
            height: 60,
            gradientColors: const [Color(0xFFFA6464), Color(0xFFE33A3A)],
            borderColor: const Color(0xFFC02A2A),
            child: const Text(
              'Restart',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPopup() {
    return CustomDialog(
      title: 'Settings',
      onClose: () => setState(() => isSettingsOpen = false),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Vibrate Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE4CD),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.vibration, color: Color(0xFFB35522), size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Vibrate',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFB35522),
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: isVibrationEnabled,
                  onChanged: (val) {
                    setState(() => isVibrationEnabled = val);
                    ProgressService.instance.saveVibration(val);
                  },
                  activeThumbColor: const Color(0xFF77D328),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Sound Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE4CD),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.volume_up_rounded, color: Color(0xFFB35522), size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Sound',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFB35522),
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: isSoundEnabled,
                  onChanged: (val) {
                    setState(() => isSoundEnabled = val);
                    ProgressService.instance.saveSound(val);
                  },
                  activeThumbColor: const Color(0xFF77D328),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ShinyButton(
            onPressed: () => setState(() => isSettingsOpen = false),
            height: 60,
            gradientColors: const [Color(0xFF5EA1F8), Color(0xFF246DF1)],
            borderColor: const Color(0xFF1B55C0),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStoreDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return CustomDialog(
              title: 'COIN STORE',
              onClose: () => Navigator.of(context).pop(),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Watch a short ad to earn coins!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Coin reward info
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4C2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFD13B), width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.monetization_on_rounded, color: Color(0xFFFFD700), size: 28),
                        SizedBox(width: 8),
                        Text(
                          '+50 Coins',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFB35522),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ShinyButton(
                    gradientColors: const [Color(0xFF5EA1F8), Color(0xFF246DF1)],
                    borderColor: const Color(0xFF1B55C0),
                    onPressed: _isAdLoading
                        ? () {} // disabled while loading
                        : () {
                            if (!AdService.instance.isReady) {
                              // Ad not loaded yet — show loading state
                              setDialogState(() {});
                              setState(() => _isAdLoading = true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Ad is loading, please wait...')),
                              );
                              // Poll until ready (max 30 seconds)
                              int attempts = 0;
                              Future.doWhile(() async {
                                await Future.delayed(const Duration(milliseconds: 500));
                                attempts++;
                                if (!mounted) return false;
                                if (AdService.instance.isReady) {
                                  setState(() => _isAdLoading = false);
                                  setDialogState(() {});
                                  return false;
                                }
                                if (attempts >= 60) {
                                  // 30 seconds timeout — give up
                                  if (mounted) setState(() => _isAdLoading = false);
                                  return false;
                                }
                                return true;
                              });
                              return;
                            }

                            Navigator.of(context).pop();
                            AdService.instance.showRewardedAd(
                              onRewarded: (amount) {
                                setState(() => coins += amount);
                                ProgressService.instance.saveCoins(coins);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('+$amount Coins earned!')),
                                );
                              },
                              onFailed: () {
                                setState(() => _isAdLoading = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Ad not available. Try again later.')),
                                );
                                AdService.instance.loadRewardedAd();
                              },
                            );
                          },
                    child: _isAdLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.play_circle_filled, color: Colors.white, size: 28),
                              SizedBox(width: 12),
                              Text(
                                'WATCH AD  +50 COINS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _onLevelTap() {
    _levelTapCount++;
    _tapTimer?.cancel();
    
    if (_levelTapCount >= 7) {
      _levelTapCount = 0;
      _showPasswordDialog();
    } else {
      _tapTimer = Timer(const Duration(seconds: 1), () {
        _levelTapCount = 0;
      });
    }
  }

  void _showPasswordDialog() {
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return CustomDialog(
          title: 'ADMIN ACCESS',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter Developer Password:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              ShinyButton(
                gradientColors: const [Color(0xFF6EBD75), Color(0xFF4CA054)],
                borderColor: const Color(0xFF388E3C),
                child: const Text('SUBMIT', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                onPressed: () {
                  final entered = passwordController.text;
                  Navigator.of(context).pop();
                  if (entered == '1234') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ManageLevelsScreen()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Incorrect password')),
                    );
                  }
                },
              ),
            ],
          ),
          onClose: () => Navigator.of(context).pop(),
        );
      },
    ).then((_) => passwordController.dispose());
  }
}
