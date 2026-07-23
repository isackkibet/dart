import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/models/result.dart';
import '../domain/autonomy_decision.dart';
import '../domain/autonomy_policy.dart';

class AutonomyRepository {
  AutonomyRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _policies =>
      _firestore.collection('autonomyPolicies');

  CollectionReference<Map<String, dynamic>> get _decisions =>
      _firestore.collection('autonomyDecisions');

  Stream<List<AutonomyPolicy>> watchPolicies(String creatorId) {
    return _policies
        .where('creatorId', isEqualTo: creatorId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AutonomyPolicy.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<AutonomyDecision>> watchDecisions(String creatorId) {
    return _decisions
        .where('creatorId', isEqualTo: creatorId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AutonomyDecision.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<Result<void>> upsertPolicy(AutonomyPolicy policy) async {
    try {
      final doc =
          policy.id.isEmpty ? _policies.doc() : _policies.doc(policy.id);
      await doc.set(
        {
          ...policy.toMap(),
          'createdAt': policy.createdAt == null
              ? FieldValue.serverTimestamp()
              : policy.createdAt!.toUtc().toIso8601String(),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': policy.creatorId,
        },
        SetOptions(merge: true),
      );
      return const Success(null);
    } catch (error) {
      return Failure(
        AppFailure(
          message: 'Failed to save autonomy policy.',
          code: 'autonomy_policy_save_failed',
          details: error,
        ),
      );
    }
  }

  Future<Result<void>> approveDecision({
    required String decisionId,
    required String actorId,
  }) async {
    try {
      await _decisions.doc(decisionId).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': actorId,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': actorId,
      });
      return const Success(null);
    } catch (error) {
      return Failure(
        AppFailure(
          message: 'Failed to approve autonomy decision.',
          code: 'autonomy_decision_approve_failed',
          details: error,
        ),
      );
    }
  }

  Future<Result<void>> rejectDecision({
    required String decisionId,
    required String actorId,
  }) async {
    try {
      await _decisions.doc(decisionId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': actorId,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': actorId,
      });
      return const Success(null);
    } catch (error) {
      return Failure(
        AppFailure(
          message: 'Failed to reject autonomy decision.',
          code: 'autonomy_decision_reject_failed',
          details: error,
        ),
      );
    }
  }
}
