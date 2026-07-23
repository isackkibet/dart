import 'package:flutter/material.dart';

import '../../design_system/tokens/yohpal_brand_colors.dart';
import '../../design_system/widgets/yohpal_gold_pulse.dart';

/// Branded splash shown while [FeedStartupWarmupService] warms the first
/// videos in the background. Reads colors from the active theme so it
/// matches Day/Night mode rather than being locked to black.
class YohPalStartupScreen extends StatelessWidget {
  const YohPalStartupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'YohPal Live',
              style: TextStyle(
                color: YohPalBrandColors.gold,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Create. Go Live. Earn. Grow.',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 36),
            const YohPalGoldPulse(),
          ],
        ),
      ),
    );
  }
}
