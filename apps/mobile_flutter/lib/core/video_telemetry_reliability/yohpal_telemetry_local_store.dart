import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'yohpal_offline_telemetry_event.dart';

class YohPalTelemetryLocalStore {
  static const String _key = 'yohpal_offline_telemetry_queue';

  Future<List<YohPalOfflineTelemetryEvent>> loadQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((item) => YohPalOfflineTelemetryEvent.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveQueue(List<YohPalOfflineTelemetryEvent> events) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(events.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> enqueue(YohPalOfflineTelemetryEvent event) async {
    final queue = await loadQueue();
    final exists = queue.any((item) => item.eventId == event.eventId);
    if (!exists) queue.add(event);
    await saveQueue(queue);
  }

  Future<void> removeSent(Set<String> sentEventIds) async {
    final queue = await loadQueue();
    final remaining =
        queue.where((e) => !sentEventIds.contains(e.eventId)).toList();
    await saveQueue(remaining);
  }
}
