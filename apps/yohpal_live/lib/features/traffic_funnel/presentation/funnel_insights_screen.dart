import 'package:flutter/material.dart';
import '../../../core/auth/yohpal_auth_service.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/yohpal_error_view.dart';
import '../../../shared/widgets/yohpal_loading.dart';
import '../../multistream_v2/domain/live_session.dart';
import '../application/funnel_insights_controller.dart';
import '../data/funnel_summary_repository.dart';

class FunnelInsightsScreen extends StatefulWidget {
  const FunnelInsightsScreen({
    super.key,
    required this.session,
  });

  final LiveSession session;

  @override
  State<FunnelInsightsScreen> createState() => _FunnelInsightsScreenState();
}

class _FunnelInsightsScreenState extends State<FunnelInsightsScreen> {
  late final FunnelInsightsController _controller;

  @override
  void initState() {
    super.initState();
    final env = AppEnvironmentConfig.fromDartDefines();
    _controller = FunnelInsightsController(
      repository: FunnelSummaryRepository(
        apiClient: ApiClient(
          baseUrl: env.apiBaseUrl,
          tokenProvider: () => YohPalAuthService().getIdToken(),
        ),
      ),
    );
    _controller.load(widget.session.id);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _maxValue(Map<String, int> values) {
    if (values.isEmpty) return 1;
    return values.values.reduce((a, b) => a > b ? a : b);
  }

  Widget _barMap(String title, Map<String, int> values) {
    final max = _maxValue(values);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: values.isEmpty
            ? Text('$title: No data yet.')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  for (final entry in values.entries) ...[
                    Row(
                      children: [
                        SizedBox(width: 90, child: Text(entry.key)),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: entry.value / max,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(entry.value.toString()),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final summary = _controller.summary;
        return Scaffold(
          appBar: AppBar(
            title: Text('Funnel Insights: ${widget.session.title}'),
            actions: [
              IconButton(
                onPressed: () => _controller.load(widget.session.id),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: _controller.isLoading && summary == null
              ? const YohPalLoading(message: 'Loading funnel insights...')
              : _controller.failure != null && summary == null
                  ? YohPalErrorView(
                      message: _controller.failure!.message,
                      onRetry: () => _controller.load(widget.session.id),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _MetricCard(
                              title: 'Traffic Events',
                              value: '${summary?.totalEvents ?? 0}',
                            ),
                            _MetricCard(
                              title: 'Conversions',
                              value: '${summary?.totalConversions ?? 0}',
                            ),
                            _MetricCard(
                              title: 'Revenue',
                              value:
                                  'KES ${(summary?.totalRevenue ?? 0).toStringAsFixed(2)}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _barMap('Traffic by Platform', summary?.byPlatform ?? {}),
                        _barMap('Events by Type', summary?.byEventType ?? {}),
                        _barMap(
                          'Conversions by Type',
                          summary?.byConversionType ?? {},
                        ),
                      ],
                    ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
