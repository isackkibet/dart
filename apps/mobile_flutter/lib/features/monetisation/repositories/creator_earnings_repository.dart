import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;
import '../models/creator_earning_model.dart';
import '../models/payout_request_model.dart';

class CreatorEarningsRepository {
  final FirebaseFirestore? _firestore;

  CreatorEarningsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  Stream<List<CreatorEarningModel>> watchCreatorEarnings(String creatorId) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('creatorEarnings')
        .where('creatorId', isEqualTo: creatorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => CreatorEarningModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<PayoutRequestModel>> watchPayoutRequests(String creatorId) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('payoutRequests')
        .where('creatorId', isEqualTo: creatorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => PayoutRequestModel.fromMap(doc.data()))
              .toList(),
        );
  }
}