import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../utils/config.dart';

class LevelData {
  String? id;
  int order;
  final int rows;
  final int cols;
  final List<BlockData> blocks;

  LevelData({
    this.id,
    this.order = 0,
    required this.rows,
    required this.cols,
    required this.blocks,
  });

  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'rows': rows,
      'cols': cols,
      'blocks': blocks.map((b) => b.toJson()).toList(),
    };
  }

  factory LevelData.fromJson(Map<String, dynamic> json, {String? id}) {
    return LevelData(
      id: id,
      order: json['order'] ?? 0,
      rows: json['rows'],
      cols: json['cols'],
      blocks: (json['blocks'] as List).map((b) => BlockData.fromJson(Map<String, dynamic>.from(b))).toList(),
    );
  }
}

class BlockData {
  final int x;
  final int y;
  final Direction direction;
  final Color color;

  const BlockData({
    required this.x,
    required this.y,
    required this.direction,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    String dirStr;
    switch (direction) {
      case Direction.up: dirStr = 'N'; break;
      case Direction.down: dirStr = 'S'; break;
      case Direction.left: dirStr = 'W'; break;
      case Direction.right: dirStr = 'E'; break;
    }
    return {
      'x': x,
      'y': y,
      'dir': dirStr,
      'color': color.toARGB32(),
    };
  }

  factory BlockData.fromJson(Map<String, dynamic> json) {
    Direction dir;
    switch (json['dir']) {
      case 'N': dir = Direction.up; break;
      case 'S': dir = Direction.down; break;
      case 'W': dir = Direction.left; break;
      case 'E': dir = Direction.right; break;
      default: dir = Direction.up; // Fallback
    }
    return BlockData(
      x: json['x'],
      y: json['y'],
      direction: dir,
      color: Color(json['color']),
    );
  }
}

class Levels {
  static final List<LevelData> allLevels = [];

  static List<LevelData> customLevels = [];

  static Future<void> loadCustomLevels() async {
    try {
      final ref = FirebaseDatabase.instance.ref('levels');
      final snapshot = await ref.get();
      
      customLevels.clear();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          try {
            final levelMap = Map<String, dynamic>.from(value as Map);
            customLevels.add(LevelData.fromJson(levelMap, id: key.toString()));
          } catch (e) {
            debugPrint('Error parsing level $key: $e');
          }
        });
        
        // Sort levels by their order
        customLevels.sort((a, b) => a.order.compareTo(b.order));
      }
    } catch (e) {
      debugPrint('Error loading custom levels from Firebase: $e');
    }
  }

  static Future<void> saveCustomLevel(LevelData level) async {
    final ref = FirebaseDatabase.instance.ref('levels');
    if (level.id != null) {
      // Update existing
      await ref.child(level.id!).set(level.toJson());
      // Update local cache
      final index = customLevels.indexWhere((l) => l.id == level.id);
      if (index != -1) {
        customLevels[index] = level;
      }
    } else {
      // Create new
      final newRef = ref.push();
      level.id = newRef.key;
      level.order = customLevels.length; // Add to end
      await newRef.set(level.toJson());
      customLevels.add(level);
    }
  }

  static Future<void> deleteCustomLevel(String id) async {
    await FirebaseDatabase.instance.ref('levels').child(id).remove();
    customLevels.removeWhere((l) => l.id == id);
  }

  static Future<void> updateLevelsOrder(List<LevelData> reorderedLevels) async {
    customLevels = reorderedLevels;
    
    // Update local orders
    for (int i = 0; i < customLevels.length; i++) {
      customLevels[i].order = i;
    }
    
    // Batch update to Firebase
    Map<String, dynamic> updates = {};
    for (var level in customLevels) {
      if (level.id != null) {
        updates['${level.id}/order'] = level.order;
      }
    }
    
    if (updates.isNotEmpty) {
      await FirebaseDatabase.instance.ref('levels').update(updates);
    }
  }

  static LevelData? getLevel(int levelNumber) {
    final int total = totalLevels;
    if (levelNumber < 1 || levelNumber > total) {
      return null;
    }
    if (levelNumber <= allLevels.length) {
      return allLevels[levelNumber - 1];
    } else {
      return customLevels[levelNumber - 1 - allLevels.length];
    }
  }

  static int get totalLevels => allLevels.length + customLevels.length;
}
