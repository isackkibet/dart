import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;
import '../domain/creator_aggregate_metrics.dart';

abstract interface class CreatorMetricsRepository {
  Stream<CreatorAggregateMetrics> watch(String creatorId);
  Future<CreatorAggregateMetrics> fetch(String creatorId);
}

final class FirestoreCreatorMetricsRepository
    implements CreatorMetricsRepository {
  FirestoreCreatorMetricsRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? fb.tryFirebaseFirestore();

  final FirebaseFirestore? _db;

  @override
  Stream<CreatorAggregateMetrics> watch(String creatorId) {
    final db = _db;
    if (db == null) return const Stream.empty();
    return db
        .collection('creatorMetrics')
        .doc(creatorId)
        .snapshots()
        .map((snap) => snap.exists
            ? CreatorAggregateMetrics.fromJson(snap.data()!)
            : const CreatorAggregateMetrics(
                totalVideos: 0,
                totalViews: 0,
                totalLikes: 0,
                totalComments: 0,
                totalShares: 0,
                totalGifts: 0,
                followerCount: 0,
              ));
  }

  @override
  Future<CreatorAggregateMetrics> fetch(String creatorId) async {
    final db = _db;
    if (db == null) {
      return const CreatorAggregateMetrics(
        totalVideos: 0,
        totalViews: 0,
        totalLikes: 0,
        totalComments: 0,
        totalShares: 0,
        totalGifts: 0,
        followerCount: 0,
      );
    }
    final snap =
        await db.collection('creatorMetrics').doc(creatorId).get();
    if (!snap.exists) {
      return const CreatorAggregateMetrics(
        totalVideos: 0,
        totalViews: 0,
        totalLikes: 0,
        totalComments: 0,
        totalShares: 0,
        totalGifts: 0,
        followerCount: 0,
      );
    }
    return CreatorAggregateMetrics.fromJson(snap.data()!);
  }
}