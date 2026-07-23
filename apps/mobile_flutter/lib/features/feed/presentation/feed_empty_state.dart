import 'package:flutter/material.dart';
import '../domain/feed_category.dart';

class FeedEmptyState extends StatelessWidget {
  const FeedEmptyState({
    required this.category,
    this.onRefresh,
    super.key,
  });

  final FeedCategory category;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final message = switch (category) {
      FeedCategory.following =>
        'Follow creators to see their latest videos here.',
      FeedCategory.recommended => 'No videos available right now.',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.video_library_outlined,
                size: 48, color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            if (onRefresh != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const ValueKey('feed-empty-refresh'),
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
