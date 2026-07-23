import 'package:flutter/material.dart';
import '../live_streaming_flags.dart';

class LiveStreamingHubScreen extends StatelessWidget {
  const LiveStreamingHubScreen({super.key});
  @override
  Widget build(BuildContext context) {
    if (!LiveStreamingFlags.enabled) {
      return const Scaffold(
        body: Center(child: Text('Live Streaming is currently disabled.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('YohPal Live Streaming')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/go-live');
            },
            icon: const Icon(Icons.videocam),
            label: const Text('Go Live'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/live-viewer');
            },
            icon: const Icon(Icons.live_tv),
            label: const Text('Watch Live'),
          ),
        ],
      ),
    );
  }
}
