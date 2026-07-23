import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../chat/screens/chat_room_screen.dart';
import '../../video_feed/models/video_model.dart';
import '../controllers/creator_profile_controller.dart';
import '../domain/creator_library_category.dart';
import '../domain/creator_profile_video.dart';
import '../models/creator_profile_model.dart';
import '../repositories/creator_profile_repository.dart';
import '../repositories/follow_repository.dart';
import '../widgets/creator_library_tabs.dart';
import '../widgets/creator_stats_card.dart';
import '../widgets/creator_video_grid.dart';
import 'creator_video_feed_screen.dart';
import 'edit_creator_profile_screen.dart';

class CreatorProfileScreen extends StatefulWidget {
  final String creatorUid;

  const CreatorProfileScreen({
    super.key,
    required this.creatorUid,
  });

  static const routeName = '/creator-profile';

  @override
  State<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen> {
  CreatorLibraryCategory _selectedCategory = CreatorLibraryCategory.publicVideos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final repo = context.read<CreatorProfileRepository>();
    final followRepo = context.read<FollowRepository>();
    final isOwner = currentUser?.uid == widget.creatorUid;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          'Creator Profile',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        actions: [
          if (isOwner) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit profile',
              onPressed: () => Navigator.pushNamed(
                context,
                EditCreatorProfileScreen.routeName,
                arguments: widget.creatorUid,
              ),
            ),
            const _LogoutButton(),
          ],
        ],
      ),
      body: StreamBuilder<CreatorProfileModel?>(
        stream: repo.watchCreatorProfile(widget.creatorUid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load profile',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = snapshot.data;
          if (profile == null) {
            return Center(
              child: Text(
                'Creator profile not found',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            );
          }

          return StreamBuilder<List<VideoModel>>(
            stream: repo.watchCreatorVideos(widget.creatorUid),
            builder: (context, videoSnap) {
              final videos = videoSnap.data ?? [];
              final gridVideos = videos
                  .map(CreatorProfileVideo.fromVideoModel)
                  .toList();

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                      child: _Header(profile: profile),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 16),
                      child: FutureBuilder<Map<String, num>>(
                        future: repo.getCreatorAnalytics(widget.creatorUid),
                        builder: (context, analyticsSnapshot) {
                          final analytics =
                              analyticsSnapshot.data ?? const <String, num>{};
                          return CreatorStatsCard(
                            followerCount: profile.followerCount,
                            followingCount: 0,
                            videoCount: videos.length,
                            totalViews: analytics['views']?.toInt() ?? 0,
                            totalLikes: analytics['likes']?.toInt() ?? 0,
                            totalComments:
                                analytics['comments']?.toInt() ?? 0,
                            totalShares: analytics['shares']?.toInt() ?? 0,
                            totalGifts: analytics['gifts']?.toInt() ?? 0,
                            eligibilityScore: profile.eligibilityScore,
                            joinedLabel: 'Joined recently',
                            isVerified: profile.status == 'verified',
                          );
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 4),
                      child: Column(
                        children: [
                          if (isOwner)
                            ElevatedButton.icon(
                              onPressed: () => Navigator.pushNamed(
                                  context, '/creator-earnings'),
                              icon: const Icon(Icons.account_balance_wallet),
                              label: const Text('Creator Earnings'),
                            ),
                          if (!isOwner && currentUser != null)
                            Row(
                              children: [
                                Expanded(
                                  child: StreamBuilder<bool>(
                                    stream: followRepo.watchIsFollowing(
                                      followerUid: currentUser.uid,
                                      creatorUid: widget.creatorUid,
                                    ),
                                    builder: (context, followSnap) {
                                      final isFollowing =
                                          followSnap.data ?? false;
                                      final controller =
                                          context.watch<CreatorProfileController>();
                                      return ElevatedButton(
                                        onPressed: controller.busy
                                            ? null
                                            : () => controller.toggleFollow(
                                                  currentlyFollowing: isFollowing,
                                                  followerUid: currentUser.uid,
                                                  creatorUid: widget.creatorUid,
                                                ),
                                        child: Text(
                                            isFollowing ? 'Unfollow' : 'Follow'),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final conversationId = await context
                                          .read<ChatController>()
                                          .createDirectConversation(
                                            currentUserId: currentUser.uid,
                                            otherUserId: profile.userId,
                                            currentUserName:
                                                currentUser.displayName ??
                                                    'YohPal User',
                                            otherUserName: profile.displayName,
                                          );
                                      if (context.mounted) {
                                        Navigator.pushNamed(
                                          context,
                                          ChatRoomScreen.routeName,
                                          arguments: conversationId,
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.message),
                                    label: const Text('Message'),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: CreatorLibraryTabs(
                      isOwner: isOwner,
                      selected: _selectedCategory,
                      onSelected: (cat) =>
                          setState(() => _selectedCategory = cat),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  CreatorVideoGrid(
                    videos: gridVideos,
                    loading: videoSnap.connectionState ==
                        ConnectionState.waiting,
                    error: videoSnap.hasError ? videoSnap.error : null,
                    hasMore: false,
                    onRetry: () => setState(() {}),
                    onLoadMore: () {},
                    onOpenVideo: (v) {
                      final index =
                          videos.indexWhere((m) => m.id == v.id);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreatorVideoFeedScreen(
                            videos: videos,
                            initialIndex: index < 0 ? 0 : index,
                          ),
                        ),
                      );
                    },
                  ),
                  const SliverPadding(
                      padding: EdgeInsets.only(bottom: 24)),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _LogoutButton extends StatefulWidget {
  const _LogoutButton();

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _signingOut = false;

  Future<void> _confirmAndSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to log in again to access your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _signingOut = true);
    try {
      await context.read<AuthController>().logout();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not sign out. Please try again.')),
      );
      setState(() => _signingOut = false);
      return;
    }
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true)
        .popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Sign out',
      icon: _signingOut
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.logout),
      onPressed: _signingOut ? null : _confirmAndSignOut,
    );
  }
}

class _Header extends StatelessWidget {
  final CreatorProfileModel profile;
  const _Header({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundImage: profile.photoUrl.isEmpty
              ? null
              : NetworkImage(profile.photoUrl),
          child: profile.photoUrl.isEmpty
              ? const Icon(Icons.person, size: 44)
              : null,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              profile.displayName.isNotEmpty
                  ? profile.displayName
                  : (profile.username.isNotEmpty
                      ? profile.username
                      : profile.userId),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (profile.status == 'verified') ...[
              const SizedBox(width: 8),
              const Icon(Icons.verified, size: 20, color: Color(0xFF4FC3F7)),
            ],
          ],
        ),
        if (profile.username.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '@${profile.username}',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
                fontSize: 15,
              ),
            ),
          ),
        if (profile.bio.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              profile.bio,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
      ],
    );
  }
}
