import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;

class VideoFeedRepository {
  final FirebaseFirestore? _firestore;

  VideoFeedRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  Stream<List<Map<String, dynamic>>> suggestedFeed() {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('videos')
        .where('visibility', isEqualTo: 'public')
        .where('playbackReady', isEqualTo: true)
        .where('processingStatus', isEqualTo: 'ready')
        .where('broken', isEqualTo: false)
        .orderBy('engagementScore', descending: true)
        .limit(30)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }
}