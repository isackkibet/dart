import 'package:cloud_firestore/cloud_firestore.dart';
import 'floating_pilot_metrics.dart';

class FloatingPilotAnalytics {
  final FirebaseFirestore firestore;
  FloatingPilotAnalytics({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;
  Future<void> recordMetric(FloatingPilotMetrics metric) async {
    await firestore.collection('floatingPilotMetrics').add(metric.toMap());
  }
  Future<void> recordEvent({
    required String uid,
    required String module,
    required String event,
    Map<String, dynamic>? properties,
  }) async {
    await firestore.collection('floatingPilotEvents').add({
      'uid': uid,
      'module': module,
      'event': event,
      'properties': properties ?? {},
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
