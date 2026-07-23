import 'dart:async';
import 'package:flutter/material.dart';
import '../application/ads_engine_controller.dart';
import '../domain/ad_placement.dart';

/// Overlay widget that displays a served ad during a live session.
/// Mount as a Stack child over the video view, above [PollOverlayWidget].
class AdOverlayWidget extends StatefulWidget {
  const AdOverlayWidget({
    super.key,
    required this.placement,
    required this.sessionId,
    required this.controller,
  });

  final AdPlacement placement;
  final String sessionId;
  final AdsEngineController controller;

  @override
  State<AdOverlayWidget> createState() => _AdOverlayWidgetState();
}

class _AdOverlayWidgetState extends State<AdOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  Timer? _skipTimer;
  Timer? _autoDismissTimer;
  bool _canSkip = false;
  int _secondsLeft = 0;

  static const int _skipDelay = 5;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.placement.durationSeconds;

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    // Record impression once visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.handleImpression(widget.sessionId);
    });

    _skipTimer = Timer(const Duration(seconds: _skipDelay), () {
      if (mounted) setState(() => _canSkip = true);
    });

    // Countdown + auto-dismiss
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsLeft = (_secondsLeft - 1).clamp(0, widget.placement.durationSeconds);
        if (_secondsLeft == 0) {
          timer.cancel();
          _dismiss();
        }
      });
    });
  }

  Future<void> _onTap() async {
    await widget.controller.handleClick(widget.sessionId);
    // Launching the URL would use url_launcher in production;
    // here we dismiss after recording the click.
    _dismiss();
  }

  void _dismiss() {
    if (!mounted) return;
    _fadeController.reverse().then((_) {
      if (mounted) widget.controller.dismissPlacement();
    });
  }

  @override
  void dispose() {
    _skipTimer?.cancel();
    _autoDismissTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.placement;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: p.isBanner ? _buildBanner(p) : _buildOverlay(p),
    );
  }

  Widget _buildBanner(AdPlacement p) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        onTap: _onTap,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.campaign_outlined,
                      color: Colors.white70),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Sponsored',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p.creativeRef,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _CtaButton(label: p.ctaLabel, onTap: _onTap),
                const SizedBox(width: 8),
                if (_canSkip)
                  GestureDetector(
                    onTap: _dismiss,
                    child: const Icon(Icons.close, color: Colors.white54, size: 18),
                  )
                else
                  Text(
                    '${_skipDelay - (widget.placement.durationSeconds - _secondsLeft).clamp(0, _skipDelay)}s',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay(AdPlacement p) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: _onTap,
        child: Container(
          color: Colors.black.withOpacity(0.75),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Sponsored',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.campaign,
                    color: Colors.white60, size: 72),
              ),
              const SizedBox(height: 24),
              Text(
                p.creativeRef,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _CtaButton(label: p.ctaLabel, onTap: _onTap, large: true),
              const SizedBox(height: 20),
              if (_canSkip)
                TextButton(
                  onPressed: _dismiss,
                  child: const Text('Skip Ad',
                      style: TextStyle(color: Colors.white60)),
                )
              else
                Text(
                  'Skip in ${_skipDelay - (widget.placement.durationSeconds - _secondsLeft).clamp(0, _skipDelay)}s',
                  style: const TextStyle(color: Colors.white38, fontSize: 13),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({
    required this.label,
    required this.onTap,
    this.large = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: large ? 28 : 14,
          vertical: large ? 14 : 8,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF3B2FD9)],
          ),
          borderRadius: BorderRadius.circular(large ? 14 : 10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: large ? 15 : 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
