import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/live_session_model.dart';
import '../repositories/live_repository.dart';
import 'live_viewer_screen.dart';

class LiveDiscoveryScreen extends StatelessWidget {
  const LiveDiscoveryScreen({super.key});

  static const routeName = '/live';

  @override
  Widget build(BuildContext context) {
    final repo = context.read<LiveRepository>();
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050816),
        title: const Text('Live Now'),
      ),
      body: StreamBuilder<List<LiveSessionModel>>(
        stream: repo.watchPublicLiveSessions(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Failed to load live sessions',
                  style: TextStyle(color: Colors.white)),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final sessions = snapshot.data!;
          if (sessions.isEmpty) {
            return const Center(
              child: Text('No one is live yet',
                  style: TextStyle(color: Colors.white54)),
            );
          }
          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return ListTile(
                title: Text(session.title,
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  '${session.viewerCount} watching',
                  style: const TextStyle(color: Colors.white54),
                ),
                trailing: const Icon(Icons.play_arrow, color: Colors.white),
                onTap: () => Navigator.pushNamed(
                  context,
                  LiveViewerScreen.routeName,
                  arguments: session.id,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
