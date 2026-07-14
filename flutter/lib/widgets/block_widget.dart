import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/block.dart';
import '../utils/config.dart';

class BlockWidget extends StatelessWidget {
  final Block block;
  final VoidCallback onTap;
  final double cellSize;

  const BlockWidget({
    super.key,
    required this.block,
    required this.onTap,
    required this.cellSize,
  });

  @override
  Widget build(BuildContext context) {
    if (block.removed && !block.isAnimating) {
      print('🚫 BlockWidget: Hiding removed block at (${block.x}, ${block.y})');
      return const SizedBox.shrink();
    }

    // Calculate base position
    double left = block.x * cellSize;
    double top = block.y * cellSize;

    // Apply shake offset
    if (block.isShaking) {
      left += block.shakeOffset * math.sin(block.animProgress * math.pi * 6);
      top += block.shakeOffset * math.cos(block.animProgress * math.pi * 6) * 0.5;
    }

    // Apply fly-off animation to reach targetPosition
    if (block.isAnimating && block.targetPosition != null) {
      final progress = block.animProgress;
      left = left + (block.targetPosition!.dx - (block.x * cellSize)) * progress;
      top = top + (block.targetPosition!.dy - (block.y * cellSize)) * progress;
    }

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: block.isAnimating || block.removed ? null : onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (block.isAnimating) _buildTrail(),
            Opacity(
              opacity: block.opacity,
              child: Transform.scale(
                scale: block.scale,
                child: Container(
                  width: GameConfig.blockSize,
                  height: GameConfig.blockSize,
                  decoration: BoxDecoration(
                      color: block.color,
                      borderRadius: BorderRadius.circular(GameConfig.blockRadius),
                      boxShadow: [
                        // Thick bottom bevel
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          offset: const Offset(0, 5),
                          blurRadius: 0,
                        ),
                        // Drop shadow
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          offset: const Offset(0, 8),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(GameConfig.blockRadius),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.5),
                            Colors.white.withValues(alpha: 0.1),
                            Colors.black.withValues(alpha: 0.15),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: GameConfig.blockSize * 0.5, // 50% of block size
                          height: GameConfig.blockSize * 0.5,
                          child: CustomPaint(
                            painter: ArrowPainter(
                              direction: block.direction,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrail() {
    if (block.animProgress == 0) return const SizedBox.shrink();

    Alignment begin = Alignment.center;
    Alignment end = Alignment.center;
    double width = GameConfig.blockSize;
    double height = GameConfig.blockSize;
    double offsetX = 0;
    double offsetY = 0;

    double maxTrailLength = 120.0;
    double currentTrailLength = maxTrailLength * block.animProgress;

    switch (block.direction) {
      case Direction.up:
        width = GameConfig.blockSize;
        height = currentTrailLength;
        begin = Alignment.topCenter;
        end = Alignment.bottomCenter;
        offsetY = GameConfig.blockSize / 2; 
        offsetX = 0;
        break;
      case Direction.down:
        width = GameConfig.blockSize;
        height = currentTrailLength;
        begin = Alignment.bottomCenter;
        end = Alignment.topCenter;
        offsetY = (GameConfig.blockSize / 2) - currentTrailLength; 
        offsetX = 0;
        break;
      case Direction.left:
        height = GameConfig.blockSize;
        width = currentTrailLength;
        begin = Alignment.centerLeft;
        end = Alignment.centerRight;
        offsetX = GameConfig.blockSize / 2;
        offsetY = 0;
        break;
      case Direction.right:
        height = GameConfig.blockSize;
        width = currentTrailLength;
        begin = Alignment.centerRight;
        end = Alignment.centerLeft;
        offsetX = (GameConfig.blockSize / 2) - currentTrailLength;
        offsetY = 0;
        break;
    }

    return Positioned(
      left: offsetX,
      top: offsetY,
      child: Opacity(
        opacity: block.opacity,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GameConfig.blockRadius),
            gradient: LinearGradient(
              begin: begin,
              end: end,
              colors: [
                Colors.yellow,
                Colors.yellow.withValues(alpha: 0.0),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.yellow.withValues(alpha: 0.6),
                blurRadius: 12,
                spreadRadius: 2,
              )
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter for arrows matching website design
class ArrowPainter extends CustomPainter {
  final Direction direction;
  final Color color;

  ArrowPainter({
    required this.direction,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Scale to 24x24 viewBox (website uses viewBox="0 0 24 24")
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale);

    final path = Path();

    switch (direction) {
      case Direction.up:
        // Line: x1="12" y1="19" x2="12" y2="5"
        path.moveTo(12, 19);
        path.lineTo(12, 5);
        // Polyline: points="5 12 12 5 19 12"
        path.moveTo(5, 12);
        path.lineTo(12, 5);
        path.lineTo(19, 12);
        break;

      case Direction.down:
        // Line: x1="12" y1="5" x2="12" y2="19"
        path.moveTo(12, 5);
        path.lineTo(12, 19);
        // Polyline: points="19 12 12 19 5 12"
        path.moveTo(19, 12);
        path.lineTo(12, 19);
        path.lineTo(5, 12);
        break;

      case Direction.left:
        // Line: x1="19" y1="12" x2="5" y2="12"
        path.moveTo(19, 12);
        path.lineTo(5, 12);
        // Polyline: points="12 19 5 12 12 5"
        path.moveTo(12, 19);
        path.lineTo(5, 12);
        path.lineTo(12, 5);
        break;

      case Direction.right:
        // Line: x1="5" y1="12" x2="19" y2="12"
        path.moveTo(5, 12);
        path.lineTo(19, 12);
        // Polyline: points="12 5 19 12 12 19"
        path.moveTo(12, 5);
        path.lineTo(19, 12);
        path.lineTo(12, 19);
        break;
    }

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(ArrowPainter oldDelegate) {
    return oldDelegate.direction != direction || oldDelegate.color != color;
  }
}
