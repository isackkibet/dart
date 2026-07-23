import 'package:flutter/material.dart';
import '../application/live_chat_controller.dart';
import '../domain/chat_message.dart';

/// Full-screen or side-panel chat overlay for viewers and creators.
/// Wrap in a [AnimatedBuilder] for reactive updates.
class LiveChatOverlay extends StatefulWidget {
  const LiveChatOverlay({
    super.key,
    required this.sessionId,
    required this.controller,
    this.isCreator = false,
  });

  final String sessionId;
  final LiveChatController controller;
  final bool isCreator;

  @override
  State<LiveChatOverlay> createState() => _LiveChatOverlayState();
}

class _LiveChatOverlayState extends State<LiveChatOverlay> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _atBottom = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onMessagesChanged);
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    final pos = _scrollCtrl.position;
    _atBottom = pos.pixels >= pos.maxScrollExtent - 40;
  }

  void _onMessagesChanged() {
    if (_atBottom && _scrollCtrl.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _send() async {
    final text = _inputCtrl.text;
    if (text.trim().isEmpty) return;
    _inputCtrl.clear();
    final result = await widget.controller.sendMessage(widget.sessionId, text);
    if (!mounted) return;
    if (result.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.controller.failure?.message ?? 'Failed to send.'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onMessagesChanged);
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Column(
          children: [
            // Pinned message
            if (widget.controller.pinnedMessage != null)
              _PinnedMessageCard(
                message: widget.controller.pinnedMessage!,
                isCreator: widget.isCreator,
                onUnpin: () => widget.controller.deleteMessage(
                  widget.sessionId,
                  widget.controller.pinnedMessage!.id,
                ),
              ),
            // Message list
            Expanded(
              child: widget.controller.messages.isEmpty
                  ? const Center(
                      child: Text(
                        'Be the first to say something! 👋',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: widget.controller.messages.length,
                      itemBuilder: (ctx, i) {
                        final msg = widget.controller.messages[i];
                        return _MessageBubble(
                          message: msg,
                          isOwn: msg.senderId == widget.controller.currentUserId,
                          isCreator: widget.isCreator,
                          isLoading: widget.controller.isLoading(msg.id),
                          onPin: () => widget.controller.pinMessage(
                              widget.sessionId, msg.id),
                          onDelete: () => widget.controller.deleteMessage(
                              widget.sessionId, msg.id),
                          onMute: () => widget.controller.muteUser(
                              widget.sessionId, msg.senderId),
                        );
                      },
                    ),
            ),
            // Input bar
            _ChatInputBar(
              controller: _inputCtrl,
              isSending: widget.controller.isSending,
              isMuted: widget.controller.isMuted,
              onSend: _send,
            ),
          ],
        );
      },
    );
  }
}

// ── Pinned Message Card ───────────────────────────────────────────────────────

class _PinnedMessageCard extends StatelessWidget {
  const _PinnedMessageCard({
    required this.message,
    required this.isCreator,
    required this.onUnpin,
  });

  final ChatMessage message;
  final bool isCreator;
  final VoidCallback onUnpin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.push_pin, color: Colors.amber, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                children: [
                  TextSpan(
                    text: '${message.senderName}: ',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: Colors.amber),
                  ),
                  TextSpan(text: message.displayText),
                ],
              ),
            ),
          ),
          if (isCreator)
            GestureDetector(
              onTap: onUnpin,
              child: const Icon(Icons.close, color: Colors.white38, size: 16),
            ),
        ],
      ),
    );
  }
}

// ── Message Bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isOwn,
    required this.isCreator,
    required this.isLoading,
    required this.onPin,
    required this.onDelete,
    required this.onMute,
  });

  final ChatMessage message;
  final bool isOwn;
  final bool isCreator;
  final bool isLoading;
  final VoidCallback onPin;
  final VoidCallback onDelete;
  final VoidCallback onMute;

  Color _nameColor(String userId) {
    final colors = [
      Colors.cyanAccent,
      Colors.greenAccent,
      Colors.pinkAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.yellowAccent,
    ];
    return colors[userId.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Text(
            message.displayText,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    final Widget bubble = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isGift)
            const Padding(
              padding: EdgeInsets.only(right: 6, top: 2),
              child: Text('🎁', style: TextStyle(fontSize: 16)),
            ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white, fontSize: 13),
                children: [
                  TextSpan(
                    text: '${message.senderName}  ',
                    style: TextStyle(
                      color: _nameColor(message.senderId),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  TextSpan(
                    text: message.displayText,
                    style: TextStyle(
                      color: message.isDeleted
                          ? Colors.white30
                          : Colors.white.withOpacity(0.87),
                      fontStyle: message.isDeleted
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
        ],
      ),
    );

    if (!isCreator || message.isDeleted) return bubble;

    return GestureDetector(
      onLongPress: () => _showModerationMenu(context),
      child: bubble,
    );
  }

  void _showModerationMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.push_pin, color: Colors.amber),
              title: const Text('Pin message',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                onPin();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete message',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
            ListTile(
              leading: const Icon(Icons.voice_over_off, color: Colors.orange),
              title: Text('Mute ${message.senderName}',
                  style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                onMute();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Chat Input Bar ────────────────────────────────────────────────────────────

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.isSending,
    required this.isMuted,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final bool isMuted;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isMuted && !isSending,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 1,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: isMuted ? 'You are muted' : 'Say something...',
                hintStyle: const TextStyle(color: Colors.white38),
                counterText: '',
                filled: true,
                fillColor: Colors.white.withOpacity(0.07),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: isSending
                ? const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton.filled(
                    onPressed: isMuted ? null : onSend,
                    icon: const Icon(Icons.send, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: isMuted
                          ? Colors.grey
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
