import 'package:flutter/material.dart';
import '../../../core/auth/yohpal_auth_scope.dart';
import '../../../core/auth/yohpal_auth_service.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/yohpal_error_view.dart';
import '../../../shared/widgets/yohpal_loading.dart';
import '../application/creator_growth_controller.dart';
import '../data/creator_growth_repository.dart';
import '../domain/creator_growth_score.dart';

class CreatorGrowthDashboardScreen extends StatefulWidget {
  const CreatorGrowthDashboardScreen({super.key});

  @override
  State<CreatorGrowthDashboardScreen> createState() =>
      _CreatorGrowthDashboardScreenState();
}

class _CreatorGrowthDashboardScreenState
    extends State<CreatorGrowthDashboardScreen> {
  late final CreatorGrowthController _controller;

  @override
  void initState() {
    super.initState();
    final env = AppEnvironmentConfig.fromDartDefines();
    _controller = CreatorGrowthController(
      repository: CreatorGrowthRepository(
        apiClient: ApiClient(
          baseUrl: env.apiBaseUrl,
          tokenProvider: () => YohPalAuthService().getIdToken(),
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = YohPalAuthScope.read(context).user;
      if (user != null) {
        _controller.load(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final user = YohPalAuthScope.read(context).user;
    if (user != null) {
      await _controller.load(user.uid);
    }
  }

  Future<void> _generate() async {
    final user = YohPalAuthScope.read(context).user;
    if (user != null) {
      await _controller.generate(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final score = _controller.score;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Creator Growth Autopilot'),
            actions: [
              IconButton(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: _controller.isLoading && score == null
              ? const YohPalLoading(message: 'Loading creator growth...')
              : _controller.failure != null && score == null
                  ? YohPalErrorView(
                      message: _controller.failure!.message,
                      onRetry: _reload,
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (score != null) _GrowthScoreCard(score: score),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _generate,
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Generate AI Growth Recommendations'),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Recommendations',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        if (_controller.recommendations.isEmpty)
                          const Text('No recommendations yet.'),
                        for (final item in _controller.recommendations)
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.tips_and_updates),
                              title: Text(item.title),
                              subtitle: Text(
                                '${item.category} • ${item.priority}\n${item.description}',
                              ),
                              isThreeLine: true,
                              trailing: Chip(label: Text(item.expectedImpact)),
                            ),
                          ),
                      ],
                    ),
        );
      },
    );
  }
}

class _GrowthScoreCard extends StatelessWidget {
  const _GrowthScoreCard({required this.score});

  final CreatorGrowthScore score;

  Widget _scoreRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(value: (value / 100).clamp(0, 1)),
          ),
          const SizedBox(width: 8),
          Text(value.toStringAsFixed(0)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Growth Score', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              score.overallScore.toStringAsFixed(0),
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 16),
            _scoreRow('Reach', score.reachScore),
            _scoreRow('Conversion', score.conversionScore),
            _scoreRow('Retention', score.retentionScore),
            _scoreRow('Monetisation', score.monetisationScore),
            _scoreRow('Consistency', score.consistencyScore),
            _scoreRow('Collaboration', score.collaborationScore),
            _scoreRow('Virality', score.viralityScore),
          ],
        ),
      ),
    );
  }
}
