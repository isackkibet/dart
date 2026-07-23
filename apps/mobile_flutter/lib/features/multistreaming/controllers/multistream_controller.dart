import 'package:flutter/foundation.dart';
import '../repositories/multistream_repository.dart';
import '../services/multistream_service.dart';

class MultistreamController extends ChangeNotifier {
  final MultistreamRepository repository;
  final MultistreamService service;

  MultistreamController({
    required this.repository,
    required this.service,
  });

  bool loading = false;
  String? error;
  String? activeSessionId;

  Future<void> createAndStart({
    required String liveSessionId,
    required String creatorId,
    required List<Map<String, String>> destinations,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final sessionId = await repository.createSession(
        liveSessionId: liveSessionId,
        creatorId: creatorId,
      );
      for (final destination in destinations) {
        await repository.addDestination(
          sessionId: sessionId,
          platform: destination['platform']!,
          rtmpUrl: destination['rtmpUrl']!,
          streamKey: destination['streamKey']!,
        );
      }
      await service.startFanOut(
        multistreamSessionId: sessionId,
        liveSessionId: liveSessionId,
      );
      await repository.markSessionLive(sessionId);
      activeSessionId = sessionId;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    final id = activeSessionId;
    if (id == null) return;
    await service.stopFanOut(multistreamSessionId: id);
    activeSessionId = null;
    notifyListeners();
  }

  Future<void> retryDestination(String destinationId) async {
    final id = activeSessionId;
    if (id == null) return;
    await service.retryDestination(
      multistreamSessionId: id,
      destinationId: destinationId,
    );
  }
}
