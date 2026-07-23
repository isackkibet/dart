import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/firebase.dart' as fb;
import 'yohpal_analytics_service.dart';

class FirebaseAnalyticsService implements YohPalAnalyticsService {
  final FirebaseFirestore? _firestore;

  FirebaseAnalyticsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  @override
  Future<void> track({
    required String event,
    required String module,
    Map<String, dynamic>? properties,
  }) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs.collection('platformAnalyticsEvents').add({
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