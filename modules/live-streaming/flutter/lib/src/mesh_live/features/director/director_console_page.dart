import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../core/api.dart';
import '../../core/config.dart';

class DirectorConsolePage extends StatefulWidget {
  final String productionId, token, participantId;
  final List<String> cameraPairingUrls;
  const DirectorConsolePage({
    super.key,
    required this.productionId,
    required this.token,
    required this.participantId,
    required this.cameraPairingUrls,
  });
  @override
  State<DirectorConsolePage> createState() => _S();
}

class _S extends State<DirectorConsolePage> {
  late io.Socket socket;
  final renderers = <String, RTCVideoRenderer>{};
  final peers = <String, RTCPeerConnection>{};
  List<Map<String, dynamic>> cameras = [];
  String layout = 'SINGLE';
  final selected = <String>[];
  Map<String, dynamic>? _iceConfig;

  @override
  void initState() {
    super.initState();
    _initIce();
    connect();
  }

  Future<void> _initIce() async {
    _iceConfig = await MeshApi().fetchIceConfig(widget.productionId);
    setState(() {});
  }

  Future<void> connect() async {
    socket = io.io(
      AppConfig.apiBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': widget.token})
          .disableAutoConnect()
          .build(),
    );
    socket.on('production-state', (p) {
      final list = (p['participants'] as List)
          .cast<Map<String, dynamic>>()
          .where((x) => x['role'] == 'CAMERA' && x['connected'] == true)
          .toList();
      setState(() => cameras = list);
      for (final c in list) {
        ensurePeer(c['participantId']);
      }
    });
    socket.on('signal', (m) => handleSignal(Map<String, dynamic>.from(m)));
    socket.connect();
  }

  Future<void> ensurePeer(String id) async {
    if (peers.containsKey(id)) return;
    final r = RTCVideoRenderer();
    await r.initialize();
    final config = _iceConfig ?? AppConfig.defaultIceServers;
    final pc = await createPeerConnection(config);
    pc.onTrack = (e) {
      if (e.streams.isNotEmpty) setState(() => r.srcObject = e.streams.first);
    };
    pc.onIceCandidate = (c) {
      if (c.candidate != null) {
        socket.emit('signal', {
          'productionId': widget.productionId,
          'fromParticipantId': widget.participantId,
          'toParticipantId': id,
          'type': 'ice-candidate',
          'payload': c.toMap(),
        });
      }
    };
    peers[id] = pc;
    renderers[id] = r;
    socket.emit('director-command', {'type': 'REQUEST_OFFER', 'cameraId': id});
  }

  Future<void> handleSignal(Map<String, dynamic> m) async {
    final from = m['fromParticipantId'] as String;
    await ensurePeer(from);
    final pc = peers[from]!;
    if (m['type'] == 'offer') {
      await pc.setRemoteDescription(
        RTCSessionDescription(m['payload']['sdp'], m['payload']['type']),
      );
      final a = await pc.createAnswer();
      await pc.setLocalDescription(a);
      socket.emit('signal', {
        'productionId': widget.productionId,
        'fromParticipantId': widget.participantId,
        'toParticipantId': from,
        'type': 'answer',
        'payload': a.toMap(),
      });
    } else if (m['type'] == 'ice-candidate') {
      final p = m['payload'];
      await pc.addCandidate(
        RTCIceCandidate(p['candidate'], p['sdpMid'], p['sdpMLineIndex']),
      );
    }
  }

  Future<void> apply() async {
    await MeshApi().setLayout(widget.productionId, layout, selected);
  }

  @override
  void dispose() {
    socket.dispose();
    for (final p in peers.values) {
      p.close();
    }
    for (final r in renderers.values) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    final tabs = <Widget>[];
    for (int i = 0; i < widget.cameraPairingUrls.length; i++) {
      final j = i;
      tabs.add(
        Expanded(
          child: Column(
            children: [
              Text('Camera ${j + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: QrImageView(
                  data: widget.cameraPairingUrls[j],
                  padding: const EdgeInsets.all(8),
                ),
              ),
              TextButton(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: widget.cameraPairingUrls[j]),
                  );
                  ScaffoldMessenger.of(c).showSnackBar(
                    SnackBar(content: Text('Camera ${j + 1} link copied')),
                  );
                },
                child: const Text('Copy'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Director Console')),
      body: Column(
        children: [
          SizedBox(height: 200, child: Row(children: tabs)),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              children: cameras.map((cam) {
                final id = cam['participantId'] as String;
                final active = selected.contains(id);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (layout == 'SINGLE') {
                        selected..clear()..add(id);
                      } else {
                        if (active) {
                          selected.remove(id);
                        } else if (selected.length < 2) {
                          selected.add(id);
                        }
                      }
                    });
                  },
                  child: Card(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: renderers[id] == null
                              ? const Center(child: Text('Connecting…'))
                              : RTCVideoView(renderers[id]!,
                                  objectFit:
                                      RTCVideoViewObjectFit
                                          .RTCVideoViewObjectFitCover),
                        ),
                        if (active)
                          const Positioned(
                            right: 8,
                            top: 8,
                            child: Icon(Icons.check_circle),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: layout,
                  items: const [
                    DropdownMenuItem(
                        value: 'SINGLE', child: Text('Single')),
                    DropdownMenuItem(
                        value: 'SPLIT_SCREEN', child: Text('Split screen')),
                  ],
                  onChanged: (v) =>
                      setState(() { layout = v!; selected.clear(); }),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: (layout == 'SINGLE' && selected.length == 1) ||
                          (layout == 'SPLIT_SCREEN' && selected.length == 2)
                      ? apply
                      : null,
                  child: const Text('Take Live'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
