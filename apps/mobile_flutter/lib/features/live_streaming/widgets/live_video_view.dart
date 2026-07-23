import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

class LiveVideoView extends StatelessWidget {
  final Room room;

  const LiveVideoView({super.key, required this.room});

  // Local and remote have different publication types — handle separately
  // to avoid losing the VideoTrack type through Dart's generic inference.
  VideoTrack? _findActiveVideoTrack() {
    final local = room.localParticipant;
    if (local != null) {
      for (final pub in local.videoTrackPublications) {
        final track = pub.track;
        if (track is VideoTrack) return track;
      }
    }
    for (final participant in room.remoteParticipants.values) {
      for (final pub in participant.videoTrackPublications) {
        final track = pub.track;
        if (track is VideoTrack) return track;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final track = _findActiveVideoTrack();
    if (track == null) {
      return Center(
        child: Text(
          'Waiting for video...',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
      );
    }
    return VideoTrackRenderer(track);
  }
}
