import 'dart:async';
import 'package:flutter/material.dart';
import '../../../shared/widgets/yohpal_loading.dart';
import '../domain/live_session.dart';
import '../orchestration/stream_health.dart';
import '../orchestration/stream_orchestration_repository.dart';
import '../orchestration/stream_route_policy.dart';

class StreamControlScreen extends StatefulWidget {
  const StreamControlScreen({
    super.key,
    required this.session,
  });

  final LiveSession session;

  @override
  State<StreamControlScreen> createState() => _StreamControlScreenState();
}

class _StreamControlScreenState extends State<StreamControlScreen> {
  final _repository = StreamOrchestrationRepository();
  StreamSubscription<List<StreamRoutePolicy>>? _policySub;
  StreamSubscription<StreamHealth?>? _healthSub;
  List<StreamRoutePolicy> _policies = const [];
  StreamHealth? _health;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _policySub = _repository.watchPolicies(widget.session.id).listen((items) {
      setState(() {
        _policies = items;
        _loading = false;
      });
    });
    _healthSub = _repository.watchHealth(widget.session.id).listen((health) {
      setState(() => _health = health);
    });
  }

  @override
  void dispose() {
    _policySub?.cancel();
    _healthSub?.cancel();
    super.dispose();
  }

  Future<void> _sendMockHeartbeat() async {
    await _repository.mockIngestHeartbeat(widget.session.id);
  }

  Future<void> _createDefaultTeaserPolicy() async {
    final policy = StreamRoutePolicy(
      id: '',
      sessionId: widget.session.id,
      destinationId: 'default-destination',
      mode: 'teaser',
      enabled: true,
      delaySeconds: 20,
      previewWindowSeconds: 60,
      ctaOverlayEnabled: true,
      ctaText: 'Join the full live on YohPal',
      ctaUrl: 'https://yohpal.live/watch/${widget.session.id}',
      watermarkEnabled: true,
      blurAfterPreview: true,
      createdAt: null,
      updatedAt: null,
    );
    await _repository.upsertPolicy(policy);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stream Control: ${widget.session.title}'),
      ),
      body: _loading
          ? const YohPalLoading(message: 'Loading stream control...')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HealthCard(health: _health),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _sendMockHeartbeat,
                  icon: const Icon(Icons.monitor_heart_outlined),
                  label: const Text('Send Mock Ingest Heartbeat'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _createDefaultTeaserPolicy,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Create Default Teaser Policy'),
                ),
                const SizedBox(height: 24),
                Text(
                  'Route Policies',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (_policies.isEmpty)
                  const Text('No stream route policies configured yet.'),
                for (final policy in _policies)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.route),
                      title: Text(policy.mode.toUpperCase()),
                      subtitle: Text(
                        'Delay ${policy.delaySeconds}s • Preview ${policy.previewWindowSeconds}s • CTA ${policy.ctaOverlayEnabled ? "on" : "off"}',
                      ),
                      trailing: Icon(
                        policy.enabled ? Icons.check_circle : Icons.cancel,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.health});

  final StreamHealth? health;

  @override
  Widget build(BuildContext context) {
    final current = health;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: current == null
            ? const Text('No stream health heartbeat received yet.')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stream Health',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('Status: ${current.status}'),
                  Text('Ingest: ${current.ingestStatus}'),
                  Text('Active destinations: ${current.activeDestinations}'),
                  Text('Failed destinations: ${current.failedDestinations}'),
                  Text('Bitrate: ${current.bitrateKbps} kbps'),
                  Text('Latency: ${current.latencyMs} ms'),
                ],
              ),
      ),
    );
  }
}
