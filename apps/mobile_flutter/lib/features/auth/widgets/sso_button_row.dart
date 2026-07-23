import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';

/// Google + Apple SSO tiles, side by side. Apple's tile only renders on
/// iOS/macOS — `sign_in_with_apple` needs native ASAuthorizationController
/// support, which Android doesn't have without a separate web-relay setup
/// this project doesn't have configured. Showing a button that always fails
/// on Android would be worse than not showing it.
class SsoButtonRow extends StatelessWidget {
  const SsoButtonRow({super.key});

  Future<void> _handle(
    BuildContext context,
    Future<bool> Function() signIn,
  ) async {
    final ok = await signIn();
    if (ok && context.mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final auth = context.watch<AuthController>();
    // dart:io Platform throws on web — this app does have a web/ build
    // target, so kIsWeb has to be checked first, not just Platform.isIOS.
    final showApple = !kIsWeb && (Platform.isIOS || Platform.isMacOS);

    final googleTile = _SsoTile(
      assetPath: 'lib/Assets/google.png',
      label: 'Google',
      // Google's "G" is brand-colored on purpose — never tinted.
      enabled: !auth.loading,
      onTap: () => _handle(context, context.read<AuthController>().loginWithGoogle),
    );

    if (!showApple) {
      return googleTile;
    }

    return Row(
      children: [
        Expanded(child: googleTile),
        const SizedBox(width: 12),
        Expanded(
          child: _SsoTile(
            assetPath: 'lib/Assets/apple.png',
            label: 'Apple',
            // apple.png is a solid black glyph — tint it to match the
            // theme's text color or it disappears against a dark tile in
            // Night mode.
            tintColor: onSurface,
            enabled: !auth.loading,
            onTap: () => _handle(context, context.read<AuthController>().loginWithApple),
          ),
        ),
      ],
    );
  }
}

class _SsoTile extends StatelessWidget {
  final String assetPath;
  final String label;
  final Color? tintColor;
  final bool enabled;
  final VoidCallback onTap;

  const _SsoTile({
    required this.assetPath,
    required this.label,
    required this.onTap,
    this.tintColor,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return OutlinedButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Image.asset(
        assetPath,
        width: 20,
        height: 20,
        color: tintColor,
      ),
      label: Text(label, style: TextStyle(color: onSurface)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: onSurface.withValues(alpha: 0.2)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
