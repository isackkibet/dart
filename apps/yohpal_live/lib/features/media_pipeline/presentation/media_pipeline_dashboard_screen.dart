import 'package:flutter/material.dart';
import '../../../core/auth/yohpal_auth_service.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/yohpal_error_view.dart';
import '../../../shared/widgets/yohpal_loading.dart';
import '../application/media_pipeline_controller.dart';
import '../data/media_pipeline_repository.dart';
import '../domain/media_job.dart';

enum _JobFilter { all, active, completed, failed }

class MediaPipelineDashboardScreen extends StatefulWidget {
  const MediaPipelineDashboardScreen({super.key});

  @override
  State<MediaPipelineDashboardScreen> createState() =>
      _MediaPipelineDashboardScreenState();
}

class _MediaPipelineDashboardScreenState
    extends State<MediaPipelineDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final MediaPipelineController _controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final env = AppEnvironmentConfig.fromDartDefines();
    final auth = YohPalAuthService();
    _controller = MediaPipelineController(
      repository: MediaPipelineRepository(
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
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  List<MediaJob> _filteredJobs(_JobFilter filter) {
    return switch (filter) {
      _JobFilter.all => _controller.jobs,
      _JobFilter.active => _controller.activeJobs,
      _JobFilter.completed => _controller.completedJobs,
      _JobFilter.failed => _controller.failedJobs,
    };
  }

  Color _statusColor(String status) => switch (status) {
        'completed' => Colors.green,
        'processing' => Colors.blue,
        'queued' => Colors.orange,
        'failed' => Colors.red,
        'cancelled' => Colors.grey,
        _ => Colors.grey,
      };

  IconData _jobTypeIcon(String jobType) => switch (jobType) {
        'clip_export' => Icons.movie_filter,
        'transcode' => Icons.transform,
        'thumbnail' => Icons.image,
        'replay_package' => Icons.replay,
        'distribute' => Icons.send,
        _ => Icons.work,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Pipeline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _controller.startWatching,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Done'),
            Tab(text: 'Failed'),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.jobs.isEmpty && _controller.failure != null) {
            return YohPalErrorView(
              message: _controller.failure!.message,
              onRetry: _controller.startWatching,
            );
          }
          if (_controller.jobs.isEmpty) {
            return const YohPalLoading(message: 'Loading pipeline jobs...');
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _JobList(
                jobs: _filteredJobs(_JobFilter.all),
                controller: _controller,
                statusColor: _statusColor,
                jobTypeIcon: _jobTypeIcon,
              ),
              _JobList(
                jobs: _filteredJobs(_JobFilter.active),
                controller: _controller,
                statusColor: _statusColor,
                jobTypeIcon: _jobTypeIcon,
              ),
              _JobList(
                jobs: _filteredJobs(_JobFilter.completed),
                controller: _controller,
                statusColor: _statusColor,
                jobTypeIcon: _jobTypeIcon,
              ),
              _JobList(
                jobs: _filteredJobs(_JobFilter.failed),
                controller: _controller,
                statusColor: _statusColor,
                jobTypeIcon: _jobTypeIcon,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _JobList extends StatelessWidget {
  const _JobList({
    required this.jobs,
    required this.controller,
    required this.statusColor,
    required this.jobTypeIcon,
  });

  final List<MediaJob> jobs;
  final MediaPipelineController controller;
  final Color Function(String) statusColor;
  final IconData Function(String) jobTypeIcon;

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return const Center(child: Text('No jobs in this category.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _JobCard(
        job: jobs[i],
        controller: controller,
        statusColor: statusColor(jobs[i].status),
        icon: jobTypeIcon(jobs[i].jobType),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.job,
    required this.controller,
    required this.statusColor,
    required this.icon,
  });

  final MediaJob job;
  final MediaPipelineController controller;
  final Color statusColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isLoading = controller.isLoading(job.id);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    job.jobTypeLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    job.statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Priority: ${job.priority} · Retries: ${job.retryCount}/${job.maxRetries}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (job.isActive && job.progressPercent != null) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (job.progressPercent! / 100).clamp(0.0, 1.0),
                backgroundColor: statusColor.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation(statusColor),
                borderRadius: BorderRadius.circular(4),
                minHeight: 6,
              ),
              const SizedBox(height: 4),
              Text(
                '${job.progressPercent!.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (job.isFailed && job.errorMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                'Error: ${job.errorMessage}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.red),
              ),
            ],
            if (job.canRetry || job.canCancel) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (job.canRetry)
                    FilledButton.tonalIcon(
                      onPressed: isLoading
                          ? null
                          : () => controller.retryJob(job.id),
                      icon: isLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.replay, size: 16),
                      label: const Text('Retry'),
                    ),
                  if (job.canRetry && job.canCancel)
                    const SizedBox(width: 8),
                  if (job.canCancel)
                    OutlinedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () => controller.cancelJob(job.id),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Cancel'),
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
