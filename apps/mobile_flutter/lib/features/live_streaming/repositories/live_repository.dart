import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;
import '../models/live_session_model.dart';

class LiveRepository {
  final FirebaseFirestore? _firestore;

  LiveRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  Future<LiveSessionModel> createLiveSession({
    required String creatorId,
    required String title,
    required String description,
  }) async {
    final fs = _firestore;
    if (fs == null) throw StateError('Firebase not available');
    final ref = fs.collection('liveSessions').doc();
    final roomName = 'yohpal_live_${ref.id}';
    final session = LiveSessionModel(
      id: ref.id,
      creatorId: creatorId,
      title: title,
      description: description,
      status: 'starting',
      roomName: roomName,
      viewerCount: 0,
      createdAt: DateTime.now(),
    );
    await ref.set({
      ...session.toMap(),
      'visibility': 'public',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return session;
  }

  Future<void> updateLiveStatus({
    required String sessionId,
    required String status,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs.collection('liveSessions').doc(sessionId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markLive(String sessionId) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs.collection('liveSessions').doc(sessionId).update({
      'status': 'live',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markFailed({
    required String sessionId,
    required String reason,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs.collection('liveSessions').doc(sessionId).update({
      'status': 'failed',
      'errorMessage': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> incrementViewerCount(String sessionId) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs.collection('liveSessions').doc(sessionId).set({
      'viewerCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> endLive(String sessionId) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs.collection('liveSessions').doc(sessionId).update({
      'status': 'ended',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> decrementViewerCount(String sessionId) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs.collection('liveSessions').doc(sessionId).set({
      'viewerCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<LiveSessionModel>> fetchLiveSessions() async {
    final fs = _firestore;
    if (fs == null) return [];
    final snap = await fs
        .collection('liveSessions')
        .where('status', whereIn: ['starting', 'live'])
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    return snap.docs
        .map((doc) => LiveSessionModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Stream<List<LiveSessionModel>> watchPublicLiveSessions() {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('liveSessions')
        .where('status', isEqualTo: 'live')
        .where('visibility', isEqualTo: 'public')
        .orderBy('viewerCount', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => LiveSessionModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Stream<LiveSessionModel?> watchLiveSession(String sessionId) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('liveSessions')
        .doc(sessionId)
        .snapshots()
        .map((doc) =>
            doc.exists ? LiveSessionModel.fromMap({...doc.data()!, 'id': doc.id}) : null);
  }
}
