import 'package:flutter/material.dart';
import '../../../core/auth/yohpal_auth_service.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/yohpal_error_view.dart';
import '../../../shared/widgets/yohpal_loading.dart';
import '../application/command_center_controller.dart';
import '../data/command_center_repository.dart';
import '../domain/system_health.dart';

class CommandCenterDashboardScreen extends StatefulWidget {
  const CommandCenterDashboardScreen({super.key});

  @override
  State<CommandCenterDashboardScreen> createState() =>
      _CommandCenterDashboardScreenState();
}

class _CommandCenterDashboardScreenState
    extends State<CommandCenterDashboardScreen> {
  late final CommandCenterController _controller;

  @override
  void initState() {
    super.initState();
    final env = AppEnvironmentConfig.fromDartDefines();
    _controller = CommandCenterController(
      repository: CommandCenterRepository(
        apiClient: ApiClient(
          baseUrl: env.apiBaseUrl,
          tokenProvider: () => YohPalAuthService().getIdToken(),
        ),
      ),
    );
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleSafeMode(String key, bool enabled) async {
    await _controller.setSafeMode(
      key: key,
      enabled: enabled,
      reason: enabled
          ? 'Enabled from command center dashboard.'
          : 'Disabled from command center dashboard.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final health = _controller.health;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Go-Live Command Center'),
            actions: [
              IconButton(
                onPressed: _controller.load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: _controller.isLoading && health == null
              ? const YohPalLoading(message: 'Loading command center...')
              : _controller.failure != null && health == null
                  ? YohPalErrorView(
                      message: _controller.failure!.message,
                      onRetry: _controller.load,
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (health != null) _SystemHealthCard(health: health),
                        const SizedBox(height: 16),
                        Text(
                          'Safe Mode Controls',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        if (_controller.safeModeToggles.isEmpty)
                          const Text('No safe-mode toggles configured.'),
                        for (final toggle in _controller.safeModeToggles)
                          Card(
                            child: SwitchListTile(
                              value: toggle.enabled,
                              title: Text(toggle.label),
                              subtitle: Text(toggle.reason),
                              onChanged: (value) =>
                                  _toggleSafeMode(toggle.key, value),
                            ),
                          ),
                        const SizedBox(height: 24),
                        Text(
                          'Open Incidents',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        if (_controller.incidents.isEmpty)
                          const Text('No incidents.'),
                        for (final incident in _controller.incidents)
                          Card(
                            child: ListTile(
                              leading: Icon(
                                incident.severity == 'p0' ||
                                        incident.severity == 'p1'
                                    ? Icons.warning_amber
                                    : Icons.info_outline,
                              ),
                              title: Text(incident.title),
                              subtitle: Text(
                                '${incident.severity.toUpperCase()} • ${incident.status} • ${incident.affectedService}\n${incident.description}',
                              ),
                              isThreeLine: true,
                              trailing: incident.status == 'resolved'
                                  ? const Chip(label: Text('Resolved'))
                                  : TextButton(
                                      onPressed: () => _controller
                                          .resolveIncident(incident.id),
                                      child: const Text('Resolve'),
                                    ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        Text(
                          'Auto-Response Rules',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        if (_controller.rules.isEmpty)
                          const Text('No auto-response rules configured.'),
                        for (final rule in _controller.rules)
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.auto_fix_high),
                              title: Text(rule.name),
                              subtitle: Text(
                                '${rule.eventType} • if ${rule.conditionMetric} ${rule.conditionOperator} ${rule.conditionValue} → ${rule.actionType}',
                              ),
                              trailing: Chip(
                                label: Text(rule.enabled ? 'Enabled' : 'Off'),
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

class _SystemHealthCard extends StatelessWidget {
  const _SystemHealthCard({required this.health});
  final SystemHealth health;

  Color _statusColor(BuildContext context, String status) {
    return switch (status) {
      'healthy' => Colors.green,
      'degraded' => Colors.orange,
      'critical' => Colors.red,
      _ => Theme.of(context).colorScheme.outline,
    };
  }

  Widget _metric(BuildContext context, String label, String value) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
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

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, health.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 6, backgroundColor: color),
                const SizedBox(width: 8),
                Text(
                  'System Status: ${health.status.toUpperCase()}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metric(context, 'API', health.apiStatus),
                _metric(context, 'Firestore', health.firestoreStatus),
                _metric(context, 'Functions', health.functionsStatus),
                _metric(context, 'Auth', health.authStatus),
                _metric(
                  context,
                  'Active Lives',
                  health.activeLiveSessions.toString(),
                ),
                _metric(
                  context,
                  'Open Incidents',
                  health.openIncidents.toString(),
                ),
                _metric(
                  context,
                  'Critical',
                  health.criticalIncidents.toString(),
                ),
                _metric(
                  context,
                  'Safe Mode',
                  health.safeModeEnabled ? 'ON' : 'OFF',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
