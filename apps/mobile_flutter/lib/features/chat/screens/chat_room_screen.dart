import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/observability/yohpal_crash_reporter.dart';
import '../../../design_system/tokens/yohpal_brand_colors.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_message_model.dart';

class ChatRoomScreen extends StatefulWidget {
  final String conversationId;

  const ChatRoomScreen({super.key, required this.conversationId});
  static const routeName = '/chat-room';

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _input = TextEditingController();
  late final ChatController _controller;
  late final String _uid;
  bool _sending = false;
  String? _sendError;

  @override
  void initState() {
    super.initState();
    _controller = context.read<ChatController>();
    _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _controller.markRead(conversationId: widget.conversationId, userId: _uid);
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send([String? retryText]) async {
    final text = retryText ?? _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _sendError = null;
    });
    try {
      await _controller.sendMessage(
        conversationId: widget.conversationId,
        senderId: _uid,
        text: text,
      );
      if (retryText == null) _input.clear();
    } catch (error, stack) {
      if (!mounted) return;
      unawaited(
        context.read<YohPalCrashReporter>().recordError(
              error,
              stack,
              reason: 'Chat message send failure',
            ),
      );
      setState(() {
        _sendError = text;
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _retrySend() {
    final failedText = _sendError;
    if (failedText != null) _send(failedText);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessageModel>>(
              stream: _controller.messagesStream(widget.conversationId),
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
                final messages = snap.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Text('No messages yet. Say hello!',
                        style:
                            TextStyle(color: onSurface.withValues(alpha: 0.6))),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == _uid;
                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.72,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isMe ? YohPalBrandColors.gold : theme.cardColor,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 16),
                          ),
                        ),
                        child: Text(
                          msg.text,
                          style: TextStyle(
                              color:
                                  isMe ? YohPalBrandColors.black : onSurface),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_sendError != null)
            MaterialBanner(
              content: const Text('Message could not be sent.'),
              actions: [
                TextButton(
                  onPressed: _retrySend,
                  child: const Text('Retry'),
                ),
              ],
            ),
          _InputBar(
            controller: _input,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: TextStyle(color: onSurface),
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: YohPalBrandColors.gold),
              onPressed: sending ? null : onSend,
            ),
          ],
        ),
      ),
    );
  }
}
