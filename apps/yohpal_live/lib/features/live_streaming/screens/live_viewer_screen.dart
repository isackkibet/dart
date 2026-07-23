import 'package:flutter/material.dart';
import '../widgets/live_chat_panel.dart';
import '../widgets/live_gift_button.dart';

class LiveViewerScreen extends StatefulWidget {
  const LiveViewerScreen({super.key});
  @override
  State<LiveViewerScreen> createState() => _LiveViewerScreenState();
}

class _LiveViewerScreenState extends State<LiveViewerScreen> {
  bool _joining = true;
  bool _connected = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _joinLive();
  }
  Future<void> _joinLive() async {
    try {
      // TODO: Wire to LS-2 validated YohPalViewerController.
      // await viewerController.joinAndConsume();
      setState(() {
        _connected = true;
      });
    } catch (_) {
      setState(() {
        _error = 'Unable to join live stream.';
      });
    } finally {
      setState(() {
        _joining = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_joining) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live')),
        body: Center(child: Text(_error!)),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Live Now')),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              alignment: Alignment.center,
              child: Text(
                _connected
                    ? 'Remote video renderer here'
                    : 'Connecting...',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          const LiveChatPanel(),
          const LiveGiftButton(),
        ],
      ),
    );
  }
}
