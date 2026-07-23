import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../contracts/streaming_controller_contracts.dart';
import '../integration/live_viewer_coordinator.dart';
import '../models/yohpal_streaming_state.dart';
import 'live_chat_panel.dart';
import 'live_gift_button.dart';

class LiveViewerScreen extends StatefulWidget {
  const LiveViewerScreen({
    super.key,
    required this.roomId,
    required this.accessToken,
    required this.controllerFactory,
    required this.chatEnabled,
    required this.giftsEnabled,
  });

  final String roomId;
  final String accessToken;
  final YohPalViewerContract Function() controllerFactory;
  final bool chatEnabled;
  final bool giftsEnabled;

  @override
  State<LiveViewerScreen> createState() => _LiveViewerScreenState();
}

class _LiveViewerScreenState extends State<LiveViewerScreen>
    with WidgetsBindingObserver {
  late final YohPalViewerContract _controller;
  late final LiveViewerCoordinator _coordinator;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = widget.controllerFactory();
    _coordinator = LiveViewerCoordinator(
      controller: _controller,
    )..addListener(_refresh);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _coordinator.initialize();
      await _coordinator.join(
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            RTCVideoView(
              _controller.remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
            if (state.isBusy)
              const Center(
                child: CircularProgressIndicator(),
              ),
            if (state.phase == YohPalStreamingPhase.failed)
              Center(
                child: _ViewerFailurePanel(
                  message: state.message ?? 'Unable to play this stream.',
                  onRetry: _coordinator.reconnect,
                ),
              ),
            if (state.phase == YohPalStreamingPhase.ended)
              const _StreamEndedPanel(),
            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.chatEnabled && state.isLive)
                    LiveChatPanel(
                      liveSessionId: widget.roomId,
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        IconButton.filledTonal(
                          tooltip: 'Leave live stream',
                          onPressed: () async {
                            await _coordinator.leave();
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                          icon: const Icon(Icons.close),
                        ),
                        const Spacer(),
                        if (widget.giftsEnabled && state.isLive)
                          LiveGiftButton(
                            liveSessionId: widget.roomId,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewerFailurePanel extends StatelessWidget {
  const _ViewerFailurePanel({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.live_tv_outlined),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reconnect'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreamEndedPanel extends StatelessWidget {
  const _StreamEndedPanel();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'This live stream has ended.',
          ),
        ),
      ),
    );
  }
}
