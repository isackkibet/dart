import 'package:flutter/foundation.dart';
import '../models/chat_conversation_model.dart';
import '../models/chat_message_model.dart';
import '../repositories/chat_repository.dart';

class ChatController extends ChangeNotifier {
  final ChatRepository repository;

  ChatController({required this.repository});

  Stream<List<ChatConversationModel>> conversationsStream(String uid) =>
      repository.conversationsStream(uid);

  Stream<List<ChatMessageModel>> messagesStream(String conversationId) =>
      repository.messagesStream(conversationId);

  Future<String> createDirectConversation({
    required String currentUserId,
    required String otherUserId,
    required String currentUserName,
    required String otherUserName,
  }) =>
      repository.createDirectConversation(
        currentUserId: currentUserId,
        otherUserId: otherUserId,
        currentUserName: currentUserName,
        otherUserName: otherUserName,
      );

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) =>
      repository.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        text: text,
      );

  Future<void> markRead({
    required String conversationId,
    required String userId,
  }) =>
      repository.markConversationRead(
        conversationId: conversationId,
        userId: userId,
      );

  Future<void> setTyping({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) =>
      repository.setTyping(
        conversationId: conversationId,
        userId: userId,
        isTyping: isTyping,
      );
}
