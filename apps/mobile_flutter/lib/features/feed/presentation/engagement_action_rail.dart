import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../feed/controllers/engagement_controller.dart';
import '../../feed/data/engagement_repository.dart';
import '../../feed/domain/engagement_counts.dart';
import '../../feed/domain/feed_video.dart';

class EngagementActionRail extends StatefulWidget {
  const EngagementActionRail({
    required this.video,
    required this.onComments,
    required this.onShare,
    super.key,
  });

  final FeedVideo video;
  final VoidCallback onComments;
  final VoidCallback onShare;

  @override
  State<EngagementActionRail> createState() => _EngagementActionRailState();
}

class _EngagementActionRailState extends State<EngagementActionRail> {
  late final EngagementController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EngagementController(
      repository: context.read<EngagementRepository>(),
      videoId: widget.video.id,
      initial: EngagementCounts(
        views: widget.video.views,
        likes: widget.video.likes,
        comments: widget.video.comments,
        shares: widget.video.shares,
        saves: widget.video.saves,
        gifts: widget.video.gifts,
        viewerHasLiked: false,
        viewerHasSaved: false,
      ),
    )..addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller.counts;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RailAction(
          icon: c.viewerHasLiked ? Icons.favorite : Icons.favorite_border,
          label: _fmt(c.likes),
          color: c.viewerHasLiked ? Colors.red : Colors.white,
          onTap: _controller.toggleLike,
        ),
        const SizedBox(height: 16),
        _RailAction(
          icon: Icons.mode_comment_outlined,
          label: _fmt(c.comments),
          onTap: widget.onComments,
        ),
        const SizedBox(height: 16),
        _RailAction(
          icon: Icons.share_outlined,
          label: _fmt(c.shares),
          onTap: widget.onShare,
        ),
        const SizedBox(height: 16),
        _RailAction(
          icon: c.viewerHasSaved ? Icons.bookmark : Icons.bookmark_border,
          label: _fmt(c.saves),
          color: c.viewerHasSaved ? Colors.amber : Colors.white,
          onTap: _controller.toggleSave,
        ),
      ],
    );
  }

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _RailAction extends StatelessWidget {
  const _RailAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 28,
              shadows: const [Shadow(blurRadius: 4, color: Colors.black54)]),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black54)])),
        ],
      ),
    );
  }
}
