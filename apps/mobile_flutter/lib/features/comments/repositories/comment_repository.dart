import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;
import '../models/comment_model.dart';

class CommentRepository {
  final FirebaseFirestore? _firestore;

  CommentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  Stream<List<CommentModel>> watchTopLevelComments(String videoId) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('comments')
        .where('videoId', isEqualTo: videoId)
        .where('parentCommentId', isNull: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => CommentModel.fromMap(doc.data())).toList());
  }

  Stream<List<CommentModel>> watchReplies(String parentCommentId) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('comments')
        .where('parentCommentId', isEqualTo: parentCommentId)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => CommentModel.fromMap(doc.data())).toList());
  }

  Future<void> addComment({
    required String videoId,
    required String userId,
    required String text,
    String? parentCommentId,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs.collection('comments').add({
      'videoId': videoId,
      'userId': userId,
      'content': text,
      'parentCommentId': parentCommentId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reactToComment({
    required String commentId,
    required String userId,
    required String emoji,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs.collection('comments').doc(commentId).collection('reactions').doc(userId).set({
      'emoji': emoji,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reportComment({
    required String commentId,
    required String userId,
    required String reason,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs.collection('commentReports').add({
      'commentId': commentId,
      'userId': userId,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
