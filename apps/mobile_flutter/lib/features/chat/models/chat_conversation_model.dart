import 'package:cloud_firestore/cloud_firestore.dart';

class ChatConversationModel {
  final String id;
  final List<String> participantIds;
  final Map<String, dynamic> participantNames;
  final String lastMessage;
  final String lastSenderId;
  final Map<String, dynamic> unreadCounts;
  final Map<String, dynamic> typing;
  final DateTime updatedAt;

  const ChatConversationModel({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.lastMessage,
    required this.lastSenderId,
    required this.unreadCounts,
    required this.typing,
    required this.updatedAt,
  });

  factory ChatConversationModel.fromMap(Map<String, dynamic> map) {
    return ChatConversationModel(
      id: map['id'] ?? '',
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participantNames:
          Map<String, dynamic>.from(map['participantNames'] ?? {}),
      lastMessage: map['lastMessage'] ?? '',
      lastSenderId: map['lastSenderId'] ?? '',
      unreadCounts: Map<String, dynamic>.from(map['unreadCounts'] ?? {}),
      typing: Map<String, dynamic>.from(map['typing'] ?? {}),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
