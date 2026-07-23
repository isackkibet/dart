import 'package:flutter/foundation.dart';
import '../services/wallet_service.dart';

class WalletController extends ChangeNotifier {
  final WalletService service;

  WalletController({required this.service});

  bool loading = false;
  String? error;

  Future<void> openWithdrawalWeb({required String userId}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await service.openWithdrawal(userId);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> openWalletWeb({required String userId}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await service.openWallet(userId);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
