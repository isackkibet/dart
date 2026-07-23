class AdCampaignModel {
  final String id;
  final String advertiserId;
  final String title;
  final String description;
  final String mediaUrl;
  final String clickUrl;
  final String status;
  final num budget;
  final num spend;
  final num costPerImpression;
  final num costPerClick;
  final int impressions;
  final int clicks;

  const AdCampaignModel({
    required this.id,
    required this.advertiserId,
    required this.title,
    required this.description,
    required this.mediaUrl,
    required this.clickUrl,
    required this.status,
    required this.budget,
    required this.spend,
    required this.costPerImpression,
    required this.costPerClick,
    required this.impressions,
    required this.clicks,
  });

  factory AdCampaignModel.fromMap(Map<String, dynamic> map) {
    return AdCampaignModel(
      id: map['id'] ?? '',
      advertiserId: map['advertiserId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      mediaUrl: map['mediaUrl'] ?? '',
      clickUrl: map['clickUrl'] ?? '',
      status: map['status'] ?? 'draft',
      budget: map['budget'] ?? 0,
      spend: map['spend'] ?? 0,
      costPerImpression: map['costPerImpression'] ?? 1,
      costPerClick: map['costPerClick'] ?? 5,
      impressions: map['impressions'] ?? 0,
      clicks: map['clicks'] ?? 0,
    );
  }

  bool get isActive => status == 'active';
  bool get hasBudget => spend < budget;
}
