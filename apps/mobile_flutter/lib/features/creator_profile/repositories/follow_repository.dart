import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;

class FollowRepository {
  final FirebaseFirestore? _firestore;

  FollowRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  String _followDocId({
    required String followerUid,
    required String creatorUid,
  }) =>
      '${followerUid}_$creatorUid';

  Stream<bool> watchIsFollowing({
    required String followerUid,
    required String creatorUid,
  }) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    final id = _followDocId(followerUid: followerUid, creatorUid: creatorUid);
    return fs
        .collection('follows')
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Future<void> follow({
    required String followerUid,
    required String creatorUid,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    if (followerUid == creatorUid) return;
    final id = _followDocId(followerUid: followerUid, creatorUid: creatorUid);
    await fs.collection('follows').doc(id).set({
      'id': id,
      'followerUid': followerUid,
      'creatorUid': creatorUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unfollow({
    required String followerUid,
    required String creatorUid,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    final id = _followDocId(followerUid: followerUid, creatorUid: creatorUid);
    await fs.collection('follows').doc(id).delete();
  }
}