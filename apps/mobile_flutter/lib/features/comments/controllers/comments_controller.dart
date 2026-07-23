import 'package:flutter/foundation.dart';
import '../repositories/comment_repository.dart';

class CommentsController extends ChangeNotifier {
  final CommentRepository repository;

  CommentsController({required this.repository});

  bool loading = false;
  String? error;

  Future<void> addComment({
    required String videoId,
    required String userId,
    required String text,
    String? parentCommentId,
  }) async {
    if (text.trim().isEmpty) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      await repository.addComment(
        videoId: videoId,
        userId: userId,
        text: text.trim(),
        parentCommentId: parentCommentId,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> react({
    required String commentId,
    required String userId,
    required String emoji,
  }) async {
    try {
      await repository.reactToComment(
        commentId: commentId,
        userId: userId,
        emoji: emoji,
      );
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> report({
    required String commentId,
    required String userId,
    required String reason,
  }) async {
    try {
      await repository.reportComment(
        commentId: commentId,
        userId: userId,
        reason: reason,
      );
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }
}
