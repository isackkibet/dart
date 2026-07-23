import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;
import '../models/live_chat_message_model.dart';

class LiveChatRepository {
  final FirebaseFirestore? _firestore;

  LiveChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  CollectionReference<Map<String, dynamic>>? _messages(String sessionId) {
    final fs = _firestore;
    if (fs == null) return null;
    return fs
        .collection('liveSessions')
        .doc(sessionId)
        .collection('messages');
  }

  Stream<List<LiveChatMessageModel>> watchMessages(String sessionId) {
    final msgs = _messages(sessionId);
    if (msgs == null) return const Stream.empty();
    return msgs
        .where('hidden', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(80)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => LiveChatMessageModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> sendMessage({
    required String sessionId,
    required String userId,
    required String displayName,
    required String text,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final msgs = fs
        .collection('liveSessions')
        .doc(sessionId)
        .collection('messages');
    final ref = msgs.doc();
    await ref.set({
      'id': ref.id,
      'sessionId': sessionId,
      'userId': userId,
      'displayName': displayName,
      'text': trimmed,
      'hidden': false,
      'reported': false,
      'reportReason': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await fs.collection('liveEvents').add({
      'sessionId': sessionId,
      'userId': userId,
      'type': 'chat_message',
      'score': 1,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reportMessage({
    required String sessionId,
    required String messageId,
    required String userId,
    required String reason,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    final msgs = fs
        .collection('liveSessions')
        .doc(sessionId)
        .collection('messages');
    await msgs.doc(messageId).set({
      'reported': true,
      'reportReason': reason,
      'reportedBy': userId,
      'reportedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await fs.collection('liveReports').add({
      'sessionId': sessionId,
      'messageId': messageId,
      'reportedBy': userId,
      'reason': reason,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}