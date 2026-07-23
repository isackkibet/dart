import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../config/yohpal_streaming_config.dart';
import '../controllers/yohpal_viewer_controller.dart';
import '../models/yohpal_streaming_state.dart';
import 'widgets/yohpal_diagnostics_panel.dart';
import 'widgets/yohpal_error_panel.dart';
import 'widgets/yohpal_live_action_button.dart';
import 'widgets/yohpal_status_pill.dart';
import 'yohpal_live_theme.dart';

class YohPalViewerScreen extends StatefulWidget {
  final YohPalStreamingConfig config;

  const YohPalViewerScreen({
    super.key,
    required this.config,
  });

  @override
  State<YohPalViewerScreen> createState() => _YohPalViewerScreenState();
}

class _YohPalViewerScreenState extends State<YohPalViewerScreen> {
  YohPalViewerController? _controller;
  bool _initialized = false;
  bool _busy = false;
  String? _error;
  YohPalStreamingState _state = const YohPalStreamingState.idle();

  Future<void> _initialize() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      _controller = YohPalViewerController(
        config: widget.config,
      );
      await _controller!.initialize();
      setState(() {
        _initialized = true;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  Future<void> _watch() async {
    setState(() {
      _busy = true;
      _error = null;
      _state = _state.copyWith(
        phase: YohPalStreamingPhase.connecting,
        message: 'Joining live stream\u2026',
      );
    });
    try {
      await _controller!.joinStream(
        roomId: widget.config.roomId,
        accessToken: widget.config.jwtToken,
      );
      setState(() {
        _state = _state.copyWith(
          phase: YohPalStreamingPhase.live,
          message: 'Live',
        );
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _state = _state.copyWith(
          phase: YohPalStreamingPhase.failed,
          message: error.toString(),
        );
      });
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  Future<void> _stop() async {
    setState(() {
      _busy = true;
    });
    await _controller?.leaveStream();
    setState(() {
      _initialized = false;
      _busy = false;
      _controller = null;
      _state = const YohPalStreamingState.idle();
    });
  }

  @override
  void dispose() {
    _controller?.leaveStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final renderer = _controller?.remoteRenderer;

    return Scaffold(
      backgroundColor: YohPalLiveTheme.background,
      appBar: AppBar(
        backgroundColor: YohPalLiveTheme.background,
        foregroundColor: YohPalLiveTheme.text,
        title: const Text('Watch Live'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: YohPalLiveTheme.panelDecoration(),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 9 / 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ColoredBox(
                      color: Colors.black,
                      child: renderer == null
                          ? const Center(
                              child: Text(
                                'Initialize viewer',
                                style: TextStyle(
                                  color: YohPalLiveTheme.muted,
                                ),
                              ),
                            )
                          : RTCVideoView(renderer),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    YohPalStatusPill(
                      label: _initialized ? 'READY' : 'IDLE',
                      active: _initialized,
                    ),
                    const Spacer(),
                    if (_busy)
                      const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          YohPalErrorPanel(message: _error),
          const SizedBox(height: 12),
          YohPalLiveActionButton(
            label: 'Initialize Viewer',
            onPressed: (_initialized || _busy) ? null : _initialize,
          ),
          const SizedBox(height: 10),
          YohPalLiveActionButton(
            label: 'Watch',
            onPressed: (!_initialized || _busy) ? null : _watch,
          ),
          const SizedBox(height: 10),
          YohPalLiveActionButton(
            label: 'Stop',
            destructive: true,
            onPressed: (!_initialized || _busy) ? null : _stop,
          ),
          const SizedBox(height: 16),
          YohPalDiagnosticsPanel(state: _state),
        ],
      ),
    );
  }
}
