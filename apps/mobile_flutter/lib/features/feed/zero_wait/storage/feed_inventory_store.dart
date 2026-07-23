import 'dart:convert';
import 'package:hive_ce/hive.dart';
import '../models/preload_video.dart';

abstract interface class FeedInventoryStore {
  Future<void> initialize();
  Future<List<PreloadVideo>> readAll();
  Future<void> replaceAll(List<PreloadVideo> videos);
  Future<int> count();
  Future<void> clear();
}

/// Hive-backed inventory store — significantly faster than SharedPreferences
/// for 100+ records because it avoids JSON parse on every hot restart.
final class HiveFeedInventoryStore implements FeedInventoryStore {
  static const _boxName = 'yohpal_zero_wait_feed_inventory_v1';
  static const _inventoryKey = 'videos';

  Box<String>? _box;

  @override
  Future<void> initialize() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  @override
  Future<List<PreloadVideo>> readAll() async {
    final box = _box;
    if (box == null) return [];
    try {
      final raw = box.get(_inventoryKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(PreloadVideo.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> replaceAll(List<PreloadVideo> videos) async {
    final box = _box;
    if (box == null) return;
    try {
      final encoded = jsonEncode(videos.map((v) => v.toJson()).toList());
      await box.put(_inventoryKey, encoded);
    } catch (_) {}
  }

  @override
  Future<int> count() async => (await readAll()).length;

  @override
  Future<void> clear() async {
    try {
      await _box?.delete(_inventoryKey);
    } catch (_) {}
  }
}
