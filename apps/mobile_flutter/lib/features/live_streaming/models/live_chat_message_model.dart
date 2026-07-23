class LiveChatMessageModel {
  final String id;
  final String sessionId;
  final String userId;
  final String displayName;
  final String text;
  final bool hidden;
  final bool reported;
  final String reportReason;
  final DateTime createdAt;

  const LiveChatMessageModel({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.displayName,
    required this.text,
    required this.hidden,
    required this.reported,
    required this.reportReason,
    required this.createdAt,
  });

  factory LiveChatMessageModel.fromMap(Map<String, dynamic> map) {
    return LiveChatMessageModel(
      id: map['id'] ?? '',
      sessionId: map['sessionId'] ?? '',
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? '',
      text: map['text'] ?? '',
      hidden: map['hidden'] ?? false,
      reported: map['reported'] ?? false,
      reportReason: map['reportReason'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'userId': userId,
      'displayName': displayName,
      'text': text,
      'hidden': hidden,
      'reported': reported,
      'reportReason': reportReason,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
