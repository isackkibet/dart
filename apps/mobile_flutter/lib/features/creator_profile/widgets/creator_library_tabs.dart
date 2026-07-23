import 'package:flutter/material.dart';
import '../domain/creator_library_category.dart';

class CreatorLibraryTabs extends StatelessWidget {
  const CreatorLibraryTabs({
    required this.isOwner,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final bool isOwner;
  final CreatorLibraryCategory selected;
  final ValueChanged<CreatorLibraryCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    final categories = availableCreatorCategories(isOwner: isOwner);

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          return ChoiceChip(
            selected: category == selected,
            label: Text(category.label),
            onSelected: (_) => onSelected(category),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: categories.length,
      ),
    );
  }
}
