import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/video_upload_repository.dart';

class VideoProcessingStatusScreen extends StatefulWidget {
  final String videoId;

  const VideoProcessingStatusScreen({super.key, required this.videoId});

  @override
  State<VideoProcessingStatusScreen> createState() =>
      _VideoProcessingStatusScreenState();
}

class _VideoProcessingStatusScreenState
    extends State<VideoProcessingStatusScreen> {
  bool _navigated = false;

  void _returnToFeed() {
    if (_navigated) return;
    _navigated = true;
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<VideoUploadRepository>();
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050816),
        title: const Text('Processing Video'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: repo.watchVideo(widget.videoId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final status = data['status'] ?? 'unknown';

          if (status == 'live') {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _returnToFeed());
          }

          return Center(
            child: Card(
              color: const Color(0xFF101527),
              margin: const EdgeInsets.all(18),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      status == 'live'
                          ? Icons.check_circle
                          : Icons.hourglass_top,
                      color: const Color(0xFF00D9FF),
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Status: $status',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      status == 'live'
                          ? 'Your video is live! Taking you back to the feed…'
                          : 'Your video will appear in the feed after transcoding and moderation.',
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
