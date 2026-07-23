import 'package:flutter/material.dart';

import '../models/video_clip_edit.dart';

/// Dialog for picking a split point inside a clip's active trim range.
/// Returns the chosen timeline position in ms, or null if cancelled.
class SplitClipDialog extends StatefulWidget {
  const SplitClipDialog({super.key, required this.clip});

  final VideoClipEdit clip;

  static Future<int?> show(BuildContext context, VideoClipEdit clip) {
    return showDialog<int>(
      context: context,
      builder: (_) => SplitClipDialog(clip: clip),
    );
  }

  @override
  State<SplitClipDialog> createState() => _SplitClipDialogState();
}

class _SplitClipDialogState extends State<SplitClipDialog> {
  late double _position;

  @override
  void initState() {
    super.initState();
    _position =
        (widget.clip.trimStartMs + widget.clip.trimEndMs) / 2;
  }

  @override
  Widget build(BuildContext context) {
    final min = widget.clip.trimStartMs.toDouble() + 100;
    final max = widget.clip.trimEndMs.toDouble() - 100;
    final clamped = _position.clamp(min, max);

    return AlertDialog(
      backgroundColor: const Color(0xFF101527),
      title: const Text('Split Clip', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Split at ${(clamped / 1000).toStringAsFixed(1)}s',
            style: const TextStyle(color: Colors.white70),
          ),
          Slider(
            value: clamped,
            min: min,
            max: max,
            activeColor: const Color(0xFF00D9FF),
            inactiveColor: Colors.white24,
            onChanged: (value) => setState(() => _position = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, clamped.round()),
          child: const Text('Split'),
        ),
      ],
    );
  }
}
