import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;

class AppPerformanceRepository {
  final FirebaseFirestore? _firestore;

  AppPerformanceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  Future<void> recordMetric({
    required String userId,
    required String metricName,
    required int valueMs,
    required Map<String, dynamic> metadata,
  }) {
    final fs = _firestore;
    if (fs == null) return Future.value();
    return fs.collection('appPerformanceDiagnostics').add({
      'userId': userId,
      'metricName': metricName,
      'valueMs': valueMs,
      'metadata': metadata,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}