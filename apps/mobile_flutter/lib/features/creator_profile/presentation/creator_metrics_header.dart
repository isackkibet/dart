import 'package:flutter/material.dart';
import '../domain/creator_aggregate_metrics.dart';

class CreatorMetricsHeader extends StatelessWidget {
  const CreatorMetricsHeader({
    required this.metrics,
    super.key,
  });

  final CreatorAggregateMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _MetricItem(
          label: 'Videos',
          value: _compactCount(metrics.totalVideos),
        ),
        _MetricItem(
          label: 'Total views',
          value: _compactCount(metrics.totalViews),
        ),
        _MetricItem(
          label: 'Total likes',
          value: _compactCount(metrics.totalLikes),
        ),
        _MetricItem(
          label: 'Followers',
          value: _compactCount(metrics.followerCount),
        ),
      ],
    );
  }

  static String _compactCount(int n) {
    if (n >= 1000000000) return '${(n / 1000000000).toStringAsFixed(1)}B';
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}
