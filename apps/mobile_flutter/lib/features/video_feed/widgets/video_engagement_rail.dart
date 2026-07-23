import 'package:flutter/material.dart';
import '../models/video_engagement_action.dart';

class VideoEngagementRail extends StatefulWidget {
  final Map<VideoEngagementAction, bool> activeStates;
  final Map<VideoEngagementAction, String> badgeLabels;
  final void Function(VideoEngagementAction) onAction;
  final bool isOwnVideo;

  const VideoEngagementRail({
    super.key,
    required this.activeStates,
    required this.onAction,
    this.badgeLabels = const {},
    this.isOwnVideo = false,
  });

  @override
  State<VideoEngagementRail> createState() => _VideoEngagementRailState();
}

class _VideoEngagementRailState extends State<VideoEngagementRail>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _animController;
  late Animation<double> _expandAnimation;

  // All actions except 'more' — 'more' is the expand toggle at slot 7
  static final List<VideoEngagementAction> _allActions =
      VideoEngagementAction.values
          .where((a) => a != VideoEngagementAction.more)
          .toList();

  static final List<VideoEngagementAction> _defaultVisible =
      kDefaultVisibleActions
          .where((a) => a != VideoEngagementAction.more)
          .toList();

  List<VideoEngagementAction> get _extendedActions =>
      _allActions.where((a) => !_defaultVisible.contains(a)).toList();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Default visible actions
        ..._defaultVisible.map((action) => _buildActionButton(action)),

        // More toggle
        _buildMoreButton(),

        // Extended rail (animated expand)
        SizeTransition(
          sizeFactor: _expandAnimation,
          axis: Axis.vertical,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              const Divider(color: Colors.white24, height: 1, thickness: 0.5),
              const SizedBox(height: 4),
              ..._extendedActions.map((action) => _buildActionButton(action)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMoreButton() {
    return GestureDetector(
      onTap: _toggleExpanded,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                key: ValueKey(_expanded),
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _expanded ? 'Less' : 'More',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                shadows: [Shadow(blurRadius: 4)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(VideoEngagementAction action) {
    final meta = metaFor(action);
    final isActive = widget.activeStates[action] ?? false;
    final badge = widget.badgeLabels[action];

    // Hide follow/chat/tip/joinLive for own videos
    if (widget.isOwnVideo &&
        [
          VideoEngagementAction.follow,
          VideoEngagementAction.chat,
          VideoEngagementAction.tipCreator,
          VideoEngagementAction.joinCreatorLive,
          VideoEngagementAction.sponsorCreator,
        ].contains(action)) {
      return const SizedBox.shrink();
    }

    final icon = isActive && meta.activeIcon != null
        ? meta.activeIcon!
        : meta.icon;
    final color = isActive ? meta.activeColor : Colors.white;

    return GestureDetector(
      onTap: () => widget.onAction(action),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 28,
                  shadows: const [Shadow(blurRadius: 6, color: Colors.black54)],
                ),
                const SizedBox(height: 2),
                Text(
                  meta.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    shadows: [Shadow(blurRadius: 4)],
                  ),
                ),
              ],
            ),
            // Badge (e.g. view count, like count)
            if (badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Formats large numbers: 1200 → 1.2K, 1500000 → 1.5M
String formatEngagementCount(int count) {
  if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
  return '$count';
}
