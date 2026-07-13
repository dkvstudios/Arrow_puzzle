import 'package:flutter/material.dart';

class GameConfig {
  // Game Settings
  static const int initialLives = 3;
  
  // Block Settings
  static const double blockSize = 80.0;
  static const double blockGap = 8.0;
  static const double blockRadius = 12.0;
  
  // Animation Durations
  static const Duration blockMoveDuration = Duration(milliseconds: 700);
  static const Duration shakeDuration = Duration(milliseconds: 400);
  static const Duration popupDuration = Duration(milliseconds: 300);
  static const Duration victoryDelay = Duration(milliseconds: 1500);
  
  // Colors - Matching website exactly
  static const Color backgroundColor = Color(0xFFF4F4F4);
  static const Color bgGradientStart = Color(0xFFF4F4F4);
  static const Color bgGradientEnd = Color(0xFFF4F4F4);
  static const Color cream = Color(0xFFFFFFFF);
  static const Color creamDark = Color(0xFFE0E0E0);
  
  // Block Colors - HSL converted to RGB
  static const List<Color> blockColors = [
    Color(0xFFE06652), // Red-Orange - hsl(10, 80%, 60%)
    Color(0xFFF5A742), // Orange - hsl(45, 85%, 55%)
    Color(0xFFF5EB5C), // Yellow - hsl(60, 80%, 60%)
    Color(0xFF6EBD75), // Green - hsl(120, 60%, 55%)
    Color(0xFF40C9D9), // Cyan - hsl(180, 70%, 50%)
    Color(0xFF5BA3E0), // Blue - hsl(210, 75%, 55%)
    Color(0xFFA366D9), // Purple - hsl(270, 70%, 60%)
    Color(0xFFE066B8), // Pink - hsl(330, 75%, 60%)
    Color(0xFF3F51B5), // Indigo (9th color)
  ];
  
  // Shadow
  static const Color shadow = Color(0x1A000000);
  static const Color shadowStrong = Color(0x26000000);
  
  // Particle Settings
  static const int particleCount = 15;
  static const int confettiCount = 30;
  
  // Easing Curves
  // Website uses cubic-bezier(0.4, 0, 0.8, 0.6) for fly-off animation
  static const Curve blockMoveCurve = Curves.easeOutExpo;
  static const Curve popupCurve = Curves.easeOutBack;
}

enum Direction {
  up,
  down,
  left,
  right,
}

extension DirectionExtension on Direction {
  IconData get icon {
    switch (this) {
      case Direction.up:
        return Icons.arrow_upward;
      case Direction.down:
        return Icons.arrow_downward;
      case Direction.left:
        return Icons.arrow_back;
      case Direction.right:
        return Icons.arrow_forward;
    }
  }
  
  String get name {
    switch (this) {
      case Direction.up:
        return 'up';
      case Direction.down:
        return 'down';
      case Direction.left:
        return 'left';
      case Direction.right:
        return 'right';
    }
  }
}
