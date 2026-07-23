import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'yohpal_player_pool.dart';
import 'yohpal_video_cache_manager.dart';
import 'yohpal_video_preload_manager.dart';
import 'yohpal_video_source.dart';

class YohPalVideoFeedPage extends StatefulWidget {
  final List<YohPalVideoSource> videos;

  const YohPalVideoFeedPage({
    super.key,
    required this.videos,
  });

  @override
  State<YohPalVideoFeedPage> createState() => _YohPalVideoFeedPageState();
}

class _YohPalVideoFeedPageState extends State<YohPalVideoFeedPage> {
  final PageController _pageController = PageController();
  final YohPalPlayerPool _pool = YohPalPlayerPool(maxPlayers: 3);
  late final YohPalVideoPreloadManager _preloadManager;

  int _currentIndex = 0;
  final bool _isWifi = false;
  final bool _lowDataMode = false;

  @override
  void initState() {
    super.initState();
    _preloadManager = YohPalVideoPreloadManager(YohPalVideoCacheManager());
    _loadCurrentVideo(0);
  }

  Future<void> _loadCurrentVideo(int index) async {
    if (index < 0 || index >= widget.videos.length) return;
    final engine = _pool.acquire();
    await engine.load(
      video: widget.videos[index],
      isWifi: _isWifi,
      lowDataMode: _lowDataMode,
      playImmediately: true,
    );
    await _pool.pauseAllExcept(engine);
    await _preloadManager.preloadNext(
      videos: widget.videos,
      currentIndex: index,
      isWifi: _isWifi,
      lowDataMode: _lowDataMode,
    );
    if (mounted) setState(() => _currentIndex = index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pool.disposeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: widget.videos.length,
      onPageChanged: _loadCurrentVideo,
      itemBuilder: (context, index) {
        final engine = _pool.getByIndex(0);
        if (engine == null || index != _currentIndex) {
          return const ColoredBox(
            color: Colors.black,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return ColoredBox(
          color: Colors.black,
          child: Video(
            controller: VideoController(engine.player),
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}
