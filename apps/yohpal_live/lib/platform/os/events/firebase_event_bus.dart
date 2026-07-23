import 'package:cloud_firestore/cloud_firestore.dart';
import 'yohpal_enterprise_event.dart';
import 'yohpal_event_bus.dart';

class FirebaseEventBus implements YohPalEventBus {
  final FirebaseFirestore firestore;
  FirebaseEventBus({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;
  @override
  Stream<YohPalEnterpriseEvent> watchEvents() {
    return firestore
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
                createdAt: DateTime.tryParse(data['createdAt'] ?? '') ??
                    DateTime.now(),
              );
            }).toList())
        .asyncExpand((events) => Stream.fromIterable(events));
  }
  @override
  Future<void> publish(YohPalEnterpriseEvent event) async {
    await firestore.collection('enterpriseEvents').doc(event.id).set(
          event.toMap(),
        );
  }
  @override
  Future<List<YohPalEnterpriseEvent>> recent({
    String? module,
    String? severity,
    int limit = 100,
  }) async {
    Query<Map<String, dynamic>> query =
        firestore.collection('enterpriseEvents');
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
