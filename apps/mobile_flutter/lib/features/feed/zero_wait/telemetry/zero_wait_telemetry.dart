import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Telemetry interface for the zero-wait buffer system.
abstract interface class ZeroWaitTelemetry {
  // Inventory lifecycle
  static const inventoryReady         = 'zw_inventory_ready';
  static const bufferBelowMinimum     = 'zw_buffer_below_minimum';
  static const replenishmentStarted   = 'zw_replenishment_started';
  static const replenishmentCompleted = 'zw_replenishment_completed';
  // Controller lifecycle
  static const hotControllerReady     = 'zw_hot_controller_ready';
  static const firstFrame             = 'zw_first_frame';
  static const spinnerShown           = 'zw_spinner_shown';
  static const playbackStall          = 'zw_playback_stall';
  // Cache
  static const cacheHit               = 'zw_cache_hit';
  static const cacheMiss              = 'zw_cache_miss';
  static const diskCacheHit           = 'zw_disk_cache_hit';
  static const diskCacheMiss          = 'zw_disk_cache_miss';
  // Warmup
  static const warmingStarted         = 'zw_warming_started';
  static const warmingComplete        = 'zw_warming_complete';
  static const warmupFailed           = 'zw_warmup_failed';
  static const startupComplete        = 'zw_startup_complete';
  // Classification
  static const networkClassified      = 'zw_network_classified';
  static const deviceClassified       = 'zw_device_classified';
  static const policyApplied          = 'zw_policy_applied';
  // Memory
  static const memoryPressure         = 'zw_memory_pressure';

  Future<void> event(String name, Map<String, Object?> values);
  Future<void> error(
    Object error,
    StackTrace stackTrace, {
    required String reason,
    Map<String, Object?> context,
  });
}

final class FirebaseZeroWaitTelemetry implements ZeroWaitTelemetry {
  FirebaseZeroWaitTelemetry({
    FirebaseAnalytics? analytics,
    FirebaseCrashlytics? crashlytics,
  })  : _analytics = analytics,
        _crashlytics = crashlytics;

  final FirebaseAnalytics? _analytics;
  final FirebaseCrashlytics? _crashlytics;

  @override
  Future<void> event(String name, Map<String, Object?> values) async {
    try {
      final params = <String, Object>{};
      for (final e in values.entries) {
        final v = e.value;
        if (v == null) continue;
        params[e.key] = v is String || v is num ? v : v.toString();
      }
      await _analytics?.logEvent(
        name: name,
        parameters: params.isNotEmpty ? params : null,
      );
    } catch (_) {}
  }

  @override
  Future<void> error(
    Object error,
    StackTrace stackTrace, {
    required String reason,
    Map<String, Object?> context = const {},
  }) async {
    try {
      await _crashlytics?.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: false,
      );
    } catch (_) {}
  }
}
