abstract class YohPalNotificationService {
  Future<void> sendInApp({
    required String uid,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  });

  Future<void> sendPush({
    required String uid,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  });
}
