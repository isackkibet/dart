import 'package:flutter/material.dart';

class YohPalLiveTheme {
  static const Color background = Color(0xFF07111F);
  static const Color surface = Color(0xFF101B2D);
  static const Color surfaceSoft = Color(0xFF17243A);
  static const Color neon = Color(0xFF00E6C3);
  static const Color violet = Color(0xFF6D7CFF);
  static const Color danger = Color(0xFFFF657A);
  static const Color warning = Color(0xFFFFC857);
  static const Color text = Color(0xFFF5F7FB);
  static const Color muted = Color(0xFFB9C6DC);

  static BoxDecoration panelDecoration() {
    return BoxDecoration(
      color: surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.22),
          blurRadius: 32,
          offset: const Offset(0, 16),
        ),
      ],
    );
  }

  static LinearGradient liveGradient() {
    return const LinearGradient(
      colors: [neon, violet],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
