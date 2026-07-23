import 'package:cloud_firestore/cloud_firestore.dart';
import 'yohpal_analytics_service.dart';

class FirebaseAnalyticsService implements YohPalAnalyticsService {
  final FirebaseFirestore firestore;
  FirebaseAnalyticsService({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;
  @override
  Future<void> track({
    required String event,
    required String module,
    Map<String, dynamic>? properties,
  }) async {
    await firestore.collection('platformAnalyticsEvents').add({
      'event': event,
      'module': module,
      'properties': properties ?? {},
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  @override
  Future<void> screenView({
    required String screen,
    required String module,
  }) async {
    await track(
      event: 'screen_view',
      module: module,
      properties: {'screen': screen},
    );
  }
}
