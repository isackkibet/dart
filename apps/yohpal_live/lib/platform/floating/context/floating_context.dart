class FloatingContext {
  final String module;
  final String entityId;
  final String title;
  final String? mediaUrl;
  final bool isLive;
  final Map<String, dynamic> payload;
  const FloatingContext({
    required this.module,
    required this.entityId,
    required this.title,
    this.mediaUrl,
    this.isLive = false,
    this.payload = const {},
  });
}
