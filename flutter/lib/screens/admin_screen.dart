import 'package:flutter/material.dart';
import '../models/block.dart' hide Block;
import '../data/levels.dart';
import '../utils/config.dart';
import '../widgets/shiny_button.dart';
import 'dart:math' as math;

class AdminScreen extends StatefulWidget {
  final LevelData? level;
  const AdminScreen({super.key, this.level});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late int rows;
  late int cols;
  
  // Currently selected tool
  Direction selectedDirection = Direction.up;
  Color selectedColor = GameConfig.blockColors[0];
  
  // Placed blocks
  late List<BlockData> placedBlocks;

  @override
  void initState() {
    super.initState();
    if (widget.level != null) {
      rows = widget.level!.rows;
      cols = widget.level!.cols;
      placedBlocks = List.from(widget.level!.blocks);
    } else {
      rows = 8;
      cols = 8;
      placedBlocks = [];
    }
  }

  // Random generator
  final TextEditingController _blockCountController = TextEditingController(text: '25');
  
  IconData _getIconForDirection(Direction dir) {
    switch (dir) {
      case Direction.up: return Icons.arrow_upward_rounded;
      case Direction.down: return Icons.arrow_downward_rounded;
      case Direction.left: return Icons.arrow_back_rounded;
      case Direction.right: return Icons.arrow_forward_rounded;
    }
  }

  void _handleCellTap(int x, int y) {
    setState(() {
      // Check if block exists
      final existingIndex = placedBlocks.indexWhere((b) => b.x == x && b.y == y);
      
      if (existingIndex != -1) {
        // Remove existing block
        placedBlocks.removeAt(existingIndex);
      } else {
        // Place new block
        placedBlocks.add(BlockData(
          x: x, 
          y: y, 
          direction: selectedDirection, 
          color: selectedColor,
        ));
      }
    });
  }

  void _saveLevel() async {
    if (placedBlocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please place at least one block!')),
      );
      return;
    }

    final newLevel = LevelData(
      id: widget.level?.id,
      rows: rows,
      cols: cols,
      blocks: List.from(placedBlocks),
    );

    await Levels.saveCustomLevel(newLevel);
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Level saved successfully! It is now Level ${Levels.totalLevels}.')),
    );
    
    Navigator.of(context).pop(); // Go back to game screen
  }

  @override
  Widget build(BuildContext context) {
    final cellSize = GameConfig.blockSize + GameConfig.blockGap;
    final boardWidth = cols * cellSize;
    final boardHeight = rows * cellSize;

    return Scaffold(
      backgroundColor: const Color(0xFFE8DFD0),
      appBar: AppBar(
        title: const Text('LEVEL EDITOR', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF8B4513),
        actions: [
          TextButton.icon(
            onPressed: _saveLevel,
            icon: const Icon(Icons.save, color: Color(0xFF8B4513)),
            label: const Text('SAVE', style: TextStyle(color: Color(0xFF8B4513), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Size controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                _buildSizeControl('Rows', rows, (val) {
                  setState(() {
                    rows = val.clamp(8, 20);
                    // Remove blocks outside bounds
                    placedBlocks.removeWhere((b) => b.y >= rows);
                  });
                }),
                _buildSizeControl('Cols', cols, (val) {
                  setState(() {
                    cols = val.clamp(8, 20);
                    // Remove blocks outside bounds
                    placedBlocks.removeWhere((b) => b.x >= cols);
                  });
                }),
              ],
            ),
          ),
          ),
          
          // Random Generator Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _blockCountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Random Blocks (e.g. 25)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _generateRandomLevel,
                  icon: const Icon(Icons.shuffle),
                  label: const Text('GENERATE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5BA3E0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ],
            ),
          ),
          
          // Palette - Direction
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text('DIRECTION', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: Direction.values.map((dir) {
                final isSelected = selectedDirection == dir;
                return GestureDetector(
                  onTap: () => setState(() => selectedDirection = dir),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black54 : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.black12,
                        width: 2,
                      ),
                    ),
                    child: Icon(_getIconForDirection(dir), color: isSelected ? Colors.white : Colors.black87, size: 20),
                  ),
                );
              }).toList(),
            ),
          ),

          // Palette - Colors
          const Padding(
            padding: EdgeInsets.only(top: 4.0),
            child: Text('COLOR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: GameConfig.blockColors.map((color) {
                final isSelected = selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => selectedColor = color),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected ? [
                        const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                      ] : [],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Grid editor
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final scaleX = constraints.maxWidth / (boardWidth + 40);
                  final scaleY = constraints.maxHeight / (boardHeight + 40);
                  final scale = math.min(scaleX, scaleY).clamp(0.2, 1.5);
                  
                  return InteractiveViewer(
                    minScale: 0.2,
                    maxScale: 3.0,
                    constrained: false,
                    boundaryMargin: const EdgeInsets.all(100),
                    child: SizedBox(
                      width: boardWidth,
                      height: boardHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Base grid dots
                          for (int r = 0; r < rows; r++)
                            for (int c = 0; c < cols; c++)
                              Positioned(
                                left: c * cellSize,
                                top: r * cellSize,
                                child: GestureDetector(
                                  onTap: () => _handleCellTap(c, r),
                                  child: Container(
                                    width: GameConfig.blockSize,
                                    height: GameConfig.blockSize,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(GameConfig.blockRadius),
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          
                          // Placed Blocks
                          ...placedBlocks.map((block) {
                            return Positioned(
                              left: block.x * cellSize,
                              top: block.y * cellSize,
                              child: GestureDetector(
                                onTap: () => _handleCellTap(block.x, block.y),
                                child: Container(
                                  width: GameConfig.blockSize,
                                  height: GameConfig.blockSize,
                                  decoration: BoxDecoration(
                                    color: block.color,
                                    borderRadius: BorderRadius.circular(GameConfig.blockRadius),
                                    boxShadow: [
                                      BoxShadow(
                                        color: block.color.withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      _getIconForDirection(block.direction),
                                      color: Colors.white,
                                      size: GameConfig.blockSize * 0.6,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Tap an empty cell to place an arrow. Tap an arrow to remove it.', style: TextStyle(color: Colors.black54)),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeControl(String label, int value, Function(int) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B4513))),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFE06652)),
            onPressed: () => onChanged(value - 1),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF6EBD75)),
            onPressed: () => onChanged(value + 1),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  void _generateRandomLevel() {
    final int requested = int.tryParse(_blockCountController.text) ?? 0;
    final int maxBlocks = rows * cols;

    if (requested <= 0 || requested > maxBlocks) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid count! Must be between 1 and $maxBlocks for this grid.')),
      );
      return;
    }

    // 1. Calculate center
    final double centerX = (cols - 1) / 2.0;
    final double centerY = (rows - 1) / 2.0;

    // 2. Sort all cells by distance to center
    List<Offset> allCells = [];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        allCells.add(Offset(c.toDouble(), r.toDouble()));
      }
    }
    
    allCells.sort((a, b) {
      final distA = math.pow(a.dx - centerX, 2) + math.pow(a.dy - centerY, 2);
      final distB = math.pow(b.dx - centerX, 2) + math.pow(b.dy - centerY, 2);
      return distA.compareTo(distB);
    });

    final targetCells = allCells.take(requested).toList();
    List<BlockData> newBlocks = [];

    // Inside-out generation (no recursion, no crashes)
    bool tryGenerate() {
      newBlocks.clear();
      // targetCells is already sorted by distance to center (closest first)
      for (var cell in targetCells) {
        final cx = cell.dx.toInt();
        final cy = cell.dy.toInt();
        
        List<Direction> dirs = Direction.values.toList()..shuffle();
        bool placed = false;
        
        for (var dir in dirs) {
          if (_isPathClear(cx, cy, dir, newBlocks)) {
            final randomColor = GameConfig.blockColors[math.Random().nextInt(GameConfig.blockColors.length)];
            newBlocks.add(BlockData(x: cx, y: cy, direction: dir, color: randomColor));
            placed = true;
            break;
          }
        }
        
        if (!placed) {
          return false; // Got stuck!
        }
      }
      return true;
    }

    bool success = false;
    for (int i = 0; i < 1000; i++) {
      if (tryGenerate()) {
        success = true;
        break;
      }
    }

    if (success) {
      setState(() {
        placedBlocks = newBlocks;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generated successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate a solvable level with this shape. Try again!')),
      );
    }
  }

  bool _isPathClear(int x, int y, Direction dir, List<BlockData> currentBlocks) {
    switch (dir) {
      case Direction.up:
        for (int checkY = y - 1; checkY >= 0; checkY--) {
          if (currentBlocks.any((b) => b.x == x && b.y == checkY)) return false;
        }
        return true;
      case Direction.down:
        for (int checkY = y + 1; checkY < rows; checkY++) {
          if (currentBlocks.any((b) => b.x == x && b.y == checkY)) return false;
        }
        return true;
      case Direction.left:
        for (int checkX = x - 1; checkX >= 0; checkX--) {
          if (currentBlocks.any((b) => b.y == y && b.x == checkX)) return false;
        }
        return true;
      case Direction.right:
        for (int checkX = x + 1; checkX < cols; checkX++) {
          if (currentBlocks.any((b) => b.y == y && b.x == checkX)) return false;
        }
        return true;
    }
  }
}
