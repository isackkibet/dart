import 'dart:io';

import 'package:video_player/video_player.dart';

/// Reads a local video file's duration without keeping a player around —
/// needed whenever a clip is added to the timeline, since [VideoClipEdit]
/// requires `sourceDurationMs` up front.
final class VideoProbeService {
  const VideoProbeService();

  Future<int> durationMs(File file) async {
    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      return controller.value.duration.inMilliseconds;
    } finally {
      await controller.dispose();
    }
  }
}
