import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/models/result.dart';
import '../../../core/network/api_client.dart';
import '../domain/chat_message.dart';

class LiveChatRepository {
  LiveChatRepository({
    required ApiClient apiClient,
    FirebaseFirestore? firestore,
  })  : _apiClient = apiClient,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final ApiClient _apiClient;
  final FirebaseFirestore _firestore;

  // ── Real-time streams ───────────────────────────────────────────────────────

  Stream<List<ChatMessage>> watchMessages(
    String sessionId, {
    int limit = 100,
  }) {
    return _firestore
        .collection('chatMessages')
        .where('sessionId', isEqualTo: sessionId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('sentAt', descending: false)
        .limitToLast(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => ChatMessage.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<ChatMessage?> watchPinnedMessage(String sessionId) {
    return _firestore
        .collection('chatMessages')
        .where('sessionId', isEqualTo: sessionId)
        .where('isPinned', isEqualTo: true)
        .where('isDeleted', isEqualTo: false)
        .orderBy('sentAt', descending: true)
        .limit(1)
        .snapshots()
        .map(
          (snap) => snap.docs.isEmpty
              ? null
              : ChatMessage.fromMap(
                  snap.docs.first.id,
                  snap.docs.first.data(),
                ),
        );
  }

  // ── Send message ────────────────────────────────────────────────────────────

  Future<Result<void>> sendMessage({
    required String sessionId,
    required String text,
  }) async {
    final result = await _apiClient.postJson(
      '/chat/sessions/$sessionId/messages',
      body: {'text': text, 'type': 'text'},
    );
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    return const Success(null);
  }

  // ── Pin message (creator) ───────────────────────────────────────────────────

  Future<Result<void>> pinMessage({
    required String sessionId,
    required String messageId,
  }) async {
    final result = await _apiClient.postJson(
      '/chat/sessions/$sessionId/messages/$messageId/pin',
      body: {},
    );
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    return const Success(null);
  }

  // ── Delete message (creator/admin) ──────────────────────────────────────────

  Future<Result<void>> deleteMessage({
    required String sessionId,
    required String messageId,
  }) async {
    final result = await _apiClient.deleteJson(
      '/chat/sessions/$sessionId/messages/$messageId',
    );
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    return const Success(null);
  }

  // ── Mute user (creator) ─────────────────────────────────────────────────────

  Future<Result<void>> muteUser({
    required String sessionId,
    required String userId,
    int durationSeconds = 86400,
  }) async {
    final result = await _apiClient.postJson(
      '/chat/sessions/$sessionId/mute',
      body: {
        'userId': userId,
        'durationSeconds': durationSeconds,
      },
    );
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    return const Success(null);
  }
}
