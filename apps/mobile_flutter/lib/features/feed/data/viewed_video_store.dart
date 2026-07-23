import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class ViewedVideoStore {
  Future<void> markViewed({
    required String videoId,
    required double progress,
    required DateTime viewedAt,
  });

  Future<Set<String>> loadAutomaticFeedExclusions();

  Future<void> removeFromExclusions(String videoId);
}

class SharedPreferencesViewedVideoStore implements ViewedVideoStore {
  static const _exclusionsKey = 'yohpal_feed_exclusions';
  static const _progressThreshold = 80.0;

  @override
  Future<void> markViewed({
    required String videoId,
    required double progress,
    required DateTime viewedAt,
  }) async {
    if (progress < _progressThreshold) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_exclusionsKey);
    final Map<String, dynamic> stored =
        raw != null ? jsonDecode(raw) as Map<String, dynamic> : {};
    stored[videoId] = viewedAt.toIso8601String();
    await prefs.setString(_exclusionsKey, jsonEncode(stored));
  }

  @override
  Future<Set<String>> loadAutomaticFeedExclusions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_exclusionsKey);
    if (raw == null) return {};
    final Map<String, dynamic> stored =
        jsonDecode(raw) as Map<String, dynamic>;
    return stored.keys.toSet();
  }

  @override
  Future<void> removeFromExclusions(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_exclusionsKey);
    if (raw == null) return;
    final Map<String, dynamic> stored =
        jsonDecode(raw) as Map<String, dynamic>;
    stored.remove(videoId);
    await prefs.setString(_exclusionsKey, jsonEncode(stored));
  }
}
