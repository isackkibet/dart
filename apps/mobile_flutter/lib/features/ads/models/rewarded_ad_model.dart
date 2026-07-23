class RewardedAdModel {
  final String id;
  final String campaignId;
  final String advertiserId;
  final String title;
  final String caption;
  final String mediaUrl;
  final String ctaUrl;
  final int rewardTierOneSeconds;
  final int rewardTierTwoSeconds;
  final num tierOneCashAmount;
  final String tierOneCurrency;
  final bool tierOneYohPointsEnabled;
  final bool tierTwoCouponEnabled;
  final String couponDescription;
  final String couponType;
  final num couponValue;

  const RewardedAdModel({
    required this.id,
    required this.campaignId,
    required this.advertiserId,
    required this.title,
    required this.caption,
    required this.mediaUrl,
    required this.ctaUrl,
    required this.rewardTierOneSeconds,
    required this.rewardTierTwoSeconds,
    required this.tierOneCashAmount,
    required this.tierOneCurrency,
    required this.tierOneYohPointsEnabled,
    required this.tierTwoCouponEnabled,
    required this.couponDescription,
    required this.couponType,
    required this.couponValue,
  });

  factory RewardedAdModel.fromMap(Map<String, dynamic> map) {
    return RewardedAdModel(
      id: map['id'] ?? '',
      campaignId: map['campaignId'] ?? '',
      advertiserId: map['advertiserId'] ?? '',
      title: map['title'] ?? '',
      caption: map['caption'] ?? '',
      mediaUrl: map['mediaUrl'] ?? '',
      ctaUrl: map['ctaUrl'] ?? '',
      rewardTierOneSeconds: map['rewardTierOneSeconds'] ?? 30,
      rewardTierTwoSeconds: map['rewardTierTwoSeconds'] ?? 60,
      tierOneCashAmount: map['tierOneCashAmount'] ?? 0,
      tierOneCurrency: map['tierOneCurrency'] ?? 'KES',
      tierOneYohPointsEnabled: map['tierOneYohPointsEnabled'] ?? true,
      tierTwoCouponEnabled: map['tierTwoCouponEnabled'] ?? true,
      couponDescription: map['couponDescription'] ?? '',
      couponType: map['couponType'] ?? 'discount',
      couponValue: map['couponValue'] ?? 0,
    );
  }
}
