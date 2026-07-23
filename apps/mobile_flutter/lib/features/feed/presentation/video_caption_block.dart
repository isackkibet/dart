import 'package:flutter/material.dart';
import '../../creator_profile/widgets/creator_identity_block.dart';
import '../domain/feed_video.dart';
import 'video_timestamp.dart';

class VideoCaptionBlock extends StatelessWidget {
  const VideoCaptionBlock({
    required this.video,
    required this.onOpenCreator,
    super.key,
  });

  final FeedVideo video;
  final VoidCallback onOpenCreator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CreatorIdentityBlock(
          displayName: video.creatorDisplayName.isNotEmpty
              ? video.creatorDisplayName
              : video.creatorName,
          username: video.creatorUsername.isNotEmpty
              ? video.creatorUsername
              : video.creatorName,
          verified: video.creatorVerified,
          onOpenProfile: onOpenCreator,
        ),
        const SizedBox(height: 5),
        VideoTimestamp(publishedAt: video.publishedAt),
        const SizedBox(height: 5),
        Text(
          video.caption,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            shadows: [Shadow(blurRadius: 4)],
          ),
        ),
      ],
    );
  }
}
