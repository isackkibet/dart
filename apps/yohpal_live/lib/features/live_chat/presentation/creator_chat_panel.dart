import 'package:flutter/material.dart';
import '../../../core/auth/yohpal_auth_service.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/network/api_client.dart';
import '../application/live_chat_controller.dart';
import '../data/live_chat_repository.dart';
import 'live_chat_overlay.dart';

/// Creator-specific chat panel shown as a full bottom sheet.
/// Displays the chat with moderation controls enabled.
class CreatorChatPanel extends StatefulWidget {
  const CreatorChatPanel({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  static Future<void> show(BuildContext context,
      {required String sessionId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreatorChatPanel(sessionId: sessionId),
    );
  }

  @override
  State<CreatorChatPanel> createState() => _CreatorChatPanelState();
}

class _CreatorChatPanelState extends State<CreatorChatPanel> {
  late final LiveChatController _controller;

  @override
  void initState() {
    super.initState();
    final env = AppEnvironmentConfig.fromDartDefines();
    final auth = YohPalAuthService();
    _controller = LiveChatController(
      repository: LiveChatRepository(
        apiClient: ApiClient(
          baseUrl: env.apiBaseUrl,
          tokenProvider: auth.getIdToken,
        ),
      ),
      currentUserId: auth.currentUserId ?? '',
      currentUserName: auth.currentUserName ?? 'Creator',
    );
    _controller.startWatching(widget.sessionId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle + header
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline,
                        color: Colors.white70),
                    const SizedBox(width: 10),
                    Text(
                      'Live Chat',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.white),
                    ),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (_, __) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_controller.messages.length} messages',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white12),
              // Chat — creator mode (isCreator=true enables moderation)
              Expanded(
                child: LiveChatOverlay(
                  sessionId: widget.sessionId,
                  controller: _controller,
                  isCreator: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
