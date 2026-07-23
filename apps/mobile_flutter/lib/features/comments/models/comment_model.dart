class CommentModel {
  final String id;
  final String videoId;
  final String userId;
  final String text;
  final String? parentCommentId;
  final int replyCount;
  final int reactionCount;
  final bool reported;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.videoId,
    required this.userId,
    required this.text,
    this.parentCommentId,
    required this.replyCount,
    required this.reactionCount,
    required this.reported,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'videoId': videoId,
      'userId': userId,
      'text': text,
      'parentCommentId': parentCommentId,
      'replyCount': replyCount,
      'reactionCount': reactionCount,
      'reported': reported,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      id: map['id'] ?? '',
      videoId: map['videoId'] ?? '',
      userId: map['userId'] ?? '',
      text: map['text'] ?? '',
      parentCommentId: map['parentCommentId'] as String?,
      replyCount: map['replyCount'] ?? 0,
      reactionCount: map['reactionCount'] ?? 0,
      reported: map['reported'] ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
