class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.type,
    required this.isPinned,
    required this.isDeleted,
    required this.sentAt,
    this.senderAvatarUrl,
  });

  final String id;
  final String sessionId;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;

  final String text;

  /// 'text' | 'gift' | 'system' | 'pinned'
  final String type;

  final bool isPinned;
  final bool isDeleted;
  final DateTime? sentAt;

  bool get isGift => type == 'gift';
  bool get isSystem => type == 'system';
  bool get isText => type == 'text';

  String get displayText => isDeleted ? '[message deleted]' : text;

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) =>
      ChatMessage(
        id: id,
        sessionId: map['sessionId']?.toString() ?? '',
        senderId: map['senderId']?.toString() ?? '',
        senderName: map['senderName']?.toString() ?? 'Viewer',
        senderAvatarUrl: map['senderAvatarUrl']?.toString(),
        text: map['text']?.toString() ?? '',
        type: map['type']?.toString() ?? 'text',
        isPinned: map['isPinned'] == true,
        isDeleted: map['isDeleted'] == true,
        sentAt: _readDate(map['sentAt']),
      );

  static DateTime? _readDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
