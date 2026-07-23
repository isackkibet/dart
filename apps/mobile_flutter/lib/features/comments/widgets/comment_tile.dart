import 'package:flutter/material.dart';
import '../models/comment_model.dart';

const _reactionEmojis = ['❤️', '😂', '🔥', '👏'];

class CommentTile extends StatelessWidget {
  final CommentModel comment;
  final void Function(String emoji) onReact;
  final VoidCallback onReply;
  final VoidCallback onReport;

  const CommentTile({
    super.key,
    required this.comment,
    required this.onReact,
    required this.onReply,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(comment.text, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        '${comment.reactionCount} reactions · ${comment.replyCount} replies',
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'reply') {
            onReply();
          } else if (value == 'report') {
            onReport();
          } else if (_reactionEmojis.contains(value)) {
            onReact(value);
          }
        },
        itemBuilder: (_) => [
          for (final emoji in _reactionEmojis)
            PopupMenuItem(value: emoji, child: Text('$emoji React')),
          const PopupMenuItem(value: 'reply', child: Text('Reply')),
          const PopupMenuItem(value: 'report', child: Text('Report')),
        ],
      ),
    );
  }
}
