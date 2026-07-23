import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../contracts/streaming_controller_contracts.dart';
import '../integration/go_live_coordinator.dart';
import '../models/yohpal_streaming_state.dart';

class GoLiveScreen extends StatefulWidget {
  const GoLiveScreen({
    super.key,
    required this.roomId,
    required this.accessToken,
    required this.controllerFactory,
  });

  final String roomId;
  final String accessToken;
  final YohPalBroadcasterContract Function() controllerFactory;

  @override
  State<GoLiveScreen> createState() => _GoLiveScreenState();
}

class _GoLiveScreenState extends State<GoLiveScreen>
    with WidgetsBindingObserver {
  late final YohPalBroadcasterContract _controller;
  late final GoLiveCoordinator _coordinator;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = widget.controllerFactory();
    _coordinator = GoLiveCoordinator(
      controller: _controller,
    )..addListener(_refresh);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _coordinator.initialize();
      await _coordinator.start(
        roomId: widget.roomId,
        accessToken: widget.accessToken,
      );
    });
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _coordinator.state.phase == YohPalStreamingPhase.reconnecting) {
      _coordinator.reconnect();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _coordinator
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _coordinator.state;
    return PopScope(
      canPop: state.phase != YohPalStreamingPhase.live &&
          state.phase != YohPalStreamingPhase.reconnecting,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldEnd = await _confirmEnd();
        if (shouldEnd != true || !mounted) return;
        await _coordinator.stop();
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              RTCVideoView(
                _controller.localRenderer,
                mirror: true,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
              _BroadcasterOverlay(
                state: state,
                onRetry: () => _coordinator.start(
                  roomId: widget.roomId,
                  accessToken: widget.accessToken,
                ),
                onReconnect: _coordinator.reconnect,
                onEnd: _coordinator.stop,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmEnd() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End live stream?'),
        content: const Text(
          'Your viewers will be disconnected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue live'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End live'),
          ),
        ],
      ),
    );
  }
}

class _BroadcasterOverlay extends StatelessWidget {
  const _BroadcasterOverlay({
    required this.state,
    required this.onRetry,
    required this.onReconnect,
    required this.onEnd,
  });

  final YohPalStreamingState state;
  final Future<void> Function() onRetry;
  final Future<void> Function() onReconnect;
  final Future<void> Function() onEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _LiveStatusPill(state: state),
              const Spacer(),
              Semantics(
                label: '${state.viewerCount} viewers watching',
                child: Text(
                  '${state.viewerCount} viewers',
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          if (state.isBusy) const CircularProgressIndicator(),
          if (state.phase == YohPalStreamingPhase.failed)
            _StreamingErrorPanel(
              message: state.message ?? 'Streaming failed.',
              onRetry: onRetry,
            ),
          if (state.phase == YohPalStreamingPhase.live ||
              state.phase == YohPalStreamingPhase.reconnecting)
            FilledButton.icon(
              onPressed: onEnd,
              icon: const Icon(Icons.stop_circle),
              label: const Text('End Live'),
            ),
        ],
      ),
    );
  }
}

class _LiveStatusPill extends StatelessWidget {
  const _LiveStatusPill({
    required this.state,
  });

  final YohPalStreamingState state;

  @override
  Widget build(BuildContext context) {
    final label = switch (state.phase) {
      YohPalStreamingPhase.idle => 'Ready',
      YohPalStreamingPhase.preparing => 'Preparing',
      YohPalStreamingPhase.connecting => 'Connecting',
      YohPalStreamingPhase.live => 'LIVE',
      YohPalStreamingPhase.reconnecting => 'Reconnecting',
      YohPalStreamingPhase.ending => 'Ending',
      YohPalStreamingPhase.ended => 'Ended',
      YohPalStreamingPhase.failed => 'Failed',
    };

    return Semantics(
      liveRegion: true,
      label: 'Streaming status: $label',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 7,
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _StreamingErrorPanel extends StatelessWidget {
  const _StreamingErrorPanel({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
