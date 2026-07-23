import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/rewarded_ad_model.dart';
import '../repositories/rewarded_ads_repository.dart';

class RewardedAdsController extends ChangeNotifier {
  final RewardedAdsRepository repository;

  RewardedAdsController({required this.repository});

  Timer? _timer;
  bool _disposed = false;
  int watchedSeconds = 0;

  // "Unlocked" flips the instant the local watch timer crosses a
  // threshold — used for progress UI only. It is not proof the reward was
  // actually credited: rewardedAdProcessor now rejects tier-completion
  // events that arrive faster than real elapsed time allows, and this app
  // still has no real ad-network SDK to prove the ad was actually shown.
  // "Verified" only flips once the server confirms the reward was
  // processed (see RewardedAdsRepository.verifyReward) — that is what
  // should gate any "reward added" claim in the UI.
  bool tierOneUnlocked = false;
  bool tierTwoUnlocked = false;
  bool tierOneVerified = false;
  bool tierTwoVerified = false;
  bool tierOneVerifying = false;
  bool tierTwoVerifying = false;

  void startWatching({
    required String userId,
    required RewardedAdModel ad,
    String? liveSessionId,
    String? creatorId,
  }) {
    watchedSeconds = 0;
    tierOneUnlocked = false;
    tierTwoUnlocked = false;
    tierOneVerified = false;
    tierTwoVerified = false;
    tierOneVerifying = false;
    tierTwoVerifying = false;
    notifyListeners();

    repository.writeRewardedAdEvent(
      userId: userId,
      campaignId: ad.campaignId,
      type: 'view_start',
      liveSessionId: liveSessionId,
      creatorId: creatorId,
    );

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      watchedSeconds++;
      if (!tierOneUnlocked && watchedSeconds >= ad.rewardTierOneSeconds) {
        tierOneUnlocked = true;
        await repository.writeRewardedAdEvent(
          userId: userId,
          campaignId: ad.campaignId,
          type: 'tier_30_complete',
          watchedSeconds: watchedSeconds,
          liveSessionId: liveSessionId,
          creatorId: creatorId,
        );
        unawaited(_verify(ad.campaignId, 'tier_30_complete', isTierOne: true));
      }
      if (!tierTwoUnlocked && watchedSeconds >= ad.rewardTierTwoSeconds) {
        tierTwoUnlocked = true;
        await repository.writeRewardedAdEvent(
          userId: userId,
          campaignId: ad.campaignId,
          type: 'tier_60_complete',
          watchedSeconds: watchedSeconds,
          liveSessionId: liveSessionId,
          creatorId: creatorId,
        );
        unawaited(_verify(ad.campaignId, 'tier_60_complete', isTierOne: false));
      }
      notifyListeners();
    });
  }

  /// Polls verifyRewardedAd for a few seconds — rewardedAdProcessor is a
  /// Firestore trigger, so there's a real (usually sub-second, occasionally
  /// a few seconds) delay between writing the event and the reward
  /// actually being processed.
  Future<void> _verify(String campaignId, String type, {required bool isTierOne}) async {
    if (isTierOne) {
      tierOneVerifying = true;
    } else {
      tierTwoVerifying = true;
    }
    notifyListeners();

    var verified = false;
    for (var attempt = 0; attempt < 5 && !verified; attempt++) {
      if (attempt > 0) {
        await Future.delayed(const Duration(seconds: 2));
      }
      verified = await repository.verifyReward(campaignId: campaignId, type: type);
    }

    if (_disposed) return;
    if (isTierOne) {
      tierOneVerified = verified;
      tierOneVerifying = false;
    } else {
      tierTwoVerified = verified;
      tierTwoVerifying = false;
    }
    notifyListeners();
  }

  void stopWatching() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
