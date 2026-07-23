class ContextSnapshotModel {
  final String userId;
  final String currentScreen;
  final String? videoId;
  final String? creatorId;
  final bool isFollowingCreator;
  final bool hasActiveCoupon;
  final bool hasCommerceTags;
  final bool hasPoll;
  final bool isLiveAvailable;
  final bool canMessageCreator;
  final Map<String, dynamic> metadata;

  const ContextSnapshotModel({
    required this.userId,
    required this.currentScreen,
    this.videoId,
    this.creatorId,
    this.isFollowingCreator = false,
    this.hasActiveCoupon = false,
    this.hasCommerceTags = false,
    this.hasPoll = false,
    this.isLiveAvailable = false,
    this.canMessageCreator = false,
    this.metadata = const {},
  });
}
