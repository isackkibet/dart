import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/firebase.dart' as fb;
import '../models/rewarded_ad_model.dart';

class RewardedAdsRepository {
  final FirebaseFirestore? _firestore;
  final FirebaseFunctions? _functions;

  RewardedAdsRepository({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _firestore = firestore ?? fb.tryFirebaseFirestore(),
        _functions = functions ?? fb.tryFirebaseFunctions();

  Stream<List<RewardedAdModel>> watchLiveRewardedAds() {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('rewardedAdCampaigns')
        .where('status', isEqualTo: 'active')
        .where('deliveryEnabled', isEqualTo: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => RewardedAdModel.fromMap({'id': doc.id, ...doc.data()}))
            .toList());
  }

  Future<void> writeRewardedAdEvent({
    required String userId,
    required String campaignId,
    required String type,
    int? watchedSeconds,
    String? liveSessionId,
    String? creatorId,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs.collection('rewardedAdEvents').add({
      'userId': userId,
      'campaignId': campaignId,
      'type': type,
      'watchedSeconds': watchedSeconds,
      'liveSessionId': liveSessionId,
      'creatorId': creatorId,
      'source': 'mobile',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Asks the server whether a tier-completion event this client wrote was
  /// actually credited. RewardedAdsController previously showed "reward
  /// unlocked" the instant its own local Timer crossed a threshold, with no
  /// server confirmation at all — the server now also rejects events that
  /// arrive faster than real elapsed time allows (rewardedAdProcessor), so
  /// the client's own timer is no longer sufficient to know whether a
  /// reward actually landed.
  Future<bool> verifyReward({
    required String campaignId,
    required String type,
  }) async {
    final fn = _functions;
    if (fn == null) return false;
    try {
      final result = await fn.httpsCallable('verifyRewardedAd').call({
        'campaignId': campaignId,
        'type': type,
      });
      return result.data['verified'] == true;
    } on FirebaseFunctionsException {
      return false;
    }
  }
}
