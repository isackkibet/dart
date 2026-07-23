import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../design_system/tokens/yohpal_brand_colors.dart';
import '../../ads/models/rewarded_ad_model.dart';
import '../../ads/repositories/rewarded_ads_repository.dart';
import '../../ads/screens/rewarded_ad_watch_screen.dart';

class AdsArenaScreen extends StatelessWidget {
  const AdsArenaScreen({super.key});

  static const routeName = '/ads-arena';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Ads Arena'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/ads-leaderboard'),
            child: const Text('Leaderboard'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  YohPalBrandColors.gold,
                  YohPalBrandColors.deepGold,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Watch Ads. Earn Rewards.',
                    style: TextStyle(
                        color: YohPalBrandColors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Watch 30s to earn YohPoints. Watch 60s to unlock a coupon.',
                    style: TextStyle(
                        color: YohPalBrandColors.black, fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<RewardedAdModel>>(
              stream: context
                  .read<RewardedAdsRepository>()
                  .watchLiveRewardedAds(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Text('Could not load ads.\n${snap.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent)),
                  );
                }
                final ads = snap.data ?? [];
                if (ads.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_circle_outline,
                            color: onSurface.withValues(alpha: 0.24),
                            size: 64),
                        const SizedBox(height: 16),
                        Text('No ads available right now.',
                            style: TextStyle(
                                color: onSurface.withValues(alpha: 0.6),
                                fontSize: 16)),
                        const SizedBox(height: 8),
                        Text('Check back soon — new rewarded ads are added daily.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: onSurface.withValues(alpha: 0.4),
                                fontSize: 13)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: ads.length,
                  itemBuilder: (context, i) {
                    final ad = ads[i];
                    return Card(
                      color: theme.cardColor,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: YohPalBrandColors.gold,
                          child: Icon(Icons.play_arrow,
                              color: YohPalBrandColors.black),
                        ),
                        title: Text(ad.title,
                            style: TextStyle(color: onSurface,
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          ad.couponDescription.isNotEmpty
                              ? '${ad.couponDescription} · Watch ${ad.rewardTierTwoSeconds}s'
                              : 'Watch ${ad.rewardTierTwoSeconds}s to earn reward',
                          style: TextStyle(
                              color: onSurface.withValues(alpha: 0.6)),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: YohPalBrandColors.gold,
                            foregroundColor: YohPalBrandColors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                          onPressed: user == null
                              ? null
                              : () => Navigator.pushNamed(
                                    context,
                                    RewardedAdWatchScreen.routeName,
                                    arguments: {
                                      'ad': ad,
                                      'liveSessionId': null,
                                      'creatorId': null,
                                    },
                                  ),
                          child: const Text('Watch',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
