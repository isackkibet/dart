import 'package:flutter/material.dart';
import '../controllers/overlay_visibility_controller.dart';
import '../domain/feed_video.dart';
import 'feed_video_overlay.dart';

class ImmersiveVideoPage extends StatefulWidget {
  const ImmersiveVideoPage({
    required this.video,
    required this.videoPlayer,
    required this.onLike,
    required this.onOpenCreator,
    super.key,
  });

  final FeedVideo video;
  final Widget videoPlayer;
  final VoidCallback onLike;
  final VoidCallback onOpenCreator;

  @override
  State<ImmersiveVideoPage> createState() => _ImmersiveVideoPageState();
}

class _ImmersiveVideoPageState extends State<ImmersiveVideoPage> {
  late final OverlayVisibilityController _overlays;

  @override
  void initState() {
    super.initState();
    _overlays = OverlayVisibilityController()
      ..addListener(_refresh)
      ..start();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _overlays
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _overlays.toggle,
        onDoubleTap: () {
          widget.onLike();
          _overlays.showTemporarily();
        },
        onHorizontalDragEnd: (details) {
          final v = details.velocity.pixelsPerSecond;
          if (v.dx.abs() <= v.dy.abs()) return;
          if (v.dx > 500) widget.onOpenCreator();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: widget.videoPlayer,
                ),
              ),
            ),
            IgnorePointer(
              ignoring: !_overlays.visible,
              child: AnimatedOpacity(
                opacity: _overlays.visible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 220),
                child: FeedVideoOverlay(
                  video: widget.video,
                  onOpenCreator: widget.onOpenCreator,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
