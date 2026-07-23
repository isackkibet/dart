import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;
import '../models/subscription_plan_model.dart';

class SubscriptionRepository {
  final FirebaseFirestore? _firestore;

  SubscriptionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  Stream<List<SubscriptionPlanModel>> watchCreatorPlans(String creatorId) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('subscriptionPlans')
        .where('creatorId', isEqualTo: creatorId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SubscriptionPlanModel.fromMap(doc.data()))
            .toList());
  }

  Future<void> createPlan({
    required String creatorId,
    required String title,
    required String description,
    required num price,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs.collection('subscriptionPlanRequests').add({
      'creatorId': creatorId,
      'title': title,
      'description': description,
      'price': price,
      'currency': 'KES',
      'status': 'pending_web_approval',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}