import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/models/result.dart';
import 'stream_health.dart';
import 'stream_route_policy.dart';

class StreamOrchestrationRepository {
  StreamOrchestrationRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _policies =>
      _firestore.collection('streamRoutePolicies');

  CollectionReference<Map<String, dynamic>> get _health =>
      _firestore.collection('streamHealth');

  Stream<List<StreamRoutePolicy>> watchPolicies(String sessionId) {
    return _policies
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StreamRoutePolicy.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<StreamHealth?> watchHealth(String sessionId) {
    return _health.doc(sessionId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return StreamHealth.fromMap(doc.data()!);
    });
  }

  Future<Result<void>> upsertPolicy(StreamRoutePolicy policy) async {
    try {
      final doc = policy.id.isEmpty ? _policies.doc() : _policies.doc(policy.id);
      await doc.set(
        {
          ...policy.toMap(),
          'createdAt': policy.createdAt == null
              ? FieldValue.serverTimestamp()
              : policy.createdAt!.toUtc().toIso8601String(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return const Success(null);
    } catch (error) {
      return Failure(
        AppFailure(
          message: 'Failed to save stream route policy.',
          code: 'stream_policy_save_failed',
          details: error,
        ),
      );
    }
  }

  Future<Result<void>> mockIngestHeartbeat(String sessionId) async {
    try {
      await _health.doc(sessionId).set(
        {
          'sessionId': sessionId,
          'status': 'healthy',
          'ingestStatus': 'mock_ingest_active',
          'activeDestinations': 1,
          'failedDestinations': 0,
          'bitrateKbps': 4200,
          'latencyMs': 850,
          'lastHeartbeatAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return const Success(null);
    } catch (error) {
      return Failure(
        AppFailure(
          message: 'Failed to send mock ingest heartbeat.',
          code: 'mock_ingest_failed',
          details: error,
        ),
      );
    }
  }
}
