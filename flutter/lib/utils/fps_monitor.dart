import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:developer' as developer;

/// FPS Monitor - Prints FPS to console every second
class FPSMonitor extends StatefulWidget {
  final Widget child;
  
  const FPSMonitor({super.key, required this.child});

  @override
  State<FPSMonitor> createState() => _FPSMonitorState();
}

class _FPSMonitorState extends State<FPSMonitor> {
  int _frameCount = 0;
  DateTime _lastTime = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback(_onFrame);
  }

  void _onFrame(Duration timestamp) {
    if (!mounted) return;
    
    _frameCount++;
    final now = DateTime.now();
    final diff = now.difference(_lastTime);
    
    // Calculate FPS every second
    if (diff.inMilliseconds >= 1000) {
      final fps = (_frameCount * 1000 / diff.inMilliseconds).round();
      developer.log('🎮 FPS: $fps', name: 'Performance');
      
      _frameCount = 0;
      _lastTime = now;
    }
    
    // Schedule next frame callback
    SchedulerBinding.instance.addPostFrameCallback(_onFrame);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
