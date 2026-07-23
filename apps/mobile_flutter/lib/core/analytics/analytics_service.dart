import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsService {
  final FirebaseFirestore _db;
  AnalyticsService(this._db);

  Future<void> record(String type, Map<String, dynamic> payload) async {
    await _db.collection('videoEvents').add({
      'type': type,
      ...payload,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
