class CommentReactionModel {
  final String id;
  final String commentId;
  final String userId;
  final String emoji;
  final DateTime createdAt;

  const CommentReactionModel({
    required this.id,
    required this.commentId,
    required this.userId,
    required this.emoji,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'commentId': commentId,
      'userId': userId,
      'emoji': emoji,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
