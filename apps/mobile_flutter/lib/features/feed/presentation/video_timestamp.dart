import 'package:flutter/material.dart';

String formatVideoTimestamp(
  DateTime publishedAt, {
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final difference = current.difference(publishedAt.toLocal());
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inHours < 1) return '${difference.inMinutes}m ago';
  if (difference.inDays < 1) return '${difference.inHours}h ago';
  if (difference.inDays == 1) return 'Yesterday';
  if (difference.inDays < 7) return '${difference.inDays}d ago';
  return '${publishedAt.day.toString().padLeft(2, '0')}/'
      '${publishedAt.month.toString().padLeft(2, '0')}/'
      '${publishedAt.year}';
}

class VideoTimestamp extends StatelessWidget {
  const VideoTimestamp({
    required this.publishedAt,
    super.key,
  });

  final DateTime publishedAt;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatVideoTimestamp(publishedAt),
      key: const ValueKey('video-timestamp'),
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.8),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class VideoTimestampOverlay extends StatelessWidget {
  final DateTime publishedAt;

  const VideoTimestampOverlay({super.key, required this.publishedAt});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 4,
      bottom: 4,
      right: 4,
      child: VideoTimestamp(publishedAt: publishedAt),
    );
  }
}
