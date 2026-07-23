import 'dart:async';

import 'package:flutter/foundation.dart';

import '../contracts/streaming_controller_contracts.dart';
import '../models/yohpal_streaming_state.dart';

final class GoLiveCoordinator extends ChangeNotifier {
  GoLiveCoordinator({
    required YohPalBroadcasterContract controller,
  }) : _controller = controller;

  final YohPalBroadcasterContract _controller;
  YohPalStreamingState _state = const YohPalStreamingState.idle();

  YohPalStreamingState get state => _state;

  StreamSubscription<int>? _viewerSubscription;
  StreamSubscription<void>? _disconnectSubscription;
  String? _roomId;
  String? _accessToken;
  bool _disposed = false;

  Future<void> initialize() async {
    await _controller.localRenderer.initialize();

    _viewerSubscription = _controller.viewerCountStream.listen(_setViewerCount);

    _disconnectSubscription = _controller.disconnectedStream.listen((_) {
      if (_state.phase == YohPalStreamingPhase.live) {
        _setState(
          _state.copyWith(
            phase: YohPalStreamingPhase.reconnecting,
            message: 'Connection lost. Reconnecting\u2026',
          ),
        );
        unawaited(reconnect());
      }
    });
  }

  Future<void> start({
    required String roomId,
    required String accessToken,
  }) async {
    if (_state.isBusy || _state.isLive) return;

    _roomId = roomId;
    _accessToken = accessToken;

    _setState(
      _state.copyWith(
        phase: YohPalStreamingPhase.connecting,
        message: 'Preparing your live stream\u2026',
        clearError: true,
      ),
    );

    try {
      await _controller.startBroadcast(
        roomId: roomId,
        accessToken: accessToken,
      );

      _setState(
        _state.copyWith(
          phase: YohPalStreamingPhase.live,
          message: 'You are live',
          clearError: true,
        ),
      );
    } on TimeoutException catch (error) {
      _fail(
        error,
        'The streaming server did not respond in time.',
      );
    } catch (error) {
      _fail(
        error,
        'YohPal could not start this live stream.',
      );
    }
  }

  Future<void> reconnect() async {
    final roomId = _roomId;
    final accessToken = _accessToken;
    if (roomId == null || accessToken == null) return;

    _setState(
      _state.copyWith(
        phase: YohPalStreamingPhase.reconnecting,
        message: 'Reconnecting\u2026',
        clearError: true,
      ),
    );

    try {
      await _controller
          .reconnect(
            roomId: roomId,
            accessToken: accessToken,
          )
          .timeout(const Duration(seconds: 10));

      _setState(
        _state.copyWith(
          phase: YohPalStreamingPhase.live,
          message: 'You are live',
          clearError: true,
        ),
      );
    } on TimeoutException catch (error) {
      _fail(error, 'Reconnection timed out.');
    } catch (error) {
      _fail(error, 'The live stream could not reconnect.');
    }
  }

  Future<void> stop() async {
    if (!_state.isLive && _state.phase != YohPalStreamingPhase.reconnecting) {
      return;
    }

    _setState(
      _state.copyWith(
        phase: YohPalStreamingPhase.ending,
        message: 'Ending live stream\u2026',
      ),
    );

    try {
      await _controller.stopBroadcast();

      _setState(
        _state.copyWith(
          phase: YohPalStreamingPhase.ended,
          message: 'Live stream ended',
          clearError: true,
        ),
      );
    } catch (error) {
      _fail(
        error,
        'The stream could not be ended cleanly.',
      );
    }
  }

  void _setViewerCount(int count) {
    _setState(
      _state.copyWith(
        viewerCount: count < 0 ? 0 : count,
      ),
    );
  }

  void _fail(Object error, String message) {
    _setState(
      _state.copyWith(
        phase: YohPalStreamingPhase.failed,
        message: message,
        error: error,
      ),
    );
  }

  void _setState(YohPalStreamingState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_viewerSubscription?.cancel());
    unawaited(_disconnectSubscription?.cancel());
    unawaited(_controller.dispose());
    super.dispose();
  }
}
