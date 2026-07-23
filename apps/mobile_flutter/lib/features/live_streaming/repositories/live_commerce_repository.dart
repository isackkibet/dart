import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;
import '../models/live_product_model.dart';

class LiveCommerceRepository {
  final FirebaseFirestore? _firestore;

  LiveCommerceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  Future<void> addProduct({
    required String sessionId,
    required String sellerId,
    required String name,
    required String description,
    required num price,
    required String currency,
    required String imageUrl,
    required String phone,
    required String location,
    required int quantity,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    final ref = fs
        .collection('liveSessions')
        .doc(sessionId)
        .collection('products')
        .doc();
    await ref.set({
      'id': ref.id,
      'sessionId': sessionId,
      'sellerId': sellerId,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'imageUrl': imageUrl,
      'phone': phone,
      'location': location,
      'quantity': quantity,
      'status': 'available',
      'pinned': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<LiveProductModel>> watchProducts(String sessionId) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('liveSessions')
        .doc(sessionId)
        .collection('products')
        .where('status', isEqualTo: 'available')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => LiveProductModel.fromMap(doc.data()))
            .toList());
  }

  Stream<LiveProductModel?> watchPinnedProduct(String sessionId) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('liveSessions')
        .doc(sessionId)
        .collection('products')
        .where('pinned', isEqualTo: true)
        .where('status', isEqualTo: 'available')
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return LiveProductModel.fromMap(snap.docs.first.data());
    });
  }

  Future<void> pinProduct({
    required String sessionId,
    required String productId,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    final products = await fs
        .collection('liveSessions')
        .doc(sessionId)
        .collection('products')
        .get();
    final batch = fs.batch();
    for (final doc in products.docs) {
      batch.update(doc.reference, {
        'pinned': doc.id == productId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> unpinProduct({
    required String sessionId,
    required String productId,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs
        .collection('liveSessions')
        .doc(sessionId)
        .collection('products')
        .doc(productId)
        .update({
      'pinned': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> createPurchaseIntent({
    required String sessionId,
    required String productId,
    required String buyerId,
    required String sellerId,
    required String amount,
    required String currency,
  }) async {
    final fs = _firestore;
    if (fs == null) throw StateError('Firebase not initialized');
    final ref = fs.collection('livePurchaseIntents').doc();
    await ref.set({
      'id': ref.id,
      'sessionId': sessionId,
      'productId': productId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'amount': num.tryParse(amount) ?? 0,
      'currency': currency,
      'status': 'pending_payment',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> trackProductClick({
    required String sessionId,
    required String productId,
    required String userId,
    required String type,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs.collection('liveEvents').add({
      'sessionId': sessionId,
      'productId': productId,
      'userId': userId,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}