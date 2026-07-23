import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/poll_controller.dart';
import '../models/poll_model.dart';
import '../repositories/poll_repository.dart';

class PollDetailScreen extends StatelessWidget {
  final String pollId;

  const PollDetailScreen({super.key, required this.pollId});
  static const routeName = '/poll';

  @override
  Widget build(BuildContext context) {
    final repo = context.read<PollRepository>();
    final controller = context.watch<PollController>();
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050816),
        title: const Text('Poll'),
      ),
      body: StreamBuilder<PollModel?>(
        stream: repo.watchPoll(pollId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final poll = snapshot.data;
          if (poll == null) {
            return const Center(
              child: Text('Poll not found',
                  style: TextStyle(color: Colors.white54)),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text(
                poll.question,
                style: const TextStyle(color: Colors.white, fontSize: 22),
              ),
              const SizedBox(height: 8),
              Text(
                '${poll.totalVotes} votes',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ...poll.options.map((option) {
                final count = (poll.voteCounts[option] ?? 0) as int;
                final total = poll.totalVotes == 0 ? 1 : poll.totalVotes;
                final percent = ((count / total) * 100).toStringAsFixed(1);

                return Card(
                  color: const Color(0xFF101527),
                  child: ListTile(
                    title: Text(option,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: LinearProgressIndicator(
                      value: poll.totalVotes == 0 ? 0 : count / total,
                    ),
                    trailing: Text(
                      '$percent%',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    onTap: user == null || controller.loading
                        ? null
                        : () => controller.vote(
                              poll: poll,
                              userId: user.uid,
                              option: option,
                            ),
                  ),
                );
              }),
              if (controller.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(controller.error!,
                      style: const TextStyle(color: Colors.redAccent)),
                ),
            ],
          );
        },
      ),
    );
  }
}
