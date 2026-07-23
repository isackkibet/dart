import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;

class VideoInteractionService {
  final FirebaseFirestore? _firestore;

  VideoInteractionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  String likeId(String userId, String videoId) => '${userId}_$videoId';
  String bookmarkId(String userId, String videoId) => '${userId}_$videoId';

  Future<bool> isLiked({
    required String userId,
    required String videoId,
  }) async {
    final fs = _firestore;
    if (fs == null) return false;
    final doc =
        await fs.collection('likes').doc(likeId(userId, videoId)).get();
    return doc.exists;
  }

  Future<bool> isBookmarked({
    required String userId,
    required String videoId,
  }) async {
    final fs = _firestore;
    if (fs == null) return false;
    final doc = await fs
        .collection('bookmarks')
        .doc(bookmarkId(userId, videoId))
        .get();
    return doc.exists;
  }

  Future<void> likeVideo({
    required String userId,
    required String videoId,
    required String creatorId,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    final ref = fs.collection('likes').doc(likeId(userId, videoId));
    final videoRef = fs.collection('videos').doc(videoId);
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
      tx.update(videoRef, {
        'likeCount': FieldValue.increment(1),
        'engagementScore': FieldValue.increment(5),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.set(fs.collection('videoEvents').doc(), {
        'userId': userId,
        'videoId': videoId,
        'creatorId': creatorId,
        'type': 'like',
        'score': 5,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.set(
        fs.collection('videoStats').doc(videoId),
        {
          'videoId': videoId,
          'creatorId': creatorId,
          'likes': FieldValue.increment(1),
          'engagementScore': FieldValue.increment(5),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> unlikeVideo({
    required String userId,
    required String videoId,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    final ref = fs.collection('likes').doc(likeId(userId, videoId));
    final videoRef = fs.collection('videos').doc(videoId);
    await fs.runTransaction((tx) async {
      final existing = await tx.get(ref);
      if (!existing.exists) return;
      tx.delete(ref);
      tx.update(videoRef, {
        'likeCount': FieldValue.increment(-1),
        'engagementScore': FieldValue.increment(-5),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> bookmarkVideo({
    required String userId,
    required String videoId,
    required String creatorId,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    final ref =
        fs.collection('bookmarks').doc(bookmarkId(userId, videoId));
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
      tx.set(fs.collection('videoEvents').doc(), {
        'userId': userId,
        'videoId': videoId,
        'creatorId': creatorId,
        'type': 'bookmark',
        'score': 8,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.set(
        fs.collection('videoStats').doc(videoId),
        {
          'videoId': videoId,
          'creatorId': creatorId,
          'bookmarks': FieldValue.increment(1),
          'engagementScore': FieldValue.increment(8),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> unbookmarkVideo({
    required String userId,
    required String videoId,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs
        .collection('bookmarks')
        .doc(bookmarkId(userId, videoId))
        .delete();
  }

  Future<void> recordView({
    required String userId,
    required String videoId,
    required String creatorId,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs.collection('videoEvents').add({
      'userId': userId,
      'videoId': videoId,
      'creatorId': creatorId,
      'type': 'view_3s',
      'score': 2,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await fs.collection('videoStats').doc(videoId).set({
      'videoId': videoId,
      'creatorId': creatorId,
      'views': FieldValue.increment(1),
      'engagementScore': FieldValue.increment(2),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await fs.collection('videos').doc(videoId).set({
      'viewCount': FieldValue.increment(1),
      'engagementScore': FieldValue.increment(2),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> recordShare({
    required String userId,
    required String videoId,
    required String creatorId,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs.collection('videoEvents').add({
      'userId': userId,
      'videoId': videoId,
      'creatorId': creatorId,
      'type': 'share',
      'score': 10,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await fs.collection('videoStats').doc(videoId).set({
      'videoId': videoId,
      'creatorId': creatorId,
      'shares': FieldValue.increment(1),
      'engagementScore': FieldValue.increment(10),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await fs.collection('videos').doc(videoId).set({
      'shareCount': FieldValue.increment(1),
      'engagementScore': FieldValue.increment(10),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}