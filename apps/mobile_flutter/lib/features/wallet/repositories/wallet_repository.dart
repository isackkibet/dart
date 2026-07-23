import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;
import '../models/wallet_balance_model.dart';
import '../models/wallet_transaction_model.dart';

class WalletRepository {
  final FirebaseFirestore? _firestore;

  WalletRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  Stream<WalletBalanceModel?> watchBalance(String userId) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('walletBalances')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return WalletBalanceModel.fromMap(doc.data()!);
    });
  }

  Stream<List<WalletTransactionModel>> watchTransactions(String userId) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('walletTransactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => WalletTransactionModel.fromMap(doc.data()))
            .toList());
  }
}