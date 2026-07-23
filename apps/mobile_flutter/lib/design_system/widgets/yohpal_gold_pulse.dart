import 'package:flutter/material.dart';

import '../tokens/yohpal_brand_colors.dart';

/// Brand loading indicator: a softly pulsing gold ring. Used in place of a
/// plain [CircularProgressIndicator] on the startup screen and over video
/// thumbnails while their player is still warming up.
class YohPalGoldPulse extends StatefulWidget {
  final double size;

  const YohPalGoldPulse({super.key, this.size = 40});

  @override
  State<YohPalGoldPulse> createState() => _YohPalGoldPulseState();
}

class _YohPalGoldPulseState extends State<YohPalGoldPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Opacity(
          opacity: 0.45 + (0.55 * t),
          child: Transform.scale(
            scale: 0.85 + (0.15 * t),
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CircularProgressIndicator(
                color: YohPalBrandColors.gold,
                strokeWidth: 2.5,
              ),
            ),
          ),
        );
      },
    );
  }
}
