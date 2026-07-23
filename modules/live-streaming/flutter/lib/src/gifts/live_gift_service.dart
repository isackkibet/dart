import 'package:cloud_functions/cloud_functions.dart';

final class LiveGiftReceipt {
  const LiveGiftReceipt({
    required this.transactionId,
    required this.giftId,
    required this.amount,
    required this.currency,
  });

  final String transactionId;
  final String giftId;
  final num amount;
  final String currency;
}

abstract interface class LiveGiftContract {
  Future<LiveGiftReceipt> sendGift({
    required String liveSessionId,
    required String giftId,
  });
}

final class FirebaseLiveGiftService implements LiveGiftContract {
  FirebaseLiveGiftService({
    FirebaseFunctions? functions,
  }) : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  @override
  Future<LiveGiftReceipt> sendGift({
    required String liveSessionId,
    required String giftId,
  }) async {
    final callable = _functions.httpsCallable(
      'validatedGiftPurchase',
      options: HttpsCallableOptions(
        timeout: const Duration(seconds: 15),
      ),
    );

    final response = await callable.call<Map<String, dynamic>>({
      'liveSessionId': liveSessionId,
      'giftId': giftId,
    });

    final data = response.data;
    return LiveGiftReceipt(
      transactionId: data['transactionId'] as String,
      giftId: data['giftId'] as String,
      amount: data['amount'] as num,
      currency: data['currency'] as String? ?? 'KES',
    );
  }
}
