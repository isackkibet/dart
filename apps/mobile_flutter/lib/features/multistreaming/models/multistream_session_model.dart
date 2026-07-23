class MultistreamSessionModel {
  final String id;
  final String liveSessionId;
  final String creatorId;
  final String status;

  const MultistreamSessionModel({
    required this.id,
    required this.liveSessionId,
    required this.creatorId,
    required this.status,
  });

  factory MultistreamSessionModel.fromMap(Map<String, dynamic> map) {
    return MultistreamSessionModel(
      id: map['id'] ?? '',
      liveSessionId: map['liveSessionId'] ?? '',
      creatorId: map['creatorId'] ?? '',
      status: map['status'] ?? 'pending',
    );
  }
}
