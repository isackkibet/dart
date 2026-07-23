import 'package:flutter/material.dart';
import '../controllers/video_feed_controller.dart';
import '../zero_wait/services/feed_startup_warmup_service.dart';
import '../zero_wait/widgets/zero_wait_video_player.dart';

/// Zero-wait feed screen entry point.
///
/// Receives explicit dependencies so the caller controls object lifetimes and
/// can swap implementations without touching Provider configuration.
class VideoFeedScreen extends StatefulWidget {
  const VideoFeedScreen({
    super.key,
    required this.startupWarmup,
    required this.feedController,
  });

  final FeedStartupWarmupService startupWarmup;
  final VideoFeedController feedController;

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _runWarmup();
  }

  Future<void> _runWarmup() async {
    try {
      final result = await widget.startupWarmup.execute();
      await widget.feedController.initialize(
        initialVideos: result.inventory,
        policy: result.policy,
      );
    } finally {
      if (mounted) setState(() => _ready = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return _FeedView(feedController: widget.feedController);
  }
}

class _FeedView extends StatefulWidget {
  const _FeedView({required this.feedController});
  final VideoFeedController feedController;

  @override
  State<_FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<_FeedView> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    widget.feedController.addListener(_onFeedChanged);
  }

  void _onFeedChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.feedController.removeListener(_onFeedChanged);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videos = widget.feedController.inventory;

    if (videos.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: videos.length,
        onPageChanged: (index) {
          widget.feedController.onPageChanged(index);
        },
        itemBuilder: (context, index) {
          final video = videos[index];
          return ZeroWaitVideoPlayer(video: video);
        },
      ),
    );
  }
}
