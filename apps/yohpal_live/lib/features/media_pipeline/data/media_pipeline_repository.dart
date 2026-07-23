import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/models/result.dart';
import '../../../core/network/api_client.dart';
import '../domain/media_job.dart';
import '../domain/pipeline_config.dart';

class MediaPipelineRepository {
  MediaPipelineRepository({
    required ApiClient apiClient,
    FirebaseFirestore? firestore,
  })  : _apiClient = apiClient,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final ApiClient _apiClient;
  final FirebaseFirestore _firestore;

  /// Real-time stream of all jobs for a creator, newest first.
  Stream<List<MediaJob>> watchJobs(String creatorId) {
    return _firestore
        .collection('mediaJobs')
        .where('creatorId', isEqualTo: creatorId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => MediaJob.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Real-time stream of a single job.
  Stream<MediaJob?> watchJob(String jobId) {
    return _firestore
        .collection('mediaJobs')
        .doc(jobId)
        .snapshots()
        .map(
          (snap) =>
              snap.exists ? MediaJob.fromMap(snap.id, snap.data()!) : null,
        );
  }

  /// Dispatch a new media job.
  Future<Result<MediaJob>> dispatchJob({
    required String jobType,
    required String inputRef,
    String? sessionId,
    String? clipSegmentId,
    PipelineConfig config = const PipelineConfig(),
    int priority = 5,
  }) async {
    final result = await _apiClient.postJson(
      '/media-pipeline/jobs',
      body: {
        'jobType': jobType,
        'inputRef': inputRef,
        if (sessionId != null) 'sessionId': sessionId,
        if (clipSegmentId != null) 'clipSegmentId': clipSegmentId,
        'config': config.toMap(),
        'priority': priority,
      },
    );
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    final data = result.dataOrNull?['data'];
    if (data is! Map<String, dynamic>) {
      return const Failure(
        AppFailure(message: 'Invalid dispatch response.', code: 'invalid_response'),
      );
    }
    return Success(MediaJob.fromMap(data['id']?.toString() ?? '', data));
  }

  /// Cancel a queued or processing job.
  Future<Result<void>> cancelJob(String jobId) async {
    final result = await _apiClient.patchJson(
      '/media-pipeline/jobs/$jobId/cancel',
    );
    if (result is Failure<Map<String, dynamic>>) return Failure(result.failure);
    return const Success(null);
  }

  /// Retry a failed job.
  Future<Result<void>> retryJob(String jobId) async {
    final result = await _apiClient.postJson(
      '/media-pipeline/jobs/$jobId/retry',
    );
    if (result is Failure<Map<String, dynamic>>) return Failure(result.failure);
    return const Success(null);
  }
}
