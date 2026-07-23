abstract class YohPalWalletService {
  Future<num> getBalance(String uid);

  Future<void> credit({
    required String uid,
    required num amount,
    required String reason,
    required String referenceId,
  });

  Future<void> debit({
    required String uid,
    required num amount,
    required String reason,
    required String referenceId,
  });

  Future<List<Map<String, dynamic>>> getTransactions(String uid);
}
