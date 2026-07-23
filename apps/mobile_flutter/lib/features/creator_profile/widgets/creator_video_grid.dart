import 'package:flutter/material.dart';
import '../domain/creator_profile_video.dart';

String compactCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

class CreatorVideoGrid extends StatelessWidget {
  const CreatorVideoGrid({
    required this.videos,
    required this.loading,
    required this.error,
    required this.hasMore,
    required this.onRetry,
    required this.onLoadMore,
    required this.onOpenVideo,
    super.key,
  });

  final List<CreatorProfileVideo> videos;
  final bool loading;
  final Object? error;
  final bool hasMore;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;
  final ValueChanged<CreatorProfileVideo> onOpenVideo;

  @override
  Widget build(BuildContext context) {
    if (loading && videos.isEmpty) {
      return const SliverGrid(
        key: ValueKey('creator-video-grid-loading'),
        delegate: SliverChildBuilderDelegate(
          _loadingTile,
          childCount: 9,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: 9 / 16,
        ),
      );
    }

    if (error != null && videos.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Text('Videos could not be loaded.'),
              const SizedBox(height: 12),
              FilledButton(
                key: const ValueKey('creator-video-grid-retry'),
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (videos.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No videos in this category.',
              key: ValueKey('creator-video-grid-empty'),
            ),
          ),
        ),
      );
    }

    return SliverGrid(
      key: const ValueKey('creator-video-grid'),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (hasMore && index >= videos.length - 6) {
            onLoadMore();
          }
          final video = videos[index];
          return InkWell(
            key: ValueKey('creator-video-${video.id}'),
            onTap: () => onOpenVideo(video),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  video.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const ColoredBox(
                      color: Colors.black12,
                      child: Icon(Icons.broken_image_outlined),
                    );
                  },
                ),
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.play_arrow,
                        size: 15,
                        color: Colors.white,
                      ),
                      Text(
                        compactCount(video.views),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        childCount: videos.length,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 9 / 16,
      ),
    );
  }

  static Widget _loadingTile(BuildContext context, int index) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}
