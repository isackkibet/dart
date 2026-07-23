import 'package:flutter/material.dart';
import '../../../core/auth/yohpal_auth_service.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/yohpal_error_view.dart';
import '../../../shared/widgets/yohpal_loading.dart';
import '../../../core/models/result.dart';
import '../../media_pipeline/presentation/media_pipeline_dashboard_screen.dart';
import '../application/clip_factory_controller.dart';
import '../data/clip_factory_repository.dart';
import '../domain/clip_segment.dart';

class ClipFactoryScreen extends StatefulWidget {
  const ClipFactoryScreen({
    super.key,
    required this.sessionId,
    required this.sessionTitle,
  });

  final String sessionId;
  final String sessionTitle;

  @override
  State<ClipFactoryScreen> createState() => _ClipFactoryScreenState();
}

class _ClipFactoryScreenState extends State<ClipFactoryScreen> {
  late final ClipFactoryController _controller;

  @override
  void initState() {
    super.initState();
    final env = AppEnvironmentConfig.fromDartDefines();
    _controller = ClipFactoryController(
      repository: ClipFactoryRepository(
        apiClient: ApiClient(
          baseUrl: env.apiBaseUrl,
          tokenProvider: () => YohPalAuthService().getIdToken(),
        ),
      ),
      sessionId: widget.sessionId,
    );
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    await _controller.generate();
    if (mounted && _controller.failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_controller.failure!.message)),
      );
    }
  }

  Future<void> _approveClip(String clipId) async {
    await _controller.approveClip(clipId);
  }

  Future<void> _rejectClip(String clipId) async {
    await _controller.rejectClip(clipId);
  }

  Future<void> _distributeClip(String clipId) async {
    await _controller.distributeClip(clipId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clip queued for distribution!')),
      );
    }
  }

  void _openPipeline() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MediaPipelineDashboardScreen(),
      ),
    );
  }

  Color _statusColor(BuildContext context, String status) {
    return switch (status) {
      'approved' => Colors.green,
      'rejected' => Colors.red,
      'distributed' => Colors.blue,
      'exported' => Colors.teal,
      'exporting' => Colors.orange,
      _ => Theme.of(context).colorScheme.outline,
    };
  }

  IconData _triggerIcon(String triggerEventType) {
    return switch (triggerEventType) {
      'gift_spike' => Icons.card_giftcard,
      'paid_message' => Icons.attach_money,
      'peak_viewers' => Icons.visibility,
      'teaser_conversion' => Icons.play_circle_outline,
      'autonomy_decision' => Icons.psychology,
      _ => Icons.auto_awesome,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Clip Factory — ${widget.sessionTitle}'),
            actions: [
              IconButton(
                onPressed: _controller.load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: _controller.isLoading && _controller.replay == null
              ? const YohPalLoading(message: 'Loading clip factory...')
              : _controller.failure != null && _controller.replay == null
                  ? YohPalErrorView(
                      message: _controller.failure!.message,
                      onRetry: _controller.load,
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_controller.replay != null)
                          _ReplayCard(replay: _controller.replay!),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _controller.isGenerating ? null : _generate,
                          icon: _controller.isGenerating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: Text(
                            _controller.isGenerating
                                ? 'Generating AI Clips...'
                                : 'Generate AI Clips',
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'AI Clip Segments (${_controller.clips.length})',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        if (_controller.clips.isEmpty)
                          const Text(
                            'No clips yet. Tap "Generate AI Clips" to analyse this session.',
                          ),
                        for (final clip in _controller.clips)
                          _ClipCard(
                            clip: clip,
                            triggerIcon: _triggerIcon(clip.triggerEventType),
                            statusColor: _statusColor(context, clip.status),
                            onApprove: () => _approveClip(clip.id),
                            onReject: () => _rejectClip(clip.id),
                            onDistribute: () => _distributeClip(clip.id),
                            onExport: _openPipeline,
                          ),
                      ],
                    ),
        );
      },
    );
  }
}

class _ReplayCard extends StatelessWidget {
  const _ReplayCard({required this.replay});
  final dynamic replay;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Replay',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.videocam, size: 16),
                const SizedBox(width: 8),
                Text('Status: ${replay.status}'),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.timer, size: 16),
                const SizedBox(width: 8),
                Text('Duration: ${replay.formattedDuration}'),
              ],
            ),
            if (replay.storageRef.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.cloud, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      replay.storageRef,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ClipCard extends StatelessWidget {
  const _ClipCard({
    required this.clip,
    required this.triggerIcon,
    required this.statusColor,
    required this.onApprove,
    required this.onReject,
    required this.onDistribute,
    required this.onExport,
  });

  final ClipSegment clip;
  final IconData triggerIcon;
  final Color statusColor;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDistribute;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(triggerIcon, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    clip.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    clip.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${clip.formattedDuration} • Score: ${(clip.triggerScore * 100).toStringAsFixed(0)}% • ${clip.triggerEventType.replaceAll('_', ' ')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (clip.suggestedPlatforms.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: clip.suggestedPlatforms
                    .map(
                      (p) => Chip(
                        label: Text(p),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
            if (clip.status == 'proposed') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  FilledButton(
                    onPressed: onApprove,
                    child: const Text('Approve'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onReject,
                    child: const Text('Reject'),
                  ),
                ],
              ),
            ],
            if (clip.status == 'approved') ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: onDistribute,
                    icon: const Icon(Icons.send),
                    label: const Text('Send to Platforms'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onExport,
                    icon: const Icon(Icons.movie_filter),
                    label: const Text('Export via Pipeline'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
