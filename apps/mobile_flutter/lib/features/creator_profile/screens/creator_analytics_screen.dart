import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/creator_profile_repository.dart';

class CreatorAnalyticsScreen extends StatelessWidget {
  final String creatorUid;

  const CreatorAnalyticsScreen({
    super.key,
    required this.creatorUid,
  });

  static const routeName = '/creator-profile/analytics';

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CreatorProfileRepository>();
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050816),
        title: const Text('Creator Analytics'),
      ),
      body: FutureBuilder<Map<String, num>>(
        future: repo.getCreatorAnalytics(creatorUid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Failed to load analytics',
                  style: TextStyle(color: Colors.white)),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          return GridView.count(
            padding: const EdgeInsets.all(18),
            crossAxisCount: 3,
            children: [
              _MetricCard(label: 'Views', value: data['views'] ?? 0),
              _MetricCard(label: 'Likes', value: data['likes'] ?? 0),
              _MetricCard(label: 'Shares', value: data['shares'] ?? 0),
            ],
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final num value;

  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF101527),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(label, style: const TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}
