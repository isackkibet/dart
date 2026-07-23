import 'package:flutter/foundation.dart';
import 'media_worker_job_repository.dart';
class MediaWorkerJobController extends ChangeNotifier {
  final MediaWorkerJobRepository repository;
  bool loading = false;
  String? error;
  MediaWorkerJobController(this.repository);
  Future<String?> dispatch({
    required String sessionId,
    required String creatorId,
    required String jobType,
    required String inputUrl,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final jobId = await repository.dispatchJob(
        sessionId: sessionId,
        creatorId: creatorId,
        jobType: jobType,
        inputUrl: inputUrl,
      );
      return jobId;
    } catch (e) {
      error = e.toString();
      return null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
