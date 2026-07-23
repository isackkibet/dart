import 'dart:async';

import 'package:flutter/foundation.dart';

import '../contracts/streaming_controller_contracts.dart';
import '../models/yohpal_streaming_state.dart';

final class LiveViewerCoordinator extends ChangeNotifier {
  LiveViewerCoordinator({
    required YohPalViewerContract controller,
  }) : _controller = controller;

  final YohPalViewerContract _controller;
  YohPalStreamingState _state = const YohPalStreamingState.idle();

  YohPalStreamingState get state => _state;

  StreamSubscription<void>? _disconnectSubscription;
  StreamSubscription<void>? _endedSubscription;
  String? _roomId;
  String? _accessToken;
  bool _disposed = false;

  Future<void> initialize() async {
    await _controller.remoteRenderer.initialize();

    _disconnectSubscription = _controller.disconnectedStream.listen((_) {
      if (_state.phase == YohPalStreamingPhase.live) {
        unawaited(reconnect());
      }
    });

    _endedSubscription = _controller.streamEndedStream.listen((_) {
      _setState(
        _state.copyWith(
          phase: YohPalStreamingPhase.ended,
          message: 'This live stream has ended.',
        ),
      );
    });
  }

  Future<void> join({
    required String roomId,
    required String accessToken,
  }) async {
    if (_state.isBusy || _state.isLive) return;

    _roomId = roomId;
    _accessToken = accessToken;

    _setState(
      _state.copyWith(
        phase: YohPalStreamingPhase.connecting,
        message: 'Joining live stream\u2026',
        clearError: true,
      ),
    );

    try {
      await _controller.joinStream(
        roomId: roomId,
        accessToken: accessToken,
      );

      _setState(
        _state.copyWith(
          phase: YohPalStreamingPhase.live,
          message: 'Live',
          clearError: true,
        ),
      );
    } on TimeoutException catch (error) {
      _fail(
        error,
        'The live stream did not respond in time.',
      );
    } catch (error) {
      _fail(
        error,
        'YohPal could not join this live stream.',
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
          message: 'Live',
          clearError: true,
        ),
      );
    } on TimeoutException catch (error) {
      _fail(error, 'Reconnection timed out.');
    } catch (error) {
      _fail(error, 'The stream could not reconnect.');
    }
  }

  Future<void> leave() async {
    await _controller.leaveStream();

    _setState(
      _state.copyWith(
        phase: YohPalStreamingPhase.ended,
        message: 'You left the live stream.',
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
    unawaited(_disconnectSubscription?.cancel());
    unawaited(_endedSubscription?.cancel());
    unawaited(_controller.dispose());
    super.dispose();
  }
}
