import 'yohpal_watch_event.dart';

class YohPalVideoTelemetryBuffer {
  final List<YohPalWatchEvent> _events = [];
  final int maxBatchSize;

  YohPalVideoTelemetryBuffer({this.maxBatchSize = 20});

  void add(YohPalWatchEvent event) {
    _events.add(event);
  }

  bool get shouldFlush => _events.length >= maxBatchSize;

  List<YohPalWatchEvent> drain() {
    final drained = List<YohPalWatchEvent>.from(_events);
    _events.clear();
    return drained;
  }

  bool get isEmpty => _events.isEmpty;
}
