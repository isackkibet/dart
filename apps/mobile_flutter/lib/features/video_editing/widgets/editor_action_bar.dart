import 'package:flutter/material.dart';

/// Bottom action row for the editor screen: undo/redo, plus a primary
/// "Render" call-to-action once the timeline has at least one clip.
class EditorActionBar extends StatelessWidget {
  const EditorActionBar({
    super.key,
    required this.canUndo,
    required this.canRedo,
    required this.canRender,
    required this.onUndo,
    required this.onRedo,
    required this.onAddClip,
    required this.onRender,
  });

  final bool canUndo;
  final bool canRedo;
  final bool canRender;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onAddClip;
  final VoidCallback onRender;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: canUndo ? onUndo : null,
          icon: const Icon(Icons.undo),
          color: Colors.white,
          disabledColor: Colors.white24,
        ),
        IconButton(
          onPressed: canRedo ? onRedo : null,
          icon: const Icon(Icons.redo),
          color: Colors.white,
          disabledColor: Colors.white24,
        ),
        IconButton(
          onPressed: onAddClip,
          icon: const Icon(Icons.add_circle_outline),
          color: Colors.white,
          tooltip: 'Add clip',
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: canRender ? onRender : null,
          icon: const Icon(Icons.movie_creation_outlined),
          label: const Text('Render'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D9FF),
            foregroundColor: Colors.black,
            disabledBackgroundColor: Colors.white24,
          ),
        ),
      ],
    );
  }
}
