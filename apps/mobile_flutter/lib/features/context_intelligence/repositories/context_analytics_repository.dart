import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;

class ContextAnalyticsRepository {
  final FirebaseFirestore? _firestore;

  ContextAnalyticsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  Future<void> record({
    required String userId,
    required String actionId,
    required String eventType,
    required Map<String, dynamic> metadata,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    try {
      await fs.collection('contextActionEvents').add({
        'userId': userId,
        'actionId': actionId,
        'eventType': eventType,
        'metadata': metadata,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Firestore rules may not yet allow writes here; swallow silently.
    }
  }
}