import 'package:flutter/material.dart';
import '../../wallet/screens/wallet_screen.dart';

enum WalletStatusResult { success, pending, failed }

class WalletStatusArgs {
  final WalletStatusResult status;
  final String reference;

  const WalletStatusArgs({required this.status, required this.reference});

  /// Builds args from the raw query-style parameters YohPal Web appends to
  /// the return link (`status`, `reference`) — used by both the deep-link
  /// listener (YohPalDeepLinkService) and directly in tests.
  factory WalletStatusArgs.fromQueryParameters(Map<String, String> params) {
    final rawStatus = params['status'];
    final status = switch (rawStatus) {
      'success' => WalletStatusResult.success,
      'failed' => WalletStatusResult.failed,
      _ => WalletStatusResult.pending,
    };
    return WalletStatusArgs(
      status: status,
      reference: params['reference'] ?? 'unknown',
    );
  }
}

/// The screen a user lands on when they return to the app from a YohPal Web
/// wallet top-up, withdrawal, or subscription checkout.
///
/// This used to be an unimplemented placeholder with no route registered —
/// meaning every "money" flow that handed the user off to an external
/// browser gave them zero confirmation of whether it worked (Production
/// Readiness Review, Critical #7). It's reachable two ways: in-app
/// navigation with WalletStatusArgs passed directly, or via
/// YohPalDeepLinkService parsing a `yohpal://wallet-status?...` link that
/// YohPal Web opens when it redirects back to the app.
class WalletStatusScreen extends StatelessWidget {
  static const routeName = '/wallet-status';

  final WalletStatusArgs args;

  const WalletStatusScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, iconColor, title, message) = switch (args.status) {
      WalletStatusResult.success => (
          Icons.check_circle,
          Colors.green,
          'Payment received',
          'Your balance has been updated. It may take a few seconds to '
              'appear in your wallet.',
        ),
      WalletStatusResult.failed => (
          Icons.error,
          theme.colorScheme.error,
          'Payment failed',
          'The transaction did not complete. No funds were moved. You can '
              'try again from your wallet.',
        ),
      WalletStatusResult.pending => (
          Icons.hourglass_top,
          Colors.orange,
          'Payment status pending',
          "We haven't received a final confirmation yet. Check your wallet "
              'in a moment — this page does not need to stay open.',
        ),
    };

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Wallet Status'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: iconColor),
              const SizedBox(height: 16),
              Text(title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Reference: ${args.reference}',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  WalletScreen.routeName,
                  (route) => route.isFirst,
                ),
                child: const Text('View wallet'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Return to YohPal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
