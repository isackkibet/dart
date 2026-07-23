import 'package:cloud_functions/cloud_functions.dart';
import 'yohpal_notification_service.dart';

class FirebaseNotificationService implements YohPalNotificationService {
  final FirebaseFunctions _functions;

  FirebaseNotificationService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  @override
  Future<void> sendInApp({
    required String uid,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await _functions.httpsCallable('sendInAppNotification').call({
      'uid': uid,
      'title': title,
      'body': body,
      'data': data ?? {},
    });
  }

  @override
  Future<void> sendPush({
    required String uid,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await _functions.httpsCallable('sendPushNotification').call({
      'uid': uid,
      'title': title,
      'body': body,
      'data': data ?? {},
    });
  }
}
