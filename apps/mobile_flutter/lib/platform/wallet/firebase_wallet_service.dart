import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firebase.dart' as fb;
import 'yohpal_wallet_service.dart';

class FirebaseWalletService implements YohPalWalletService {
  final FirebaseFirestore? _firestore;

  FirebaseWalletService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  @override
  Future<num> getBalance(String uid) async {
    final fs = _firestore;
    if (fs == null) return 0;
    final doc = await fs.collection('wallets').doc(uid).get();
    return (doc.data()?['balance'] as num?) ?? 0;
  }

  @override
  Future<void> credit({
    required String uid,
    required num amount,
    required String reason,
    required String referenceId,
  }) async {
    throw UnsupportedError(
      'Wallet credit must be executed through backend-only Cloud Functions.',
    );
  }

  @override
  Future<void> debit({
    required String uid,
    required num amount,
    required String reason,
    required String referenceId,
  }) async {
    throw UnsupportedError(
      'Wallet debit must be executed through backend-only Cloud Functions.',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getTransactions(String uid) async {
    final fs = _firestore;
    if (fs == null) return [];
    final snap = await fs
        .collection('walletTransactions')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    return snap.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }
}