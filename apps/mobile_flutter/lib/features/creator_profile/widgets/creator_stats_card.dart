import 'package:flutter/material.dart';

class CreatorStatsCard extends StatelessWidget {
  final int followerCount;
  final int followingCount;
  final int videoCount;
  final int totalViews;
  final int totalLikes;
  final int totalComments;
  final int totalShares;
  final int totalGifts;
  final int eligibilityScore;
  final String joinedLabel;
  final bool isVerified;

  const CreatorStatsCard({
    super.key,
    required this.followerCount,
    this.followingCount = 0,
    required this.videoCount,
    this.totalViews = 0,
    this.totalLikes = 0,
    this.totalComments = 0,
    this.totalShares = 0,
    this.totalGifts = 0,
    required this.eligibilityScore,
    this.joinedLabel = 'Joined recently',
    this.isVerified = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget item(String label, String value) => Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        );

    return Card(
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                item('Followers', _formatCount(followerCount)),
                item('Following', _formatCount(followingCount)),
                item('Videos', '$videoCount'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                item('Views', _formatCount(totalViews)),
                item('Likes', _formatCount(totalLikes)),
                item('Shares', _formatCount(totalShares)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                item('Comments', _formatCount(totalComments)),
                item('Gifts', _formatCount(totalGifts)),
                item('Videos', '$videoCount'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${isVerified ? 'Verified • ' : ''}$joinedLabel',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return '$value';
  }
}
