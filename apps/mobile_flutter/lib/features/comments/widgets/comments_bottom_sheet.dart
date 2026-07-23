import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/comments_controller.dart';
import '../repositories/comment_repository.dart';
import 'comment_input.dart';
import 'comment_tile.dart';

class CommentsBottomSheet extends StatefulWidget {
  final String videoId;

  const CommentsBottomSheet({super.key, required this.videoId});

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  String? _replyingToCommentId;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final repo = context.read<CommentRepository>();
    final controller = context.watch<CommentsController>();

    final mq = MediaQuery.of(context);
    final bottomInset = mq.viewInsets.bottom + mq.padding.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFF101527),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'Comments',
            style: TextStyle(color: Colors.white, fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          if (controller.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                controller.error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder(
              stream: repo.watchTopLevelComments(widget.videoId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Failed to load comments',
                        style: TextStyle(color: Colors.white54)),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final comments = snapshot.data!;
                if (comments.isEmpty) {
                  return const Center(
                    child: Text('No comments yet — be the first!',
                        style: TextStyle(color: Colors.white54)),
                  );
                }
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return CommentTile(
                      comment: comment,
                      onReply: () =>
                          setState(() => _replyingToCommentId = comment.id),
                      onReact: (emoji) {
                        if (user == null) return;
                        controller.react(
                          commentId: comment.id,
                          userId: user.uid,
                          emoji: emoji,
                        );
                      },
                      onReport: () {
                        if (user == null) return;
                        controller.report(
                          commentId: comment.id,
                          userId: user.uid,
                          reason: 'Reported by user',
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          if (_replyingToCommentId != null)
            TextButton.icon(
              onPressed: () => setState(() => _replyingToCommentId = null),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Cancel reply'),
            ),
          CommentInput(
            hint: _replyingToCommentId == null
                ? 'Add a comment...'
                : 'Write a reply...',
            loading: controller.loading,
            onSend: (text) {
              if (user == null) return;
              controller.addComment(
                videoId: widget.videoId,
                userId: user.uid,
                text: text,
                parentCommentId: _replyingToCommentId,
              );
              setState(() => _replyingToCommentId = null);
            },
          ),
        ],
      ),
    );
  }
}
