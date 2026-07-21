import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';
import 'utils/ad_service.dart';
import 'utils/progress_service.dart';
import 'utils/sound_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await AdService.initialize();
  await ProgressService.instance.init();
  await SoundService.instance.init();
  
  // Lock orientation to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFE8DFD0),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const ArrowPuzzleApp());
}

class ArrowPuzzleApp extends StatelessWidget {
  const ArrowPuzzleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arrow Puzzle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Fredoka',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B9BD5),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}