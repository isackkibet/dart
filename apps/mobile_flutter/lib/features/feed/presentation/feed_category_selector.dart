import 'package:flutter/material.dart';
import '../domain/feed_category.dart';

class FeedCategorySelector extends StatelessWidget {
  const FeedCategorySelector({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final FeedCategory selected;
  final ValueChanged<FeedCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Semantics(
        container: true,
        label: 'Video feed categories',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: FeedCategory.values.map((category) {
            final active = category == selected;
            return TextButton(
              key: ValueKey('feed-category-${category.name}'),
              onPressed: () => onSelected(category),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category.label,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: active ? 28 : 0,
                    height: 2,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
