import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/poll_controller.dart';
import '../models/poll_model.dart';
import '../repositories/poll_repository.dart';

class VideoPollOverlay extends StatelessWidget {
  final String videoId;

  const VideoPollOverlay({super.key, required this.videoId});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<PollRepository>();
    final controller = context.watch<PollController>();
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<PollModel?>(
      stream: repo.watchVideoPoll(videoId),
      builder: (context, snapshot) {
        final poll = snapshot.data;
        if (poll == null) return const SizedBox.shrink();

        return Positioned(
          left: 14,
          right: 90,
          bottom: 210,
          child: Card(
            color: const Color(0xEE101527),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    poll.question,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  ...poll.options.take(3).map((option) {
                    final count = (poll.voteCounts[option] ?? 0) as int;
                    final total = poll.totalVotes == 0 ? 1 : poll.totalVotes;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        onTap: user == null || controller.loading
                            ? null
                            : () => controller.vote(
                                  poll: poll,
                                  userId: user.uid,
                                  option: option,
                                ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(option,
                                style:
                                    const TextStyle(color: Colors.white70)),
                            LinearProgressIndicator(
                              value: poll.totalVotes == 0
                                  ? 0
                                  : count / total,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/poll',
                      arguments: poll.id,
                    ),
                    child: const Text('View full poll'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
