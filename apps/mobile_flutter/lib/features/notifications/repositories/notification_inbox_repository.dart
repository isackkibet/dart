import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase.dart' as fb;
import '../models/notification_model.dart';

class NotificationInboxRepository {
  final FirebaseFirestore? _firestore;

  NotificationInboxRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? fb.tryFirebaseFirestore();

  Stream<List<YohPalNotificationModel>> watchNotifications(String userId) {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => YohPalNotificationModel.fromMap({
                    'id': doc.id,
                    ...doc.data(),
                  }))
              .toList(),
        );
  }

  Future<void> markRead(String notificationId) async {
    final fs = _firestore;
    if (fs == null) return;
    await fs.collection('notifications').doc(notificationId).set(
      {'read': true, 'readAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }
}