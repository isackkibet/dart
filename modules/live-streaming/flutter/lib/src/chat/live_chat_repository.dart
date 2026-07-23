import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'live_chat_message.dart';

abstract interface class LiveChatContract {
  Stream<List<LiveChatMessage>> watchMessages({
    required String liveSessionId,
  });
  Future<void> sendMessage({
    required String liveSessionId,
    required String text,
  });
}

final class FirestoreLiveChatRepository implements LiveChatContract {
  FirestoreLiveChatRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Stream<List<LiveChatMessage>> watchMessages({
    required String liveSessionId,
  }) {
    return _firestore
        .collection('liveSessions')
        .doc(liveSessionId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(LiveChatMessage.fromDocument)
              .toList(growable: false),
        );
  }

  @override
  Future<void> sendMessage({
    required String liveSessionId,
    required String text,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Authentication required.');
    }

    final normalized = text.trim();
    if (normalized.isEmpty) {
      throw const FormatException(
        'Message cannot be empty.',
      );
    }
    if (normalized.length > 500) {
      throw const FormatException(
        'Message must not exceed 500 characters.',
      );
    }

    await _firestore
        .collection('liveSessions')
        .doc(liveSessionId)
        .collection('messages')
        .add({
      'userId': user.uid,
      'displayName': user.displayName ?? 'YohPal user',
      'text': normalized,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
