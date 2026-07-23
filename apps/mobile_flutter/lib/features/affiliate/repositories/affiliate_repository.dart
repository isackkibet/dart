import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;

class AffiliateRepository {
  final FirebaseFirestore? _firestore;

  AffiliateRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  Future<String> createAffiliateLink({
    required String ownerUserId,
    required String type,
    String? targetId,
  }) async {
    final fs = _firestore;
    if (fs == null) throw StateError('Firebase not initialized');
    final ref = fs.collection('affiliateLinks').doc();
    final url = 'https://yohpal.com/a/${ref.id}';
    await ref.set({
      'id': ref.id,
      'ownerUserId': ownerUserId,
      'type': type,
      'targetId': targetId,
      'url': url,
      'clickCount': 0,
      'registrationCount': 0,
      'purchaseCount': 0,
      'commissionTotal': 0,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return url;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUserLinks(String userId) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('affiliateLinks')
        .where('ownerUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUserCommissions(
      String userId) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('affiliateCommissions')
        .where('affiliateUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> trackClick({
    required String linkId,
    required String viewerUserId,
    required String deviceFingerprint,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    final linkRef = fs.collection('affiliateLinks').doc(linkId);
    final clickId = '${linkId}_$viewerUserId';

    await fs.runTransaction((tx) async {
      final linkDoc = await tx.get(linkRef);
      if (!linkDoc.exists) return;

      final link = linkDoc.data()!;
      if (link['ownerUserId'] == viewerUserId) {
        throw Exception('Self-referral is not allowed');
      }

      final clickRef =
          fs.collection('affiliateAttributions').doc(clickId);
      final clickDoc = await tx.get(clickRef);
      if (clickDoc.exists) return;

      tx.set(clickRef, {
        'id': clickId,
        'linkId': linkId,
        'affiliateUserId': link['ownerUserId'],
        'viewerUserId': viewerUserId,
        'deviceFingerprint': deviceFingerprint,
        'type': 'click',
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.update(linkRef, {
        'clickCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> trackRegistration({
    required String linkId,
    required String newUserId,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    final linkRef = fs.collection('affiliateLinks').doc(linkId);

    await fs.runTransaction((tx) async {
      final linkDoc = await tx.get(linkRef);
      if (!linkDoc.exists) return;

      final link = linkDoc.data()!;
      if (link['ownerUserId'] == newUserId) {
        throw Exception('Self-referral is not allowed');
      }

      tx.set(fs.collection('affiliateAttributions').doc(), {
        'linkId': linkId,
        'affiliateUserId': link['ownerUserId'],
        'referredUserId': newUserId,
        'type': 'registration',
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.update(linkRef, {
        'registrationCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> trackPurchase({
    required String linkId,
    required String buyerUserId,
    required num purchaseAmount,
    required String source,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    final linkRef = fs.collection('affiliateLinks').doc(linkId);
    final commissionRef =
        fs.collection('affiliateCommissions').doc();

    await fs.runTransaction((tx) async {
      final linkDoc = await tx.get(linkRef);
      if (!linkDoc.exists) return;

      final link = linkDoc.data()!;
      if (link['ownerUserId'] == buyerUserId) {
        throw Exception('Self-referral is not allowed');
      }

      final commissionAmount = calculateCommission(purchaseAmount);

      tx.set(commissionRef, {
        'id': commissionRef.id,
        'linkId': linkId,
        'affiliateUserId': link['ownerUserId'],
        'buyerUserId': buyerUserId,
        'purchaseAmount': purchaseAmount,
        'commissionAmount': commissionAmount,
        'source': source,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.update(linkRef, {
        'purchaseCount': FieldValue.increment(1),
        'commissionTotal': FieldValue.increment(commissionAmount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  num calculateCommission(num purchaseAmount) => purchaseAmount * 0.10;
}