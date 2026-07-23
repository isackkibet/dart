import 'package:flutter/foundation.dart';
import '../data/video_exposure_repository.dart';
import '../domain/video_exposure.dart';

class VideoExposureController extends ChangeNotifier {
  VideoExposureController({required VideoExposureRepository repository})
      : _repository = repository;

  final VideoExposureRepository _repository;

  Future<void> recordExposure({
    required String videoId,
    required VideoExposureSource source,
    required double progress,
    required bool completed,
  }) async {
    await _repository.recordExposure(
      videoId: videoId,
      source: source,
      progress: progress,
      completed: completed,
    );
  }

  Future<void> synchronize() async {
    await _repository.synchronize();
    notifyListeners();
  }
}
