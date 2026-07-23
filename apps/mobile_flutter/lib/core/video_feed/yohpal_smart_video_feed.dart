import 'package:flutter/material.dart';

import '../video_native/yohpal_native_video_controller.dart';
import '../video_native/yohpal_native_video_view.dart';
import 'yohpal_feed_cache_service.dart';
import 'yohpal_feed_preload_service.dart';
import 'yohpal_feed_video_source.dart';
import 'yohpal_smart_player_pool.dart';
import 'yohpal_video_quality_selector.dart';

class YohPalSmartVideoFeed extends StatefulWidget {
  final List<YohPalFeedVideoSource> videos;
  final bool lowDataMode;
  final bool hlsEnabled;
  final bool isWifi;

  const YohPalSmartVideoFeed({
    super.key,
    required this.videos,
    required this.lowDataMode,
    required this.hlsEnabled,
    required this.isWifi,
  });

  @override
  State<YohPalSmartVideoFeed> createState() => _YohPalSmartVideoFeedState();
}

class _YohPalSmartVideoFeedState extends State<YohPalSmartVideoFeed> {
  late final YohPalSmartPlayerPool pool;
  late final YohPalFeedPreloadService preloadService;
  final PageController pageController = PageController();
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final qualitySelector = YohPalVideoQualitySelector();
    pool = YohPalSmartPlayerPool(
      qualitySelector: qualitySelector,
      previousController: YohPalNativeVideoController(),
      currentController: YohPalNativeVideoController(),
      nextController: YohPalNativeVideoController(),
    );
    preloadService = YohPalFeedPreloadService(
      cacheService: YohPalFeedCacheService(),
      qualitySelector: qualitySelector,
    );
    _onPageChanged(0);
  }

  Future<void> _onPageChanged(int index) async {
    currentIndex = index;
    await pool.bindWindow(
      videos: widget.videos,
      currentIndex: index,
      isWifi: widget.isWifi,
      lowDataMode: widget.lowDataMode,
      hlsEnabled: widget.hlsEnabled,
    );
    await preloadService.preloadAround(
      videos: widget.videos,
      currentIndex: index,
      isWifi: widget.isWifi,
      lowDataMode: widget.lowDataMode,
      hlsEnabled: widget.hlsEnabled,
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    pool.disposeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: pageController,
      scrollDirection: Axis.vertical,
      itemCount: widget.videos.length,
      onPageChanged: _onPageChanged,
      itemBuilder: (context, index) {
        return const ColoredBox(
          color: Colors.black,
          child: YohPalNativeVideoView(),
        );
      },
    );
  }
}
