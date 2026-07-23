import 'package:flutter/material.dart';

import '../yohpal_live_theme.dart';

class YohPalLiveActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool destructive;
  final bool secondary;

  const YohPalLiveActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.destructive = false,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    if (secondary) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: YohPalLiveTheme.text,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: destructive
            ? const LinearGradient(
                colors: [YohPalLiveTheme.danger, Color(0xFFFF8EA0)])
            : YohPalLiveTheme.liveGradient(),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: destructive ? Colors.white : const Color(0xFF04101F),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
