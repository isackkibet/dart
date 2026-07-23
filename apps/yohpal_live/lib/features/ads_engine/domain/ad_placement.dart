class AdPlacement {
  const AdPlacement({
    required this.placementId,
    required this.campaignId,
    required this.advertiserId,
    required this.creativeType,
    required this.creativeRef,
    required this.ctaLabel,
    required this.ctaUrl,
    required this.durationSeconds,
    required this.impressionToken,
  });

  final String placementId;
  final String campaignId;
  final String advertiserId;

  /// 'banner' | 'overlay' | 'sponsored_poll'
  final String creativeType;
  final String creativeRef;
  final String ctaLabel;
  final String ctaUrl;

  /// How long to show the overlay before offering skip.
  final int durationSeconds;

  /// Signed server token used to record this impression securely.
  final String impressionToken;

  bool get isBanner => creativeType == 'banner';
  bool get isOverlay => creativeType == 'overlay';
  bool get isSponsoredPoll => creativeType == 'sponsored_poll';

  factory AdPlacement.fromMap(Map<String, dynamic> map) => AdPlacement(
        placementId: map['placementId']?.toString() ?? '',
        campaignId: map['campaignId']?.toString() ?? '',
        advertiserId: map['advertiserId']?.toString() ?? '',
        creativeType: map['creativeType']?.toString() ?? 'banner',
        creativeRef: map['creativeRef']?.toString() ?? '',
        ctaLabel: map['ctaLabel']?.toString() ?? 'Learn More',
        ctaUrl: map['ctaUrl']?.toString() ?? '',
        durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 15,
        impressionToken: map['impressionToken']?.toString() ?? '',
      );
}
