import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/models/result.dart';
import '../data/media_pipeline_repository.dart';
import '../domain/media_job.dart';
import '../domain/pipeline_config.dart';

class MediaPipelineController extends ChangeNotifier {
  MediaPipelineController({
    required MediaPipelineRepository repository,
    required String creatorId,
  })  : _repository = repository,
        _creatorId = creatorId;

  final MediaPipelineRepository _repository;
  final String _creatorId;

  StreamSubscription<List<MediaJob>>? _subscription;
  List<MediaJob> _jobs = const [];
  final Set<String> _loadingIds = {};
  AppFailure? _failure;
  bool _isDispatching = false;

  List<MediaJob> get jobs => _jobs;
  AppFailure? get failure => _failure;
  bool get isDispatching => _isDispatching;
  bool isLoading(String jobId) => _loadingIds.contains(jobId);

  List<MediaJob> get activeJobs =>
      _jobs.where((j) => j.isActive).toList();
  List<MediaJob> get completedJobs =>
      _jobs.where((j) => j.isCompleted).toList();
  List<MediaJob> get failedJobs =>
      _jobs.where((j) => j.isFailed).toList();

  void startWatching() {
    _subscription?.cancel();
    _subscription = _repository.watchJobs(_creatorId).listen(
      (jobs) {
        _jobs = jobs;
        _failure = null;
        notifyListeners();
      },
      onError: (Object error) {
        _failure = AppFailure(
          message: error.toString(),
          code: 'pipeline_stream_error',
        );
        notifyListeners();
      },
    );
  }

  Future<Result<MediaJob>> dispatchClipExport({
    required String clipSegmentId,
    required String inputRef,
    PipelineConfig config = const PipelineConfig(),
  }) async {
    _isDispatching = true;
    _failure = null;
    notifyListeners();
    final result = await _repository.dispatchJob(
      jobType: 'clip_export',
      inputRef: inputRef,
      clipSegmentId: clipSegmentId,
      config: config,
      priority: 7,
    );
    _isDispatching = false;
    if (result is Failure<MediaJob>) _failure = result.failure;
    notifyListeners();
    return result;
  }

  Future<Result<MediaJob>> dispatchReplayPackage({
    required String sessionId,
    required String inputRef,
    PipelineConfig config = const PipelineConfig(),
  }) async {
    _isDispatching = true;
    _failure = null;
    notifyListeners();
    final result = await _repository.dispatchJob(
      jobType: 'replay_package',
      inputRef: inputRef,
      sessionId: sessionId,
      config: config,
      priority: 5,
    );
    _isDispatching = false;
    if (result is Failure<MediaJob>) _failure = result.failure;
    notifyListeners();
    return result;
  }

  Future<void> cancelJob(String jobId) async {
    _loadingIds.add(jobId);
    _failure = null;
    notifyListeners();
    final result = await _repository.cancelJob(jobId);
    _loadingIds.remove(jobId);
    if (result is Failure<void>) _failure = result.failure;
    notifyListeners();
  }

  Future<void> retryJob(String jobId) async {
    _loadingIds.add(jobId);
    _failure = null;
    notifyListeners();
    final result = await _repository.retryJob(jobId);
    _loadingIds.remove(jobId);
    if (result is Failure<void>) _failure = result.failure;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
