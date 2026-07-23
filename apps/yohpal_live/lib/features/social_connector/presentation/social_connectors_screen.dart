import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/auth/yohpal_auth_service.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/yohpal_error_view.dart';
import '../application/social_connector_controller.dart';
import '../data/social_connector_repository.dart';
import '../domain/social_connector.dart';

class SocialConnectorsScreen extends StatefulWidget {
  const SocialConnectorsScreen({super.key});

  @override
  State<SocialConnectorsScreen> createState() => _SocialConnectorsScreenState();
}

class _SocialConnectorsScreenState extends State<SocialConnectorsScreen> {
  late final SocialConnectorController _controller;

  static const _supportedPlatforms = [
    _PlatformMeta('youtube', 'YouTube', Icons.play_circle_fill, Color(0xFFFF0000)),
    _PlatformMeta('tiktok', 'TikTok', Icons.music_note, Color(0xFF010101)),
    _PlatformMeta('instagram', 'Instagram', Icons.camera_alt, Color(0xFFE1306C)),
    _PlatformMeta('facebook', 'Facebook', Icons.facebook, Color(0xFF1877F2)),
    _PlatformMeta('x', 'X (Twitter)', Icons.close, Color(0xFF000000)),
    _PlatformMeta('linkedin', 'LinkedIn', Icons.work, Color(0xFF0A66C2)),
    _PlatformMeta('twitch', 'Twitch', Icons.live_tv, Color(0xFF9146FF)),
    _PlatformMeta('kick', 'Kick', Icons.sports_esports, Color(0xFF53FC18)),
  ];

  @override
  void initState() {
    super.initState();
    final env = AppEnvironmentConfig.fromDartDefines();
    final auth = YohPalAuthService();
    _controller = SocialConnectorController(
      repository: SocialConnectorRepository(
        apiClient: ApiClient(
          baseUrl: env.apiBaseUrl,
          tokenProvider: auth.getIdToken,
        ),
      ),
      creatorId: auth.currentUserId ?? '',
    );
    _controller.startWatching();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _connectPlatform(String platform) async {
    final url = await _controller.getOAuthUrl(platform);
    if (url == null) {
      if (mounted && _controller.failure != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_controller.failure!.message)),
        );
      }
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _checkHealth(String connectorId) async {
    final health = await _controller.checkHealth(connectorId);
    if (mounted && health != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            health.isHealthy
                ? 'Connection is healthy (${health.latencyMs ?? '--'}ms)'
                : 'Health check failed: ${health.errorMessage ?? health.status}',
          ),
          backgroundColor: health.isHealthy ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _disconnect(SocialConnector connector) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect Platform'),
        content: Text(
          'Disconnect your ${connector.platform} account (@${connector.externalUsername})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await _controller.disconnect(connector.id);
    if (mounted && !ok && _controller.failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_controller.failure!.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Connectors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _controller.startWatching,
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.failure != null && _controller.connectors.isEmpty) {
            return YohPalErrorView(
              message: _controller.failure!.message,
              onRetry: _controller.startWatching,
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Connect your social accounts to enable simultaneous streaming, clip distribution, and growth analytics across all platforms.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 20),
              for (final meta in _supportedPlatforms) ...[
                _PlatformConnectorCard(
                  meta: meta,
                  connector: _controller.connectors
                      .where((c) => c.platform == meta.id)
                      .firstOrNull,
                  health: _controller.healthResults[
                      _controller.connectors
                          .where((c) => c.platform == meta.id)
                          .firstOrNull
                          ?.id ??
                          ''],
                  isCheckingHealth: _controller.connectors
                      .where((c) => c.platform == meta.id)
                      .firstOrNull
                      ?.id
                      .let(_controller.isCheckingHealth) ??
                      false,
                  isDisconnecting: _controller.connectors
                      .where((c) => c.platform == meta.id)
                      .firstOrNull
                      ?.id
                      .let(_controller.isDisconnecting) ??
                      false,
                  isConnectingOAuth: _controller.isLoadingOAuth,
                  onConnect: () => _connectPlatform(meta.id),
                  onCheckHealth: () {
                    final id = _controller.connectors
                        .where((c) => c.platform == meta.id)
                        .firstOrNull
                        ?.id;
                    if (id != null) _checkHealth(id);
                  },
                  onDisconnect: () {
                    final c = _controller.connectors
                        .where((c) => c.platform == meta.id)
                        .firstOrNull;
                    if (c != null) _disconnect(c);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PlatformMeta {
  const _PlatformMeta(this.id, this.label, this.icon, this.color);
  final String id;
  final String label;
  final IconData icon;
  final Color color;
}

extension _LetExt<T> on T {
  R let<R>(R Function(T) block) => block(this);
}

class _PlatformConnectorCard extends StatelessWidget {
  const _PlatformConnectorCard({
    required this.meta,
    required this.connector,
    required this.health,
    required this.isCheckingHealth,
    required this.isDisconnecting,
    required this.isConnectingOAuth,
    required this.onConnect,
    required this.onCheckHealth,
    required this.onDisconnect,
  });

  final _PlatformMeta meta;
  final SocialConnector? connector;
  final dynamic health;
  final bool isCheckingHealth;
  final bool isDisconnecting;
  final bool isConnectingOAuth;
  final VoidCallback onConnect;
  final VoidCallback onCheckHealth;
  final VoidCallback onDisconnect;

  Color _statusColor(String status) {
    return switch (status) {
      'connected' => Colors.green,
      'expired' => Colors.orange,
      'revoked' => Colors.red,
      _ => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = connector?.isConnected ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: meta.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(meta.icon, color: meta.color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (isConnected && connector != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '@${connector!.externalUsername}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _statusColor(connector!.status),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          connector!.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _statusColor(connector!.status),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 2),
                    Text(
                      'Not connected',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isConnected)
              FilledButton(
                onPressed: isConnectingOAuth ? null : onConnect,
                style: FilledButton.styleFrom(
                  backgroundColor: meta.color,
                ),
                child: const Text('Connect'),
              )
            else
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'health') onCheckHealth();
                  if (value == 'disconnect') onDisconnect();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'health',
                    child: isCheckingHealth
                        ? const Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Text('Checking...'),
                            ],
                          )
                        : const Row(
                            children: [
                              Icon(Icons.health_and_safety, size: 18),
                              SizedBox(width: 8),
                              Text('Check Health'),
                            ],
                          ),
                  ),
                  const PopupMenuItem(
                    value: 'disconnect',
                    child: Row(
                      children: [
                        Icon(Icons.link_off, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Disconnect',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
                child: isDisconnecting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.more_vert),
              ),
          ],
        ),
      ),
    );
  }
}
