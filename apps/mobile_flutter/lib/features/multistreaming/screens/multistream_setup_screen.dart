import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/multistream_controller.dart';
import '../repositories/multistream_repository.dart';

class MultistreamSetupScreen extends StatefulWidget {
  final String liveSessionId;

  const MultistreamSetupScreen({
    super.key,
    required this.liveSessionId,
  });

  static const routeName = '/multistream';

  @override
  State<MultistreamSetupScreen> createState() => _MultistreamSetupScreenState();
}

class _MultistreamSetupScreenState extends State<MultistreamSetupScreen> {
  String _selectedPlatform = 'YouTube';
  final rtmpUrl = TextEditingController();
  final streamKey = TextEditingController();
  final List<Map<String, String>> destinations = [];

  @override
  void dispose() {
    rtmpUrl.dispose();
    streamKey.dispose();
    super.dispose();
  }

  void addDestination() {
    if (rtmpUrl.text.trim().isEmpty || streamKey.text.trim().isEmpty) return;
    setState(() {
      destinations.add({
        'platform': _selectedPlatform,
        'rtmpUrl': rtmpUrl.text.trim(),
        'streamKey': streamKey.text.trim(),
      });
      rtmpUrl.clear();
      streamKey.clear();
    });
  }

  Future<void> start() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await context.read<MultistreamController>().createAndStart(
          liveSessionId: widget.liveSessionId,
          creatorId: user.uid,
          destinations: destinations,
        );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MultistreamController>();
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050816),
        title: const Text('Multistream Setup'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          DropdownButton<String>(
            value: _selectedPlatform,
            dropdownColor: const Color(0xFF101527),
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'YouTube', child: Text('YouTube')),
              DropdownMenuItem(value: 'Facebook', child: Text('Facebook')),
              DropdownMenuItem(value: 'TikTok', child: Text('TikTok')),
              DropdownMenuItem(value: 'Twitch', child: Text('Twitch')),
              DropdownMenuItem(value: 'Custom RTMP', child: Text('Custom RTMP')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _selectedPlatform = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: rtmpUrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'RTMP URL'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: streamKey,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Stream Key'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: addDestination,
            icon: const Icon(Icons.add),
            label: const Text('Add Destination'),
          ),
          const SizedBox(height: 20),
          ...destinations.map(
            (d) => Card(
              color: const Color(0xFF101527),
              child: ListTile(
                title: Text(d['platform']!,
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text(d['rtmpUrl']!,
                    style: const TextStyle(color: Colors.white54)),
              ),
            ),
          ),
          if (controller.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(controller.error!,
                  style: const TextStyle(color: Colors.redAccent)),
            ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed:
                controller.loading || destinations.isEmpty ? null : start,
            icon: const Icon(Icons.broadcast_on_personal),
            label: Text(
                controller.loading ? 'Starting...' : 'Start Multistream'),
          ),
          if (controller.activeSessionId != null) ...[
            const SizedBox(height: 20),
            _DestinationHealth(sessionId: controller.activeSessionId!),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: controller.stop,
              icon: const Icon(Icons.stop_circle),
              label: const Text('Stop Multistream'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DestinationHealth extends StatelessWidget {
  final String sessionId;

  const _DestinationHealth({required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<MultistreamRepository>();
    final controller = context.read<MultistreamController>();
    return StreamBuilder(
      stream: repo.watchDestinations(sessionId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }
        final destinations = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Destination Health',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            ...destinations.map(
              (d) => Card(
                color: const Color(0xFF101527),
                child: ListTile(
                  title: Text(d.platform,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    '${d.status} · key ${d.streamKeyMasked}'
                    '${d.error == null ? '' : '\n${d.error}'}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: d.status == 'failed'
                      ? IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: () => controller.retryDestination(d.id),
                        )
                      : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
