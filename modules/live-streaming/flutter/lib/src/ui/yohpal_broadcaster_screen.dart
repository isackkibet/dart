import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../config/yohpal_streaming_config.dart';
import '../controllers/yohpal_broadcaster_controller.dart';
import 'widgets/yohpal_error_panel.dart';
import 'widgets/yohpal_live_action_button.dart';
import 'widgets/yohpal_status_pill.dart';
import 'yohpal_live_theme.dart';

class YohPalBroadcasterScreen extends StatefulWidget {
  final YohPalStreamingConfig config;

  const YohPalBroadcasterScreen({
    super.key,
    required this.config,
  });

  @override
  State<YohPalBroadcasterScreen> createState() =>
      _YohPalBroadcasterScreenState();
}

class _YohPalBroadcasterScreenState extends State<YohPalBroadcasterScreen> {
  YohPalBroadcasterController? _controller;
  bool _initialized = false;
  bool _isLive = false;
  bool _busy = false;
  String? _error;

  Future<void> _initialize() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      _controller = YohPalBroadcasterController(
        config: widget.config,
      );
      await _controller!.initializePreview();
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

  Future<void> _goLive() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _controller!.startBroadcast(
        roomId: widget.config.roomId,
        accessToken: widget.config.jwtToken,
      );
      setState(() {
        _isLive = true;
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

  Future<void> _stop() async {
    setState(() {
      _busy = true;
    });
    await _controller?.stopBroadcast();
    setState(() {
      _initialized = false;
      _isLive = false;
      _busy = false;
      _controller = null;
    });
  }

  @override
  void dispose() {
    _controller?.stopBroadcast();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final renderer = _controller?.localRenderer;

    return Scaffold(
      backgroundColor: YohPalLiveTheme.background,
      appBar: AppBar(
        backgroundColor: YohPalLiveTheme.background,
        foregroundColor: YohPalLiveTheme.text,
        title: const Text('Creator Live Studio'),
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
                                'Initialize camera preview',
                                style: TextStyle(
                                  color: YohPalLiveTheme.muted,
                                ),
                              ),
                            )
                          : RTCVideoView(
                              renderer,
                              mirror: true,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    YohPalStatusPill(
                      label: _isLive ? 'LIVE' : 'OFFLINE',
                      active: _isLive,
                      activeColor: YohPalLiveTheme.neon,
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
            label: 'Initialize Preview',
            onPressed: (_initialized || _busy) ? null : _initialize,
          ),
          const SizedBox(height: 10),
          YohPalLiveActionButton(
            label: 'Go Live',
            onPressed: (!_initialized || _isLive || _busy) ? null : _goLive,
          ),
          const SizedBox(height: 10),
          YohPalLiveActionButton(
            label: 'Stop',
            destructive: true,
            onPressed: (!_initialized || _busy) ? null : _stop,
          ),
          const SizedBox(height: 16),
          Container(
            decoration: YohPalLiveTheme.panelDecoration(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Session',
                  style: TextStyle(
                    color: YohPalLiveTheme.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                _row('Room', widget.config.roomId),
                _row('WSS', widget.config.wsUrl),
                _row(
                  'TURN',
                  'turn:${widget.config.lanIp}:3478',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: YohPalLiveTheme.muted,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: YohPalLiveTheme.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
