import 'package:flutter/material.dart';

/// Fallback for Navigator.pushNamed calls to routes that don't exist in
/// YohPalRouter.routes — previously an unhandled push here crashed the app
/// (e.g. the '/creator-analytics' route mismatch) instead of showing this.
class UnknownRouteScreen extends StatelessWidget {
  const UnknownRouteScreen({super.key, this.attemptedRoute});

  final String? attemptedRoute;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page unavailable')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_off, size: 48),
              const SizedBox(height: 16),
              const Text(
                'This destination is unavailable.',
                textAlign: TextAlign.center,
              ),
              if (attemptedRoute != null) ...[
                const SizedBox(height: 8),
                Text(attemptedRoute!, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Return home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
