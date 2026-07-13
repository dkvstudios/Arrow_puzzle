import 'package:flutter/material.dart';
import '../utils/config.dart';

class Block {
  final String id; // Unique identifier for tracking
  final int x;
  final int y;
  final Direction direction;
  final Color color;
  bool removed;
  bool isAnimating;
  bool isShaking;
  
  // Animation properties
  double animProgress;
  Offset? targetPosition;
  double opacity;
  double scale;
  
  // Shake animation
  double shakeOffset;

  Block({
    String? id,
    required this.x,
    required this.y,
    required this.direction,
    required this.color,
    this.removed = false,
    this.isAnimating = false,
    this.isShaking = false,
    this.animProgress = 0.0,
    this.targetPosition,
    this.opacity = 1.0,
    this.scale = 1.0,
    this.shakeOffset = 0.0,
  }) : id = id ?? '${x}_${y}_${DateTime.now().microsecondsSinceEpoch}';

  /// Check if block can move in its direction
  bool canMove(List<List<bool>> grid, int rows, int cols) {
    if (removed) return false;

    switch (direction) {
      case Direction.up:
        for (int checkY = y - 1; checkY >= 0; checkY--) {
          if (grid[checkY][x]) return false;
        }
        return true;

      case Direction.down:
        for (int checkY = y + 1; checkY < rows; checkY++) {
          if (grid[checkY][x]) return false;
        }
        return true;

      case Direction.left:
        for (int checkX = x - 1; checkX >= 0; checkX--) {
          if (grid[y][checkX]) return false;
        }
        return true;

      case Direction.right:
        for (int checkX = x + 1; checkX < cols; checkX++) {
          if (grid[y][checkX]) return false;
        }
        return true;
    }
  }

  /// Get target position for fly-off animation
  Offset getTargetPosition(int rows, int cols) {
    final cellSize = GameConfig.blockSize + GameConfig.blockGap;
    
    switch (direction) {
      case Direction.up:
        return Offset(x * cellSize, y * cellSize - cellSize * 5.0);
      case Direction.down:
        return Offset(x * cellSize, y * cellSize + cellSize * 5.0);
      case Direction.left:
        return Offset(x * cellSize - cellSize * 5.0, y * cellSize);
      case Direction.right:
        return Offset(x * cellSize + cellSize * 5.0, y * cellSize);
    }
  }

  /// Create a copy with updated properties
  Block copyWith({
    bool? removed,
    bool? isAnimating,
    bool? isShaking,
    double? animProgress,
    Offset? targetPosition,
    double? opacity,
    double? scale,
    double? shakeOffset,
  }) {
    return Block(
      id: id, // Preserve the ID
      x: x,
      y: y,
      direction: direction,
      color: color,
      removed: removed ?? this.removed,
      isAnimating: isAnimating ?? this.isAnimating,
      isShaking: isShaking ?? this.isShaking,
      animProgress: animProgress ?? this.animProgress,
      targetPosition: targetPosition ?? this.targetPosition,
      opacity: opacity ?? this.opacity,
      scale: scale ?? this.scale,
      shakeOffset: shakeOffset ?? this.shakeOffset,
    );
  }
}
