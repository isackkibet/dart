class LiveSession {
  const LiveSession({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.streamMode,
    required this.createdAt,
    required this.updatedAt,
    this.scheduledAt,
    this.startedAt,
    this.endedAt,
  });

  final String id;
  final String creatorId;
  final String title;
  final String description;
  final String category;
  final String status;
  final String streamMode;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? endedAt;

  factory LiveSession.fromMap(String id, Map<String, dynamic> map) {
    return LiveSession(
      id: id,
      creatorId: map['creatorId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      status: map['status']?.toString() ?? 'draft',
      streamMode: map['streamMode']?.toString() ?? 'teaser',
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
      scheduledAt: _readDate(map['scheduledAt']),
      startedAt: _readDate(map['startedAt']),
      endedAt: _readDate(map['endedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'creatorId': creatorId,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'streamMode': streamMode,
      'scheduledAt': scheduledAt?.toUtc().toIso8601String(),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
  }

  LiveSession copyWith({
    String? id,
    String? creatorId,
    String? title,
    String? description,
    String? category,
    String? status,
    String? streamMode,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? scheduledAt,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return LiveSession(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      streamMode: streamMode ?? this.streamMode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  static DateTime? _readDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
