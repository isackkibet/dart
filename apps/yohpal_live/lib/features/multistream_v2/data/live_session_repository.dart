import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/models/result.dart';
import '../domain/live_session.dart';

class LiveSessionRepository {
  LiveSessionRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection('liveSessions');

  Stream<List<LiveSession>> watchCreatorSessions(String creatorId) {
    return _sessions
        .where('creatorId', isEqualTo: creatorId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LiveSession.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<Result<LiveSession>> create(LiveSession session) async {
    try {
      final doc = _sessions.doc();
      final payload = {
        ...session.toMap(),
        'status': session.status,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': session.creatorId,
        'updatedBy': session.creatorId,
      };
      await doc.set(payload);
      return Success(
        session.copyWith(
          id: doc.id,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    } catch (error) {
      return Failure(
        AppFailure(
          message: 'Failed to create live session.',
          code: 'live_session_create_failed',
          details: error,
        ),
      );
    }
  }

  Future<Result<void>> updateStatus({
    required String sessionId,
    required String status,
    required String actorId,
  }) async {
    try {
      final update = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': actorId,
      };
      if (status == 'live') {
        update['startedAt'] = FieldValue.serverTimestamp();
      }
      if (status == 'ended') {
        update['endedAt'] = FieldValue.serverTimestamp();
      }
      await _sessions.doc(sessionId).update(update);
      return const Success(null);
    } catch (error) {
      return Failure(
        AppFailure(
          message: 'Failed to update live session status.',
          code: 'live_session_status_failed',
          details: error,
        ),
      );
    }
  }

  Future<Result<void>> delete(String sessionId) async {
    try {
      await _sessions.doc(sessionId).delete();
      return const Success(null);
    } catch (error) {
      return Failure(
        AppFailure(
          message: 'Failed to delete live session.',
          code: 'live_session_delete_failed',
          details: error,
        ),
      );
    }
  }
}
