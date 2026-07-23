import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../comments/widgets/comments_bottom_sheet.dart';
import '../../context_intelligence/controllers/context_intelligence_controller.dart';
import '../../context_intelligence/models/context_snapshot_model.dart';
import '../../creator_profile/controllers/creator_profile_controller.dart';
import '../../video_feed/controllers/video_interaction_controller.dart';
import '../../video_feed/models/video_model.dart';
import '../../video_feed/services/video_safety_service.dart';
import '../../video_feed/widgets/video_overlay_widget.dart';
import '../../video_playback/controllers/zero_wait_playback_controller.dart';
import '../../video_playback/models/playback_diagnostic_model.dart';
import '../../video_playback/repositories/playback_diagnostics_repository.dart';
import '../../video_playback/widgets/zero_wait_video_player.dart';
import '../../engagement/widgets/video_engagement_rail_widget.dart';

/// Full-screen vertical feed of a creator's videos, starting at [initialIndex].
/// Stack layout mirrors VideoFeedScreen — immersive, no nav bar, no top bar.
class CreatorVideoFeedScreen extends StatefulWidget {
  final List<VideoModel> videos;
  final int initialIndex;

  const CreatorVideoFeedScreen({
    super.key,
    required this.videos,
    required this.initialIndex,
  });

  @override
  State<CreatorVideoFeedScreen> createState() => _CreatorVideoFeedScreenState();
}

class _CreatorVideoFeedScreenState extends State<CreatorVideoFeedScreen> {
  late final PageController _pageController;
  late int _activeIndex;
  Timer? _viewTimer;
  Timer? _controlsTimer;
  bool _showControls = true;
  final _safetyService = VideoSafetyService();

  @override
  void initState() {
    super.initState();
    _activeIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadAround(_activeIndex);
      _resetControlsTimer();
    });
  }

  @override
  void dispose() {
    _viewTimer?.cancel();
    _controlsTimer?.cancel();
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    if (!_showControls) setState(() => _showControls = true);
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _preloadAround(int index) {
    context.read<ZeroWaitPlaybackController>().preloadAroundAdaptive(
          currentIndex: index,
          dataFor: (i) {
            if (i < 0 || i >= widget.videos.length) return null;
            final v = widget.videos[i];
            return {'id': v.id, 'hlsUrl': v.hlsUrl, '_feedIndex': i};
          },
        );
  }

  void _scheduleViewTimer(int index) {
    _viewTimer?.cancel();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || index >= widget.videos.length) return;
    final video = widget.videos[index];
    _viewTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      context.read<VideoInteractionController>().recordViewOnce(
            userId: user.uid,
            videoId: video.id,
            creatorId: video.ownerId,
          );
    });
  }

  void _onFollow(VideoModel video, bool currentlyFollowing) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    context.read<CreatorProfileController>().toggleFollow(
          currentlyFollowing: currentlyFollowing,
          followerUid: user.uid,
          creatorUid: video.ownerId,
        );
  }

  void _onLike(VideoModel video) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    context.read<VideoInteractionController>().toggleLike(
          userId: user.uid,
          videoId: video.id,
          creatorId: video.ownerId,
        );
  }

  void _onComments(VideoModel video) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsBottomSheet(videoId: video.id),
    );
  }

  void _onFavourite(VideoModel video) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    context.read<VideoInteractionController>().toggleBookmark(
          userId: user.uid,
          videoId: video.id,
          creatorId: video.ownerId,
        );
  }

  void _onShare(VideoModel video) {
    SharePlus.instance.share(
      ShareParams(text: '${video.caption}\n${video.hlsUrl}'),
    );
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.read<VideoInteractionController>().recordShare(
            userId: user.uid,
            videoId: video.id,
            creatorId: video.ownerId,
          );
    }
  }

  void _onReport(VideoModel video) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _safetyService.reportVideo(
      userId: user.uid,
      videoId: video.id,
      creatorId: video.ownerId,
      reason: 'user_reported',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report submitted. Thank you.')),
    );
  }

  void _onNotInterested(VideoModel video) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _safetyService.markNotInterested(
      userId: user.uid,
      creatorId: video.ownerId,
      videoId: video.id,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("We'll show fewer videos like this.")),
    );
  }

  void _onBlock(VideoModel video) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _safetyService.blockCreator(userId: user.uid, creatorId: video.ownerId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('@${video.ownerUsername} blocked.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: widget.videos.length,
            onPageChanged: (index) {
              setState(() => _activeIndex = index);
              _scheduleViewTimer(index);
              _preloadAround(index);
              _resetControlsTimer();
              final video = widget.videos[index];
              context.read<ContextIntelligenceController>().updateContext(
                    ContextSnapshotModel(
                      userId: uid,
                      currentScreen: 'creator_feed',
                      videoId: video.id,
                      creatorId: video.ownerId,
                      isFollowingCreator: false,
                      hasCommerceTags: false,
                      hasActiveCoupon: false,
                      hasPoll: false,
                      isLiveAvailable: false,
                      canMessageCreator: video.ownerId != uid,
                    ),
                  );
            },
            itemBuilder: (context, index) {
              final video = widget.videos[index];
              final startTime = DateTime.now();

              return Stack(
                children: [
                  Positioned.fill(
                    child: ZeroWaitVideoPlayer(
                      videoId: video.id,
                      thumbnailUrl: video.thumbnailUrl,
                      playbackUrl: video.hlsUrl,
                      isActive: index == _activeIndex,
                      onTap: _resetControlsTimer,
                      onFirstFrame: () {
                        final elapsed =
                            DateTime.now().difference(startTime).inMilliseconds;
                        PlaybackDiagnosticsRepository().record(
                          PlaybackDiagnosticModel(
                            videoId: video.id,
                            userId: uid,
                            timeToFirstFrameMs: elapsed,
                            preloadHit: context
                                .read<ZeroWaitPlaybackController>()
                                .isPreloaded(video.id),
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
                        PlaybackDiagnosticsRepository().record(
                          PlaybackDiagnosticModel(
                            videoId: video.id,
                            userId: uid,
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
                      onTapCreator: () => Navigator.of(context).pop(),
                    ),
                  ),
                  VideoEngagementRailWidget(
                    video: video,
                    followerUid: uid,
                    creatorUid: video.ownerId,
                    onFollow: (isFollowing) => _onFollow(video, isFollowing),
                    onLike: () => _onLike(video),
                    onComments: () => _onComments(video),
                    onFavourite: () => _onFavourite(video),
                    onShare: () => _onShare(video),
                    onReport: () => _onReport(video),
                    onNotInterested: () => _onNotInterested(video),
                    onBlock: () => _onBlock(video),
                    onDownload: () =>
                        ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Download — coming soon.')),
                    ),
                  ),
                ],
              );
            },
          ),
          if (_showControls)
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  tooltip: 'Back to profile',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
