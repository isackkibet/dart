import 'package:flutter/material.dart';
import '../../../core/auth/yohpal_auth_scope.dart';
import '../../../core/auth/yohpal_auth_service.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/yohpal_error_view.dart';
import '../../../shared/widgets/yohpal_loading.dart';
import '../application/revenue_controller.dart';
import '../data/revenue_repository.dart';

class CreatorRevenueDashboardScreen extends StatefulWidget {
  const CreatorRevenueDashboardScreen({super.key});

  @override
  State<CreatorRevenueDashboardScreen> createState() =>
      _CreatorRevenueDashboardScreenState();
}

class _CreatorRevenueDashboardScreenState
    extends State<CreatorRevenueDashboardScreen> {
  late final RevenueController _controller;

  @override
  void initState() {
    super.initState();
    final env = AppEnvironmentConfig.fromDartDefines();
    _controller = RevenueController(
      repository: RevenueRepository(
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final summary = _controller.summary;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Creator Revenue'),
            actions: [
              IconButton(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: _controller.isLoading && summary == null
              ? const YohPalLoading(message: 'Loading revenue...')
              : _controller.failure != null && summary == null
                  ? YohPalErrorView(
                      message: _controller.failure!.message,
                      onRetry: _reload,
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _MetricCard(
                              title: 'Available',
                              value:
                                  '${summary?.currency ?? 'KES'} ${(summary?.availableBalance ?? 0).toStringAsFixed(2)}',
                            ),
                            _MetricCard(
                              title: 'Pending',
                              value:
                                  '${summary?.currency ?? 'KES'} ${(summary?.pendingBalance ?? 0).toStringAsFixed(2)}',
                            ),
                            _MetricCard(
                              title: 'Gifts',
                              value:
                                  '${summary?.currency ?? 'KES'} ${(summary?.giftRevenue ?? 0).toStringAsFixed(2)}',
                            ),
                            _MetricCard(
                              title: 'Paid Messages',
                              value:
                                  '${summary?.currency ?? 'KES'} ${(summary?.paidMessageRevenue ?? 0).toStringAsFixed(2)}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Recent Ledger Entries',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        if (_controller.ledger.isEmpty)
                          const Text('No ledger entries yet.'),
                        for (final entry in _controller.ledger)
                          Card(
                            child: ListTile(
                              leading: Icon(
                                entry.direction == 'credit'
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                              ),
                              title: Text(entry.entryType),
                              subtitle: Text(
                                '${entry.referenceType} • ${entry.referenceId}',
                              ),
                              trailing: Text(
                                '${entry.currency} ${entry.amount.toStringAsFixed(2)}',
                              ),
                            ),
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
      width: 190,
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
