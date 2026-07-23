import '../models/ad_campaign_model.dart';

class AdDeliveryService {
  AdCampaignModel? selectAdForSlot({
    required List<AdCampaignModel> campaigns,
    required int feedIndex,
  }) {
    final active = campaigns.where((c) => c.isActive && c.hasBudget).toList();
    if (active.isEmpty) return null;
    return active[feedIndex % active.length];
  }

  bool shouldShowAd({
    required int feedIndex,
    int frequency = 6,
  }) {
    if (feedIndex == 0) return false;
    return feedIndex % frequency == 0;
  }
}
