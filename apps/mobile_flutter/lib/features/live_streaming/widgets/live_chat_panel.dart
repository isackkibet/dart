import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/live_chat_message_model.dart';
import '../repositories/live_chat_repository.dart';

class LiveChatPanel extends StatefulWidget {
  final String sessionId;

  const LiveChatPanel({
    super.key,
    required this.sessionId,
  });

  @override
  State<LiveChatPanel> createState() => _LiveChatPanelState();
}

class _LiveChatPanelState extends State<LiveChatPanel> {
  final input = TextEditingController();

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final text = input.text.trim();
    if (text.isEmpty) return;
    input.clear();
    await context.read<LiveChatRepository>().sendMessage(
          sessionId: widget.sessionId,
          userId: user.uid,
          displayName: user.displayName ?? 'Viewer',
          text: text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.read<LiveChatRepository>();
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: .65),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<LiveChatMessageModel>>(
              stream: repo.watchMessages(widget.sessionId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No live chat yet',
                      style: TextStyle(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return ListTile(
                      dense: true,
                      title: Text(
                        msg.displayName,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 12,
                        ),
                      ),
                      subtitle: Text(
                        msg.text,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.flag,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                          size: 18,
                        ),
                        onPressed: () {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) return;
                          repo.reportMessage(
                            sessionId: widget.sessionId,
                            messageId: msg.id,
                            userId: user.uid,
                            reason: 'Reported during live',
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: input,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Say something...',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: send,
                icon: Icon(Icons.send, color: theme.colorScheme.onSurface),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
