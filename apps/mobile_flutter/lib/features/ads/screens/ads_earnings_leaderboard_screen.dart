import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../design_system/tokens/yohpal_brand_colors.dart';

class AdsEarningsLeaderboardScreen extends StatelessWidget {
  const AdsEarningsLeaderboardScreen({super.key});

  static const routeName = '/ads-leaderboard';

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text('Ads Earnings Leaderboard'),
      ),
      body: const DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: 'Viewers'),
                Tab(text: 'Creators'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _LeaderboardList(collection: 'viewerAdEarningStats'),
                  _LeaderboardList(collection: 'creatorAdEarningStats'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  final String collection;

  const _LeaderboardList({required this.collection});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .orderBy('totalEarned', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        final onSurface = Theme.of(context).colorScheme.onSurface;
        if (docs.isEmpty) {
          return Center(
            child: Text('No earnings yet',
                style: TextStyle(color: onSurface.withValues(alpha: 0.6))),
          );
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            return ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(
                data['username'] ?? 'YohPal User',
                style: TextStyle(color: onSurface),
              ),
              subtitle: Text(
                'Ads watched: ${data['adsWatched'] ?? 0} · Coupons: ${data['couponsUnlocked'] ?? 0}',
                style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
              ),
              trailing: Text(
                'KES ${data['totalEarned'] ?? 0}',
                style: const TextStyle(
                    color: YohPalBrandColors.deepGold,
                    fontWeight: FontWeight.bold),
              ),
            );
          },
        );
      },
    );
  }
}
