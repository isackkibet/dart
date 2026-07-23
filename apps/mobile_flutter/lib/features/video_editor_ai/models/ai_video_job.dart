class AiVideoJob {
  final String id;
  final String userId;
  final String videoId;
  final String type;
  final String status;
  final Map<String, dynamic> input;
  final Map<String, dynamic> result;
  final String? error;
  final DateTime createdAt;

  const AiVideoJob({
    required this.id,
    required this.userId,
    required this.videoId,
    required this.type,
    required this.status,
    required this.input,
    required this.result,
    this.error,
    required this.createdAt,
  });

  factory AiVideoJob.fromMap(Map<String, dynamic> map) {
    return AiVideoJob(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      videoId: map['videoId'] ?? '',
      type: map['type'] ?? '',
      status: map['status'] ?? 'queued',
      input: Map<String, dynamic>.from(map['input'] ?? {}),
      result: Map<String, dynamic>.from(map['result'] ?? {}),
      error: map['error'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
