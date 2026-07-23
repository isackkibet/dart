import 'package:flutter/material.dart';

import '../config/yohpal_streaming_config.dart';
import 'widgets/yohpal_live_action_button.dart';
import 'widgets/yohpal_status_pill.dart';
import 'yohpal_broadcaster_screen.dart';
import 'yohpal_live_theme.dart';
import 'yohpal_viewer_screen.dart';

class YohPalStreamingHomeScreen extends StatelessWidget {
  final YohPalStreamingConfig config;

  const YohPalStreamingHomeScreen({
    super.key,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YohPalLiveTheme.background,
      appBar: AppBar(
        backgroundColor: YohPalLiveTheme.background,
        foregroundColor: YohPalLiveTheme.text,
        title: const Text('YohPal Live Streaming'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 1.2,
            colors: [
              YohPalLiveTheme.violet.withValues(alpha: 0.18),
              YohPalLiveTheme.background,
            ],
            center: Alignment.topLeft,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              decoration: YohPalLiveTheme.panelDecoration(),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const YohPalStatusPill(
                    label: 'Local streaming overlay',
                    active: true,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Go live with YohPal',
                    style: TextStyle(
                      color: YohPalLiveTheme.text,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Self-hosted WebRTC streaming powered by mediasoup, TURN, WSS signaling, and Flutter.',
                    style: TextStyle(
                      color: YohPalLiveTheme.muted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  YohPalLiveActionButton(
                    label: 'Creator: Go Live',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              YohPalBroadcasterScreen(config: config),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  YohPalLiveActionButton(
                    label: 'Viewer: Watch Live',
                    secondary: true,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => YohPalViewerScreen(config: config),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: YohPalLiveTheme.panelDecoration(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current local config',
                    style: TextStyle(
                      color: YohPalLiveTheme.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _row('WSS', config.wsUrl),
                  _row('Room', config.roomId),
                  _row('LAN IP', config.lanIp),
                  _row('TURN user', config.turnUsername),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(color: YohPalLiveTheme.muted)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: YohPalLiveTheme.text),
            ),
          ),
        ],
      ),
    );
  }
}
