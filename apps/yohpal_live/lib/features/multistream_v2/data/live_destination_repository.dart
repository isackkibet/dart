import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/models/result.dart';
import '../domain/live_destination.dart';

class LiveDestinationRepository {
  LiveDestinationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _destinations =>
      _firestore.collection('liveDestinations');

  Stream<List<LiveDestination>> watchSessionDestinations(String sessionId) {
    return _destinations
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LiveDestination.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<Result<LiveDestination>> create(LiveDestination destination) async {
    try {
      final doc = _destinations.doc();
      await doc.set({
        ...destination.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': destination.creatorId,
        'updatedBy': destination.creatorId,
      });
      return Success(destination);
    } catch (error) {
      return Failure(
        AppFailure(
          message: 'Failed to create destination.',
          code: 'destination_create_failed',
          details: error,
        ),
      );
    }
  }

  Future<Result<void>> update(LiveDestination destination) async {
    try {
      await _destinations.doc(destination.id).update({
        ...destination.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': destination.creatorId,
      });
      return const Success(null);
    } catch (error) {
      return Failure(
        AppFailure(
          message: 'Failed to update destination.',
          code: 'destination_update_failed',
          details: error,
        ),
      );
    }
  }

  Future<Result<void>> delete(String destinationId) async {
    try {
      await _destinations.doc(destinationId).delete();
      return const Success(null);
    } catch (error) {
      return Failure(
        AppFailure(
          message: 'Failed to delete destination.',
          code: 'destination_delete_failed',
          details: error,
        ),
      );
    }
  }
}
