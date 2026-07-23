import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/firebase.dart' as fb;
import '../domain/engagement_counts.dart';
import 'engagement_repository.dart';

final class FirestoreEngagementRepository implements EngagementRepository {
  FirestoreEngagementRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? fb.tryFirebaseFirestore();

  final FirebaseFirestore? _db;

  String? get _uid {
    try { return FirebaseAuth.instance.currentUser?.uid; } catch (_) { return null; }
  }

  @override
  Stream<EngagementCounts> watch(String videoId) {
    final fs = _db;
    if (fs == null) return const Stream.empty();
    final viewerUid = _uid;
    final engStream = fs.collection('videoEngagement').doc(videoId).snapshots();

    if (viewerUid == null) {
      return engStream.map((snap) => snap.exists
          ? EngagementCounts.fromMap(snap.data()!)
          : EngagementCounts.empty());
    }

    final likeRef = fs.collection('videoLikes').doc('${videoId}_$viewerUid');
    final saveRef = fs.collection('videoSaves').doc('${videoId}_$viewerUid');

    return engStream.asyncMap((engSnap) async {
      final counts = engSnap.exists
          ? EngagementCounts.fromMap(engSnap.data()!)
          : EngagementCounts.empty();
      final likeSnap = await likeRef.get();
      final saveSnap = await saveRef.get();
      return counts.copyWith(
        viewerHasLiked: likeSnap.exists,
        viewerHasSaved: saveSnap.exists,
      );
    });
  }

  @override
  Future<EngagementCounts> setLike({
    required String videoId,
    required bool liked,
    required String mutationId,
  }) async {
    final fs = _db;
    if (fs == null) return EngagementCounts.empty();
    final viewerUid = _uid ?? '';
    final mutationRef = fs.collection('engagementMutations').doc(mutationId);
    final likeRef = fs.collection('videoLikes').doc('${videoId}_$viewerUid');
    final engRef = fs.collection('videoEngagement').doc(videoId);

    await fs.runTransaction((tx) async {
      final existing = await tx.get(mutationRef);
      if (existing.exists) return;

      final currentLike = await tx.get(likeRef);
      final alreadyLiked = currentLike.exists;

      if (liked && !alreadyLiked) {
        tx.set(likeRef, {
          'videoId': videoId,
          'userId': viewerUid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.set(engRef, {'likes': FieldValue.increment(1), 'updatedAt': FieldValue.serverTimestamp()},
            SetOptions(merge: true));
      } else if (!liked && alreadyLiked) {
        tx.delete(likeRef);
        tx.set(engRef, {'likes': FieldValue.increment(-1), 'updatedAt': FieldValue.serverTimestamp()},
            SetOptions(merge: true));
      }

      tx.set(mutationRef, {
        'mutationId': mutationId,
        'videoId': videoId,
        'userId': viewerUid,
        'action': liked ? 'like' : 'unlike',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    final snap = await engRef.get();
    final likeSnap = await likeRef.get();
    return snap.exists
        ? EngagementCounts.fromMap(snap.data()!, viewerHasLiked: likeSnap.exists)
        : EngagementCounts.empty();
  }

  @override
  Future<EngagementCounts> setSaved({
    required String videoId,
    required bool saved,
    required String mutationId,
  }) async {
    final fs = _db;
    if (fs == null) return EngagementCounts.empty();
    final viewerUid = _uid ?? '';
    final mutationRef = fs.collection('engagementMutations').doc(mutationId);
    final saveRef = fs.collection('videoSaves').doc('${videoId}_$viewerUid');
    final engRef = fs.collection('videoEngagement').doc(videoId);

    await fs.runTransaction((tx) async {
      final existing = await tx.get(mutationRef);
      if (existing.exists) return;

      final currentSave = await tx.get(saveRef);
      final alreadySaved = currentSave.exists;

      if (saved && !alreadySaved) {
        tx.set(saveRef, {
          'videoId': videoId,
          'userId': viewerUid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.set(engRef, {'saves': FieldValue.increment(1), 'updatedAt': FieldValue.serverTimestamp()},
            SetOptions(merge: true));
      } else if (!saved && alreadySaved) {
        tx.delete(saveRef);
        tx.set(engRef, {'saves': FieldValue.increment(-1), 'updatedAt': FieldValue.serverTimestamp()},
            SetOptions(merge: true));
      }

      tx.set(mutationRef, {
        'mutationId': mutationId,
        'videoId': videoId,
        'userId': viewerUid,
        'action': saved ? 'save' : 'unsave',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    final snap = await engRef.get();
    final saveSnap = await saveRef.get();
    return snap.exists
        ? EngagementCounts.fromMap(snap.data()!, viewerHasSaved: saveSnap.exists)
        : EngagementCounts.empty();
  }

  @override
  Future<void> registerView({
    required String videoId,
    required String viewSessionId,
    required int watchedMilliseconds,
  }) async {
    final fs = _db;
    if (fs == null) return;
    await fs.collection('videoEngagement').doc(videoId).set(
        {'views': FieldValue.increment(1), 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true));
  }

  @override
  Future<void> registerShare({
    required String videoId,
    required String mutationId,
    required String channel,
  }) async {
    final fs = _db;
    if (fs == null) return;
    final mutationRef = fs.collection('engagementMutations').doc(mutationId);
    final engRef = fs.collection('videoEngagement').doc(videoId);

    await fs.runTransaction((tx) async {
      final existing = await tx.get(mutationRef);
      if (existing.exists) return;
      tx.set(engRef, {'shares': FieldValue.increment(1), 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true));
      tx.set(mutationRef, {
        'mutationId': mutationId,
        'videoId': videoId,
        'action': 'share',
        'channel': channel,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
