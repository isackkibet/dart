import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WatchLaterScreen extends StatelessWidget {
  const WatchLaterScreen({super.key});

  static const routeName = '/watch-later';

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream(String uid) {
    return FirebaseFirestore.instance
        .collection('watchLater')
        .where('userId', isEqualTo: uid)
        .orderBy('savedAt', descending: true)
        .limit(50)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF050510),
        appBar: AppBar(
          backgroundColor: const Color(0xFF050510),
          title: const Text('Watch Later'),
        ),
        body: const Center(
          child: Text('Sign in to use Watch Later.',
              style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050510),
        title: const Text('Watch Later'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream(user.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('Could not load saved videos.\n${snap.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent)),
            );
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.watch_later_outlined,
                      color: Colors.white24, size: 64),
                  SizedBox(height: 16),
                  Text('No videos saved yet.',
                      style: TextStyle(color: Colors.white54, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Tap the clock icon on any video to save it.',
                      style: TextStyle(color: Colors.white38, fontSize: 13)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data();
              final title = data['videoTitle'] as String? ?? 'Untitled';
              final creator = data['ownerUsername'] as String? ?? '';
              return Card(
                color: const Color(0xFF101020),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.play_circle_outline,
                      color: Color(0xFF7C4DFF)),
                  title: Text(title,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  subtitle: creator.isNotEmpty
                      ? Text('@$creator',
                          style: const TextStyle(color: Colors.white54))
                      : null,
                  trailing: IconButton(
                    icon:
                        const Icon(Icons.delete_outline, color: Colors.white38),
                    onPressed: () => FirebaseFirestore.instance
                        .collection('watchLater')
                        .doc(docs[i].id)
                        .delete(),
                  ),
                  onTap: () {
                    // There's no standalone video-detail route in this app —
                    // playback only happens inside the feed's PageView.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Opening saved videos — coming soon'),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
