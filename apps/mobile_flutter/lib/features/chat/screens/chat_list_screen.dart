import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../design_system/tokens/yohpal_brand_colors.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_conversation_model.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});
  static const routeName = '/chat';

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final controller = context.read<ChatController>();
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Messages'),
      ),
      body: StreamBuilder<List<ChatConversationModel>>(
        stream: controller.conversationsStream(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('Error: ${snap.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          }
          final conversations = snap.data ?? [];
          if (conversations.isEmpty) {
            return Center(
              child: Text('No conversations yet',
                  style: TextStyle(color: onSurface.withValues(alpha: 0.6))),
            );
          }
          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final c = conversations[index];
              final otherEntry = c.participantNames.entries.firstWhere(
                (e) => e.key != uid,
                orElse: () => const MapEntry('', 'Unknown'),
              );
              final otherName = otherEntry.value.toString();
              final unread = ((c.unreadCounts[uid] ?? 0) as num).toInt();
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.cardColor,
                  child: Text(
                    otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                    style: TextStyle(color: onSurface),
                  ),
                ),
                title: Text(otherName, style: TextStyle(color: onSurface)),
                subtitle: Text(
                  c.lastMessage.isEmpty
                      ? 'Start a conversation'
                      : c.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                ),
                trailing: unread > 0
                    ? CircleAvatar(
                        radius: 12,
                        backgroundColor: YohPalBrandColors.gold,
                        child: Text(
                          '$unread',
                          style: const TextStyle(
                              color: YohPalBrandColors.black, fontSize: 10),
                        ),
                      )
                    : null,
                onTap: () async {
                  await controller.markRead(
                    conversationId: c.id,
                    userId: uid,
                  );
                  if (context.mounted) {
                    Navigator.pushNamed(
                      context,
                      ChatRoomScreen.routeName,
                      arguments: c.id,
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
