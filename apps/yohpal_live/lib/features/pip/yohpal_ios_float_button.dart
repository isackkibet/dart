import 'package:flutter/material.dart';
import 'pip_flags.dart';
import 'yohpal_ios_pip_service.dart';

class YohPalIosFloatButton extends StatelessWidget {
  final String videoUrl;
  final bool isLive;
  final Future<void> Function(String event, Map<String, dynamic> data)? analytics;
  const YohPalIosFloatButton({
    super.key,
    required this.videoUrl,
    required this.isLive,
    this.analytics,
  });
  @override
  Widget build(BuildContext context) {
    if (!PipFlags.iosEnabled) return const SizedBox.shrink();
    return IconButton(
      icon: const Icon(Icons.picture_in_picture_alt),
      color: Theme.of(context).colorScheme.primary,
      onPressed: () async {
        final service = YohPalIosPipService();
        final prepared = await service.prepare(
          videoUrl: videoUrl,
          isLive: isLive,
        );
        if (!prepared) {
          await analytics?.call('ios_pip_failed', {
            'reason': 'prepare_failed',
            'source': isLive ? 'live' : 'short_video',
          });
          return;
        }
        final started = await service.start();
        await analytics?.call(
          started ? 'ios_pip_entered' : 'ios_pip_failed',
          {
            'source': isLive ? 'live' : 'short_video',
          },
        );
      },
    );
  }
}
