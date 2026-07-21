import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle all game sound effects
/// Alternates between Tring-1 and Tring-2 for arrow taps
class SoundService {
  static final SoundService instance = SoundService._internal();
  factory SoundService() => instance;
  SoundService._internal();

  // Pools for alternating arrow sounds to avoid source loading overhead
  final List<AudioPlayer> _tring1Pool = [];
  final List<AudioPlayer> _tring2Pool = [];
  static const int _poolSize = 2; // 2 of each is enough for 4 concurrent tap sounds
  int _tring1Index = 0;
  int _tring2Index = 0;

  // Separate players for other sounds
  final AudioPlayer _flyPlayer = AudioPlayer();
  final AudioPlayer _dialogPlayer = AudioPlayer();
  final AudioPlayer _touchPlayer = AudioPlayer();

  // Track which tring sound to play next (alternates between 1 and 2)
  int _currentTringIndex = 1;

  // Sound enabled state (synced with game settings)
  bool _isSoundEnabled = true;

  /// Initialize sound service and load settings
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
    
    final audioContext = AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.game,
        audioFocus: AndroidAudioFocus.none,
      ),
    );

    // Set global context (optional, but good for all players)
    await AudioPlayer.global.setAudioContext(audioContext);

    // Pre-load pools for rapid tapping
    for (int i = 0; i < _poolSize; i++) {
      final p1 = AudioPlayer();
      await p1.setAudioContext(audioContext);
      await p1.setReleaseMode(ReleaseMode.stop);
      await p1.setPlayerMode(PlayerMode.lowLatency);
      await p1.setSourceAsset('audio/Tring-1.mp3');
      _tring1Pool.add(p1);

      final p2 = AudioPlayer();
      await p2.setAudioContext(audioContext);
      await p2.setReleaseMode(ReleaseMode.stop);
      await p2.setPlayerMode(PlayerMode.lowLatency);
      await p2.setSourceAsset('audio/Tring-2.mp3');
      _tring2Pool.add(p2);
    }
    
    // Pre-load other sounds
    await _flyPlayer.setAudioContext(audioContext);
    await _flyPlayer.setReleaseMode(ReleaseMode.stop);
    await _flyPlayer.setPlayerMode(PlayerMode.lowLatency);
    await _flyPlayer.setSourceAsset('audio/fly.mp3');

    await _dialogPlayer.setAudioContext(audioContext);
    await _dialogPlayer.setReleaseMode(ReleaseMode.stop);
    await _dialogPlayer.setPlayerMode(PlayerMode.lowLatency);
    await _dialogPlayer.setSourceAsset('audio/dialog.mp3');

    await _touchPlayer.setAudioContext(audioContext);
    await _touchPlayer.setReleaseMode(ReleaseMode.stop);
    await _touchPlayer.setPlayerMode(PlayerMode.lowLatency);
    await _touchPlayer.setSourceAsset('audio/touch.mp3');
  }

  /// Update sound enabled state
  void setSoundEnabled(bool enabled) {
    _isSoundEnabled = enabled;
  }

  /// Get current sound enabled state
  bool get isSoundEnabled => _isSoundEnabled;

  /// Play alternating arrow tap sound (Tring-1 → Tring-2 → Tring-1 → ...)
  void playArrowTap() {
    if (!_isSoundEnabled) return;

    try {
      if (_currentTringIndex == 1) {
        final player = _tring1Pool[_tring1Index];
        _tring1Index = (_tring1Index + 1) % _poolSize;
        player.stop().then((_) => player.resume()).ignore();
      } else {
        final player = _tring2Pool[_tring2Index];
        _tring2Index = (_tring2Index + 1) % _poolSize;
        player.stop().then((_) => player.resume()).ignore();
      }
      
      // Alternate for next tap: 1 → 2 → 1 → 2 ...
      _currentTringIndex = _currentTringIndex == 1 ? 2 : 1;
    } catch (e) {
      // Silent fail
    }
  }

  /// Play fly-off sound when arrow exits screen
  void playFlyOff() {
    if (!_isSoundEnabled) return;

    try {
      _flyPlayer.stop().then((_) => _flyPlayer.resume()).ignore();
    } catch (e) {
      // Silent fail
    }
  }

  /// Play dialog open sound (settings, game over, victory)
  void playDialogOpen() {
    if (!_isSoundEnabled) return;

    try {
      _dialogPlayer.stop().then((_) => _dialogPlayer.resume()).ignore();
    } catch (e) {
      // Silent fail
    }
  }

  /// Play touch sound (button taps, UI interactions)
  void playTouch() {
    if (!_isSoundEnabled) return;

    try {
      _touchPlayer.stop().then((_) => _touchPlayer.resume()).ignore();
    } catch (e) {
      // Silent fail
    }
  }

  /// Reset tring alternation (useful when starting new level)
  void resetTringSequence() {
    _currentTringIndex = 1;
  }

  /// Stop all sounds (useful for pause/game over)
  Future<void> stopAllSounds() async {
    for (var player in _tring1Pool) {
      await player.stop();
    }
    for (var player in _tring2Pool) {
      await player.stop();
    }
    await _flyPlayer.stop();
    await _dialogPlayer.stop();
    await _touchPlayer.stop();
  }

  /// Dispose all audio players
  void dispose() {
    for (var player in _tring1Pool) {
      player.dispose();
    }
    for (var player in _tring2Pool) {
      player.dispose();
    }
    _flyPlayer.dispose();
    _dialogPlayer.dispose();
    _touchPlayer.dispose();
  }
}
