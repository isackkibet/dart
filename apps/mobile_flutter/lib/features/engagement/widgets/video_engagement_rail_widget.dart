import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../ai_video_companion/widgets/ai_video_companion_sheet.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../chat/screens/chat_room_screen.dart';
import '../../creator_profile/repositories/follow_repository.dart';
import '../../feed/controllers/engagement_controller.dart';
import '../../feed/data/engagement_repository.dart';
import '../../feed/domain/engagement_counts.dart';
import '../../video_feed/models/video_model.dart';
import '../controllers/video_engagement_rail_controller.dart';
import '../models/video_engagement_action_model.dart';

const _kActions = [
  VideoEngagementActionModel(id: 'follow', label: 'Follow', icon: Icons.person_add_alt, type: 'follow', isPrimary: true),
  VideoEngagementActionModel(id: 'like', label: 'Like', icon: Icons.favorite_border, type: 'like', isPrimary: true),
  VideoEngagementActionModel(id: 'views', label: 'Views', icon: Icons.visibility, type: 'views', isPrimary: true),
  VideoEngagementActionModel(id: 'comments', label: 'Comments', icon: Icons.mode_comment_outlined, type: 'comments', isPrimary: true),
  VideoEngagementActionModel(id: 'chat', label: 'Chat', icon: Icons.chat_bubble_outline, type: 'chat'),
  VideoEngagementActionModel(id: 'ask_ai', label: 'Ask AI', icon: Icons.psychology, type: 'ask_ai'),
  VideoEngagementActionModel(id: 'favourite', label: 'Save', icon: Icons.bookmark_border, type: 'favourite'),
  VideoEngagementActionModel(id: 'share', label: 'Share', icon: Icons.share, type: 'share'),
  VideoEngagementActionModel(id: 'shop', label: 'Shop', icon: Icons.shopping_bag_outlined, type: 'shop'),
  VideoEngagementActionModel(id: 'coupon', label: 'Coupon', icon: Icons.local_offer_outlined, type: 'coupon'),
  VideoEngagementActionModel(id: 'gift', label: 'Gift', icon: Icons.card_giftcard, type: 'gift'),
  VideoEngagementActionModel(id: 'duet', label: 'Duet', icon: Icons.splitscreen, type: 'duet'),
  VideoEngagementActionModel(id: 'translate', label: 'Translate', icon: Icons.translate, type: 'translate'),
  VideoEngagementActionModel(id: 'summarise', label: 'Summary', icon: Icons.summarize_outlined, type: 'summarise'),
  VideoEngagementActionModel(id: 'watch_later', label: 'Later', icon: Icons.watch_later_outlined, type: 'watch_later'),
  VideoEngagementActionModel(id: 'private_like', label: 'Private Like', icon: Icons.favorite, type: 'private_like'),
  VideoEngagementActionModel(id: 'private_comment', label: 'Private Comment', icon: Icons.lock_outline, type: 'private_comment'),
  VideoEngagementActionModel(id: 'rewarded_ad', label: 'Earn', icon: Icons.payments_outlined, type: 'rewarded_ad'),
  VideoEngagementActionModel(id: 'report', label: 'Report', icon: Icons.flag_outlined, type: 'report'),
  VideoEngagementActionModel(id: 'not_interested', label: 'Not Interested', icon: Icons.visibility_off_outlined, type: 'not_interested'),
  VideoEngagementActionModel(id: 'block', label: 'Block', icon: Icons.block, type: 'block'),
  VideoEngagementActionModel(id: 'download', label: 'Download', icon: Icons.download, type: 'download'),
];

class VideoEngagementRailWidget extends StatefulWidget {
  final VideoModel video;
  final String followerUid;
  final String creatorUid;
  final VoidCallback? onLike;
  final VoidCallback onComments;
  final VoidCallback? onFavourite;
  final VoidCallback onShare;
  final VoidCallback onReport;
  final VoidCallback onNotInterested;
  final VoidCallback onBlock;
  final VoidCallback onDownload;
  final void Function(bool isFollowing) onFollow;

  const VideoEngagementRailWidget({
    super.key,
    required this.video,
    required this.followerUid,
    required this.creatorUid,
    this.onLike,
    required this.onComments,
    this.onFavourite,
    required this.onShare,
    required this.onReport,
    required this.onNotInterested,
    required this.onBlock,
    required this.onDownload,
    required this.onFollow,
  });

  @override
  State<VideoEngagementRailWidget> createState() =>
      _VideoEngagementRailWidgetState();
}

class _VideoEngagementRailWidgetState
    extends State<VideoEngagementRailWidget> {
  late final EngagementController _engagement;

  @override
  void initState() {
    super.initState();
    _engagement = EngagementController(
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
    )..addListener(_onEngagementChanged);
  }

  void _onEngagementChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _engagement
      ..removeListener(_onEngagementChanged)
      ..dispose();
    super.dispose();
  }

  void _showMoreSheet(List<VideoEngagementActionModel> secondary) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      builder: (ctx) => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.9,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: secondary.length,
        itemBuilder: (_, i) {
          final action = secondary[i];
          return InkWell(
            onTap: () {
              Navigator.pop(ctx);
              _handleAction(action.type);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xAA050816),
                  child: Icon(action.icon, color: Colors.white, size: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  action.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _fmt(int count) {
    if (count >= 1000000000) return '${(count / 1000000000).toStringAsFixed(1)}B';
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }

  String? _countFor(String type) {
    final c = _engagement.counts;
    switch (type) {
      case 'views':    return _fmt(c.views);
      case 'like':     return _fmt(c.likes);
      case 'comments': return _fmt(c.comments);
      case 'share':    return _fmt(c.shares);
      case 'favourite':return _fmt(c.saves);
      case 'gift':     return _fmt(c.gifts);
      default:         return null;
    }
  }

  IconData _iconFor(String type) {
    if (type == 'like') {
      return _engagement.counts.viewerHasLiked
          ? Icons.favorite
          : Icons.favorite_border;
    }
    if (type == 'favourite') {
      return _engagement.counts.viewerHasSaved
          ? Icons.bookmark
          : Icons.bookmark_border;
    }
    return _kActions.firstWhere((a) => a.type == type,
        orElse: () => const VideoEngagementActionModel(
            id: '', label: '', icon: Icons.circle, type: '')).icon;
  }

  Future<void> _handleAction(String type) async {
    final user = FirebaseAuth.instance.currentUser;
    switch (type) {
      case 'like':
        await _engagement.toggleLike();
        break;
      case 'favourite':
        await _engagement.toggleSave();
        break;
      case 'comments':
        widget.onComments();
        break;
      case 'share':
        widget.onShare();
        break;
      case 'report':
        widget.onReport();
        break;
      case 'not_interested':
        widget.onNotInterested();
        break;
      case 'block':
        widget.onBlock();
        break;
      case 'download':
        widget.onDownload();
        break;
      case 'views':
        break;
      case 'chat':
        if (user == null) return;
        final nav = Navigator.of(context);
        final conversationId =
            await context.read<ChatController>().createDirectConversation(
                  currentUserId: user.uid,
                  otherUserId: widget.video.ownerId,
                  currentUserName: user.displayName ?? 'YohPal User',
                  otherUserName: widget.video.ownerUsername.isNotEmpty
                      ? widget.video.ownerUsername
                      : 'Creator',
                );
        if (mounted) {
          nav.pushNamed(ChatRoomScreen.routeName, arguments: conversationId);
        }
        break;
      case 'ask_ai':
      case 'translate':
      case 'summarise':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => AiVideoCompanionSheet(videoId: widget.video.id),
        );
        break;
      case 'shop':
        Navigator.pushNamed(context, '/timeline-overlay-detail',
            arguments: {'videoId': widget.video.id, 'type': 'product'});
        break;
      case 'coupon':
        Navigator.pushNamed(context, '/coupon-wallet');
        break;
      case 'gift':
        Navigator.pushNamed(context, '/creator-gift',
            arguments: widget.video.ownerId);
        break;
      case 'duet':
        Navigator.pushNamed(context, '/collaboration-create',
            arguments: {'videoId': widget.video.id, 'mode': 'duet'});
        break;
      case 'watch_later':
        Navigator.pushNamed(context, '/watch-later');
        break;
      case 'rewarded_ad':
        Navigator.pushNamed(context, '/ads-arena');
        break;
      case 'private_like':
        if (user == null) return;
        final messenger = ScaffoldMessenger.of(context);
        await context.read<VideoEngagementRailController>().privateLike(
              userId: user.uid,
              creatorId: widget.video.ownerId,
              videoId: widget.video.id,
            );
        if (mounted) {
          messenger.showSnackBar(const SnackBar(
            content: Text('Private like sent to creator'),
            behavior: SnackBarBehavior.floating,
          ));
        }
        break;
      case 'private_comment':
        if (user == null) return;
        await _openPrivateCommentDialog(user.uid);
        break;
    }
  }

  Future<void> _openPrivateCommentDialog(String userId) async {
    final messenger = ScaffoldMessenger.of(context);
    final input = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Private comment to creator',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: input,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Only the creator will see this',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              await context
                  .read<VideoEngagementRailController>()
                  .privateComment(
                    userId: userId,
                    creatorId: widget.video.ownerId,
                    videoId: widget.video.id,
                    text: input.text,
                  );
              if (mounted) {
                nav.pop();
                messenger.showSnackBar(const SnackBar(
                  content: Text('Private comment sent'),
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
    input.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryActions = _kActions.where((a) => a.isPrimary).toList();
    final secondaryActions = _kActions.where((a) => !a.isPrimary).toList();

    return Positioned(
      right: 8,
      top: 110,
      bottom: 90,
      child: SizedBox(
        width: 78,
        child: Column(
          children: [
            ...primaryActions.map((action) {
              if (action.type == 'follow') {
                if (widget.followerUid == widget.creatorUid) {
                  return const Expanded(child: SizedBox.shrink());
                }
                return Expanded(
                  child: Center(
                    child: StreamBuilder<bool>(
                      stream: context
                          .read<FollowRepository>()
                          .watchIsFollowing(
                            followerUid: widget.followerUid,
                            creatorUid: widget.creatorUid,
                          ),
                      builder: (ctx, snap) {
                        final isFollowing = snap.data ?? false;
                        return _RailButton(
                          action: action,
                          count: null,
                          color:
                              isFollowing ? const Color(0xFF6C3FF7) : null,
                          labelOverride:
                              isFollowing ? 'Following' : 'Follow',
                          onTap: () => widget.onFollow(isFollowing),
                        );
                      },
                    ),
                  ),
                );
              }
              return Expanded(
                child: Center(
                  child: _RailButton(
                    action: action,
                    iconOverride: _iconFor(action.type),
                    count: _countFor(action.type),
                    onTap: () => _handleAction(action.type),
                  ),
                ),
              );
            }),
            Expanded(
              child: Center(
                child: _MoreRailButton(
                  onTap: () => _showMoreSheet(secondaryActions),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreRailButton extends StatelessWidget {
  final VoidCallback onTap;
  const _MoreRailButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xAA050816),
            child: Icon(Icons.more_horiz, color: Colors.white, size: 23),
          ),
        ),
        const SizedBox(height: 3),
        const Text('More', style: TextStyle(color: Colors.white, fontSize: 10)),
      ],
    );
  }
}

class _RailButton extends StatelessWidget {
  final VideoEngagementActionModel action;
  final String? count;
  final Color? color;
  final String? labelOverride;
  final IconData? iconOverride;
  final VoidCallback onTap;

  const _RailButton({
    required this.action,
    required this.onTap,
    this.count,
    this.color,
    this.labelOverride,
    this.iconOverride,
  });

  @override
  Widget build(BuildContext context) {
    final label = labelOverride ?? action.label;
    return Column(
      children: [
        Semantics(
          button: true,
          label: label,
          value: count,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: color ?? const Color(0xAA050816),
              child: Icon(iconOverride ?? action.icon, color: Colors.white, size: 23),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          count ?? labelOverride ?? action.label,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      ],
    );
  }
}
