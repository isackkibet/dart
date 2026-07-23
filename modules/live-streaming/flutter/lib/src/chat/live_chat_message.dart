import 'package:cloud_firestore/cloud_firestore.dart';

final class LiveChatMessage {
  const LiveChatMessage({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String displayName;
  final String text;
  final DateTime createdAt;

  factory LiveChatMessage.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const {};
    return LiveChatMessage(
      id: document.id,
      userId: data['userId'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'YohPal user',
      text: data['text'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
