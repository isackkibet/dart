import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/feed_category.dart';
import '../domain/video_exposure.dart';
import 'video_exposure_repository.dart';

class LocalViewedVideoStore implements VideoExposureRepository {
  static const _keyPrefix = 'yohpal_exposure_';
  static const _progressThreshold = 0.80;

  String _key(FeedCategory category) => '$_keyPrefix${category.name}';

  @override
  Future<void> recordExposure({
    required String videoId,
    required VideoExposureSource source,
    required double progress,
    required bool completed,
  }) async {
    if (!completed && progress < _progressThreshold) return;
    final prefs = await SharedPreferences.getInstance();
    for (final category in FeedCategory.values) {
      final raw = prefs.getString(_key(category));
      final Map<String, dynamic> stored =
          raw != null ? jsonDecode(raw) as Map<String, dynamic> : {};
      stored[videoId] = {
        'progress': progress,
        'completed': completed,
        'recordedAt': DateTime.now().toIso8601String(),
        'source': source.name,
      };
      await prefs.setString(_key(category), jsonEncode(stored));
    }
  }

  @override
  Future<Set<String>> loadAutomaticFeedExclusions({
    required FeedCategory category,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(category));
    if (raw == null) return {};
    final Map<String, dynamic> stored =
        jsonDecode(raw) as Map<String, dynamic>;
    return stored.keys.toSet();
  }

  @override
  Future<void> synchronize() async {
    // No-op for local store; server sync handled by backend.
  }
}
