import 'package:flutter/material.dart';

import '../config/yohpal_streaming_config.dart';
import 'yohpal_streaming_home_screen.dart';

class YohPalExistingAppIntegrationExample extends StatelessWidget {
  const YohPalExistingAppIntegrationExample({super.key});

  @override
  Widget build(BuildContext context) {
    final config = YohPalStreamingConfig(
      wsUrl: 'wss://192.168.1.10/ws',
      roomId: 'room1',
      jwtToken: '<backend-or-local-issued-jwt>',
      lanIp: '192.168.1.10',
      turnUsername: 'localuser',
      turnPassword: 'localpass',
    );

    return ElevatedButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => YohPalStreamingHomeScreen(config: config),
          ),
        );
      },
      child: const Text('Open YohPal Live Streaming'),
    );
  }
}
