import 'package:flutter/material.dart';
import '../domain/feed_video.dart';
import 'video_caption_block.dart';

class FeedVideoOverlay extends StatelessWidget {
  const FeedVideoOverlay({
    required this.video,
    required this.onOpenCreator,
    super.key,
  });

  final FeedVideo video;
  final VoidCallback onOpenCreator;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 16,
          bottom: 88,
          right: 90,
          child: VideoCaptionBlock(
            video: video,
            onOpenCreator: onOpenCreator,
          ),
        ),
      ],
    );
  }
}
