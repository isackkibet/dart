import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;

// Handles privateLikes and privateComments — visible to the creator only,
// do not affect public like/comment counts or engagementScore.
class PrivateEngagementService {
  final FirebaseFirestore? _firestore;

  PrivateEngagementService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  String _privateLikeId(String userId, String videoId) =>
      '${userId}_$videoId';

  // ── Private Likes ──────────────────────────────────────────────────────────

  Future<bool> isPrivateLiked({
    required String userId,
    required String videoId,
  }) async {
    final fs = _firestore;
    if (fs == null) return false;
    final doc = await fs
        .collection('privateLikes')
        .doc(_privateLikeId(userId, videoId))
        .get();
    return doc.exists;
  }

  Future<void> addPrivateLike({
    required String userId,
    required String videoId,
    required String creatorId,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    final ref = fs
        .collection('privateLikes')
        .doc(_privateLikeId(userId, videoId));
    await fs.runTransaction((tx) async {
      final existing = await tx.get(ref);
      if (existing.exists) return;
      tx.set(ref, {
        'id': ref.id,
        'userId': userId,
        'videoId': videoId,
        'creatorId': creatorId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> removePrivateLike({
    required String userId,
    required String videoId,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs
        .collection('privateLikes')
        .doc(_privateLikeId(userId, videoId))
        .delete();
  }

  // ── Private Comments ───────────────────────────────────────────────────────

  Future<void> addPrivateComment({
    required String userId,
    required String videoId,
    required String creatorId,
    required String text,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    if (text.trim().isEmpty) return;
    await fs
        .collection('videos')
        .doc(videoId)
        .collection('privateComments')
        .add({
      'userId': userId,
      'videoId': videoId,
      'creatorId': creatorId,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPrivateComments({
    required String videoId,
  }) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('videos')
        .doc(videoId)
        .collection('privateComments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}