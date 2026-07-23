import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/diagnostics/app_start_clock.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/startup/models/startup_diagnostic_model.dart';
import '../features/startup/repositories/startup_diagnostics_repository.dart';
import '../features/startup/yohpal_startup_screen.dart';
import '../features/video_feed/startup/feed_startup_warmup_service.dart';

/// Gates [child] behind a branded splash from the very start of the app —
/// before Firebase's auth state has even resolved, and while the first
/// suggested videos warm in the background. Reveals [child] once BOTH the
/// real auth state is known and the first video's player controller is
/// initialized, or after a fallback timeout — whichever comes first — so
/// nobody ever sees a flash of the login screen or a bare loading spinner.
class YohPalBootstrap extends StatefulWidget {
  final Widget child;
  final FeedStartupWarmupService warmupService;
  final StartupDiagnosticsRepository? diagnosticsRepository;

  const YohPalBootstrap({
    super.key,
    required this.child,
    required this.warmupService,
    this.diagnosticsRepository,
  });

  @override
  State<YohPalBootstrap> createState() => _YohPalBootstrapState();
}

class _YohPalBootstrapState extends State<YohPalBootstrap> {
  static const _fallbackTimeout = Duration(seconds: 4);
  static const _minSplashDuration = Duration(seconds: 2);

  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _waitForAuthReady() async {
    final auth = context.read<AuthController>();
    if (auth.authReady) return;
    final completer = Completer<void>();
    void listener() {
      if (auth.authReady && !completer.isCompleted) completer.complete();
    }

    auth.addListener(listener);
    try {
      await completer.future.timeout(_fallbackTimeout, onTimeout: () {});
    } finally {
      auth.removeListener(listener);
    }
  }

  Future<void> _boot() async {
    final appStartMs = msSinceAppStart();
    final warmupStart = DateTime.now();
    var warmupSuccess = false;
    int? firstVideoReadyMs;

    // Feed warm-up and auth-state resolution run concurrently — total added
    // latency is bounded by the slower of the two, not their sum.
    final warmupFuture = widget.warmupService
        .warmupSuggestedFeed()
        .timeout(_fallbackTimeout)
        .then((result) {
      warmupSuccess = result.firstVideoReady;
      if (result.firstVideoReady) {
        firstVideoReadyMs = msSinceAppStart();
      }
    }).catchError((_) {
      // Never block app launch forever — proceed with an unwarmed feed.
    });

    await Future.wait([warmupFuture, _waitForAuthReady()]);

    final feedWarmupMs =
        DateTime.now().difference(warmupStart).inMilliseconds;

    final elapsedSplash = DateTime.now().difference(warmupStart);
    if (elapsedSplash < _minSplashDuration) {
      await Future.delayed(_minSplashDuration - elapsedSplash);
    }

    (widget.diagnosticsRepository ?? StartupDiagnosticsRepository()).record(
      StartupDiagnosticModel(
        appStartMs: appStartMs,
        feedWarmupMs: feedWarmupMs,
        firstVideoReadyMs: firstVideoReadyMs,
        warmupSuccess: warmupSuccess,
      ),
    );

    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    return _ready ? widget.child : const YohPalStartupScreen();
  }
}
