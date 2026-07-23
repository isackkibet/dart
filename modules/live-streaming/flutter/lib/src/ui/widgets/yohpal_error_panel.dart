import 'package:flutter/material.dart';

import '../yohpal_live_theme.dart';

class YohPalErrorPanel extends StatelessWidget {
  final String? message;

  const YohPalErrorPanel({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: YohPalLiveTheme.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: YohPalLiveTheme.danger.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(12),
      child: Text(
        message!,
        style: const TextStyle(
          color: YohPalLiveTheme.text,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
