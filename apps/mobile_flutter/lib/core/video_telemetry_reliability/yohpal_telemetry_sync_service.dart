import 'dart:convert';
import 'package:http/http.dart' as http;
import 'yohpal_connectivity_guard.dart';
import 'yohpal_telemetry_local_store.dart';
import 'yohpal_telemetry_retry_policy.dart';

class YohPalTelemetrySyncService {
  final String baseUrl;
  final String authToken;
  final YohPalTelemetryLocalStore localStore;
  final YohPalConnectivityGuard connectivityGuard;
  final YohPalTelemetryRetryPolicy retryPolicy;

  YohPalTelemetrySyncService({
    required this.baseUrl,
    required this.authToken,
    required this.localStore,
    required this.connectivityGuard,
    this.retryPolicy = const YohPalTelemetryRetryPolicy(),
  });

  Future<void> sync() async {
    final hasConnection = await connectivityGuard.hasConnection();
    if (!hasConnection) return;

    final queue = await localStore.loadQueue();
    if (queue.isEmpty) return;

    final retryable =
        queue.where((e) => retryPolicy.canRetry(e.retryCount)).toList();
    if (retryable.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/video-telemetry/events/retry-safe'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'events': retryable.map((e) => e.toJson()).toList(),
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final accepted = Set<String>.from(
          (json['acceptedEventIds'] as List?)?.cast<String>() ?? [],
        );
        await localStore.removeSent(accepted);
      } else {
        final updated = queue.map((e) => e.incrementRetry()).toList();
        await localStore.saveQueue(updated);
      }
    } catch (_) {
      // Sync failure must never block playback.
      final updated = queue.map((e) => e.incrementRetry()).toList();
      await localStore.saveQueue(updated);
    }
  }
}
