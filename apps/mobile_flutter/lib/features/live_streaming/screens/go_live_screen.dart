import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/live_stream_controller.dart';
import '../widgets/live_chat_panel.dart';
import '../widgets/live_product_pinning_panel.dart';
import '../widgets/live_video_view.dart';

class GoLiveScreen extends StatefulWidget {
  const GoLiveScreen({super.key});

  static const routeName = '/go-live';

  @override
  State<GoLiveScreen> createState() => _GoLiveScreenState();
}

class _GoLiveScreenState extends State<GoLiveScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await context.read<LiveStreamController>().startLive(
          creatorId: user.uid,
          title: _title.text.trim().isEmpty
              ? 'YohPal Live Stream'
              : _title.text.trim(),
          description: _description.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final live = context.watch<LiveStreamController>();
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050816),
        title: const Text('Go Live'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(
            controller: _title,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Live title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 20),
          if (live.room != null)
            SizedBox(
              height: 360,
              child: LiveVideoView(room: live.room!),
            ),
          if (live.activeSession != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 260,
              child: LiveChatPanel(sessionId: live.activeSession!.id),
            ),
            const SizedBox(height: 16),
            LiveProductPinningPanel(sessionId: live.activeSession!.id),
          ],
          if (live.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                live.error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          const SizedBox(height: 20),
          if (live.room == null)
            ElevatedButton.icon(
              onPressed: live.loading ? null : _start,
              icon: const Icon(Icons.podcasts),
              label: Text(live.loading ? 'Starting...' : 'Start Live'),
            )
          else
            ElevatedButton.icon(
              onPressed: live.endLive,
              icon: const Icon(Icons.stop_circle),
              label: const Text('End Live'),
            ),
          if (live.activeSession != null) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/multistream',
                  arguments: live.activeSession!.id,
                );
              },
              icon: const Icon(Icons.cast),
              label: const Text('Multistream'),
            ),
          ],
        ],
      ),
    );
  }
}
