import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../controllers/zero_wait_playback_controller.dart';
import '../models/preload_video.dart';

/// Renders a single [PreloadVideo] from the zero-wait buffer.
///
/// Reads the [ZeroWaitPlaybackController] from the widget tree via Provider.
/// Starts playback on mount and pauses on unmount.
class ZeroWaitVideoPlayer extends StatefulWidget {
  const ZeroWaitVideoPlayer({
    super.key,
    required this.video,
    this.fit = BoxFit.cover,
  });

  final PreloadVideo video;
  final BoxFit fit;

  @override
  State<ZeroWaitVideoPlayer> createState() => _ZeroWaitVideoPlayerState();
}

class _ZeroWaitVideoPlayerState extends State<ZeroWaitVideoPlayer> {
  ZeroWaitPlaybackController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ctrl = context.read<ZeroWaitPlaybackController>();
    if (_controller != ctrl) {
      _controller?.removeListener(_rebuild);
      _controller = ctrl;
      _controller!.addListener(_rebuild);
      _controller!.play(widget.video.id);
    }
  }

  @override
  void didUpdateWidget(ZeroWaitVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video.id != widget.video.id) {
      _controller?.pause(oldWidget.video.id);
      _controller?.play(widget.video.id);
    }
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_rebuild);
    _controller?.pause(widget.video.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ZeroWaitPlaybackController>().controllerFor(widget.video.id);

    if (ctrl == null || !ctrl.value.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }

    return AspectRatio(
      aspectRatio: ctrl.value.aspectRatio > 0 ? ctrl.value.aspectRatio : 9 / 16,
      child: VideoPlayer(ctrl),
    );
  }
}
