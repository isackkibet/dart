import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../chat/screens/chat_room_screen.dart';
import '../controllers/notification_inbox_controller.dart';
import '../models/notification_model.dart';
import '../repositories/notification_inbox_repository.dart';

class NotificationInboxScreen extends StatelessWidget {
  const NotificationInboxScreen({super.key});
  static const routeName = '/notifications';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final repo = context.read<NotificationInboxRepository>();

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050816),
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<List<YohPalNotificationModel>>(
        stream: repo.watchNotifications(user.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(
              child: Text('No notifications yet',
                  style: TextStyle(color: Colors.white54)),
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final n = items[index];
              return ListTile(
                leading: Icon(
                  n.read
                      ? Icons.notifications_none
                      : Icons.notifications_active,
                  color: n.read ? Colors.white54 : Colors.cyanAccent,
                ),
                title: Text(n.title,
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text(n.body,
                    style: const TextStyle(color: Colors.white54)),
                trailing: Text(n.type,
                    style: const TextStyle(color: Colors.white38,
                        fontSize: 11)),
                onTap: () async {
                  await context
                      .read<NotificationInboxController>()
                      .markRead(n.id);
                  if (context.mounted) {
                    _routeNotification(context, n);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  void _routeNotification(
    BuildContext context,
    YohPalNotificationModel n,
  ) {
    switch (n.type) {
      case 'live':
        Navigator.pushNamed(context, '/live-viewer', arguments: n.targetId);
      case 'chat':
        Navigator.pushNamed(context, ChatRoomScreen.routeName,
            arguments: n.targetId);
      case 'poll':
        Navigator.pushNamed(context, '/poll', arguments: n.targetId);
      case 'follow':
        Navigator.pushNamed(context, '/creator-profile',
            arguments: n.targetId);
    }
  }
}
