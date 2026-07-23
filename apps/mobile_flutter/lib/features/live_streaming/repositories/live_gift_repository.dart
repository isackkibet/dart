import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;

class LiveGiftRepository {
  final FirebaseFirestore? _firestore;

  LiveGiftRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  CollectionReference<Map<String, dynamic>>? _gifts(String sessionId) {
    final fs = _firestore;
    if (fs == null) return null;
    return fs
        .collection('liveSessions')
        .doc(sessionId)
        .collection('gifts');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchGifts(String sessionId) {
    final g = _gifts(sessionId);
    if (g == null) return const Stream.empty();
    return g
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots();
  }
}