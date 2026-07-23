import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;
import '../models/poll_model.dart';

class PollRepository {
  final FirebaseFirestore? _firestore;

  PollRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  Stream<PollModel?> watchPoll(String pollId) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs.collection('polls').doc(pollId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return PollModel.fromMap({'id': doc.id, ...doc.data()!});
    });
  }

  Stream<PollModel?> watchVideoPoll(String videoId) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('polls')
        .where('videoId', isEqualTo: videoId)
        .where('status', isEqualTo: 'active')
        .where('visible', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      return PollModel.fromMap({'id': doc.id, ...doc.data()});
    });
  }

  Future<bool> hasVoted({
    required String pollId,
    required String userId,
  }) async {
    final fs = _firestore;
    if (fs == null) return false;
    final doc = await fs
        .collection('polls')
        .doc(pollId)
        .collection('votes')
        .doc(userId)
        .get();
    return doc.exists;
  }

  Future<void> vote({
    required PollModel poll,
    required String userId,
    required String option,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    if (poll.status != 'active' || !poll.visible) {
      throw Exception('Poll is not active');
    }
    final pollRef = fs.collection('polls').doc(poll.id);
    final voteRef = pollRef.collection('votes').doc(userId);

    await fs.runTransaction((tx) async {
      final voteDoc = await tx.get(voteRef);
      if (voteDoc.exists) {
        throw Exception('You have already voted');
      }
      tx.set(voteRef, {
        'pollId': poll.id,
        'videoId': poll.videoId,
        'userId': userId,
        'option': option,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.update(pollRef, {
        'voteCounts.$option': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.set(fs.collection('pollEvents').doc(), {
        'pollId': poll.id,
        'videoId': poll.videoId,
        'userId': userId,
        'type': 'vote',
        'option': option,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}