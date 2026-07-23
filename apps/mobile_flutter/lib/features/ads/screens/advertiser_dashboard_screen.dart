import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/web_handoff/yohpal_web_handoff.dart';
import '../models/ad_campaign_model.dart';
import '../repositories/ads_repository.dart';

class AdvertiserDashboardScreen extends StatelessWidget {
  const AdvertiserDashboardScreen({super.key});

  static const routeName = '/advertiser-dashboard';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final repo = context.read<AdsRepository>();

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050816),
        title: const Text('Advertiser Dashboard'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: ElevatedButton.icon(
              onPressed: () async {
                await context
                    .read<YohPalWebHandoff>()
                    .openAdvertiserDashboard(advertiserId: user.uid);
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Manage Ads on YohPal Web'),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AdCampaignModel>>(
              stream: repo.watchAdvertiserCampaigns(user.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final campaigns = snapshot.data!;
                if (campaigns.isEmpty) {
                  return const Center(
                    child: Text(
                      'No campaigns yet.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(18),
                  children: campaigns.map((campaign) {
                    final ctr = campaign.impressions == 0
                        ? 0.0
                        : (campaign.clicks / campaign.impressions) * 100;
                    return Card(
                      color: const Color(0xFF101527),
                      child: ListTile(
                        title: Text(
                          campaign.title,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'Status: ${campaign.status}\n'
                          'Impressions: ${campaign.impressions}\n'
                          'Clicks: ${campaign.clicks}\n'
                          'CTR: ${ctr.toStringAsFixed(2)}%\n'
                          'Spend: KES ${campaign.spend} / ${campaign.budget}',
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
