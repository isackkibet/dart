import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/models/result.dart';
import '../../../core/network/api_client.dart';
import '../domain/live_poll.dart';

class PollOverlayRepository {
  PollOverlayRepository({
    required ApiClient apiClient,
    FirebaseFirestore? firestore,
  })  : _apiClient = apiClient,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final ApiClient _apiClient;
  final FirebaseFirestore _firestore;

  // ── Real-time stream ────────────────────────────────────────────────────────

  Stream<List<LivePoll>> watchSessionPolls(String sessionId) {
    return _firestore
        .collection('polls')
        .where('sessionId', isEqualTo: sessionId)
        .where('status', isNotEqualTo: 'archived')
        .orderBy('status')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => LivePoll.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // ── Create poll ─────────────────────────────────────────────────────────────

  Future<Result<LivePoll>> createPoll({
    required String sessionId,
    required String question,
    required List<String> options,
    int durationSeconds = 30,
    bool allowMultipleVotes = false,
  }) async {
    final result = await _apiClient.postJson(
      '/polls/session/$sessionId',
      body: {
        'question': question,
        'options': options,
        'durationSeconds': durationSeconds,
        'allowMultipleVotes': allowMultipleVotes,
      },
    );
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    final data = result.dataOrNull?['data'];
    if (data == null) {
      return const Failure(AppFailure(
        message: 'Invalid response from server.',
        code: 'invalid_response',
      ));
    }
    final id = data['id']?.toString() ?? '';
    return Success(LivePoll.fromMap(id, Map<String, dynamic>.from(data)));
  }

  // ── Cast vote ───────────────────────────────────────────────────────────────

  Future<Result<void>> castVote({
    required String pollId,
    required String sessionId,
    required List<String> optionIds,
  }) async {
    final result = await _apiClient.postJson(
      '/polls/$pollId/vote',
      body: {
        'sessionId': sessionId,
        'optionIds': optionIds,
      },
    );
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    return const Success(null);
  }

  // ── Close poll ──────────────────────────────────────────────────────────────

  Future<Result<void>> closePoll(String pollId) async {
    final result = await _apiClient.patchJson('/polls/$pollId/close', body: {});
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    return const Success(null);
  }

  // ── Delete poll ─────────────────────────────────────────────────────────────

  Future<Result<void>> deletePoll(String pollId) async {
    final result = await _apiClient.deleteJson('/polls/$pollId');
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    return const Success(null);
  }
}
