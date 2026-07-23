import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;
import 'yohpal_enterprise_event.dart';
import 'yohpal_event_bus.dart';

class FirebaseEventBus implements YohPalEventBus {
  final FirebaseFirestore? _firestore;

  FirebaseEventBus({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  @override
  Stream<YohPalEnterpriseEvent> watchEvents() {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('enterpriseEvents')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              return YohPalEnterpriseEvent(
                id: doc.id,
                module: data['module'] ?? '',
                type: data['type'] ?? '',
                severity: data['severity'] ?? 'info',
                payload: Map<String, dynamic>.from(data['payload'] ?? {}),
                createdAt:
                    DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
              );
            }).toList())
        .asyncExpand((events) => Stream.fromIterable(events));
  }

  @override
  Future<void> publish(YohPalEnterpriseEvent event) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs
        .collection('enterpriseEvents')
        .doc(event.id)
        .set(event.toMap());
  }

  @override
  Future<List<YohPalEnterpriseEvent>> recent({
    String? module,
    String? severity,
    int limit = 100,
  }) async {
    final fs = _firestore;
    if (fs == null) return [];
    Query<Map<String, dynamic>> query =
        fs.collection('enterpriseEvents');
    if (module != null) {
      query = query.where('module', isEqualTo: module);
    }
    if (severity != null) {
      query = query.where('severity', isEqualTo: severity);
    }
    final snap =
        await query.orderBy('createdAt', descending: true).limit(limit).get();
    return snap.docs.map((doc) {
      final data = doc.data();
      return YohPalEnterpriseEvent(
        id: doc.id,
        module: data['module'] ?? '',
        type: data['type'] ?? '',
        severity: data['severity'] ?? 'info',
        payload: Map<String, dynamic>.from(data['payload'] ?? {}),
        createdAt:
            DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
      );
    }).toList();
  }
}