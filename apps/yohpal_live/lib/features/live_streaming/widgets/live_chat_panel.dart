import 'package:flutter/material.dart';
import '../live_streaming_flags.dart';

class LiveChatPanel extends StatelessWidget {
  const LiveChatPanel({super.key});
  @override
  Widget build(BuildContext context) {
    if (!LiveStreamingFlags.chatEnabled) {
      return const SizedBox.shrink();
    }
    return Container(
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Live Chat'),
          SizedBox(height: 8),
          Text('Chat messages will appear here.'),
        ],
      ),
    );
  }
}
