import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import '../../../design_system/widgets/yohpal_gold_pulse.dart';
import '../controllers/zero_wait_playback_controller.dart';

class ZeroWaitVideoPlayer extends StatefulWidget {
  final String videoId;
  final String thumbnailUrl;
  final String playbackUrl;
  final bool isActive;
  final String creatorName;
  final String caption;
  final VoidCallback? onFirstFrame;
  final VoidCallback? onPlaybackError;
  final VoidCallback? onDoubleTapLike;
  final VoidCallback? onTap;

  const ZeroWaitVideoPlayer({
    super.key,
    required this.videoId,
    required this.thumbnailUrl,
    required this.playbackUrl,
    required this.isActive,
    this.creatorName = '',
    this.caption = '',
    this.onFirstFrame,
    this.onPlaybackError,
    this.onDoubleTapLike,
    this.onTap,
  });

  @override
  State<ZeroWaitVideoPlayer> createState() => _ZeroWaitVideoPlayerState();
}

class _ZeroWaitVideoPlayerState extends State<ZeroWaitVideoPlayer> {
  bool _firstFrameShown = false;
  bool _userPaused = false;
  bool _showPauseIcon = false;
  bool _showHeart = false;
  Timer? _startupTimer;
  Timer? _pauseIconTimer;
  // Stream subscriptions for first-frame and error detection on the Player.
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<String>? _errorSub;

  @override
  void initState() {
    super.initState();
    _warm();
  }

  @override
  void didUpdateWidget(covariant ZeroWaitVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Feed reordering can put a different video at this PageView index.
    // Reset all playback state so we don't show the previous video's frame.
    if (widget.videoId != oldWidget.videoId) {
      _firstFrameShown = false;
      _cleanupListeners();
      _startupTimer?.cancel();
      _userPaused = false;
      if (widget.isActive) _warm();
      return;
    }
    if (widget.isActive && !oldWidget.isActive) {
      _userPaused = false;
      _play();
    }
    if (!widget.isActive && oldWidget.isActive) {
      context.read<ZeroWaitPlaybackController>().pause(widget.videoId);
    }
  }

  Future<void> _warm() async {
    if (!mounted) return;
    await context.read<ZeroWaitPlaybackController>().warmVideo(
          videoId: widget.videoId,
          url: widget.playbackUrl,
        );
    // Guard against the race where didUpdateWidget already called _play() while
    // warmVideo() was in-flight: if the startup timer is running or the first
    // frame has already been confirmed, a second _play() call would cancel and
    // restart the timer — causing a spurious ~4-second timeout on a healthy video.
    if (widget.isActive &&
        !_userPaused &&
        !_firstFrameShown &&
        _startupTimer == null) {
      await _play();
    }
  }

  Future<void> _play() async {
    if (!mounted) return;
    _startupTimer?.cancel();
    _cleanupListeners();

    final ctrl = context.read<ZeroWaitPlaybackController>();
    final player = ctrl.playerFor(widget.videoId);
    if (player == null) {
      // Not yet opened — defer so we don't call notifyListeners during build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onPlaybackError?.call();
      });
      return;
    }
    // Only wait for first-frame confirmation when we haven't seen one yet.
    // For returning to a previously-watched video, resume immediately so
    // there's no thumbnail flash — the Video widget already has the correct
    // content from when the player was paused.
    if (!_firstFrameShown) {
      _attachFrameListener(player);
      _startupTimer = Timer(const Duration(seconds: 4), () {
        _cleanupListeners();
        if (!_firstFrameShown) widget.onPlaybackError?.call();
      });
    }
    await ctrl.play(widget.videoId);
  }

  void _attachFrameListener(Player player) {
    _cleanupListeners();
    _posSub = player.stream.position.listen((pos) {
      if (!_firstFrameShown && pos > Duration.zero) {
        _firstFrameShown = true;
        _startupTimer?.cancel();
        _cleanupListeners();
        if (mounted) setState(() {});
        widget.onFirstFrame?.call();
      }
    });
    _errorSub = player.stream.error.listen((error) {
      if (error.isNotEmpty) {
        _startupTimer?.cancel();
        _cleanupListeners();
        if (!_firstFrameShown) widget.onPlaybackError?.call();
      }
    });
  }

  void _cleanupListeners() {
    _posSub?.cancel();
    _posSub = null;
    _errorSub?.cancel();
    _errorSub = null;
  }

  void _onTap() {
    if (!mounted) return;
    final ctrl = context.read<ZeroWaitPlaybackController>();
    setState(() {
      _userPaused = !_userPaused;
      _showPauseIcon = true;
    });
    if (_userPaused) {
      ctrl.pause(widget.videoId);
    } else {
      ctrl.play(widget.videoId);
    }
    widget.onTap?.call();
    _pauseIconTimer?.cancel();
    _pauseIconTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showPauseIcon = false);
    });
  }

  void _onDoubleTap() {
    if (!mounted) return;
    widget.onDoubleTapLike?.call();
    setState(() => _showHeart = true);
    _pauseIconTimer?.cancel();
    _pauseIconTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  Widget _buildHeartBurst() {
    return Center(
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 400),
        child: const Icon(
          Icons.favorite,
          color: Colors.white,
          size: 72,
        ),
      ),
    );
  }
  @override
  void dispose() {
    _startupTimer?.cancel();
    _pauseIconTimer?.cancel();
    _cleanupListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playbackController = context.watch<ZeroWaitPlaybackController>();
    final videoController = playbackController.controllerFor(widget.videoId);
    final isMuted = playbackController.isMuted;

    return Semantics(
      container: true,
      label: widget.creatorName.isNotEmpty || widget.caption.isNotEmpty
          ? 'Video by ${widget.creatorName}. ${widget.caption}'
          : 'Video',
      hint: 'Single tap to play or pause. Double tap to like.',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        onDoubleTap: _onDoubleTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Layer 0: thumbnail background — always present.
            if (widget.thumbnailUrl.isNotEmpty)
              Image.network(
                widget.thumbnailUrl,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) =>
                    const ColoredBox(color: Colors.black),
              ),
            // Layer 1: Video surface — kept in the tree whenever the
            // controller is available so the native texture stays warm.
            // Keyed by videoId: if the feed reorders and this slot gets a
            // different video, Flutter creates a fresh texture surface.
            if (videoController != null)
              Video(
                key: ValueKey(widget.videoId),
                controller: videoController,
                fit: BoxFit.cover,
                controls: NoVideoControls,
              ),
            // Layer 2: thumbnail mask — sits above the Video until the first
            // real frame is confirmed. Blocks any native-texture recycling
            // artifact (stale pixels from a previous video) from showing.
            if (!_firstFrameShown && widget.thumbnailUrl.isNotEmpty)
              Image.network(
                widget.thumbnailUrl,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) =>
                    const ColoredBox(color: Colors.black),
              ),
            // Layer 3: loading pulse — shown until the first frame arrives.
            if (!_firstFrameShown) const Center(child: YohPalGoldPulse()),
            if (_showPauseIcon)
              Center(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Icon(
                    _userPaused ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            if (_showHeart) _buildHeartBurst(),
            Positioned(
              top: 16,
              right: 16,
              child: Semantics(
                button: true,
                label: isMuted ? 'Unmute video' : 'Mute video',
                child: IconButton.filledTonal(
                  tooltip: isMuted ? 'Unmute' : 'Mute',
                  onPressed: playbackController.toggleMute,
                  icon: Icon(isMuted ? Icons.volume_off : Icons.volume_up),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
