import 'dart:convert';
import 'package:http/http.dart' as http;
import 'yohpal_watch_event.dart';
import 'yohpal_video_telemetry_buffer.dart';

class YohPalVideoTelemetryClient {
  final String baseUrl;
  final String authToken;
  final YohPalVideoTelemetryBuffer buffer;

  YohPalVideoTelemetryClient({
    required this.baseUrl,
    required this.authToken,
    required this.buffer,
  });

  Future<void> record(YohPalWatchEvent event) async {
    buffer.add(event);
    if (buffer.shouldFlush) {
      await flush();
    }
  }

  Future<void> flush() async {
    if (buffer.isEmpty) return;
    final events = buffer.drain();
    try {
      await http.post(
        Uri.parse('$baseUrl/video-telemetry/events'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'events': events.map((e) => e.toJson()).toList(),
        }),
      );
    } catch (_) {
      // Telemetry failure must never break playback.
      // V7 will persist and retry unsent events locally.
    }
  }
}
