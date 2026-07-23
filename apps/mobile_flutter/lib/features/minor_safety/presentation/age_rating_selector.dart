import 'package:flutter/material.dart';
import '../domain/minor_content_classification.dart';

class AgeRatingSelector extends StatelessWidget {
  final VideoAgeRating selected;
  final ValueChanged<VideoAgeRating> onChanged;

  const AgeRatingSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Age Rating', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: VideoAgeRating.values.map((rating) {
            final isSelected = rating == selected;
            return ChoiceChip(
              label: Text(rating.label),
              selected: isSelected,
              onSelected: (_) => onChanged(rating),
              selectedColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        Text(
          'Minimum recommended age: ${selected.minimumRecommendedAge == 0 ? 'All ages' : '${selected.minimumRecommendedAge}+'}',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
      ],
    );
  }
}
