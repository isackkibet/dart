import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;
import '../models/multistream_destination_model.dart';

class MultistreamRepository {
  final FirebaseFirestore? _firestore;

  MultistreamRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  Future<String> createSession({
    required String liveSessionId,
    required String creatorId,
  }) async {
    final fs = _firestore;
    if (fs == null) throw StateError('Firebase not initialized');
    final ref = fs.collection('multistreamSessions').doc();
    await ref.set({
      'id': ref.id,
      'liveSessionId': liveSessionId,
      'creatorId': creatorId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> addDestination({
    required String sessionId,
    required String platform,
    required String rtmpUrl,
    required String streamKey,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    final ref = fs
        .collection('multistreamSessions')
        .doc(sessionId)
        .collection('destinations')
        .doc();
    await ref.set({
      'id': ref.id,
      'platform': platform,
      'rtmpUrl': rtmpUrl,
      'streamKey': streamKey,
      'streamKeyMasked': maskKey(streamKey),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<MultistreamDestinationModel>> watchDestinations(String sessionId) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('multistreamSessions')
        .doc(sessionId)
        .collection('destinations')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MultistreamDestinationModel.fromMap(doc.data()))
            .toList());
  }

  Future<void> markSessionLive(String sessionId) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs.collection('multistreamSessions').doc(sessionId).update({
      'status': 'live',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  String maskKey(String key) {
    if (key.length <= 6) return '******';
    return '${key.substring(0, 3)}******${key.substring(key.length - 3)}';
  }
}