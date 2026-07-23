import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;
import '../models/video_model.dart';

class VideoRepository {
  final FirebaseFirestore? _db;

  VideoRepository({FirebaseFirestore? db})
      : _db = db ?? fb.tryFirebaseFirestore();

  Future<List<VideoModel>> getSuggestedVideos({
    DocumentSnapshot? startAfter,
  }) async {
    final db = _db;
    if (db == null) return [];
    try {
      Query q = db
          .collection('videos')
          .where('status', isEqualTo: 'live')
          .where('broken', isEqualTo: false)
          .orderBy('engagementScore', descending: true)
          .limit(30);
      if (startAfter != null) q = q.startAfterDocument(startAfter);
      final snap = await q.get();
      return snap.docs.map((d) {
        try {
          final v = VideoModel.fromMap(d.id, d.data() as Map<String, dynamic>);
          return v.isPlayable ? v : null;
        } catch (_) { return null; }
      }).whereType<VideoModel>().toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<VideoModel>> getFollowingVideos(String userId) async {
    final db = _db;
    if (db == null) return [];
    final followsSnap = await db
        .collection('follows')
        .where('followerUid', isEqualTo: userId)
        .limit(50)
        .get();
    final creatorIds = followsSnap.docs
        .map((d) => d.data()['creatorUid'] as String?)
        .whereType<String>()
        .toList();
    if (creatorIds.isEmpty) return [];
    final results = <String, VideoModel>{};
    for (final ownerField in ['ownerId', 'userId']) {
      try {
        final snap = await db
            .collection('videos')
            .where(ownerField, whereIn: creatorIds.take(10).toList())
            .where('status', isEqualTo: 'live')
            .where('broken', isEqualTo: false)
            .orderBy('timestamp', descending: true)
            .limit(30)
            .get();
        for (final d in snap.docs) {
          if (results.containsKey(d.id)) continue;
          try {
            final v = VideoModel.fromMap(d.id, d.data());
            if (v.isPlayable) results[d.id] = v;
          } catch (_) {}
        }
      } catch (_) {}
    }
    return results.values.toList();
  }

  Future<List<VideoModel>> getTrendingVideos() async {
    final db = _db;
    if (db == null) return [];
    try {
      final snap = await db
          .collection('videos')
          .where('status', isEqualTo: 'live')
          .where('broken', isEqualTo: false)
          .orderBy('engagementScore', descending: true)
          .limit(30)
          .get();
      return snap.docs.map((d) {
        try {
          final v = VideoModel.fromMap(d.id, d.data());
          return v.isPlayable ? v : null;
        } catch (_) { return null; }
      }).whereType<VideoModel>().toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<VideoModel>> getCategoryVideos(String category) async {
    final db = _db;
    if (db == null) return [];
    try {
      final snap = await db
          .collection('videos')
          .where('status', isEqualTo: 'live')
          .where('broken', isEqualTo: false)
          .where('category', isEqualTo: category)
          .orderBy('timestamp', descending: true)
          .limit(30)
          .get();
      return snap.docs.map((d) {
        try {
          final v = VideoModel.fromMap(d.id, d.data());
          return v.isPlayable ? v : null;
        } catch (_) { return null; }
      }).whereType<VideoModel>().toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> markVideoAsBroken(String videoId, String reason) async {
    final db = _db;
    if (db == null) return;
    await db.collection('videos').doc(videoId).update({
      'broken': true,
      'brokenReason': reason,
      'brokenAt': FieldValue.serverTimestamp(),
    });
  }

  // Legacy method kept for backwards compatibility.
  Future<List<VideoModel>> fetchFeed({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) =>
      getSuggestedVideos(startAfter: startAfter);
}