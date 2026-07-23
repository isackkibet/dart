import 'package:flutter/material.dart';

class GoLiveScreen extends StatefulWidget {
  const GoLiveScreen({super.key});
  @override
  State<GoLiveScreen> createState() => _GoLiveScreenState();
}

class _GoLiveScreenState extends State<GoLiveScreen> {
  bool _starting = false;
  bool _live = false;
  String? _error;
  Future<void> _startLive() async {
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      // TODO: Wire to LS-2 validated YohPalBroadcasterController.
      // await broadcasterController.startBroadcast();
      setState(() {
        _live = true;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to start live stream. Please try again.';
      });
    } finally {
      setState(() {
        _starting = false;
      });
    }
  }
  Future<void> _endLive() async {
    // TODO: await broadcasterController.stopBroadcast();
    setState(() => _live = false);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Go Live'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            const Spacer(),
            Icon(
              _live ? Icons.radio_button_checked : Icons.videocam,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              _live ? 'You are live' : 'Ready to go live?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _starting ? null : (_live ? _endLive : _startLive),
              child: Text(
                _starting
                    ? 'Starting...'
                    : _live
                        ? 'End Stream'
                        : 'Start Live',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
