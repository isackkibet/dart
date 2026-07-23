import 'package:flutter/foundation.dart';
import '../models/ad_campaign_model.dart';
import '../repositories/ads_repository.dart';
import '../services/ad_delivery_service.dart';

class AdsController extends ChangeNotifier {
  final AdsRepository repository;
  final AdDeliveryService deliveryService;

  AdsController({
    required this.repository,
    required this.deliveryService,
  });

  List<AdCampaignModel> activeCampaigns = [];
  String? error;

  void setCampaigns(List<AdCampaignModel> campaigns) {
    activeCampaigns = campaigns;
    notifyListeners();
  }

  AdCampaignModel? adForIndex(int index) {
    if (!deliveryService.shouldShowAd(feedIndex: index)) return null;
    return deliveryService.selectAdForSlot(
      campaigns: activeCampaigns,
      feedIndex: index,
    );
  }

  Future<void> trackImpression({
    required String campaignId,
    required String userId,
    required num cost,
  }) async {
    try {
      await repository.trackImpression(
        campaignId: campaignId,
        userId: userId,
        cost: cost,
      );
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> trackClick({
    required String campaignId,
    required String userId,
    required num cost,
  }) async {
    try {
      await repository.trackClick(
        campaignId: campaignId,
        userId: userId,
        cost: cost,
      );
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }
}
