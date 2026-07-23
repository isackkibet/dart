import 'package:flutter/material.dart';

import '../chat/live_chat_message.dart';
import '../chat/live_chat_repository.dart';

class LiveChatPanel extends StatefulWidget {
  const LiveChatPanel({
    super.key,
    required this.liveSessionId,
    this.repository,
  });

  final String liveSessionId;
  final LiveChatContract? repository;

  @override
  State<LiveChatPanel> createState() => _LiveChatPanelState();
}

class _LiveChatPanelState extends State<LiveChatPanel> {
  final _messageController = TextEditingController();
  late final LiveChatContract _repository =
      widget.repository ?? FirestoreLiveChatRepository();

  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    final value = _messageController.text.trim();
    if (value.isEmpty) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await _repository.sendMessage(
        liveSessionId: widget.liveSessionId,
        text: value,
      );
      _messageController.clear();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Message failed to send. Tap Send to retry.';
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.56),
      child: SizedBox(
        height: 260,
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<LiveChatMessage>>(
                stream: _repository.watchMessages(
                  liveSessionId: widget.liveSessionId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Chat is temporarily unavailable.',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    );
                  }

                  final messages = snapshot.data ?? const [];

                  if (messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'Start the conversation.',
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return Semantics(
                        label: '${message.displayName} said '
                            '${message.text}',
                        child: ListTile(
                          dense: true,
                          title: Text(
                            message.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            message.text,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    maxLength: 500,
                    textInputAction: TextInputAction.send,
                    decoration: const InputDecoration(
                      hintText: 'Say something\u2026',
                      counterText: '',
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(
                  tooltip: 'Send message',
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
