import 'package:flutter/material.dart';
import '../models/ai_thumbnail_idea.dart';

class ThumbnailIdeaSelector extends StatelessWidget {
  final List<AiThumbnailIdea> ideas;
  final AiThumbnailIdea? selected;
  final void Function(AiThumbnailIdea idea) onSelect;

  const ThumbnailIdeaSelector({
    super.key,
    required this.ideas,
    required this.onSelect,
    this.selected,
  });

  @override
  Widget build(BuildContext context) {
    if (ideas.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thumbnail Ideas — tap to select',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...ideas.asMap().entries.map((entry) {
          final idx = entry.key;
          final idea = entry.value;
          final isSelected = selected == idea;
          return GestureDetector(
            onTap: () => onSelect(idea),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF00D9FF).withAlpha(30)
                    : const Color(0xFF1A2035),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF00D9FF)
                      : Colors.white12,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${idx + 1}.',
                    style: const TextStyle(
                      color: Color(0xFF00D9FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          idea.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          idea.textOverlay,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle,
                        color: Color(0xFF00D9FF), size: 18),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
