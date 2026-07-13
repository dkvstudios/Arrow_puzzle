import 'package:flutter/material.dart';
import 'dart:async';
import '../data/levels.dart';
import 'game_screen.dart';
import 'manage_levels_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  String _loadingText = "Fetching levels...";
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    
    _loadData();
  }
  
  Future<void> _loadData() async {
    try {
      await Levels.loadCustomLevels();
      
      if (Levels.customLevels.isEmpty) {
        if (mounted) {
          setState(() {
            _loadingText = "No levels found in database.";
            _hasError = true;
          });
        }
      } else {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const GameScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingText = "Failed to load levels: $e";
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _animation,
              child: const Icon(
                Icons.arrow_upward_rounded,
                size: 80,
                color: Color(0xFF5BA3E0),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "ARROW PUZZLE",
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF8B4513),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 48),
            if (!_hasError) const CircularProgressIndicator(color: Color(0xFFE06652)),
            const SizedBox(height: 16),
            Text(
              _loadingText,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 16,
                color: _hasError ? Colors.red : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (_hasError) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const ManageLevelsScreen()),
                  );
                },
                icon: const Icon(Icons.settings),
                label: const Text("Go to Admin Panel"),
              )
            ]
          ],
        ),
      ),
    );
  }
}
