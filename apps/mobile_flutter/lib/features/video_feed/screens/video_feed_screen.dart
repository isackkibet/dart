import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../design_system/widgets/yohpal_gold_pulse.dart';
import '../../../features/feed/controllers/feed_category_controller.dart';
import '../../../features/feed/domain/feed_category.dart';
import '../../../features/feed/presentation/feed_category_selector.dart';
import '../controllers/video_feed_controller.dart';
import '../controllers/video_interaction_controller.dart';
import '../models/video_model.dart';
import '../../ads/repositories/ads_repository.dart';
import '../../ads/controllers/ads_controller.dart';
import '../../ads/models/ad_campaign_model.dart';
import '../../ads/widgets/in_feed_ad_widget.dart';
import '../../comments/widgets/comments_bottom_sheet.dart';
import '../../creator_profile/controllers/creator_profile_controller.dart';
import '../../engagement/widgets/video_engagement_rail_widget.dart';
import '../../live_streaming/screens/live_discovery_screen.dart';
import '../../search/screens/search_screen.dart';
import '../../video_feed/services/video_safety_service.dart';
import '../../video_playback/controllers/zero_wait_playback_controller.dart';
import '../../video_playback/models/playback_diagnostic_model.dart';
import '../../video_playback/repositories/playback_diagnostics_repository.dart';
import '../../video_playback/widgets/zero_wait_video_player.dart';
import '../widgets/video_overlay_widget.dart';
import '../../context_intelligence/controllers/context_intelligence_controller.dart';
import '../../context_intelligence/models/context_snapshot_model.dart';
// import '../../context_intelligence/widgets/context_action_strip.dart';

class VideoFeedScreen extends StatefulWidget {
  const VideoFeedScreen({super.key});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  Timer? _viewTimer;
  int _activeIndex = 0;
  String _feedType = 'suggested';
  bool _showControls = true;
  Timer? _controlsHideTimer;
  String? _preloadedFeedType;
  late final FeedCategoryController _categoryController;
  late final PageController _pageController;

  final _safetyService = VideoSafetyService();

  @override
  void initState() {
    super.initState();
    _categoryController = FeedCategoryController();
    _pageController = PageController();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ));
  }

  void _scheduleViewTimer() {
    _viewTimer?.cancel();
    final feedCtrl = context.read<VideoFeedController>();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null ||
        feedCtrl.videos.isEmpty ||
        _activeIndex >= feedCtrl.videos.length) {
      return;
    }
    final data = feedCtrl.videos[_activeIndex];
    final videoId = data['id'] as String;
    _viewTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      feedCtrl.addRecentlyViewedVideo(videoId);
      context.read<VideoInteractionController>().recordViewOnce(
            userId: user.uid,
            videoId: videoId,
            creatorId: (data['ownerId'] ?? data['userId'] ?? '') as String,
          );
    });
  }

  void _switchFeed(String type) {
    if (_feedType == type) return;
    setState(() {
      _feedType = type;
      _activeIndex = 0;
    });
    final ctrl = context.read<VideoFeedController>();
    final user = FirebaseAuth.instance.currentUser;
    if (type == 'suggested') {
      ctrl.startSuggestedFeed();
    } else if (type == 'following') {
      ctrl.startFollowingFeed(user?.uid ?? '');
    } else {
      ctrl.startTrendingFeed();
    }
  }

  void _preloadAround(int index, List<String> videoIds) {
    final videos = context.read<VideoFeedController>().videos;
    context.read<ZeroWaitPlaybackController>().preloadAroundAdaptive(
          currentIndex: index,
          dataFor: (i) {
            if (i < 0 || i >= videos.length) return null;
            return {...videos[i], '_feedIndex': i};
          },
        );
  }

  // ── Rail action handlers ──────────────────────────────────────────────

  void _onFollow(
      BuildContext context, VideoModel video, bool currentlyFollowing) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    context.read<CreatorProfileController>().toggleFollow(
          currentlyFollowing: currentlyFollowing,
          followerUid: user.uid,
          creatorUid: video.ownerId,
        );
  }

  void _onLike(BuildContext context, VideoModel video) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    context.read<VideoInteractionController>().toggleLike(
          userId: user.uid,
          videoId: video.id,
          creatorId: video.ownerId,
        );
  }

  void _onComments(BuildContext context, VideoModel video) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsBottomSheet(videoId: video.id),
    );
  }

  void _onFavourite(BuildContext context, VideoModel video) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    context.read<VideoInteractionController>().toggleBookmark(
          userId: user.uid,
          videoId: video.id,
          creatorId: video.ownerId,
        );
  }

  void _onShare(BuildContext context, VideoModel video) {
    final user = FirebaseAuth.instance.currentUser;
    SharePlus.instance.share(
      ShareParams(text: '${video.caption}\n${video.hlsUrl}'),
    );
    if (user != null) {
      context.read<VideoInteractionController>().recordShare(
            userId: user.uid,
            videoId: video.id,
            creatorId: video.ownerId,
          );
    }
  }

  void _onReport(BuildContext context, VideoModel video) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _safetyService.reportVideo(
      userId: user.uid,
      videoId: video.id,
      creatorId: video.ownerId,
      reason: 'user_reported',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report submitted. Thank you.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onNotInterested(BuildContext context, VideoModel video) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _safetyService.markNotInterested(
      userId: user.uid,
      creatorId: video.ownerId,
      videoId: video.id,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("We'll show fewer videos like this."),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onBlock(BuildContext context, VideoModel video) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _safetyService.blockCreator(
      userId: user.uid,
      creatorId: video.ownerId,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('@${video.ownerUsername} blocked.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onDownload(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Download — coming soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _resetControlsTimer() {
    _controlsHideTimer?.cancel();
    if (!mounted) return;
    setState(() => _showControls = true);
    _controlsHideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _onVideoTap() {
    if (_showControls) {
      _resetControlsTimer();
      return;
    }
    setState(() => _showControls = true);
    _controlsHideTimer?.cancel();
    _controlsHideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _showCreatorProfile(VideoModel video) {
    Navigator.pushNamed(context, '/creator-profile', arguments: video.ownerId);
  }

  void _handleSwipe(DragEndDetails details, VideoModel video) {
    final v = details.velocity.pixelsPerSecond;
    // Require clear horizontal dominance to avoid triggering on feed swipes.
    if (v.dx.abs() < v.dy.abs()) return;
    if (v.dx.abs() < 200) return;
    if (v.dx > 0) {
      _showCreatorProfile(video);
    } else {
      Navigator.maybePop(context);
    }
  }

  @override
  void dispose() {
    _viewTimer?.cancel();
    _controlsHideTimer?.cancel();
    _categoryController.dispose();
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VideoFeedController>();
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Row(
              children: [
                Semantics(
                  label: 'Search YohPal Live',
                  button: true,
                  child: IconButton(
                    tooltip: 'Search',
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () => Navigator.pushNamed(
                      context,
                      SearchScreen.routeName,
                    ),
                  ),
                ),
                Expanded(
                  child: FeedCategorySelector(
                    selected: _categoryController.selected,
                    onSelected: (cat) {
                      setState(() {
                        _categoryController.select(cat);
                      });
                      if (cat == FeedCategory.recommended) {
                        _switchFeed('suggested');
                      } else {
                        _switchFeed('following');
                      }
                    },
                  ),
                ),
                Semantics(
                  label: 'Discover live streams',
                  button: true,
                  child: IconButton(
                    tooltip: 'Live now',
                    icon: const Icon(Icons.live_tv, color: Colors.white),
                    onPressed: () => Navigator.pushNamed(
                      context,
                      LiveDiscoveryScreen.routeName,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody(controller)),
        ],
      ),
    );
  }

  Widget _buildBody(VideoFeedController controller) {
    final theme = Theme.of(context);

    if (controller.loading) {
      return const Center(child: YohPalGoldPulse(size: 48));
    }
    if (controller.error != null) {
      return Center(
        child: Semantics(
          liveRegion: true,
          label: 'Video feed failed to load',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, color: Colors.white54, size: 48),
              const SizedBox(height: 12),
              Text(
                'We could not load your feed.',
                style: TextStyle(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: controller.retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    if (controller.videos.isEmpty) {
      return const Center(
        child: Text(
          'No videos available yet',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    // Trigger preload for the first few videos the moment a feed loads,
    // without waiting for the user to swipe.
    if (_preloadedFeedType != _feedType) {
      _preloadedFeedType = _feedType;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _preloadAround(0, const []);
      });
    }

    return StreamBuilder<List<AdCampaignModel>>(
      stream: context.read<AdsRepository>().watchActiveCampaigns(),
      builder: (context, adSnapshot) {
        if (adSnapshot.hasData) {
          Future.microtask(() {
            if (context.mounted) {
              context.read<AdsController>().setCampaigns(adSnapshot.data!);
            }
          });
        }

        return PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: controller.videos.length,
          onPageChanged: (index) {
            setState(() {
              _activeIndex = index;
              _showControls = true;
            });
            _scheduleViewTimer();
            _resetControlsTimer();
            final videoIds =
                controller.videos.map((v) => v['id'] as String).toList();
            _preloadAround(index, videoIds);
            if (index >= controller.videos.length - 5) {
              context.read<VideoFeedController>().loadMore();
            }
            final data = controller.videos[index];
            final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
            context.read<ContextIntelligenceController>().updateContext(
                  ContextSnapshotModel(
                    userId: uid,
                    currentScreen: 'feed',
                    videoId: data['id'] as String?,
                    creatorId: (data['ownerId'] ?? data['userId']) as String?,
                    isFollowingCreator: data['isFollowingCreator'] == true,
                    hasCommerceTags:
                        (data['commerceTags'] as List?)?.isNotEmpty == true,
                    hasActiveCoupon: data['hasActiveCoupon'] == true,
                    hasPoll: data['pollId'] != null,
                    isLiveAvailable: data['creatorIsLive'] == true,
                    canMessageCreator:
                        (data['ownerId'] ?? data['userId']) != uid,
                  ),
                );
          },
          itemBuilder: (context, index) {
            final ad = context.watch<AdsController>().adForIndex(index);
            if (ad != null) return InFeedAdWidget(ad: ad);

            final data = controller.videos[index];
            final videoId = data['id'] as String;
            final video = VideoModel.fromMap(videoId, data);
            final startTime = DateTime.now();

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _onVideoTap,
              onHorizontalDragEnd: (details) => _handleSwipe(details, video),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ZeroWaitVideoPlayer(
                    key: ValueKey(videoId),
                    videoId: videoId,
                    thumbnailUrl: video.thumbnailUrl,
                    playbackUrl: video.hlsUrl,
                    isActive: index == _activeIndex,
                    creatorName: video.ownerUsername.isNotEmpty
                        ? video.ownerUsername
                        : video.ownerId,
                    caption: video.caption,
                    onTap: _resetControlsTimer,
                    onDoubleTapLike: () => _onLike(context, video),
                    onFirstFrame: () {
                      _resetControlsTimer();
                      final elapsed =
                          DateTime.now().difference(startTime).inMilliseconds;
                      PlaybackDiagnosticsRepository().record(
                        PlaybackDiagnosticModel(
                          videoId: videoId,
                          userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                          timeToFirstFrameMs: elapsed,
                          preloadHit: context
                              .read<ZeroWaitPlaybackController>()
                              .isPreloaded(videoId),
                          sourceUrlType:
                              video.hlsUrl.contains('.m3u8') ? 'hls' : 'mp4',
                          networkType: context
                                  .read<ZeroWaitPlaybackController>()
                                  .isOnWifi
                              ? 'wifi'
                              : 'cellular',
                        ),
                      );
                    },
                    onPlaybackError: () {
                      context.read<VideoFeedController>().reportBroken(videoId);
                      PlaybackDiagnosticsRepository().record(
                        PlaybackDiagnosticModel(
                          videoId: videoId,
                          userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                          timeToFirstFrameMs: 9999,
                          preloadHit: false,
                          sourceUrlType: 'unknown',
                          networkType: 'unknown',
                          playbackError: 'startup_timeout',
                        ),
                      );
                    },
                  ),
                ),
                Positioned.fill(
                  child: VideoOverlayWidget(
                    video: video,
                    showControls: _showControls,
                    onTapCreator: () => _showCreatorProfile(video),
                  ),
                ),
                if (_showControls)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.swipe_right, color: Colors.white70, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Swipe right for creator profile',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // ContextActionStrip(
                //   userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                // ),
                if (_showControls)
                  VideoEngagementRailWidget(
                    video: video,
                    followerUid: FirebaseAuth.instance.currentUser?.uid ?? '',
                    creatorUid: video.ownerId,
                    onFollow: (isFollowing) =>
                        _onFollow(context, video, isFollowing),
                    onLike: () => _onLike(context, video),
                    onComments: () => _onComments(context, video),
                    onFavourite: () => _onFavourite(context, video),
                    onShare: () => _onShare(context, video),
                    onReport: () => _onReport(context, video),
                    onNotInterested: () => _onNotInterested(context, video),
                    onBlock: () => _onBlock(context, video),
                    onDownload: () => _onDownload(context),
                  ),
              ],
            ),
          );
          },
        );
      },
    );
  }
}
