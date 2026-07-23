class LiveSessionModel {
  final String id;
  final String creatorId;
  final String title;
  final String description;
  final String status;
  final String roomName;
  final int viewerCount;
  final DateTime createdAt;

  const LiveSessionModel({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.status,
    required this.roomName,
    required this.viewerCount,
    required this.createdAt,
  });

  factory LiveSessionModel.fromMap(Map<String, dynamic> map) {
    return LiveSessionModel(
      id: map['id'] ?? '',
      creatorId: map['creatorId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'scheduled',
      roomName: map['roomName'] ?? '',
      viewerCount: map['viewerCount'] ?? 0,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'creatorId': creatorId,
      'title': title,
      'description': description,
      'status': status,
      'roomName': roomName,
      'viewerCount': viewerCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
