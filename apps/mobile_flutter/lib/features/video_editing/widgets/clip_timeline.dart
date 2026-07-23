import 'package:flutter/material.dart';

import '../models/video_clip_edit.dart';

/// Horizontal, reorderable strip of clip tiles. Tile width is proportional
/// to each clip's edited (post-trim) duration so the strip reads as an
/// actual timeline, not just a plain list.
class ClipTimeline extends StatelessWidget {
  const ClipTimeline({
    super.key,
    required this.clips,
    required this.selectedClipId,
    required this.onSelect,
    required this.onReorder,
    required this.onDelete,
  });

  final List<VideoClipEdit> clips;
  final String? selectedClipId;
  final ValueChanged<String> onSelect;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<String> onDelete;

  static const double _pxPerSecond = 28;
  static const double _minTileWidth = 64;

  @override
  Widget build(BuildContext context) {
    if (clips.isEmpty) {
      return Container(
        height: 88,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF101527),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Add a clip to start building your timeline',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
      );
    }

    return SizedBox(
      height: 88,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        buildDefaultDragHandles: false,
        itemCount: clips.length,
        onReorderItem: (oldIndex, newIndex) => onReorder(oldIndex, newIndex),
        itemBuilder: (context, index) {
          final clip = clips[index];
          final selected = clip.id == selectedClipId;
          final width = (clip.editedDurationMs / 1000 * _pxPerSecond)
              .clamp(_minTileWidth, 240)
              .toDouble();

          return ReorderableDragStartListener(
            key: ValueKey(clip.id),
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelect(clip.id),
                child: Container(
                  width: width,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2230),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? const Color(0xFF00D9FF) : Colors.white12,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '#${index + 1}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => onDelete(clip.id),
                            child: const Icon(Icons.close,
                                color: Colors.white54, size: 16),
                          ),
                        ],
                      ),
                      Text(
                        '${(clip.editedDurationMs / 1000).toStringAsFixed(1)}s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
