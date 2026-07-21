import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/block.dart';
import '../utils/config.dart';

class BlockWidget extends StatefulWidget {
  final Block block;
  final VoidCallback onTap;
  final double cellSize;
  final bool showHint; // Whether to show hint animation

  const BlockWidget({
    super.key,
    required this.block,
    required this.onTap,
    required this.cellSize,
    this.showHint = false,
  });

  @override
  State<BlockWidget> createState() => _BlockWidgetState();
}

class _BlockWidgetState extends State<BlockWidget> with SingleTickerProviderStateMixin {
  late AnimationController _hintController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _hintController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Pulse scale animation (1.0 -> 1.15 -> 1.0)
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_hintController);

    // Rotate animation (0 -> 2π)
    _rotateAnimation = Tween<double>(begin: 0, end: math.pi * 2).animate(_hintController);
  }

  @override
  void didUpdateWidget(BlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showHint && !oldWidget.showHint) {
      _hintController.repeat();
    } else if (!widget.showHint && oldWidget.showHint) {
      _hintController.stop();
      _hintController.reset();
    }
  }

  @override
  void dispose() {
    _hintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.block.removed && !widget.block.isAnimating) {
      return const SizedBox.shrink();
    }

    // Calculate base position
    double left = widget.block.x * widget.cellSize;
    double top = widget.block.y * widget.cellSize;

    // Apply shake offset
    if (widget.block.isShaking) {
      left += widget.block.shakeOffset * math.sin(widget.block.animProgress * math.pi * 6);
      top += widget.block.shakeOffset * math.cos(widget.block.animProgress * math.pi * 6) * 0.5;
    }

    // Apply fly-off animation to reach targetPosition
    if (widget.block.isAnimating && widget.block.targetPosition != null) {
      final progress = widget.block.animProgress;
      left = left + (widget.block.targetPosition!.dx - (widget.block.x * widget.cellSize)) * progress;
      top = top + (widget.block.targetPosition!.dy - (widget.block.y * widget.cellSize)) * progress;
    }

    return Positioned(
      left: left,
      top: top,
      child: RepaintBoundary(
        child: GestureDetector(
          onTap: widget.block.isAnimating || widget.block.removed ? null : widget.onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
            if (widget.block.isAnimating) _buildTrail(),
            // Pulsing scale animation for the hint block
            AnimatedBuilder(
              animation: widget.showHint ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.showHint ? _pulseAnimation.value : 1.0,
                  child: Opacity(
                    opacity: widget.block.opacity,
                    child: Transform.scale(
                      scale: widget.block.scale,
                      child: Container(
                        width: GameConfig.blockSize,
                        height: GameConfig.blockSize,
                        decoration: BoxDecoration(
                            color: widget.block.color,
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
                              // Hint glow effect
                              if (widget.showHint)
                                BoxShadow(
                                  color: const Color(0xFFF5A742).withValues(alpha: 0.6),
                                  blurRadius: 20,
                                  spreadRadius: 4,
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
                                    direction: widget.block.direction,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildTrail() {
    if (widget.block.animProgress == 0) return const SizedBox.shrink();

    Alignment begin = Alignment.center;
    Alignment end = Alignment.center;
    double width = GameConfig.blockSize;
    double height = GameConfig.blockSize;
    double offsetX = 0;
    double offsetY = 0;

    double maxTrailLength = 120.0;
    double currentTrailLength = maxTrailLength * widget.block.animProgress;

    switch (widget.block.direction) {
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
        opacity: widget.block.opacity,
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
