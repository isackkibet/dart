import 'package:flutter/material.dart';

/// "or continue with" divider used between password auth and SSO options
/// on both LoginScreen and SignupScreen.
class SsoDivider extends StatelessWidget {
  const SsoDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(context).dividerColor;
    final textColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);

    return Row(
      children: [
        Expanded(child: Divider(color: dividerColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or continue with',
            style: TextStyle(color: textColor, fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: dividerColor)),
      ],
    );
  }
}
