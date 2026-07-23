import '../repositories/affiliate_repository.dart';

class AffiliateService {
  final AffiliateRepository repository;

  AffiliateService({required this.repository});

  Future<String> createGeneralLink(String userId) {
    return repository.createAffiliateLink(
      ownerUserId: userId,
      type: 'general',
    );
  }

  Future<String> createVideoLink({
    required String userId,
    required String videoId,
  }) {
    return repository.createAffiliateLink(
      ownerUserId: userId,
      type: 'video',
      targetId: videoId,
    );
  }

  Future<String> createCreatorLink({
    required String userId,
    required String creatorId,
  }) {
    return repository.createAffiliateLink(
      ownerUserId: userId,
      type: 'creator',
      targetId: creatorId,
    );
  }

  Future<void> trackClick({
    required String linkId,
    required String viewerUserId,
  }) {
    return repository.trackClick(
      linkId: linkId,
      viewerUserId: viewerUserId,
      deviceFingerprint: 'device_fingerprint_placeholder',
    );
  }

  Future<void> trackRegistration({
    required String linkId,
    required String newUserId,
  }) {
    return repository.trackRegistration(
      linkId: linkId,
      newUserId: newUserId,
    );
  }

  Future<void> trackPurchase({
    required String linkId,
    required String buyerUserId,
    required num purchaseAmount,
    required String source,
  }) {
    return repository.trackPurchase(
      linkId: linkId,
      buyerUserId: buyerUserId,
      purchaseAmount: purchaseAmount,
      source: source,
    );
  }
}
