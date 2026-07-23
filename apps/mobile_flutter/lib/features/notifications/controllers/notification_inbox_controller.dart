import 'package:flutter/foundation.dart';
import '../repositories/notification_inbox_repository.dart';

class NotificationInboxController extends ChangeNotifier {
  final NotificationInboxRepository repository;

  NotificationInboxController({required this.repository});

  Future<void> markRead(String notificationId) {
    return repository.markRead(notificationId);
  }
}
