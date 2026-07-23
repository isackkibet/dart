import '../../../core/web_handoff/yohpal_web_handoff.dart';

class WalletService {
  final YohPalWebHandoff handoff;

  WalletService({required this.handoff});

  Future<void> openWallet(String userId) {
    return handoff.openWallet(userId: userId);
  }

  Future<void> openWithdrawal(String userId) {
    return handoff.openWithdrawal(userId: userId);
  }
}
