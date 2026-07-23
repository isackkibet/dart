import 'package:flutter/material.dart';
import 'live_streaming_flags.dart';

class LiveStreamingGate extends StatelessWidget {
  final Widget child;
  const LiveStreamingGate({
    super.key,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    if (!LiveStreamingFlags.enabled) {
      return const Scaffold(
        body: Center(
          child: Text('Live Streaming is coming soon.'),
        ),
      );
    }
    return child;
  }
}
