// Gift service implementation stub.
// Cloud Functions integration requires platform-specific initialization.
// This will be fully integrated after Firebase setup is validated on target platforms.

class GiftPurchaseException implements Exception {
  final String message;
  const GiftPurchaseException(this.message);

  @override
  String toString() => message;
}

class GiftService {
  GiftService({dynamic functions});

  Future<void> sendGift({
    required String sessionId,
    required String creatorId,
    required String giftType,
  }) async {
    throw GiftPurchaseException(
      'Gift service is currently unavailable. Please try again later.',
    );
  }
}
