class AppNotificationPayload {
  final String type;
  final String? videoId;
  final String? liveSessionId;
  final String? chatId;
  final String? pollId;

  const AppNotificationPayload({
    required this.type,
    this.videoId,
    this.liveSessionId,
    this.chatId,
    this.pollId,
  });

  factory AppNotificationPayload.fromMap(Map<String, dynamic> data) {
    return AppNotificationPayload(
      type: data['type'] ?? '',
      videoId: data['videoId'] as String?,
      liveSessionId: data['liveSessionId'] as String?,
      chatId: data['chatId'] as String?,
      pollId: data['pollId'] as String?,
    );
  }
}
