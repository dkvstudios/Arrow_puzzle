import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// Handles local SQLite storage for user game progress.
///
/// Stores:
///   - current_level : the level the user is currently on
///   - coins         : total coins earned
class ProgressService {
  static ProgressService? _instance;
  static ProgressService get instance => _instance ??= ProgressService._();
  ProgressService._();

  static const String _dbName    = 'arrow_progress.db';
  static const String _tableName = 'progress';
  static const int    _dbVersion = 1;

  Database? _db;
  
  // Batching mechanism for performance
  Timer? _saveTimer;
  final Map<String, int> _pendingSaves = {};

  /// Open (or create) the database. Call once at startup.
  Future<void> init() async {
    if (_db != null) return;

    final dbPath = await getDatabasesPath();
    final path   = join(dbPath, _dbName);

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            key   TEXT PRIMARY KEY,
            value INTEGER NOT NULL
          )
        ''');
        // Insert defaults
        await db.insert(_tableName, {'key': 'current_level', 'value': 1});
        await db.insert(_tableName, {'key': 'coins',         'value': 0});
        debugPrint('✅ ProgressService: DB created with defaults');
      },
      onOpen: (db) {
        debugPrint('✅ ProgressService: DB opened');
      },
    );
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  Future<int> _get(String key, int defaultValue) async {
    await init();
    final rows = await _db!.query(
      _tableName,
      where: 'key = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return defaultValue;
    return rows.first['value'] as int;
  }

  Future<void> _set(String key, int value) async {
    await init();
    await _db!.insert(
      _tableName,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // debugPrint('💾 ProgressService: $key = $value'); // Removed for performance
  }

  /// Batched save - schedules a save operation without blocking UI
  void _scheduleSave(String key, int value) {
    _pendingSaves[key] = value;
    
    // Cancel existing timer and start a new one
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 300), () async {
      if (_pendingSaves.isEmpty) return;
      
      // Copy pending saves and clear
      final saves = Map<String, int>.from(_pendingSaves);
      _pendingSaves.clear();
      
      // Batch save all pending values
      await init();
      final batch = _db!.batch();
      for (final entry in saves.entries) {
        batch.insert(
          _tableName,
          {'key': entry.key, 'value': entry.value},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Returns the saved current level (defaults to 1 on first launch).
  Future<int> getCurrentLevel() => _get('current_level', 1);

  /// Saves the current level locally (batched for performance).
  void saveCurrentLevel(int level) => _scheduleSave('current_level', level);
  
  /// Saves the current level immediately (use only when app is closing).
  Future<void> saveCurrentLevelSync(int level) => _set('current_level', level);

  /// Returns the saved coin count.
  Future<int> getCoins() => _get('coins', 0);

  /// Saves the coin count locally (batched for performance).
  void saveCoins(int coins) => _scheduleSave('coins', coins);
  
  /// Saves the coin count immediately (use only when app is closing).
  Future<void> saveCoinsSync(int coins) => _set('coins', coins);

  /// Returns vibration setting (defaults to true/1).
  Future<bool> getVibration() async => (await _get('vibration', 1)) == 1;

  /// Saves vibration setting.
  Future<void> saveVibration(bool enabled) => _set('vibration', enabled ? 1 : 0);

  /// Returns sound setting (defaults to true/1).
  Future<bool> getSound() async => (await _get('sound', 1)) == 1;

  /// Saves sound setting.
  Future<void> saveSound(bool enabled) => _set('sound', enabled ? 1 : 0);

  /// Load all progress at once. Returns a map with 'level', 'coins', 'vibration', 'sound'.
  Future<Map<String, int>> loadAll() async {
    final level      = await getCurrentLevel();
    final coins      = await getCoins();
    final vibration  = await _get('vibration', 1);
    final sound      = await _get('sound', 1);
    // Removed debug prints for performance
    // print('════════════════════════════════════════');
    // print('📂 ProgressService — LOADED FROM SQLITE');
    // print('   Current Level : $level');
    // print('   Coins         : $coins');
    // print('   Vibration     : ${vibration == 1}');
    // print('   Sound         : ${sound == 1}');
    // print('════════════════════════════════════════');
    return {
      'level':     level,
      'coins':     coins,
      'vibration': vibration,
      'sound':     sound,
    };
  }

  /// Reset all progress back to defaults (level 1, 0 coins).
  Future<void> resetAll() async {
    await _set('current_level', 1);
    await _set('coins', 0);
    debugPrint('🔄 ProgressService: Progress reset to defaults');
  }
}
