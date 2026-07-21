import 'package:flutter/material.dart';
import 'dart:async';
import '../data/levels.dart';
import '../utils/ad_config.dart';
import '../utils/ad_service.dart';
import 'game_screen.dart';
import 'manage_levels_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _loadingText = "Fetching levels...";
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    try {
      // Step 1 — Sync ad IDs from Firebase (falls back to cache if offline)
      setState(() => _loadingText = "Syncing config...");
      await AdConfig.instance.loadAndSync();

      // Step 2 — Preload ads now that we have the correct IDs
      AdService.instance.loadRewardedAd();
      AdService.instance.loadInterstitialAd();

      // Step 3 — Load game levels
      setState(() => _loadingText = "Fetching levels...");
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
          // Small delay to show logo before transition
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const GameScreen()),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingText = "Failed to load: $e";
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F1DA),
      body: Center(
        child: _hasError
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _loadingText,
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 16,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                        _loadingText = "Retrying...";
                      });
                      _loadData();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text("Retry"),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const ManageLevelsScreen()),
                      );
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text("Go to Admin Panel"),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 350),
                  Image.asset(
                    'assets/logo.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 200),
                  const Text(
                    'DKV Studio',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8B4513),
                      letterSpacing: 1,
                    ),
                  ),
                  Spacer(),
                ],
              ),
      ),
    );
  }
}
