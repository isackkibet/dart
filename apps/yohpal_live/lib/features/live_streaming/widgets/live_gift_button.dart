import 'package:flutter/material.dart';
import '../live_streaming_flags.dart';

class LiveGiftButton extends StatelessWidget {
  const LiveGiftButton({super.key});
  @override
  Widget build(BuildContext context) {
    if (!LiveStreamingFlags.giftsEnabled) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: ElevatedButton.icon(
        onPressed: () {
          // TODO: Wire to wallet/gift service after finance validation.
        },
        icon: const Icon(Icons.card_giftcard),
        label: const Text('Send Gift'),
      ),
    );
  }
}
