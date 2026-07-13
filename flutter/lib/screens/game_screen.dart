import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import '../models/block.dart';
import '../data/levels.dart';
import '../utils/config.dart';
import '../widgets/block_widget.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/shiny_button.dart';
import 'admin_screen.dart';
import 'manage_levels_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // Game state
  int currentLevel = 16;
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
  
  // Continue mechanics
  int _continueCost = 900;
  
  // Track active animation controllers for cleanup
  final Set<AnimationController> _activeControllers = {};

  // Admin access
  int _levelTapCount = 0;
  Timer? _tapTimer;

  @override
  void initState() {
    super.initState();
    _loadLevel(currentLevel);
  }
  
  @override
  void dispose() {
    // Clean up all active controllers
    for (var controller in _activeControllers) {
      controller.dispose();
    }
    _activeControllers.clear();
    super.dispose();
  }

  void _loadLevel(int levelNumber) {
    print('📋 Loading level $levelNumber');
    final levelData = Levels.getLevel(levelNumber);
    if (levelData == null) {
      print('🏆 All levels complete! Restarting from level 1');
      // All levels complete - restart from level 1
      setState(() {
        currentLevel = 1;
        lives = GameConfig.initialLives;
      });
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
    
    // Play haptic feedback
    if (isVibrationEnabled) {
      HapticFeedback.lightImpact();
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
    print('💥 Starting shake animation for block at (${block.x}, ${block.y}) [ID: ${block.id}]');
    if (isVibrationEnabled) {
      HapticFeedback.mediumImpact();
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
    print('🔍 Checking win condition: $remainingBlocks blocks remaining');
    
    if (remainingBlocks == 0) {
      print('🎉 VICTORY! Level $currentLevel completed!');
      setState(() {
        isVictory = true;
        coins += 100;
      });
      HapticFeedback.heavyImpact();
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
    print('⬆️ Advancing to level ${currentLevel + 1}');
    setState(() {
      currentLevel++;
    });
    _loadLevel(currentLevel);
  }

  void _restartGame() {
    print('🔄 Restarting game from level 1');
    setState(() {
      currentLevel = 1;
      lives = GameConfig.initialLives;
    });
    _loadLevel(1);
  }

  void _restartLevel() {
    print('🔄 Restarting current level');
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
    matrix.scale(newScale / currentScale);
    _transformationController.value = matrix;
  }

  void _zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = math.max(0.5, currentScale - 0.2);
    final matrix = _transformationController.value.clone();
    matrix.scale(newScale / currentScale);
    _transformationController.value = matrix;
  }

  @override
  Widget build(BuildContext context) {
    final cellSize = GameConfig.blockSize + GameConfig.blockGap;
    final boardWidth = cols * cellSize - GameConfig.blockGap;
    final boardHeight = rows * cellSize - GameConfig.blockGap;

    // Generate grid dots background
    final List<Widget> gridDots = [];
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        gridDots.add(
          Positioned(
            left: x * cellSize + (GameConfig.blockSize / 2) - 3,
            top: y * cellSize + (GameConfig.blockSize / 2) - 3,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }
    }

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
                                  ...gridDots,
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
                            child: Container(
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
                  color: Colors.black.withOpacity(0.1),
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
                  color: Colors.black.withOpacity(0.15),
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
                          color: Colors.black.withOpacity(0.2),
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
              color: Colors.black.withOpacity(0.15),
              offset: const Offset(0, 3),
              blurRadius: 2,
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
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
                color: Colors.black.withOpacity(0.15),
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
      onClose: () {},
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF6EBD75).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF6EBD75),
              size: 70,
            ),
          ),
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
          // Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Transform.rotate(
                        angle: value * math.pi * 2,
                        child: child,
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.star,
                    color: Color(0xFFFFD13B),
                    size: 50,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(0, 4),
                        blurRadius: 4,
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
                  // TODO: Implement actual ad reward logic here
                  setState(() {
                    lives = GameConfig.initialLives;
                    isGameOver = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('+3 Lives from Ad!')),
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
                  onChanged: (val) => setState(() => isVibrationEnabled = val),
                  activeColor: const Color(0xFF77D328),
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
                  onChanged: (val) => setState(() => isSoundEnabled = val),
                  activeColor: const Color(0xFF77D328),
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
        return CustomDialog(
          title: 'COIN STORE',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Get more coins to continue your game!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              ShinyButton(
                gradientColors: const [Color(0xFF5EA1F8), Color(0xFF246DF1)],
                borderColor: const Color(0xFF1B55C0),
                onPressed: () {
                  // TODO: Implement actual ad reward logic here
                  setState(() {
                    coins += 1000;
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('+1000 Coins earned!')),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.play_circle_filled, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'WATCH AD\n+1000 COINS',
                      textAlign: TextAlign.center,
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
                  if (passwordController.text == '1234') {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ManageLevelsScreen()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Incorrect password')),
                    );
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
          onClose: () => Navigator.of(context).pop(),
        );
      }
    );
  }
}
