import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/rewarded_ads_controller.dart';
import '../models/rewarded_ad_model.dart';

class RewardedAdWatchScreen extends StatefulWidget {
  final RewardedAdModel ad;
  final String? liveSessionId;
  final String? creatorId;

  const RewardedAdWatchScreen({
    super.key,
    required this.ad,
    this.liveSessionId,
    this.creatorId,
  });

  static const routeName = '/rewarded-ad-watch';

  @override
  State<RewardedAdWatchScreen> createState() => _RewardedAdWatchScreenState();
}

class _RewardedAdWatchScreenState extends State<RewardedAdWatchScreen> {
  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Future.microtask(() {
        if (!mounted) return;
        context.read<RewardedAdsController>().startWatching(
              userId: user.uid,
              ad: widget.ad,
              liveSessionId: widget.liveSessionId,
              creatorId: widget.creatorId,
            );
      });
    }
  }

  @override
  void dispose() {
    context.read<RewardedAdsController>().stopWatching();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RewardedAdsController>();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Rewarded Ad')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: widget.ad.mediaUrl.isEmpty
                  ? const Icon(Icons.campaign, color: Colors.white, size: 90)
                  : Image.network(widget.ad.mediaUrl),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Text(
                  '${controller.watchedSeconds}s watched',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: (controller.watchedSeconds /
                          widget.ad.rewardTierTwoSeconds)
                      .clamp(0.0, 1.0),
                ),
                const SizedBox(height: 16),
                Text(
                  _statusText(controller),
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Only claims a reward was granted once the server has actually
  // confirmed it (controller.tierXVerified) — the local timer crossing a
  // threshold (tierXUnlocked) used to be treated as "granted" on its own,
  // which was misleading the moment the server started rejecting
  // suspiciously-fast completions.
  String _statusText(RewardedAdsController controller) {
    if (controller.tierTwoVerified) {
      return '60s reward confirmed: coupon added to your wallet.';
    }
    if (controller.tierTwoUnlocked) {
      return controller.tierTwoVerifying
          ? 'Confirming your 60s reward...'
          : "Couldn't confirm your 60s reward yet. It may still be processing.";
    }
    if (controller.tierOneVerified) {
      return '30s reward confirmed. Continue to 60s for a coupon.';
    }
    if (controller.tierOneUnlocked) {
      return controller.tierOneVerifying
          ? 'Confirming your 30s reward...'
          : "Couldn't confirm your 30s reward yet. It may still be processing.";
    }
    return 'Watch 30s to earn a reward. Watch 60s to unlock a coupon.';
  }
}
