import 'dart:async';
import 'package:flutter/widgets.dart';
import '../controllers/zero_wait_playback_controller.dart';

/// [WidgetsBindingObserver] that forwards OS lifecycle events to the
/// zero-wait playback controller.
///
/// Call [register] after construction and [unregister] in the owning
/// widget's dispose to avoid a common memory-pressure listener leak.
final class ZeroWaitLifecycleObserver with WidgetsBindingObserver {
  ZeroWaitLifecycleObserver({required ZeroWaitPlaybackController controller})
      : _controller = controller;

  final ZeroWaitPlaybackController _controller;

  void register() {
    WidgetsBinding.instance.addObserver(this);
  }

  void unregister() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didHaveMemoryPressure() {
    unawaited(_controller.handleMemoryPressure());
  }
}
