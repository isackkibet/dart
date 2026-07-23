import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../core/firebase.dart' as fb;
import '../models/app_notification_payload.dart';

class NotificationService {
  final FirebaseMessaging? _messaging;
  final FirebaseFirestore? _firestore;

  NotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
  })  : _messaging = messaging ?? fb.tryFirebaseMessaging(),
        _firestore = firestore ?? fb.tryFirebaseFirestore();

  Future<void> requestPermission() async {
    final m = _messaging;
    if (m == null) return;
    await m.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<String?> getToken() async => _messaging?.getToken();

  Future<void> saveTokenForUser(String uid) async {
    final fs = _firestore;
    final m = _messaging;
    if (fs == null || m == null) return;
    final token = await m.getToken();
    if (token == null) return;
    await fs.collection('users').doc(uid).set({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<RemoteMessage> foregroundMessages() => FirebaseMessaging.onMessage;

  Stream<RemoteMessage> notificationTaps() =>
      FirebaseMessaging.onMessageOpenedApp;

  Future<AppNotificationPayload?> getInitialPayload() async {
    final m = _messaging;
    if (m == null) return null;
    final message = await m.getInitialMessage();
    if (message == null) return null;
    return AppNotificationPayload.fromMap(message.data);
  }
}
