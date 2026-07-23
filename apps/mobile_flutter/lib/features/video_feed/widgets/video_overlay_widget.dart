import 'package:flutter/material.dart';
import '../../creator_profile/widgets/creator_identity_block.dart';
import '../../polls/widgets/video_poll_overlay.dart';
import '../models/video_model.dart';

// Displays creator info, caption, and the poll overlay.
// Action buttons live in VideoEngagementRailWidget (features/engagement/).
class VideoOverlayWidget extends StatelessWidget {
  final VideoModel video;
  final bool showControls;
  final VoidCallback? onTapCreator;

  const VideoOverlayWidget({
    super.key,
    required this.video,
    this.showControls = true,
    this.onTapCreator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!showControls) {
      return VideoPollOverlay(videoId: video.id);
    }

    final handle = video.ownerUsername.isNotEmpty
        ? video.ownerUsername
        : video.ownerId;
    final displayName = video.ownerDisplayName.trim();
    final showDisplayName = displayName.isNotEmpty && displayName != handle;

    return Stack(
      children: [
        VideoPollOverlay(videoId: video.id),
        Positioned(
          left: 16,
          bottom: 88,
          right: 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CreatorIdentityBlock(
                displayName: showDisplayName ? displayName : handle,
                username: handle,
                verified: video.ownerVerified,
                onOpenProfile: onTapCreator ??
                    () => Navigator.pushNamed(
                          context,
                          '/creator-profile',
                          arguments: video.ownerId,
                        ),
              ),
              const SizedBox(height: 4),
              Text(
                video.timestampLabel,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                  fontSize: 12,
                  shadows: const [Shadow(blurRadius: 4)],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                video.caption,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  shadows: const [Shadow(blurRadius: 4)],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (video.isMinorSafetyRestricted)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Minor-safety review required before publishing',
                    style: TextStyle(
                      color: theme.colorScheme.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      shadows: const [Shadow(blurRadius: 4)],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
