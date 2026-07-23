import 'package:flutter/material.dart';
import '../domain/minor_content_classification.dart';

class MinorContentWarning extends StatelessWidget {
  final VideoAgeRating ageRating;
  final MinorContentType contentType;
  final VoidCallback? onDismiss;

  const MinorContentWarning({
    super.key,
    required this.ageRating,
    required this.contentType,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (contentType == MinorContentType.none &&
        ageRating == VideoAgeRating.general) {
      return const SizedBox.shrink();
    }

    final (color, icon, headline, body) = _content(ageRating, contentType);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: color, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(body, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close, size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
        ],
      ),
    );
  }

  (Color, IconData, String, String) _content(
      VideoAgeRating rating, MinorContentType type) {
    if (type == MinorContentType.minorCreator ||
        type == MinorContentType.minorParticipant) {
      return (
        Colors.orange,
        Icons.child_care,
        'Minor Creator',
        'This content was created by or features a minor. '
            'Guardian consent is on file.',
      );
    }
    if (type == MinorContentType.directedToChildren) {
      return (
        Colors.blue,
        Icons.family_restroom,
        'Directed to Children',
        'This content is specifically made for children under ${rating.minimumRecommendedAge}. '
            'Some features are restricted.',
      );
    }
    if (type == MinorContentType.educationalForMinors) {
      return (
        Colors.teal,
        Icons.school_outlined,
        'Educational Content',
        'Appropriate for viewers aged ${rating.minimumRecommendedAge}+.',
      );
    }
    if (type == MinorContentType.advertisingToMinors) {
      return (
        Colors.amber,
        Icons.campaign_outlined,
        'Child-Safe Advertising',
        'Advertising in this content complies with child-directed ad standards.',
      );
    }
    if (rating == VideoAgeRating.mature || rating == VideoAgeRating.adultsOnly) {
      return (
        Colors.red,
        Icons.warning_amber_rounded,
        'Mature Content — ${rating.label}',
        'Not suitable for viewers under ${rating.minimumRecommendedAge}.',
      );
    }
    return (
      Colors.grey,
      Icons.info_outline,
      rating.label,
      'Rated for viewers aged ${rating.minimumRecommendedAge}+.',
    );
  }
}

class MinorContentBadge extends StatelessWidget {
  final VideoAgeRating ageRating;

  const MinorContentBadge({super.key, required this.ageRating});

  @override
  Widget build(BuildContext context) {
    if (ageRating == VideoAgeRating.general) return const SizedBox.shrink();

    final color = _badgeColor(ageRating);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        ageRating.minimumRecommendedAge == 0
            ? 'ALL'
            : '${ageRating.minimumRecommendedAge}+',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _badgeColor(VideoAgeRating r) {
    switch (r) {
      case VideoAgeRating.earlyChildhood:
      case VideoAgeRating.children:
        return Colors.blue;
      case VideoAgeRating.preTeen:
        return Colors.teal;
      case VideoAgeRating.teen:
        return Colors.green;
      case VideoAgeRating.general:
        return Colors.grey;
      case VideoAgeRating.mature:
        return Colors.orange;
      case VideoAgeRating.adultsOnly:
        return Colors.red;
    }
  }
}
