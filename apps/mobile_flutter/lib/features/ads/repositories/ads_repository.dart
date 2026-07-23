import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;
import '../models/ad_campaign_model.dart';

class AdsRepository {
  final FirebaseFirestore? _firestore;

  AdsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  Stream<List<AdCampaignModel>> watchActiveCampaigns() {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('adCampaigns')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => AdCampaignModel.fromMap(doc.data()))
              .where((ad) => ad.hasBudget)
              .toList(),
        );
  }

  Stream<List<AdCampaignModel>> watchAdvertiserCampaigns(String advertiserId) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('adCampaigns')
        .where('advertiserId', isEqualTo: advertiserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => AdCampaignModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> trackImpression({
    required String campaignId,
    required String userId,
    required num cost,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs.collection('adEngagementEvents').add({
      'campaignId': campaignId,
      'userId': userId,
      'type': 'impression',
      'source': 'mobile',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> trackClick({
    required String campaignId,
    required String userId,
    required num cost,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs.collection('adEngagementEvents').add({
      'campaignId': campaignId,
      'userId': userId,
      'type': 'click',
      'source': 'mobile',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}