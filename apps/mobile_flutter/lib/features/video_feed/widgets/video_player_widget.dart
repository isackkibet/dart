import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/video_model.dart';

class VideoPlayerWidget extends StatefulWidget {
  final VideoModel video;
  final void Function(String reason)? onPlaybackError;

  const VideoPlayerWidget({
    super.key,
    required this.video,
    this.onPlaybackError,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  Timer? _stallTimer;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final c = VideoPlayerController.networkUrl(
        Uri.parse(widget.video.hlsUrl),
      );
      _controller = c;
      await c.initialize().timeout(const Duration(seconds: 15));
      await c.setLooping(true);
      await c.play();
      _stallTimer = Timer(const Duration(seconds: 12), () {
        if (mounted && !(_controller?.value.isPlaying ?? false)) {
          _showError();
        }
      });
      if (mounted) setState(() {});
    } catch (e) {
      final msg = e.toString().toLowerCase();
      // Network/SSL errors are transient — show error UI but don't mark the
      // video broken in Firestore, so it recovers automatically on retry.
      final isNetworkError = msg.contains('ssl') ||
          msg.contains('socket') ||
          msg.contains('connection') ||
          msg.contains('network') ||
          msg.contains('timeout') ||
          msg.contains('host');
      if (isNetworkError) {
        _showError();
      } else {
        _fail(e.toString());
      }
    }
  }

  void _showError() {
    if (_failed) return;
    _failed = true;
    if (mounted) setState(() {});
  }

  void _fail(String reason) {
    if (_failed) return;
    _failed = true;
    widget.onPlaybackError?.call(reason);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _stallTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const Center(
        child: Text(
          'Skipping broken video...',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final ready = _controller?.value.isInitialized == true;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.video.thumbnailUrl.isNotEmpty)
          Image.network(widget.video.thumbnailUrl, fit: BoxFit.cover),
        if (ready)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
            ),
          ),
        if (!ready && !_failed)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
