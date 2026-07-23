import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/models/result.dart';
import '../domain/traffic_event.dart';

class TrafficEventRepository {
  TrafficEventRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _events =>
      _firestore.collection('trafficEvents');

  Future<Result<void>> capture(TrafficEvent event) async {
    try {
      await _events.add(event.toMap());
      return const Success(null);
    } catch (error) {
      return Failure(
        AppFailure(
          message: 'Failed to capture traffic event.',
          code: 'traffic_event_capture_failed',
          details: error,
        ),
      );
    }
  }
}
