import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;
import '../models/chat_conversation_model.dart';
import '../models/chat_message_model.dart';

class ChatRepository {
  final FirebaseFirestore? _firestore;

  ChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  Stream<List<ChatConversationModel>> conversationsStream(String uid) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('chatConversations')
        .where('participantIds', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatConversationModel.fromMap(
                  Map<String, dynamic>.from(d.data())..['id'] = d.id,
                ))
            .toList());
  }

  Stream<List<ChatMessageModel>> messagesStream(String conversationId) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('chatConversations')
        .doc(conversationId)
        .collection('chatMessages')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatMessageModel.fromMap(
                  Map<String, dynamic>.from(d.data())..['id'] = d.id,
                ))
            .toList());
  }

  Future<String> createDirectConversation({
    required String currentUserId,
    required String otherUserId,
    required String currentUserName,
    required String otherUserName,
  }) async {
    final fs = _firestore;
    if (fs == null) throw StateError('Firebase not initialized');
    final sorted = [currentUserId, otherUserId]..sort();
    final conversationId = 'direct_${sorted[0]}_${sorted[1]}';
    final ref =
        fs.collection('chatConversations').doc(conversationId);
    final existing = await ref.get();
    if (!existing.exists) {
      await ref.set({
        'id': conversationId,
        'participantIds': sorted,
        'participantNames': {
          currentUserId: currentUserName,
          otherUserId: otherUserName,
        },
        'lastMessage': '',
        'lastSenderId': '',
        'unreadCounts': {currentUserId: 0, otherUserId: 0},
        'typing': {},
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    return conversationId;
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final conversationRef =
        fs.collection('chatConversations').doc(conversationId);
    final messageRef = conversationRef.collection('chatMessages').doc();

    await fs.runTransaction((tx) async {
      final conversationDoc = await tx.get(conversationRef);
      if (!conversationDoc.exists) {
        throw Exception('Conversation not found');
      }
      final data = conversationDoc.data()!;
      final participants = List<String>.from(data['participantIds'] ?? []);
      if (!participants.contains(senderId)) {
        throw Exception('Sender is not a conversation participant');
      }
      final recipientIds =
          participants.where((id) => id != senderId).toList();
      final updates = <String, dynamic>{
        'lastMessage': trimmed,
        'lastSenderId': senderId,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      for (final recipientId in recipientIds) {
        updates['unreadCounts.$recipientId'] = FieldValue.increment(1);
      }
      tx.set(messageRef, {
        'id': messageRef.id,
        'conversationId': conversationId,
        'senderId': senderId,
        'text': trimmed,
        'status': 'sent',
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.update(conversationRef, updates);
    });
  }

  Future<void> markConversationRead({
    required String conversationId,
    required String userId,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs
        .collection('chatConversations')
        .doc(conversationId)
        .update({'unreadCounts.$userId': 0});
  }

  Future<void> setTyping({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs
        .collection('chatConversations')
        .doc(conversationId)
        .update({'typing.$userId': isTyping});
  }
}